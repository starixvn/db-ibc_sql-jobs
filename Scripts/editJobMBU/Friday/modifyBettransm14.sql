/*<info serverAlias="DBTXN-msdb"></info>*/
EXEC msdb.dbo.sp_update_jobstep @job_name=N'Joe : DBTRANS_bodb02 : Friday routine', @step_name=N'1', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
DECLARE @archiveDate TABLE (rid INT PRIMARY KEY IDENTITY(1,1), winlostdate SMALLDATETIME);
DECLARE @wldate SMALLDATETIME
, @WaitFor VARCHAR(50);

INSERT INTO @archiveDate (winlostdate)
SELECT winlostdate
FROM dbo.Task_ArchiveDate WITH (NOLOCK)
ORDER BY winlostdate

SELECT @wldate = winlostdate
FROM @archiveDate
WHERE rid = 1;

DECLARE @rowcount INT;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettrans14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

-- 143763 Patrick edited job--
DECLARE	@__tmpTransId TABLE (transid BIGINT);
CREATE TABLE #__transIdsM (rowId INT IDENTITY(1,1) PRIMARY KEY, transid BIGINT);

DECLARE @rc INT
INSERT INTO #__transIdsM(transId) 
SELECT transId FROM dbo.bettransm14 WITH(NOLOCK) WHERE winlostdate = @wldate;
SET @rc = @@ROWCOUNT

DECLARE @transIds VARCHAR(MAX), @rowId INT
SET @transIds = ''''

SELECT @rowcount = 1, @rowId = 1;
WHILE @rc > 0
BEGIN
	DELETE @__tmpTransId
	SET @transIds = NULL

	INSERT INTO @__tmpTransId(transid)
	SELECT transid
	FROM #__transIdsM WITH (NOLOCK) WHERE rowId >= @rowId AND rowId < @rowId + 1000
	SET @rc = @@ROWCOUNT
	
	SELECT @transIds = COALESCE(@transIds + ''^'' + CAST(transid AS VARCHAR(50)), CAST(transid AS VARCHAR(50)))
	FROM @__tmpTransId
	
	EXECUTE dbo.ExecRep_02 @Command = ''ALL_DB'', @deletedTarget = ''bettransm14'', @transIds = @transIds, @rowcount = @rowcount OUTPUT;

	SET @rowId = @rowId + 1000
	SELECT @WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END
--remove all data on that day if any replicated servers have diff rows for dbtrans
EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransm14'', @rowcount = @rowcount OUTPUT;

DROP TABLE #__transIdsM
-- /143763 Patrick edited job--
SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''sum_winloss'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransG14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''translog14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransLC14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransRNG14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;
 
SELECT @rowcount = 1;
WHILE @rowcount <> 0

BEGIN;	
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''Transfer_Coll'', @rowcount = @rowcount OUTPUT;
	

	-- Dynamic Delay Time --	
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');	
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
    DECLARE @__winlostdate SMALLDATETIME
    SET @__winlostdate = DATEADD(DAY, -1, @wldate)
    EXECUTE dbo.ExecRep_02 @winlostdate = @__winlostdate, @Command = ''ALL_DB'', @deletedTarget = ''Intg_GameRoundBetStake'', @rowcount = @rowcount OUTPUT;            

    -- Dynamic Delay Time --    
    SELECT    @WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');    
    WAITFOR DELAY @WaitFor;
END;

EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''others'';
WAITFOR DELAY ''00:00:03'';
', 
		@database_name=N'bodb02', 
		@flags=0
		
go

EXEC msdb.dbo.sp_update_jobstep @job_name=N'Joe : DBTRANS_bodb02 : Friday routine', @step_name=N'7', 
		@step_id=9, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
DECLARE @archiveDate TABLE (rid INT PRIMARY KEY IDENTITY(1,1), winlostdate SMALLDATETIME);
DECLARE @wldate SMALLDATETIME
, @WaitFor VARCHAR(50);

INSERT INTO @archiveDate (winlostdate)
SELECT winlostdate
FROM dbo.Task_ArchiveDate WITH (NOLOCK)
ORDER BY winlostdate

SELECT @wldate = winlostdate
FROM @archiveDate
WHERE rid = 7;

DECLARE @rowcount INT;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettrans14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

-- 143763 Patrick edited job--
DECLARE	@__tmpTransId TABLE (transid BIGINT);
CREATE TABLE #__transIdsM (rowId INT IDENTITY(1,1) PRIMARY KEY, transid BIGINT);

DECLARE @rc INT
INSERT INTO #__transIdsM(transId) 
SELECT transId FROM dbo.bettransm14 WITH(NOLOCK) WHERE winlostdate = @wldate;
SET @rc = @@ROWCOUNT

DECLARE @transIds VARCHAR(MAX), @rowId INT
SET @transIds = ''''

