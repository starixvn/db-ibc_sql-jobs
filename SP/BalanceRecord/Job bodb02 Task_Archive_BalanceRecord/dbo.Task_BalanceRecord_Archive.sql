/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE Task_BalanceRecord_Archive
    @step INT
AS
/*
    Created: 
    DB: DBBAH.bodb02
    Task: 
    Revision:
		- 20230615@Kathy: add new column winlostdate, modds, refno [Redmine:#181595]
*/

-- get list of custid + rowid to archive
IF @step = 1
BEGIN --IF @step = 1

--CREATE TABLE tempdb.dbo.AList (custid int NOT NULL, nRowID bigint, xRowID bigint, cnt int NOT NULL)
--CREATE CLUSTERED INDEX CIX_Alist ON tempdb.dbo.Alist (cnt desc)
--ALTER TABLE tempdb.dbo.AList ADD CONSTRAINT PK_AList PRIMARY KEY NONCLUSTERED (custid)

CREATE TABLE tempdb.dbo.BalanceRecord_Archive_List (id INT IDENTITY(1,1) PRIMARY KEY, custid int NOT NULL, RowID bigint NOT NULL)

-- account not active more than 4 months
-- last balance is zero
-- we archive the last row that kept in BalanceRecord
;WITH CTE AS (
SELECT custid
FROM dbo.BalanceRecord WITH (NOLOCK)
GROUP BY custid
HAVING 
    COUNT(*) = 1 
    AND MAX(ActionDate) < DATEADD(month, -4, CURRENT_TIMESTAMP)
)
SELECT TOP (100000) b.custid, min(RowID) nRowID, min(RowID) + 1 xRowID, 1 CNT
INTO #list1
FROM dbo.BalanceRecord b WITH (NOLOCK)
INNER JOIN CTE ON b.custid = CTE.custid
GROUP BY b.custid
HAVING 
    SUM(cast(b.NewBalance as decimal(21,5))) = 0
--Modify from SUM(NewBalance) = 0 to SUM(cast(b.NewBalance as decimal(21,5))) = 0 :: Joe@20180430

-- remove data to let each custid has only 1 row in BalanceRecord :: Joe@20201013
IF @@ROWCOUNT < 100
BEGIN
    ;WITH CTE AS (
        SELECT custid, min(RowID) nRowID, max(RowID) xRowID, COUNT(*) cnt
        FROM dbo.BalanceRecord WITh (NOLOCK)
        GROUP BY custid
        HAVING COUNT(*) > 1
    )
    SELECT TOP (100000) custid, nRowID, xRowID, cnt
    INTO #list2
    FROM CTE
    WHERE xRowID >= xRowID
    ORDER BY cnt DESC

    INSERT INTO tempdb.dbo.BalanceRecord_Archive_List (custid, RowID)
    SELECT br.custid, br.RowID
    FROM dbo.BalanceRecord br WITH (NOLOCK)
        INNER JOIN #list2 l WITH (NOLOCK) ON br.custid = l.custid AND br.RowID BETWEEN nRowID AND xRowID - 1
END

INSERT INTO tempdb.dbo.BalanceRecord_Archive_List (custid, RowID)
SELECT br.custid, br.RowID
FROM dbo.BalanceRecord br WITH (NOLOCK)
    INNER JOIN #list1 l WITH (NOLOCK) ON br.custid = l.custid AND br.RowID BETWEEN nRowID AND xRowID - 1

END--IF @step = 1


-- archive
IF @step = 2
BEGIN --IF @step = 2

    Declare @id int, @maxid int
    Declare @cnt int
    Declare @custid int, @RowID BIGINT

    SELECT TOP (1)
        @id = id
    FROM tempdb.dbo.BalanceRecord_Archive_List
    ORDER BY id

IF @@ROWCOUNT = 0
BEGIN
    -- raiserror here to continue to next step of jobs
    RAISERROR ('* no more data *', -- Message text.
               16, -- Severity.
               1 -- State.
               );
END
ELSE
BEGIN
    -- do 100 rows per each batch
    SET @maxid = @id + 99
    SET @cnt = 0

DeleteAgain:
    SELECT
        @cnt = @cnt + 1,
        @id = @id + 1, 
        @custid = custid, @RowID = RowID
    FROM tempdb.dbo.BalanceRecord_Archive_List WITH (ROWLOCK)
    WHERE id = @id

    IF @@ROWCOUNT = 0 GOTO NoMore

    BEGIN TRANSACTION
        DELETE FROM tempdb.dbo.BalanceRecord_Archive_List WITH (ROWLOCK)
            WHERE id = @id - 1

        ;WITH CTE AS (
            SELECT * FROM dbo.BalanceRecord WITH (ROWLOCK)
            WHERE custid = @custid AND RowID = @RowID
        )
        DELETE FROM CTE
        OUTPUT
            DELETED.RowID, DELETED.custid, DELETED.transid, DELETED.bettype,
            DELETED.actual_stake, DELETED.winlost, DELETED.playercomm,
            DELETED.BalanceChanged, DELETED.NewBalance,
            DELETED.ActionDate, DELETED.ActionID, DELETED.[Action],
            DELETED.BTBalance,
            DELETED.matchid, DELETED.StatusId, DELETED.SettlementType,
            DELETED.swinlost, DELETED.mwinlost, DELETED.awinlost, DELETED.scomm, DELETED.acomm, DELETED.comm, DELETED.modds, DELETED.winlostdate, DELETED.refno
        INTO BalanceRecord.dbo.BalanceRecord_bk (
            RowID, custid, transid, bettype, 
            actual_stake, winlost, playercomm,
            BalanceChanged, NewBalance, 
            ActionDate, ActionID, [Action],
            BTBalance,
            MatchId, StatusId, SettlementType, swinlost, mwinlost, awinlost, scomm, acomm, comm, modds, winlostdate, refno
            )

    COMMIT TRANSACTION

    IF @id <= @maxid GOTO DeleteAgain

NoMore:
    PRINT '** Total Archived : ' + CAST(@cnt AS VARCHAR(50)) + ' rows ***'
END

END --IF @step = 2

