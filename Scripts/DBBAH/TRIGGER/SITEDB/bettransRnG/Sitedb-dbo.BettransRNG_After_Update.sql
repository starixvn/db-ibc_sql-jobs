/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/    
/*
   Created:Kathy@20230621  
   DB: DBSIG-bodb02
*/
USE bodb02
GO
--A): alter trigger case:

	--1)check long running
	--2)set lock timeout
	--3)set deadlock priority low
	--4)GO
	--5)alter trigger

--B): alter table case:

	--1)check long running
	--2)set lock timeout
	--3)set deadlock priority low
	--4)alter command

--#1)
DECLARE @__messageInfo VARCHAR(200)
__tryAgain:
IF (dbo.f_dba_check_long_holding_locks ('bettransRnG' /*tableName*/, getdate() /*current time*/, 1000 /*long query exceeded 1s*/, 1 /*retry in 1 min*/)) = 1
BEGIN
	SELECT @__messageInfo = 'curdt: ' + convert(varchar(50), getdate(), 121) + ' | Too many long running operations on the table. Retry attempt again ...'
	RAISERROR(@__messageInfo, 0, 1) WITH NOWAIT
	WAITFOR DELAY '00:00:00:333' --wait for alter schema
	GOTO __tryAgain
END


--doing.... 
--#2 #3)
SET LOCK_TIMEOUT 1024
SET DEADLOCK_PRIORITY LOW

--#4
GO

ALTER TRIGGER [dbo].[BettransRNG_After_Update]
   ON [dbo].[bettransRnG]
   AFTER UPDATE
AS 
/*
    Created: Joe@
    DB: DBSIG.bodb02
    Task: 
    Revision:
        - 20210309@Kathy: Allow null for bettype,actual_stake, winlost, playercomm [Redmine:#138552]
        - 20220629@Helen: BalanceRecord -> wrong capture balance change and new balance when resettle tickets AE-Sexy product [Redmine:#173971]
        - 20220912@Helen: clone trigger from db05 to sitedb for scaleout project [176932]
		- 20230615@Kathy: add new column winlostdate [Redmine:#181595]
		- 20230912@Louisa: Capture Bet Rejected [Redmine:#193830]
		- 20240102@Kathy: Trigger hasn't been covered in case placing bet many choices for a game of MaxGame and FGG [Redmine:#197575]
*/
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Insert statements for trigger here
    INSERT INTO dbo.BalanceTrigger (custid, transid, bettype, actual_stake, winlost, playercomm, ActionDate, 
        ActionID, [Action],
        BalanceChanged, winlostdate)
    SELECT
        -- if inserted.custid = 0, this should be VOID + Hidden
        -- if deleted.custid = 0, this may be Bet Recover
        case when i.custid =0 then d.custid else i.custid end,
        i.transid, i.gameID, ISNULL(i.actual_stake,0), ISNULL(i.winlost,0), ISNULL(i.playercomm,0), CURRENT_TIMESTAMP, 

        CASE
        WHEN i.custid = 0 THEN 130 -- cancel transfer (custid set to zero)
        WHEN i.IsSum = 1 AND d.IsSum = 0 THEN 33 -- Record SUM
        WHEN i.statusid = 102 THEN 050 -- Void Bet
        WHEN d.statusid = 0 AND i.statusID = 101 THEN 020 -- running to reject
		WHEN d.statusid = 0 AND	i.statusID = 0 AND (i.actual_stake <> d.actual_stake) THEN 12 -- place bet more: running to running
		WHEN d.statusid = 0 AND (i.statusid BETWEEN 111 AND 113 OR i.statusid = 103) THEN 030 -- Settled : running -> Won/Lose/Draw/Refund
		WHEN d.statusid = 102 AND i.statusid = 0 THEN 055 -- unvoid/recover : void -> running
		WHEN d.statusid = 1 AND i.statusID = 101 THEN 020 -- waiting --> reject
        WHEN d.statusid > 0 THEN CASE i.statusid WHEN 0 THEN 032 ELSE 031 END -- resettle or unsettle
        ELSE 0 END,
        
        --CASE WHEN i.custid =0 THEN 'Delete ' ELSE 'Update ' END
        --  + CASE WHEN i.bettype < 19001 then 'Bet' ELSE 'Transfer' END + 
        --CASE WHEN i.custid <> 0 THEN ', from '+ d.[status] + ' to ' + i.[status] ELSE '' END
        --[Action]--vvv
        CASE WHEN (d.statusid = 0 AND  i.statusid = 101) OR (d.statusid = 1 AND i.statusID = 101) THEN 'Bet rejected'
			 ELSE 'RNG' +
					CASE
						WHEN i.IsSum = d.IsSum THEN ' (IsSUM : ' + CAST(d.IsSUM AS varchar(50)) + ')'
						ELSE ' (IsSUM : ' + CAST(d.IsSUM AS varchar(50)) + ' to ' + CAST(i.IsSUM AS varchar(50)) + ') ' + CAST(ISNULL(i.RefNo,0) AS VARCHAR(50))
					END +
					CASE
						WHEN i.custid = 0 THEN ' cancelled, ' + d.[status] + ' to ' + i.[status]
						WHEN d.statusid = 0 AND i.statusID = 102 THEN ' voided'
						WHEN d.statusID = 0 AND i.statusID = 0 AND (i.actual_stake <> d.actual_stake) THEN ' inserted as ' + i.[status]
						WHEN d.statusid = 0 AND (i.statusID BETWEEN 111 AND 113 OR i.statusID = 103) THEN ' settled, ' + d.[status] + ' to ' + i.[status]
						ELSE ' updated, ' + d.[status] + ' to ' + i.[status]
					END
		END
        --[Action]--^^^ 
        , CASE  WHEN (ISNULL(i.winlost,0)- ISNULL(i.actual_stake,0) + ISNULL(i.playercomm,0)) <> (ISNULL(d.winlost,0) - ISNULL(d.actual_stake,0) + ISNULL(d.playercomm,0)) 
            THEN (ISNULL(i.winlost,0)- ISNULL(i.actual_stake,0) + ISNULL(i.playercomm,0)) - (ISNULL(d.winlost,0) - ISNULL(d.actual_stake,0) + ISNULL(d.playercomm,0)) 
        ELSE 0 END
		,i.winlostdate
    FROM
        inserted i INNER JOIN deleted d
        ON i.transid = d.transid
    WHERE
        d.custid <> d.recommend AND
        d.custid <> d.mrecommend AND
        d.custid <> d.srecommend
        -- Joe@20120705 : eliminate row which data is not change 
        AND (
            ISNULL(i.actual_stake,0) <> ISNULL(d.actual_stake,0) OR ISNULL(i.winlost,0) <> ISNULL(d.winlost,0) OR ISNULL(i.playercomm,0) <> ISNULL(d.playercomm,0)
            OR i.statusid <> d.statusid
            OR i.custid <> d.custid
            OR i.IsSum <> d.IsSum
        )
        
END
