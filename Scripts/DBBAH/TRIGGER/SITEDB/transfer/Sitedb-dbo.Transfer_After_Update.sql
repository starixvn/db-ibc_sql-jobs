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
IF (dbo.f_dba_check_long_holding_locks ('Transfer' /*tableName*/, getdate() /*current time*/, 1000 /*long query exceeded 1s*/, 1 /*retry in 1 min*/)) = 1
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
   
ALTER TRIGGER [dbo].[Transfer_After_Update]
   ON [dbo].[Transfer]
   AFTER UPDATE
AS 
/*
    Created: 20221110@Max
    DB: DBSIG-bodb02
    Task: [LAP] Detail transaction_Display Different Balance Amount of Deposit & Withdrawal [Redmine: #180295]
    Revision:
        - 20221110@Max: clone trigger from db05 to sitedb [Redmine:#180295]
        - 20230309@Aries: Enhance trigger on table transfer of SiteDB [Redmine:#184782]
		- 20230615@Kathy: add new column winlostdate [Redmine:#181595]
*/

BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Insert statements for trigger here
    INSERT INTO dbo.BalanceTrigger (custid, transid, bettype, actual_stake, winlost, playercomm, ActionDate, 
        ActionID, [Action],
        BalanceChanged,
        MatchId, StatusId, SettlementType, swinlost, mwinlost, awinlost, scomm, acomm, comm, modds, winlostdate)
    SELECT
        -- if inserted.custid = 0, this should be VOID + Hidden
        -- if deleted.custid = 0, this may be Bet Recover
        case when i.custid =0 then d.custid else i.custid end,
        i.transid, i.bettype, i.actual_stake, isnull(i.winlost,0) as winlost, isnull(i.playercomm,0) as playercomm, CURRENT_TIMESTAMP, 

        CASE 
            WHEN (
                i.actual_stake <> d.actual_stake 
                OR isnull(i.winlost,0) <> isnull(d.winlost,0) 
                OR isnull(i.playercomm,0) <> isnull(d.playercomm,0)
                OR isnull(i.statusid,0) <> isnull(d.statusid,0)
                OR i.custid <> d.custid
            ) THEN
                CASE
                WHEN i.bettype > 20000 AND i.custid = 0 THEN 130 -- cancel transfer (custid set to zero)
                WHEN i.bettype > 20000 THEN 120 -- update transfer
                ELSE 0 END
            ELSE 001
        END,
        
        --[Action]--vvv
        CASE
            WHEN i.bettype > 20000 THEN 'Transfer'
            ELSE ''
        END +
        CASE
            WHEN i.custid = 0      THEN ' cancelled, ' + CAST(d.[StatusId] AS varchar(50)) + ' to ' + CAST(i.[StatusId] AS varchar(50))
            WHEN i.bettype > 20000 THEN ' updated, '   + CAST(d.[StatusId] AS varchar(50)) + ' to ' + CAST(i.[StatusId] AS varchar(50))
            ELSE ' Updated, ' + CAST(d.[StatusId] AS varchar(50)) + ' to ' + CAST(i.[StatusId] AS varchar(50))
        END
        --[Action]--^^^ 
        , (isnull(i.winlost,0) - ISNULL(i.actual_stake, 0) + ISNULL(i.playercomm,0))
            - (ISNULL(d.winlost,0) - ISNULL(d.actual_stake, 0) + ISNULL(d.playercomm,0))
        ,0 --i.matchid
        ,isnull(i.statusID,0)
        ,0 -- SettlementType
        ,isnull(i.swinlost,0) as swinlost
        ,isnull(i.mwinlost,0) as mwinlost
        ,isnull(i.awinlost,0) as awinlost
        ,isnull(i.scomm,0) as scomm
        ,isnull(i.acomm,0) as acomm
        ,isnull(i.comm,0) as comm
        ,0 --i.modds
		,i.winlostdate
    FROM
        inserted i INNER JOIN deleted d
        ON i.transid = d.transid
    WHERE
        d.custid <> d.recommend AND
        d.custid <> d.mrecommend AND
        d.custid <> d.srecommend AND 
        i.Bettype NOT IN (19999, 20000)     
END

