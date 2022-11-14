/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
     Created: 20221114@Max
	Task: Scale out DBTrans - Migrate & Initialize data Seamless Wallet Licensees from SiteDB1 & SiteDB2 [Redmine:#180033]
	DB:DBBAH/bodb02

*/
USE bodb02
GO
--------------DECLARE temporary tables ------------------
CREATE TABLE #temp_MemberInput(
	ID INT IDENTITY (1,1) PRIMARY KEY,
	custid INT
)

CREATE TABLE #tempMember (custid INT PRIMARY KEY)
--------------GET members needs to process ------------------
INSERT INTO #temp_MemberInput (custid)
SELECT DISTINCT b.custid
FROM [bodb02].[dbo].BalanceRecord b WITH(NOLOCK)
	INNER JOIN  [bodb02].[dbo].Customer c WITH(NOLOCK) ON c.custid = b.custid
WHERE c.site = 'Betway'

SELECT @@ROWCOUNT AS [custid_Count]

-- delete data [dbo].[BalanceTrigger_ProcessData] for customers will process to insert balancerecord for credit
DELETE b
FROM BalanceTrigger_ProcessData b
	INNER JOIN #temp_MemberInput m ON b.custid = m.custid

----------- get maxtransid: Run on DBTRans/bodb02----------------
select *
from (
	select MAX(transid) FROM dbo.bettrans WITH(NOLOCK)
) as b(bettrans_transid)
outer apply (
	select MAX(transid) FROM dbo.Transfer WITH(NOLOCK)
) as b2(Transfer_transid)
outer apply (
	select MAX(translogid) FROM dbo.translog WITH(NOLOCK)
) as b3(translog_translogid)
outer apply (
	select MAX(transid) FROM dbo.bettransLC WITH(NOLOCK)
) as b4(bettransLC_transid)
outer apply (
	select MAX(transid) FROM dbo.bettransRnG WITH(NOLOCK)
) as b5(bettransRnG_transid)

------ info for deployer 
DECLARE @debug_message VARCHAR(MAX) = ''

--------------LOOP BY batch 500 of customers ------------------
DECLARE @rid_loop INT, @rowCount int  =0, @batch int = 500, @loop_cnt int = 1
DECLARE @StartRow INT = 1
		, @StopRow INT 
		, @retrycnt INT = 0 
		, @isSuccess BIT = 0
		
SET @rid_loop = ((SELECT MAX(ID) FROM #temp_MemberInput)/@batch) + 1
SET @StopRow = @batch

WHILE (@loop_cnt <= @rid_loop)
BEGIN
	
	TRUNCATE TABLE #tempMember

	SET @debug_message = CONCAT(CONVERT(VARCHAR(50), GETDATE(), 121), ', processing for round:',  @loop_cnt, '/', @rid_loop)
	RAISERROR (@debug_message, 0, 1) WITH NOWAIT

	-- process by recommend, 2000 customers per batch
	INSERT INTO #tempMember(custid)
	SELECT custid
	FROM #temp_MemberInput 
	WHERE ID BETWEEN @StartRow AND @StopRow

	IF @@ROWCOUNT = 0
		BREAK

	--- step 2 insert balance record to re-init
	INSERT INTO BalanceRecord (custid, transid, bettype, actual_stake, winlost, playercomm, balancechanged, newbalance, actionDate, actionID, [action])
	SELECT	m.custid, 0, 0, 0, 0, 0, 0, bal.Balance,CURRENT_TIMESTAMP, 255, 'Balance : Re-Init'
	FROM #tempMember m
		CROSS APPLY (
			SELECT TOP 1 Balance 
			FROM DBTRANS.bodb02.dbo.v_BalanceTable b WITH(NOLOCK) -- v_BalanceTable: this is a view, get data from 8 balance tables
			WHERE b.custid = m.custid
		) AS bal

	SET @rowCount += @@ROWCOUNT
	-- step 3: delete balance trigger if exists
	WHILE (@isSuccess = 0)
	BEGIN
		BEGIN TRY
			DELETE b
			FROM BalanceTrigger b
				INNER JOIN #tempMember m ON b.custid = m.custid

			SET @isSuccess = 1
		END TRY
		BEGIN CATCH
			SET @retrycnt = @retrycnt + 1
			PRINT @retrycnt

		END CATCH
	END
	
	WAITFOR DELAY '00:00:00.020' --optional

	SET @StartRow = @StopRow + 1
	SET @StopRow = @StopRow + @batch

	SELECT  @loop_cnt += 1

END

SELECT @rowCount

DROP TABLE #temp_MemberInput
DROP TABLE #tempMember