SELECT @rowcount = 1, @rowId = 1;
WHILE @rc > 0
BEGIN
	DELETE @__tmpTransId
	SET @transIds = NULL

	INSERT INTO @__tmpTransId(transid)
	SELECT transid
	FROM #__transIdsM WITH (NOLOCK) WHERE rowId >= @rowId AND rowId < @rowId + 1000
	SET @rc = @@ROWCOUNT
	
	SELECT @transIds = COALESCE(@transIds + ''^'' + CAST(transid AS VARCHAR(50)), CAST(transid AS VARCHAR(50)))
	FROM @__tmpTransId
	
	EXECUTE dbo.ExecRep_02 @Command = ''ALL_DB'', @deletedTarget = ''bettransm14'', @transIds = @transIds, @rowcount = @rowcount OUTPUT;

	SET @rowId = @rowId + 1000
	SELECT @WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END
--remove all data on that day if any replicated servers have diff rows for dbtrans
EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransm14'', @rowcount = @rowcount OUTPUT;

DROP TABLE #__transIdsM
-- /143763 Patrick edited job--
SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''sum_winloss'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransG14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''translog14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransLC14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransRNG14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;
 
SELECT @rowcount = 1;
WHILE @rowcount <> 0

BEGIN;	
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''Transfer_Coll'', @rowcount = @rowcount OUTPUT;
	

	-- Dynamic Delay Time --	
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');	
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
    DECLARE @__winlostdate SMALLDATETIME
    SET @__winlostdate = DATEADD(DAY, -1, @wldate)
    EXECUTE dbo.ExecRep_02 @winlostdate = @__winlostdate, @Command = ''ALL_DB'', @deletedTarget = ''Intg_GameRoundBetStake'', @rowcount = @rowcount OUTPUT;            

    -- Dynamic Delay Time --    
    SELECT    @WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');    
    WAITFOR DELAY @WaitFor;
END;

EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''others'';
WAITFOR DELAY ''00:00:03'';
', 
		@database_name=N'bodb02', 
		@flags=0
		
go

EXEC msdb.dbo.sp_update_jobstep @job_name=N'Joe : DBTRANS_bodb02 : Friday routine', @step_name=N'6', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
DECLARE @archiveDate TABLE (rid INT PRIMARY KEY IDENTITY(1,1), winlostdate SMALLDATETIME);
DECLARE @wldate SMALLDATETIME
, @WaitFor VARCHAR(50);

INSERT INTO @archiveDate (winlostdate)
SELECT winlostdate
FROM dbo.Task_ArchiveDate WITH (NOLOCK)
ORDER BY winlostdate

SELECT @wldate = winlostdate
FROM @archiveDate
WHERE rid = 6;

DECLARE @rowcount INT;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettrans14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

-- 143763 Patrick edited job--
DECLARE	@__tmpTransId TABLE (transid BIGINT);
CREATE TABLE #__transIdsM (rowId INT IDENTITY(1,1) PRIMARY KEY, transid BIGINT);

