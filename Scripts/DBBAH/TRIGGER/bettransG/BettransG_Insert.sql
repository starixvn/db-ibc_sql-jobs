/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/
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


ALTER TRIGGER [dbo].[bettransG_After_Insert]
ON [dbo].[bettransG]
FOR INSERT
AS
/*
    Created: Helen
    DB: DBBAH.bodb02
    Task: 
    Revision:
        - 20230818@Helen: NAP - SA Gaming - can not use betlist to search the refno which showed on bet credit history [Redmine:#179580]
*/
BEGIN

    INSERT INTO BalanceTrigger (
        custid, transid, bettype, 
        actual_stake, winlost, playercomm,
        BalanceChanged,
        ActionDate, ActionID, [Action],
        BTBalance, winlostdate)
    SELECT
        i.custid, transid, i.bettype, ISNULL(actual_stake,0), ISNULL(winlost,0), ISNULL(playercomm,0),
       
        ISNULL(winlost,0) - ISNULL(actual_stake,0) + ISNULL(playercomm,0),
        current_timestamp,
        12, -- ticket insert
        'Bet inserted as ' + [status],
        NULL Balance,
		i.winlostdate
        --v.Balance
    FROM
        inserted i
        --INNER JOIN DBTRANS.bodb02.dbo.v_BalanceTable v ON i.custid = v.custid
    WHERE i.SiteDBGroupID = 0
		AND i.matchid = 244 -- process trigger for SA Gaming only on bettransG
    ORDER BY
        i.transid
END


    

GO