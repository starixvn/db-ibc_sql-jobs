/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
/*
	Created: 20210319@Max
	Task: add new steps for job [Redmine: #111093]
	DB: DBTXN-bodb02
	
*/

USE [msdb]
GO
EXEC msdb.dbo.sp_update_jobstep
		@job_name=N'Joe : DBTRANS_bodb02 : Friday routine',
		@step_id=2, 
		@command=N'DECLARE @archiveDate TABLE (rid int PRIMARY KEY IDENTITY(1,1), winlostdate smalldatetime)
INSERT INTO @archiveDate (winlostdate)
SELECT winlostdate FROM dbo.task_archivedate
ORDER BY 1

Declare @wldate smalldatetime

SELECT @wldate = MAX(winlostdate) FROM @archiveDate;
EXECUTE dbo.Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = ''MarkedTransaction'';
WAITFOR DELAY ''00:00:30'';

EXEC Task_Archive_Bet_Control

SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 1   EXEC DB02.bodb02.dbo.Task_Archive_Event @wldate, @Action = ''delete''
WAITFOR DELAY ''00:00:05''
SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 2   EXEC DB02.bodb02.dbo.Task_Archive_Event @wldate, @Action = ''delete''
WAITFOR DELAY ''00:01:05''
SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 3   EXEC DB02.bodb02.dbo.Task_Archive_Event @wldate, @Action = ''delete''
WAITFOR DELAY ''00:00:05''
SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 4   EXEC DB02.bodb02.dbo.Task_Archive_Event @wldate, @Action = ''delete''
WAITFOR DELAY ''00:01:05''
SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 5   EXEC DB02.bodb02.dbo.Task_Archive_Event @wldate, @Action = ''delete''
WAITFOR DELAY ''00:00:05''
SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 6   EXEC DB02.bodb02.dbo.Task_Archive_Event @wldate, @Action = ''delete''
WAITFOR DELAY ''00:01:05''
SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 7   EXEC DB02.bodb02.dbo.Task_Archive_Event @wldate, @Action = ''delete''

WAITFOR DELAY ''00:01:10''

SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 1
EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = ''betParlayResult''
WAITFOR DELAY ''00:00:30''
EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = ''betParlayDetail''
WAITFOR DELAY ''00:01:00''

SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 2
EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = ''betParlayResult''
WAITFOR DELAY ''00:00:30''
EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = ''betParlayDetail''
WAITFOR DELAY ''00:01:00''

SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 3
EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = ''betParlayResult''
WAITFOR DELAY ''00:00:30''
EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = ''betParlayDetail''
WAITFOR DELAY ''00:01:00''

SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 4
EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = ''betParlayResult''
WAITFOR DELAY ''00:00:30''
EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = ''betParlayDetail''
WAITFOR DELAY ''00:01:00''

SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 5
EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = ''betParlayResult''
WAITFOR DELAY ''00:00:30''
EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = ''betParlayDetail''
WAITFOR DELAY ''00:01:00''

SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 6
EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = ''betParlayResult''
WAITFOR DELAY ''00:00:30''
EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = ''betParlayDetail''
WAITFOR DELAY ''00:01:00''

SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 7
EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = ''betParlayResult''
WAITFOR DELAY ''00:00:30''
EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = ''betParlayDetail''

WAITFOR DELAY ''00:01:30''

SELECT @wldate = MAX(winlostdate) FROM @archiveDate;
EXECUTE dbo.Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = ''Task_bettrans14_IP2Country''
WAITFOR DELAY ''00:00:30'';
EXECUTE dbo.Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = ''Task_bettransRNG14_IP2Country''
WAITFOR DELAY ''00:00:30'';
EXECUTE dbo.Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = ''Task_bettransLC14_IP2Country''
WAITFOR DELAY ''00:00:30'';

--- delete old data for NG2
SELECT @wldate = MAX(winlostdate)
FROM @archiveDate 

DELETE b 
FROM dbo.bettrans_Staging b 
	INNER JOIN SettlementNG2_Message m WITH(NOLOCK) ON b.SeqId = m.SeqID
WHERE
	m.EventDate <= @wldate
WAITFOR DELAY ''00:01:20''

DELETE FROM SettlementNG2_Message
WHERE EventDate <= @wldate

WAITFOR DELAY ''00:01:30''
' 
GO