DECLARE @rc INT
INSERT INTO #__transIdsM(transId) 
SELECT transId FROM dbo.bettransm14 WITH(NOLOCK) WHERE winlostdate = @wldate;
SET @rc = @@ROWCOUNT

DECLARE @transIds VARCHAR(MAX), @rowId INT
SET @transIds = ''''

SELECT @rowcount = 1, @rowId = 1;
WHILE @rc > 0
BEGIN
	DELETE @__tmpTransId
	SET @transIds = NULL

	INSERT INTO @__tmpTransId(transid)
	SELECT transid
	FROM #__transIdsM WITH (NOLOCK) WHERE rowId >= @rowId AND rowId < @rowId + 1000
	SET @rc = @@ROWCOUNT
	
	SELECT @transIds = COALESCE(@transIds + ''^'' + CAST(transid AS VARCHAR(50)), CAST(transid AS VARCHAR(50)))
	FROM @__tmpTransId
	
	EXECUTE dbo.ExecRep_02 @Command = ''ALL_DB'', @deletedTarget = ''bettransm14'', @transIds = @transIds, @rowcount = @rowcount OUTPUT;

	SET @rowId = @rowId + 1000
	SELECT @WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END
--remove all data on that day if any replicated servers have diff rows for dbtrans
EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransm14'', @rowcount = @rowcount OUTPUT;

DROP TABLE #__transIdsM
-- /143763 Patrick edited job--
SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''sum_winloss'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransG14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''translog14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransLC14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransRNG14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;
 
SELECT @rowcount = 1;
WHILE @rowcount <> 0

BEGIN;	
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''Transfer_Coll'', @rowcount = @rowcount OUTPUT;
	

	-- Dynamic Delay Time --	
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');	
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
    DECLARE @__winlostdate SMALLDATETIME
    SET @__winlostdate = DATEADD(DAY, -1, @wldate)
    EXECUTE dbo.ExecRep_02 @winlostdate = @__winlostdate, @Command = ''ALL_DB'', @deletedTarget = ''Intg_GameRoundBetStake'', @rowcount = @rowcount OUTPUT;            

    -- Dynamic Delay Time --    
    SELECT    @WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');    
    WAITFOR DELAY @WaitFor;
END;

EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''others'';
WAITFOR DELAY ''00:00:03'';
', 
		@database_name=N'bodb02', 
		@flags=0
		
go

EXEC msdb.dbo.sp_update_jobstep @job_name=N'Joe : DBTRANS_bodb02 : Friday routine', @step_name=N'5', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
DECLARE @archiveDate TABLE (rid INT PRIMARY KEY IDENTITY(1,1), winlostdate SMALLDATETIME);
DECLARE @wldate SMALLDATETIME
, @WaitFor VARCHAR(50);

INSERT INTO @archiveDate (winlostdate)
SELECT winlostdate
FROM dbo.Task_ArchiveDate WITH (NOLOCK)
ORDER BY winlostdate

SELECT @wldate = winlostdate
FROM @archiveDate
WHERE rid = 5;

DECLARE @rowcount INT;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettrans14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

-- 143763 Patrick edited job--
DECLARE	@__tmpTransId TABLE (transid BIGINT);
CREATE TABLE #__transIdsM (rowId INT IDENTITY(1,1) PRIMARY KEY, transid BIGINT);

DECLARE @rc INT
INSERT INTO #__transIdsM(transId) 
SELECT transId FROM dbo.bettransm14 WITH(NOLOCK) WHERE winlostdate = @wldate;
SET @rc = @@ROWCOUNT

DECLARE @transIds VARCHAR(MAX), @rowId INT
SET @transIds = ''''

