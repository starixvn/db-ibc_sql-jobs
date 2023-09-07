/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/  
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
IF (dbo.f_dba_check_long_holding_locks ('bettransG' /*tableName*/, getdate() /*current time*/, 1000 /*long query exceeded 1s*/, 1 /*retry in 1 min*/)) = 1
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


ALTER TRIGGER [dbo].[bettransG_After_Update]
   ON [dbo].[bettransG]
   AFTER UPDATE
AS 
/*
    Created: Helen
    DB: DBSIG.bodb02
    Task: 
    Revision:
        - 20230818@Helen: NAP - SA Gaming - can not use betlist to search the refno which showed on bet credit history [Redmine:#179580]
		- 20230906@Louisa: Capture ActionId 020 for bet Rejects [Redmine:#179580]
*/
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

	DECLARE @IsSAGaming BIT = 0
	SET @IsSAGaming = ISNULL((SELECT TOP (1) 1 FROM inserted WHERE matchid = 244),0) -- process trigger for SA Gaming only on bettransG

	IF @IsSAGaming = 0 
		RETURN

    -- Insert statements for trigger here
    INSERT INTO dbo.BalanceTrigger (custid, transid, bettype, actual_stake, winlost, playercomm, ActionDate, 
        ActionID, [Action],
        BalanceChanged, winlostdate)
    SELECT
        -- if inserted.custid = 0, this should be VOID + Hidden
        -- if deleted.custid = 0, this may be Bet Recover
        case when i.custid =0 then d.custid else i.custid end,
        i.transid, i.bettype, ISNULL(i.actual_stake,0), ISNULL(i.winlost,0), ISNULL(i.playercomm,0), CURRENT_TIMESTAMP, 

        CASE
        WHEN i.custid = 0 THEN 130 -- cancel transfer (custid set to zero)
        WHEN i.statusid = 102 THEN 050 -- Void Bet
        WHEN d.statusid = 0 THEN CASE WHEN i.statusid = 101 THEN 020 -- running -> Reject
									  WHEN i.statusid > 0 THEN 030 -- Settled : running -> Won/Lose/Draw/Refund
									  END
		WHEN d.statusid = 1 AND i.statusID = 101 THEN 020 -- waiting --> reject
		WHEN d.statusid = 102 AND i.statusid = 0 THEN 055 -- unvoid/recover : void -> running
        WHEN d.statusid > 0 THEN CASE i.statusid WHEN 0 THEN 032 ELSE 031 END -- resettle or unsettle
        ELSE 0 END,
        
        'Bet' +
        ISNULL(
        CASE
            WHEN i.custid = 0 THEN ' cancelled, ' + d.[status] + ' to ' + i.[status]
            WHEN d.statusid = 0 THEN
                CASE i.statusid
				WHEN 101 THEN ' rejected'
                WHEN 102 THEN ' voided'
                ELSE ' settled, ' + d.[status] + ' to ' + i.[status]
                END
			WHEN d.statusid = 1 AND i.statusID = 101 THEN ' rejected'
            WHEN i.statusID = d.statusID THEN ' updated'
            ELSE ' updated, ' + d.[status] + ' to ' + i.[status]
        END,' NULL ')
        --[Action]--^^^ 
        , 
        CASE  WHEN (ISNULL(i.winlost,0)- ISNULL(i.actual_stake,0) + ISNULL(i.playercomm,0)) <> (ISNULL(d.winlost,0) - ISNULL(d.actual_stake,0) + ISNULL(d.playercomm,0)) 
            THEN (ISNULL(i.winlost,0)- ISNULL(i.actual_stake,0) + ISNULL(i.playercomm,0)) - (ISNULL(d.winlost,0) - ISNULL(d.actual_stake,0) + ISNULL(d.playercomm,0)) 
        ELSE 0 END
		,i.winlostdate
    FROM
        inserted i INNER JOIN deleted d
        ON i.transid = d.transid
    WHERE
            ISNULL(i.actual_stake,0) <> ISNULL(d.actual_stake,0) OR ISNULL(i.winlost,0) <> ISNULL(d.winlost,0) OR ISNULL(i.playercomm,0) <> ISNULL(d.playercomm,0)
            OR i.statusid <> d.statusid
            OR i.custid <> d.custid
END
    

GO


