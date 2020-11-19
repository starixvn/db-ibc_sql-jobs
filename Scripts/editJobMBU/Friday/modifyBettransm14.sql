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

-- 143763 Brice edited job--
DECLARE	@__tmpTransId AS TABLE (
				id int IDENTITY(1,1) PRIMARY KEY,
				transid		BIGINT
			);
declare @t1 sql_variant, @t2 sql_variant, @t3 sql_variant;
create table #bettransm14_ExecRep_02(transId bigint);
insert into #bettransm14_ExecRep_02(transId) select transId from bettransm14 with(nolock) where winlostdate=@wldate;

SELECT @rowcount = 1;
WHILE @rowcount <> 0
BEGIN
	DELETE	@__tmpTransId
	
	DELETE	TOP(1500) tmpTable
	OUTPUT	Deleted.transid
	INTO	@__tmpTransId (transid)
	FROM	#bettransm14_ExecRep_02 tmpTable;
	
	set @t1= cast((select (cast(transid as varchar(20)) + '','') from @__tmpTransId where id between 0 and 500 FOR XML PATH('''')) as varchar(8000));
	set @t2= cast((select (cast(transid as varchar(20)) + '','') from @__tmpTransId where id between 501 and 1000 FOR XML PATH('''')) as varchar(8000));
	set @t3= cast((select (cast(transid as varchar(20)) + '','') from @__tmpTransId where id between 1000 and 1500 FOR XML PATH('''')) as varchar(8000));
	
	EXECUTE dbo.ExecRep_02_brice @tmp1=@t1, @tmp2=@t1, @tmp3=@t1, @winlostdate = @wldate, @Command = ''ALL_DB'', @deletedTarget = ''bettransm14'', @rowcount = @rowcount OUTPUT;

	-- Dynamic Delay Time --
	SELECT	@WaitFor = dbo.f_BU_GetDelayTime(''FriRoutine'');
	WAITFOR DELAY @WaitFor;
END

drop table #bettransm14_ExecRep_02
-- /143763 Brice edited job--
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