SELECT @rowcount = 1, @rowId = 1;
WHILE @rc > 0
BEGIN
	DELETE @__tmpTransId
	SET @transIds = NULL

	INSERT INTO @__tmpTransId(transid)
	SELECT transid
	FROM #__transIdsM WITH (NOLOCK) WHERE rowId >= @rowId AND rowId < @rowId + 1000
	SET @rc = @@ROWCOUNT
	
	SELECT @transIds = COALESCE(@transIds + ''^'' + CAST(transid AS VARCHAR(50)), CAST(transid AS VARCHAR(50)))
	FROM @__tmpTransId
	
	EXECUTE dbo.ExecRep_02 @Command = ''ALL_DB'', @deletedTarget = ''bettransm14'', @transIds = @transIds, @rowcount = @rowcount OUTPUT;

	SET @rowId = @rowId + 1000
	SELECT @WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END
--remove all data on that day if any replicated servers have diff rows for dbtrans
EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransm14'', @rowcount = @rowcount OUTPUT;

DROP TABLE #__transIdsM
-- /143763 Patrick edited job--
SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''sum_winloss'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransG14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''translog14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransLC14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransRNG14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;
 
SELECT @rowcount = 1;
WHILE @rowcount <> 0

BEGIN;	
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''Transfer_Coll'', @rowcount = @rowcount OUTPUT;
	

	-- Dynamic Delay Time --	
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');	
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
    DECLARE @__winlostdate SMALLDATETIME
    SET @__winlostdate = DATEADD(DAY, -1, @wldate)
    EXECUTE dbo.ExecRep_02 @winlostdate = @__winlostdate, @Command = ''ALL_DB'', @deletedTarget = ''Intg_GameRoundBetStake'', @rowcount = @rowcount OUTPUT;            

    -- Dynamic Delay Time --    
    SELECT    @WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');    
    WAITFOR DELAY @WaitFor;
END;

EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''others'';
WAITFOR DELAY ''00:00:03'';
', 
		@database_name=N'bodb02', 
		@flags=0
		
go

EXEC msdb.dbo.sp_update_jobstep @job_name=N'Joe : DBTRANS_bodb02 : Friday routine', @step_name=N'4', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
DECLARE @archiveDate TABLE (rid INT PRIMARY KEY IDENTITY(1,1), winlostdate SMALLDATETIME);
DECLARE @wldate SMALLDATETIME
, @WaitFor VARCHAR(50);

INSERT INTO @archiveDate (winlostdate)
SELECT winlostdate
FROM dbo.Task_ArchiveDate WITH (NOLOCK)
ORDER BY winlostdate

SELECT @wldate = winlostdate
FROM @archiveDate
WHERE rid = 4;

DECLARE @rowcount INT;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettrans14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

-- 143763 Patrick edited job--
DECLARE	@__tmpTransId TABLE (transid BIGINT);
CREATE TABLE #__transIdsM (rowId INT IDENTITY(1,1) PRIMARY KEY, transid BIGINT);

DECLARE @rc INT
INSERT INTO #__transIdsM(transId) 
SELECT transId FROM dbo.bettransm14 WITH(NOLOCK) WHERE winlostdate = @wldate;
SET @rc = @@ROWCOUNT

