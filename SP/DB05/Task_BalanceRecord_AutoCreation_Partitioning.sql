/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Task_BalanceRecord_AutoCreation_Partitioning]
	@MonthDate DATE = NULL
	, @ModeView BIT = 1
AS
/*
	Created: 20220725@Bobby
	DB: DBBAH.bodb02
	Task: 
	Revision:
		- 20220725@Bobby: Init [Redmine:#175815]
*/
BEGIN
	--SELECT @MonthDate = '2022-08-01';

	DECLARE @checkServer BIT = 0
		, @cleanCommand NVARCHAR(MAX)
		, @splitCommand NVARCHAR(MAX);

	DECLARE @DBA_Task_AutoPartitionExtend  TABLE
	(
		TABLE_NAME			VARCHAR(250),
		TABLE_SCHEME		VARCHAR(250),
		FGROUP_NAME			VARCHAR(250),
		PartitionFunction	VARCHAR(250),
		PartitionScheme		VARCHAR(250),
		FIRST_NUMBER		TINYINT,
		FIRST_RANGE			DATETIME,
		LAST_RANGE			DATETIME,
		running_month		DATETIME,
		clean_range			DATETIME,
		DiffCleanMonth		INT,
		isClean				BIT,
		next_range			DATETIME,
		DiffNextMonth		INT,
		isNextExtend		BIT,
		Clean_FileGroup		VARCHAR(250),
		Next_FileGroup		VARCHAR(250)
	);

	DECLARE @DBA_Task_AutoPartition  TABLE
	(
		month_date	DATETIME,
		range_value	DATETIME,
		NoM			TINYINT,
		NoP			VARCHAR(250),
		last_range	DATETIME,
		last_NoP	VARCHAR(250),
		next_range	DATETIME,
		next_NoP	VARCHAR(250)
	);

	SELECT @MonthDate	= ISNULL(@MonthDate, CURRENT_TIMESTAMP)
		,@MonthDate		= DATEADD(DAY, -DATEPART(DAY,@MonthDate)+1, @MonthDate);

	;WITH meta AS (
		SELECT 'BalanceRecord_bk' AS TABLE_NAME
			,'BR_22M' AS FGROUP_NAME
			,cast(@MonthDate as datetime) as running_month
	),
	temp as (
		SELECT m.TABLE_NAME, s.name AS TABLE_SCHEME, m.FGROUP_NAME,
			pf.name as PartitionFunction, 
			ps.name as PartitionScheme, 
			MIN(p.partition_number) AS FIRST_NUMBER,
			convert(datetime,MIN(rv.value)) AS FIRST_RANGE,
			convert(datetime,MAX(rv.value)) AS LAST_RANGE,
			m.running_month
		FROM meta m
		INNER JOIN sys.tables o ON o.name = m.TABLE_NAME
		inner join sys.partitions p ON p.object_id = o.object_id
		INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
		inner JOIN sys.schemas s ON s.schema_id = o.schema_id
		INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id
		INNER JOIN sys.partition_functions pf ON pf.function_id = ps.function_id
		INNER JOIN sys.partition_range_values rv ON pf.function_id = rv.function_id AND p.partition_number = rv.boundary_id
		GROUP BY s.name,m.TABLE_NAME, pf.name, ps.name, m.FGROUP_NAME,m.running_month
	)
	INSERT INTO @DBA_Task_AutoPartitionExtend (
		TABLE_NAME,	TABLE_SCHEME,	FGROUP_NAME,	PartitionFunction,	PartitionScheme,	FIRST_NUMBER,	FIRST_RANGE,	LAST_RANGE,	running_month,	clean_range,	DiffCleanMonth,	isClean,	next_range,	DiffNextMonth,	isNextExtend
	)
	SELECT t.* 
		--MERGE
		, sk.clean_range
		, DATEDIFF(MONTH, t.FIRST_RANGE, sk.clean_range) AS DiffCleanMonth
		, CASE WHEN DATEDIFF(MONTH, t.FIRST_RANGE, sk.clean_range) >=0  THEN 1 ELSE 0 END isClean
		--SPLIT
		, sk.next_range
		, DATEDIFF(MONTH, t.LAST_RANGE, sk.next_range) AS DiffNextMonth
		, CASE WHEN DATEDIFF(MONTH, t.LAST_RANGE, sk.next_range) >=1  THEN 1 ELSE 0 END isNextExtend
	FROM temp t
	CROSS APPLY (
		SELECT DATEADD(MILLISECOND, -3, DATEADD(MONTH, 1, CONVERT(DATETIME, CAST(DATEADD(MONTH, 3, DATEADD(DAY, -DATEPART(DAY,t.running_month)+1, t.running_month)) AS DATE)))) AS next_range
			,DATEADD(MILLISECOND, -3, DATEADD(MONTH, 1, CONVERT(DATETIME, CAST(DATEADD(MONTH, -4, DATEADD(DAY, -DATEPART(DAY,t.running_month)+1, t.running_month)) AS DATE)))) AS clean_range
	) sk


	-- PARTITION files mapping
	;
	WITH meta ([MoY],F_GROUP) AS ( 
		SELECT CONCAT(FORMAT(@MonthDate, 'yyyy'),'-01-01'), 'BR_22M'
	),
	cte_month (month_date, range_value, NoM) as
	(
		select cast([MoY] as datetime), DATEADD(MILLISECOND, -3, DATEADD(MONTH,1,cast([MoY] as datetime))), 1
		FROM meta
		union all
		select DATEADD(MONTH, 1, month_date), DATEADD(MILLISECOND, -3, DATEADD(MONTH,2,month_date)), NoM+1
		from cte_month
		where NoM < 12
	),
	cte_partition AS (
		SELECT m.*, CONCAT(t.F_GROUP, case when NoM < 10 then '0' else '' end, NoM) AS NoP
			, sk.last_range, CONCAT(t.F_GROUP, case when sk.last_P < 10 then '0' else '' end, sk.last_P) AS last_NoP
			, sk.next_range, CONCAT(t.F_GROUP, case when sk.next_P < 10 then '0' else '' end, sk.next_P) AS next_NoP
		FROM cte_month m
		CROSS APPLY meta t
		CROSS APPLY (
			SELECT 
				DATEADD(MILLISECOND, -3, dateadd(MONTH, -3, m.month_date)), MONTH(dateadd(MONTH, -4, m.month_date))
				,DATEADD(MILLISECOND, -3, dateadd(MONTH, 4, m.month_date)), MONTH(dateadd(MONTH, 3, m.month_date))

		) AS sk (last_range, last_P, next_range, next_P)
	)
	INSERT INTO @DBA_Task_AutoPartition
	SELECT *
	FROM cte_partition

	--SELECT  * FROM @DBA_Task_AutoPartitionExtend
	--SELECT  * FROM @DBA_Task_AutoPartition WHERE month_date = @MonthDate;

	;WITH cte_PreCommand AS (
		SELECT clean.Clean_FileGroup
			,split.Next_FileGroup
		FROM @DBA_Task_AutoPartitionExtend ex
		OUTER APPLY (
			SELECT p.last_NoP AS Clean_FileGroup
			FROM @DBA_Task_AutoPartition p
			WHERE ex.FIRST_RANGE = p.last_range
				AND ex.isClean = 1
		) AS clean
		OUTER APPLY (
			SELECT p.Next_NoP AS Next_FileGroup
			FROM @DBA_Task_AutoPartition p
			WHERE ex.next_range = p.next_range
				AND ex.isNextExtend = 1
		) AS split
	)
	UPDATE ex
	SET Clean_FileGroup = pre.Clean_FileGroup
		,Next_FileGroup = pre.Next_FileGroup
	FROM @DBA_Task_AutoPartitionExtend ex
	CROSS APPLY cte_PreCommand pre
	;

	--SELECT * FROM @DBA_Task_AutoPartitionExtend;

	-- TRUNCATE & MERGE Command
	SELECT @cleanCommand = COALESCE(@cleanCommand + ' ', '') + ISNULL(CmdText,'')
	FROM @DBA_Task_AutoPartitionExtend t
	CROSS APPLY (
		SELECT CONCAT('TRUNCATE TABLE ',  t.TABLE_SCHEME, '.',t.TABLE_NAME, ' WITH(PARTITIONS(',t.FIRST_NUMBER,'));')
		UNION ALL
		SELECT CONCAT('ALTER PARTITION FUNCTION ', PartitionFunction, '() MERGE RANGE (''',CONVERT(VARCHAR, FIRST_RANGE, 25),''');')
	) AS c (CmdText)
	WHERE t.isClean = 1

	-- SPLIT Command
	SELECT @splitCommand = COALESCE(@splitCommand + ' ', '') + ISNULL(CmdText,'')
	FROM @DBA_Task_AutoPartitionExtend t
	CROSS APPLY (
		SELECT CONCAT('ALTER PARTITION SCHEME ', PartitionScheme, ' NEXT USED [',t.Next_FileGroup,'];')
		UNION ALL
		SELECT CONCAT('ALTER PARTITION FUNCTION ', PartitionFunction, '() SPLIT RANGE (''',CONVERT(VARCHAR, t.next_range, 25),''');')
	) AS c (CmdText)
	WHERE t.isNextExtend = 1

	------ WRITE Logs
	INSERT INTO dbo.DBA_AutoPartition_Logs (
		table_name,
		running_month,
		clean_range,
		clean_command,
		split_range,
		split_command,
		start_time
	)
	SELECT ex.TABLE_NAME, ex.running_month, ex.clean_range, @cleanCommand, ex.next_range, @splitCommand, CURRENT_TIMESTAMP
	FROM @DBA_Task_AutoPartitionExtend ex
	WHERE @ModeView = 0
		AND (ex.isClean = 1 OR ex.isNextExtend = 1)
		AND NOT EXISTS (
			SELECT 1 FROM dbo.DBA_AutoPartition_Logs l
			WHERE l.table_name =  ex.TABLE_NAME AND l.running_month = ex.running_month
		)
	------ END Logs

	------ PRE-DO:
	DECLARE @cntLoop INT = 0, @isSuccess BIT = 0, @ERROR VARCHAR(1000);
	------ TODO:
	DO_PARTITION:
	SET LOCK_TIMEOUT 1000; --- wait for 1s lock released if any
	BEGIN TRAN
	BEGIN TRY
		IF @ModeView= 1
		BEGIN
			SELECT @cleanCommand AS CMD
			UNION ALL
			SELECT @splitCommand
		END
		ELSE
		BEGIN
			EXEC (@cleanCommand);
			EXEC (@splitCommand);
		END
		COMMIT
		SET @isSuccess = 1;
	
	END TRY
	BEGIN CATCH
		SELECT @ERROR = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK
		SET @cntLoop += 1;
		IF @cntLoop < 5
			GOTO DO_PARTITION;	
	END CATCH

	-- CHECK server to send notify
	SELECT @checkServer = 1
	WHERE @@SERVERNAME IN ('DB05', 'DB05BK1')

	---- UPDATE Logs
	UPDATE l WITH(ROWLOCK, UPDLOCK)
	SET end_time	= CURRENT_TIMESTAMP
		, error		= @ERROR 
	FROM dbo.DBA_AutoPartition_Logs l
	INNER JOIN @DBA_Task_AutoPartitionExtend ex ON ex.TABLE_NAME = l.table_name AND ex.running_month = l.running_month
	WHERE @ModeView = 0
	------ END Logs

	-- CHECK Result
	IF (@isSuccess=0 AND LEN(@ERROR) > 0)
	BEGIN
		DECLARE @msgError NVARCHAR(1000);
		SET @msgError = CONCAT(@@SERVERNAME, '@',DB_NAME(), '.dbo.',OBJECT_NAME(@@PROCID),' auto partition with ERROR. ', @ERROR)
		RAISERROR  (@msgError, 16, 1) WITH NOWAIT;
	END
	ELSE
	BEGIN
		-- SEND Notification via PONTUS's Skype
		DECLARE @msgNotify NVARCHAR(1000), @mergeP varchar(250), @splitP varchar(250);
		SELECT @mergeP = ISNULL(p.Clean_FileGroup, 'N/A'), @splitP = ISNULL(p.Next_FileGroup, 'N/A')
		FROM @DBA_Task_AutoPartitionExtend p

		SELECT @msgNotify = CONCAT(@@SERVERNAME, '@',DB_NAME(), '.dbo.',OBJECT_NAME(@@PROCID),' auto partition with SUCCESS on [CURRENT-Partition: ', @MonthDate, ', MERGE-Partition: ', @mergeP ,', SPLIT-Partition: ', @splitP, ']')
		WHERE @mergeP IS NOT NULL OR @splitP IS NOT NULL

		--select @msgNotify AS [@msgNotify]
		IF (@checkServer = 1)
		BEGIN	
			BEGIN TRY
				EXEC DBNOTI.NotificationDB.[dbo].[DBA_Skype_NewMessage]
					@ServerName			= 'PONTUS'
				,	@JobName			= N'Custom Message'
				,	@Message			= @msgNotify
			END TRY
			BEGIN CATCH
				--TODO:
				RAISERROR  (@msgNotify, 16, 1) WITH NOWAIT;
			END CATCH
		END

		-- DBCC SHRINKFILE Command
		DECLARE @shinkFileGroup NVARCHAR(250);

		SELECT @shinkFileGroup = COALESCE(@shinkFileGroup + ' ', '') + ISNULL(CmdText,'')
		FROM @DBA_Task_AutoPartitionExtend t
		CROSS APPLY (SELECT CAST(FILEPROPERTY(t.Clean_FileGroup, 'SpaceUsed') AS INT)) f(SpaceUsed)
		CROSS APPLY (
			SELECT concat('DBCC SHRINKFILE (N''',t.Clean_FileGroup,''',', CEILING((CAST(f.SpaceUsed AS FLOAT)*8)/1024),')')
		) AS c (CmdText)
		WHERE t.isClean = 1 AND t.Clean_FileGroup IS NOT NULL

		BEGIN TRY
			IF @ModeView= 1
			BEGIN
				SELECT @shinkFileGroup AS CMD
			END
			ELSE
			BEGIN
				EXEC (@shinkFileGroup);
			END
			SELECT @msgNotify = CONCAT(@@SERVERNAME, '@',DB_NAME(), '-SHRINKFILE with SUCCESS on command [', @shinkFileGroup, ']')
			WHERE @shinkFileGroup IS NOT NULL
		END TRY
		BEGIN CATCH
			SELECT @ERROR = ERROR_MESSAGE();
			SELECT @msgNotify = CONCAT(@@SERVERNAME, '@',DB_NAME(), '-SHRINKFILE with ERROR.', @ERROR)
		END CATCH

		--select @msgNotify AS [@msgNotify]
		IF (@checkServer = 1)
		BEGIN	
			BEGIN TRY
				EXEC DBNOTI.NotificationDB.[dbo].[DBA_Skype_NewMessage]
					@ServerName			= 'PONTUS'
				,	@JobName			= N'Custom Message'
				,	@Message			= @msgNotify
			END TRY
			BEGIN CATCH
				--TODO:
				RAISERROR  (@msgNotify, 16, 1) WITH NOWAIT;
			END CATCH
		END
	END
END
GO