/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
   Created:Kathy@20230621  
   DB: DBBAH-bodb02
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
IF (dbo.f_dba_check_long_holding_locks ('translog' /*tableName*/, getdate() /*current time*/, 1000 /*long query exceeded 1s*/, 1 /*retry in 1 min*/)) = 1
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

ALTER TRIGGER [dbo].[TransLog_After_Update]
   ON [dbo].[translog]
   AFTER UPDATE
AS 
/*
    Created: Joe@
    DB: DBBAH/bodb02
    Task: 
    Revision:
        - 20210309@Kathy: Allow null for bettype,actual_stake, winlost, playercomm [Redmine:#138552]
        - 20220912@Helen: scaleout project, exclude 'sitedb' data since it has been processed in sitedb already [176932]
        - 20221108@Victoria: Migration Data From SiteDB to CentralDB - Change to not capture when update sitedbgroupid = 0 [Redmine:#180033]
		- 20230614@Kathy: Use new actionid when settle ticket, add new column winlostdate [Redmine:#189598]
		- 20230731@Kathy: exclude ticket <> sitedbgroupid = 0 [Redmine:#181595]
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
        case when i.custid = 0 then d.custid else i.custid end,
        i.translogid, i.gameID, ISNULL(i.actual_stake,0), 0, 0, CURRENT_TIMESTAMP, 

        /*
        i.custid <> 0
            statusID 0 -> X : settled, void
            statusID X -> 0 : unsettle
        i.custid = 0
            statusID 0 -> X : settled, void
            statusID X -> 0 : unsettle
            statusID not change
        */
        CASE
        WHEN i.custid = 0 THEN 130 -- cancel transfer (custid set to zero)
        WHEN d.custid = 0 AND i.custid > 0 THEN 055 -- recover bet
        WHEN i.statusid = 102 THEN 050 -- Void Bet
        WHEN d.statusID = 0 AND i.statusID = 0 AND (i.actual_stake <> d.actual_stake) THEN 011 -- place bet more
        WHEN d.statusid = 0 AND i.statusid > 0 THEN 035 -- Settled : running -> Won/Lose/Draw/Refund		
        WHEN d.statusid = 102 AND i.statusid = 0 THEN 055 -- unvoid/recover : void -> running
        WHEN d.statusid > 0 THEN CASE i.statusid WHEN 0 THEN 032 ELSE 031 END -- resettle or unsettle
        ELSE 0 END,
        
        --[Action]--vvv
        'TransLog' +
        CASE
            WHEN i.custid = 0 THEN ' cancelled, ' + d.[status] + ' to ' + i.[status]
            WHEN d.statusid = 0  AND i.statusid = 102 THEN ' voided'
			WHEN d.statusid = 0  AND i.statusid = 0 AND (i.actual_stake <> d.actual_stake)  THEN ' inserted as ' + i.[status]
			WHEN d.statusid = 0  AND (i.statusid BETWEEN 111 AND 113 OR i.statusID = 103) THEN  ' settled, ' + d.[status] + ' to ' + i.[status]
            ELSE ' updated, ' + d.[status] + ' to ' + i.[status]
        END
        --[Action]--^^^ 
        , 
        CASE
        WHEN i.statusID > 0 AND d.statusID = 0 THEN 0
        WHEN i.statusID = 0 AND d.statusID > 0 THEN -ISNULL(i.actual_stake,0) -- set back to Running : deduct balance again
        WHEN i.statusID = d.statusID THEN -- status not change? try to see actual_stake/custid
            CASE
            WHEN i.statusID = 0 AND ISNULL(i.actual_stake,0) <> ISNULL(d.actual_stake,0) THEN ISNULL(d.actual_stake,0) - ISNULL(i.actual_stake,0) -- re-adjust value
            WHEN i.statusID = 0 AND i.custid = 0 AND i.custid <> d.custid THEN -ISNULL(i.actual_stake,0) --remove value, when change custid to 0
            WHEN i.statusID = 0 AND d.custid = 0 AND i.custid <> d.custid THEN  ISNULL(i.actual_stake,0) --add back value, when change custid back from 0
            ELSE 0 END
        ELSE 0
        END
		,i.winlostdate
    FROM
        inserted i INNER JOIN deleted d
        ON i.translogid = d.translogid
    WHERE
        d.custid <> d.recommend AND
        d.custid <> d.mrecommend AND
        d.custid <> d.srecommend
        AND d.SiteDBGroupID = 0
		AND i.SiteDBGroupID = 0
        -- Joe@20120705 : eliminate row which data is not change 
        AND (
            ISNULL(i.actual_stake,0) <> ISNULL(d.actual_stake,0)
            OR i.statusid <> d.statusid
            OR i.custid <> d.custid
        )
END