DECLARE @transIds VARCHAR(MAX), @rowId INT
SET @transIds = ''''

SELECT @rowcount = 1, @rowId = 1;
WHILE @rc > 0
BEGIN
	DELETE @__tmpTransId
	SET @transIds = NULL

	INSERT INTO @__tmpTransId(transid)
	SELECT transid
	FROM #__transIdsM WITH (NOLOCK) WHERE rowId >= @rowId AND rowId < @rowId + 1000
	SET @rc = @@ROWCOUNT
	
	SELECT @transIds = COALESCE(@transIds + ''^'' + CAST(transid AS VARCHAR(50)), CAST(transid AS VARCHAR(50)))
	FROM @__tmpTransId
	
	EXECUTE dbo.ExecRep_02 @Command = ''ALL_DB'', @deletedTarget = ''bettransm14'', @transIds = @transIds, @rowcount = @rowcount OUTPUT;

	SET @rowId = @rowId + 1000
	SELECT @WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END
--remove all data on that day if any replicated servers have diff rows for dbtrans
EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransm14'', @rowcount = @rowcount OUTPUT;

DROP TABLE #__transIdsM
-- /143763 Patrick edited job--
SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''sum_winloss'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransG14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''translog14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransLC14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransRNG14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;
 
SELECT @rowcount = 1;
WHILE @rowcount <> 0

BEGIN;	
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''Transfer_Coll'', @rowcount = @rowcount OUTPUT;
	

	-- Dynamic Delay Time --	
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');	
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
    DECLARE @__winlostdate SMALLDATETIME
    SET @__winlostdate = DATEADD(DAY, -1, @wldate)
    EXECUTE dbo.ExecRep_02 @winlostdate = @__winlostdate, @Command = ''ALL_DB'', @deletedTarget = ''Intg_GameRoundBetStake'', @rowcount = @rowcount OUTPUT;            

    -- Dynamic Delay Time --    
    SELECT    @WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');    
    WAITFOR DELAY @WaitFor;
END;

EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''others'';
WAITFOR DELAY ''00:00:03'';
', 
		@database_name=N'bodb02', 
		@flags=0
		
go

EXEC msdb.dbo.sp_update_jobstep @job_name=N'Joe : DBTRANS_bodb02 : Friday routine', @step_name=N'3', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
DECLARE @archiveDate TABLE (rid INT PRIMARY KEY IDENTITY(1,1), winlostdate SMALLDATETIME);
DECLARE @wldate SMALLDATETIME
, @WaitFor VARCHAR(50);

INSERT INTO @archiveDate (winlostdate)
SELECT winlostdate
FROM dbo.Task_ArchiveDate WITH (NOLOCK)
ORDER BY winlostdate

SELECT @wldate = winlostdate
FROM @archiveDate
WHERE rid = 3;

DECLARE @rowcount INT;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettrans14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

-- 143763 Patrick edited job--
DECLARE	@__tmpTransId TABLE (transid BIGINT);
CREATE TABLE #__transIdsM (rowId INT IDENTITY(1,1) PRIMARY KEY, transid BIGINT);

DECLARE @rc INT
INSERT INTO #__transIdsM(transId) 
SELECT transId FROM dbo.bettransm14 WITH(NOLOCK) WHERE winlostdate = @wldate;
SET @rc = @@ROWCOUNT

DECLARE @transIds VARCHAR(MAX), @rowId INT
SET @transIds = ''''

SELECT @rowcount = 1, @rowId = 1;
WHILE @rc > 0
BEGIN
	DELETE @__tmpTransId
	SET @transIds = NULL

	INSERT INTO @__tmpTransId(transid)
	SELECT transid
	FROM #__transIdsM WITH (NOLOCK) WHERE rowId >= @rowId AND rowId < @rowId + 1000
	SET @rc = @@ROWCOUNT
	
	SELECT @transIds = COALESCE(@transIds + ''^'' + CAST(transid AS VARCHAR(50)), CAST(transid AS VARCHAR(50)))
	FROM @__tmpTransId
	
	EXECUTE dbo.ExecRep_02 @Command = ''ALL_DB'', @deletedTarget = ''bettransm14'', @transIds = @transIds, @rowcount = @rowcount OUTPUT;

	SET @rowId = @rowId + 1000
	SELECT @WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END
--remove all data on that day if any replicated servers have diff rows for dbtrans
EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransm14'', @rowcount = @rowcount OUTPUT;

DROP TABLE #__transIdsM
-- /143763 Patrick edited job--
SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''sum_winloss'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransG14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''translog14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransLC14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransRNG14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;
 
SELECT @rowcount = 1;
WHILE @rowcount <> 0

BEGIN;	
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''Transfer_Coll'', @rowcount = @rowcount OUTPUT;
	

	-- Dynamic Delay Time --	
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');	
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
    DECLARE @__winlostdate SMALLDATETIME
    SET @__winlostdate = DATEADD(DAY, -1, @wldate)
    EXECUTE dbo.ExecRep_02 @winlostdate = @__winlostdate, @Command = ''ALL_DB'', @deletedTarget = ''Intg_GameRoundBetStake'', @rowcount = @rowcount OUTPUT;            

    -- Dynamic Delay Time --    
    SELECT    @WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');    
    WAITFOR DELAY @WaitFor;
END;

EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''others'';
WAITFOR DELAY ''00:00:03'';
', 
		@database_name=N'bodb02', 
		@flags=0
		
go

EXEC msdb.dbo.sp_update_jobstep @job_name=N'Joe : DBTRANS_bodb02 : Friday routine', @step_name=N'2', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
DECLARE @archiveDate TABLE (rid INT PRIMARY KEY IDENTITY(1,1), winlostdate SMALLDATETIME);
DECLARE @wldate SMALLDATETIME
, @WaitFor VARCHAR(50);

INSERT INTO @archiveDate (winlostdate)
SELECT winlostdate
FROM dbo.Task_ArchiveDate WITH (NOLOCK)
ORDER BY winlostdate

SELECT @wldate = winlostdate
FROM @archiveDate
WHERE rid = 2;

DECLARE @rowcount INT;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettrans14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

-- 143763 Patrick edited job--
DECLARE	@__tmpTransId TABLE (transid BIGINT);
CREATE TABLE #__transIdsM (rowId INT IDENTITY(1,1) PRIMARY KEY, transid BIGINT);

DECLARE @rc INT
INSERT INTO #__transIdsM(transId) 
SELECT transId FROM dbo.bettransm14 WITH(NOLOCK) WHERE winlostdate = @wldate;
SET @rc = @@ROWCOUNT

DECLARE @transIds VARCHAR(MAX), @rowId INT
SET @transIds = ''''

SELECT @rowcount = 1, @rowId = 1;
WHILE @rc > 0
BEGIN
	DELETE @__tmpTransId
	SET @transIds = NULL

	INSERT INTO @__tmpTransId(transid)
	SELECT transid
	FROM #__transIdsM WITH (NOLOCK) WHERE rowId >= @rowId AND rowId < @rowId + 1000
	SET @rc = @@ROWCOUNT
	
	SELECT @transIds = COALESCE(@transIds + ''^'' + CAST(transid AS VARCHAR(50)), CAST(transid AS VARCHAR(50)))
	FROM @__tmpTransId
	
	EXECUTE dbo.ExecRep_02 @Command = ''ALL_DB'', @deletedTarget = ''bettransm14'', @transIds = @transIds, @rowcount = @rowcount OUTPUT;

	SET @rowId = @rowId + 1000
	SELECT @WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END
--remove all data on that day if any replicated servers have diff rows for dbtrans
EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransm14'', @rowcount = @rowcount OUTPUT;

DROP TABLE #__transIdsM
-- /143763 Patrick edited job--
SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''sum_winloss'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransG14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''translog14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransLC14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransRNG14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END;
 
SELECT @rowcount = 1;
WHILE @rowcount <> 0

BEGIN;	
	EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''Transfer_Coll'', @rowcount = @rowcount OUTPUT;
	

	-- Dynamic Delay Time --	
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');	
	WAITFOR DELAY @WaitFor;
END;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN;
    DECLARE @__winlostdate SMALLDATETIME
    SET @__winlostdate = DATEADD(DAY, -1, @wldate)
    EXECUTE dbo.ExecRep_02 @winlostdate = @__winlostdate, @Command = ''ALL_DB'', @deletedTarget = ''Intg_GameRoundBetStake'', @rowcount = @rowcount OUTPUT;            

    -- Dynamic Delay Time --    
    SELECT    @WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');    
    WAITFOR DELAY @WaitFor;
END;

EXECUTE dbo.ExecRep_02 @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''others'';
WAITFOR DELAY ''00:00:03'';
', 
		@database_name=N'bodb02', 
		@flags=0