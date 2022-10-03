/*<info serverAlias="DBTP-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
GO
ALTER PROCEDURE [dbo].[Task_MBU_CheckRowCount_DR]
AS
/*
	Created: 20220429@Bobby
	Task: Check consistency data for archiving process
		
	Revisions:
		- 20220429@Bobby:	Initial - [Redmine: #000000]
		- 20221003@Max: [TVS] Enhance archive process of TVS data regarding the Scale Out DB project - [Redmine: #178234]
*/
BEGIN;
	SET NOCOUNT ON;

	DECLARE	@rowIndex		INT
		,	@winlostdate	SMALLDATETIME
		,	@OutputData		VARCHAR(4000)
		,	@xmlData		XML
		,	@hasDiff		BIT
		,	@StartDate		SMALLDATETIME
		,	@EndDate		SMALLDATETIME 
		;

	DECLARE	@email_body		NVARCHAR(MAX)
		,	@subject		NVARCHAR(200)
		;

	CREATE TABLE	#__archiveDate (
						rid				INT					IDENTITY(1,1)
							PRIMARY KEY CLUSTERED
					,	winlostdate		SMALLDATETIME
					);
	
	CREATE TABLE	#__archiveDRResult (
						winlostdate		SMALLDATETIME
					,	tableName		VARCHAR(128)
					,	CheckRowCount	INT
					);
	
	CREATE TABLE	#__archiveDRResult_TVS_tmp (
						winlostdate		SMALLDATETIME
					,	tableName		VARCHAR(128)
					,	CheckRowCount	INT
					);


	INSERT INTO	#__archiveDate (winlostdate)
	SELECT	TOP(10)
			winlostdate
	FROM	DBTXN.bodb02.dbo.Task_ArchiveDate WITH (NOLOCK)
	ORDER BY winlostdate;
	
	SELECT @StartDate = MIN(winlostdate), @EndDate = MAX(winlostdate)
	FROM #__archiveDate
	
	DECLARE @StartDate_tmp	SMALLDATETIME	= @StartDate
			,@EndDate_tmp	SMALLDATETIME = @EndDate 
	
	SET	@rowIndex = 1;
	WHILE	EXISTS (SELECT TOP(1) 1 FROM #__archiveDate WHERE rid = @rowIndex)
	BEGIN;
		SELECT	@winlostdate = winlostdate
		FROM	#__archiveDate WITH (NOLOCK)
		WHERE	rid = @rowIndex;

		SET	@rowIndex += 1;
		IF	@winlostdate IS NULL
			CONTINUE;

		--//event in DR AWS@DB061
		SET	@OutputData = NULL;
		EXECUTE	DB061AWS.bodb_Archive.dbo.Task_MBU_Event_BK_CheckRowCount_Sel
					@DateCheck = @winlostdate
				,	@OutputData = @OutputData	OUTPUT
				;

		IF	@OutputData IS NOT NULL
		BEGIN;
			SET	@xmlData = CAST(@OutputData AS XML);
			INSERT INTO	#__archiveDRResult (winlostdate, tableName, CheckRowCount)
			SELECT	@winlostdate, r.value('./@t','varchar(128)'), r.value('./@r','int')
			FROM	@xmlData.nodes('//r') AS RECORDS(r)
			OPTION (OPTIMIZE FOR (@xmlData = NULL ));
		END;

		--//Bet in DR AWS@DB061
		SET	@OutputData = NULL;
		EXECUTE	DB061AWS.bodb_Archive.dbo.Task_MBU_Bet_BK_CheckRowCount_Sel
					@DateCheck	= @winlostdate
				,	@OutputData	= @OutputData	OUTPUT
				;

		IF	@OutputData IS NOT NULL
		BEGIN;
			SET @xmlData = CAST(@OutputData AS XML);
			INSERT #__archiveDRResult(winlostdate, tableName, CheckRowCount)
			SELECT @winlostdate, r.value('./@t','varchar(128)'), r.value('./@r','int')
			FROM @xmlData.nodes('//r') AS RECORDS(r)
			OPTION (OPTIMIZE FOR (@xmlData = NULL ));
		END;

		--//TO in DR AWS@DB061
		SET	@OutputData = NULL;
		EXECUTE	DB061AWS.bodb_Archive.dbo.Task_MBU_TO_BK_CheckRowCount_Sel
					@DateCheck	= @winlostdate
				,	@OutputData	= @OutputData	OUTPUT
				;

		IF	@OutputData IS NOT NULL
		BEGIN;
			SET @xmlData = CAST(@OutputData AS XML);
			INSERT #__archiveDRResult(winlostdate, tableName, CheckRowCount)
			SELECT @winlostdate, r.value('./@t','varchar(128)'), r.value('./@r','int')
			FROM @xmlData.nodes('//r') AS RECORDS(r)
			OPTION (OPTIMIZE FOR (@xmlData = NULL ));
		END;

	END;

	----------- Get Result for TVS --------
	DECLARE	@ArchiveTable TABLE (
				rid			INT				IDENTITY(1,1)
			,	tablename	NVARCHAR(128)
			,	PRIMARY KEY CLUSTERED (rid)
			)

	DECLARE	@ArchiveTable_oneDay TABLE (
				rid			INT				IDENTITY(1,1)
			,	tablename	NVARCHAR(128)
			,	PRIMARY KEY CLUSTERED (rid)
			)
		
	DECLARE @start_rid INT, @End_rid INT, @TableName VARCHAR(50)
	INSERT INTO	@ArchiveTable
			(tablename)
	VALUES	('TicketVoiding_RequestDetail')
		,	('TicketVoiding_Request')
		,	('TicketVoiding_AutoUnmarkSetting')	

	INSERT INTO	@ArchiveTable_oneDay
			(tablename)
	VALUES	('zzzbettransM')
		,	('zzzbettrans')
		,	('TicketVoiding_VoidedTransaction')
		,	('CashOutSelling')
		
	SET @start_rid = 1
	SET @End_rid = (SELECT MAX(rid) FROM @ArchiveTable)
	-------------------------// TVS Table in active data in DBTRANS & DB061 -------------------------------------
	----- first: check one by one table name in the @ArchiveTable
	WHILE @start_rid <= @End_rid
	BEGIN
		SELECT @TableName = (SELECT tablename FROM @ArchiveTable WHERE rid = @start_rid)
		
		----------- DR AWS@DB061--------
		SET	@OutputData = NULL;
		EXECUTE	DB061AWS.bodb_Archive.dbo.Task_MBU_TVS_BK_CheckRowCount_Sel_DR
				@StartDate	= @StartDate
				, @EndDate = @EndDate
				, @TableName = @TableName
				,@OutputData	= @OutputData	OUTPUT

		IF	@OutputData IS NOT NULL
		BEGIN;
			SET @xmlData = CAST(@OutputData AS XML);
			INSERT #__archiveDRResult_TVS_tmp(winlostdate, tableName, CheckRowCount)
			SELECT r.value('./@ADate','SMALLDATETIME'), r.value('./@t','varchar(128)'), r.value('./@r','int')
			FROM @xmlData.nodes('//r') AS RECORDS(r)
			OPTION (OPTIMIZE FOR (@xmlData = NULL ));
		END

		SET @start_rid = @start_rid + 1
		
	END
	----- second: check one by one table name in the @ArchiveTable_oneDay
	SET @start_rid = 1
	SET @End_rid = (SELECT MAX(rid) FROM @ArchiveTable_oneDay)
	WHILE @start_rid <= @End_rid
	BEGIN
		SELECT @TableName = (SELECT tablename FROM @ArchiveTable_oneDay WHERE rid = @start_rid)
		SET @StartDate_tmp = @StartDate
		
		WHILE (@StartDate_tmp <= @EndDate_tmp)
		BEGIN
			----------------------DR AWS@DB061 -----------------
			SET	@OutputData = NULL;
			EXECUTE	DB061AWS.bodb_Archive.dbo.Task_MBU_TVS_BK_CheckRowCount_Sel_DR
					@StartDate	= @StartDate_tmp
					, @TableName = @TableName
					,	@OutputData	= @OutputData	OUTPUT

			IF	@OutputData IS NOT NULL
			BEGIN;
				SET @xmlData = CAST(@OutputData AS XML);
				INSERT #__archiveDRResult_TVS_tmp(winlostdate, tableName, CheckRowCount)
				SELECT r.value('./@ADate','SMALLDATETIME'), r.value('./@t','varchar(128)'), r.value('./@r','int')
				FROM @xmlData.nodes('//r') AS RECORDS(r)
				OPTION (OPTIMIZE FOR (@xmlData = NULL ));
			END

			SET @StartDate_tmp = DATEADD(DD, 1, @StartDate_tmp)
			
		END	
		SET @start_rid = @start_rid + 1
		
	END
	--------------INSERT Result for TVS Table -------------------------	
	INSERT INTO #__archiveDRResult (winlostdate,tableName,CheckRowCount)
	SELECT ISNULL(winlostdate, @StartDate), tableName, SUM(CheckRowCount)
	FROM #__archiveDRResult_TVS_tmp
	GROUP BY ISNULL(winlostdate, @StartDate),tableName
	
	-- INSERT Logs
	BEGIN TRY
		INSERT INTO dbo.Task_MBU_CheckRowCount_Logs (
			SourceName,
			TableName,
			Winlostdate,
			CheckRowCount,
			Thursday
		)
		SELECT 'DB061AWS' AS SourceName, a.tablename, ISNULL(a.winlostdate, @StartDate) AS Winlostdate, a.CheckRowCount, @EndDate AS [Thursday]
		FROM #__archiveDRResult a
	END TRY
	BEGIN CATCH
		-- TODO: 
		SELECT ERROR_PROCEDURE() AS [ERROR_PROCEDURE]
			, ERROR_NUMBER() AS [ERROR_NUMBER]
			, ERROR_MESSAGE() AS [ERROR_MESSAGE]
	END CATCH
	
	IF	EXISTS (
		SELECT TOP(1) 1
		FROM dbo.Task_MBU_CheckRowCount_Logs t WITH(NOLOCK)
		FULL OUTER JOIN	#__archiveDRResult tt
					ON	ISNULL(t.winlostdate,'') = ISNULL(tt.winlostdate,'')
					AND	t.tableName = tt.tableName
		WHERE t.Thursday = @EndDate AND t.SourceName = 'DBActive'
			AND ISNULL(t.CheckRowCount, 0) <> ISNULL(tt.CheckRowCount, 0)
	)
	BEGIN;
		SET	@hasDiff = 1;
	END;
	ELSE
	BEGIN;
		SET	@hasDiff = 0;
	END;

	DECLARE @ArchiveRange_TVS VARCHAR(50)
	SET @ArchiveRange_TVS = CONVERT(VARCHAR(12),@startdate, 23) + ' -> ' + CONVERT(VARCHAR(12),@EndDate,23)
	
	-- Build html
	SELECT	@subject	= N'DR - Archving process check count - AWS@' + @@SERVERNAME
		,	@email_body = (
				SELECT	
						[@style]		= N'width: 100%;'
					,	[h1/@align]		= N'center'
					,	[h1]			= N'DR - Archiving Data Row Count Check!'
					,	[p/b]			= N'Check time: '
					,	[p]				= CONVERT(NVARCHAR, GETDATE(), 120)
					,	[div/@align]	= N'center'
					,	[div/@style]	= N'\
background-color:' + s.color + N';\
width:80%;color:white;text-align:center;margin:0 auto;padding:20px;font-size:30px;\
'
					,	[div/b]			= s.status
					,	[p/b]			= CASE WHEN @hasDiff = 0 THEN NULL ELSE N'Error message: ' END
					,	[p]				= CASE	WHEN @hasDiff = 1 THEN N'One or more tables has mismatch data when archiving data. Please check!!!'
												WHEN @hasDiff IS NULL THEN N'Unexpected error. Please check!!!'
												ELSE NULL
										  END
					,	[br]			= N''
					,	(
						SELECT	[@border]		= 1
							,	[@cellpadding]	= 5
							,	[@width]		= N'95%'
							,	[@style]		= N'margin:0 auto;white-space:nowrap;border-collapse:collapse;'
							,	(
								SELECT	NULL, [th]	= N'WinLostDate'
									,	NULL, [th]	= N'TableName'
									,	NULL, [th]	= N'Active RowCount'
									,	NULL, [th]	= N'Archive DR RowCount'
									,	NULL, [th]	= N'Delta DR'
								WHERE	@hasDiff IS NOT NULL
								FOR XML PATH ('tr')
								,	TYPE
								)
							,	(
								SELECT	NULL, [td]	= ISNULL(CONVERT(VARCHAR(50),CAST(ISNULL(active.winlostdate, archive.winlostdate) AS DATE), 120), @ArchiveRange_TVS)
									,	NULL, [td]	= ISNULL(active.tableName, archive.tableName)
									,	NULL, [td]	= ISNULL(active.CheckRowCount, 0)
									,	NULL, [td]	= ISNULL(archive.CheckRowCount, 0)
									,	NULL, [td]	= ISNULL(active.CheckRowCount, 0) - ISNULL(archive.CheckRowCount, 0)
								FROM	dbo.Task_MBU_CheckRowCount_Logs AS active WITH(NOLOCK)
								FULL OUTER JOIN	#__archiveDRResult AS archive WITH (NOLOCK)
											ON	active.tableName = archive.tableName
											AND	ISNULL(active.winlostdate,'') = ISNULL(archive.winlostdate,'')
								WHERE active.Thursday = @EndDate AND active.SourceName = 'DBActive'
								ORDER BY	CASE WHEN ISNULL(active.CheckRowCount, 0) <> ISNULL(archive.CheckRowCount, 0) THEN 0 
												 WHEN ISNULL(active.CheckRowCount, 0) <> ISNULL(archive.CheckRowCount, 0) THEN 0 ELSE 1 END
										,	ISNULL(active.winlostdate, archive.winlostdate)
										,	ISNULL(active.tableName, archive.tableName)
								FOR XML PATH ('tr')
								,	TYPE
								)
						FOR XML PATH ('table')
						,	TYPE
						)
				FROM	(
					SELECT	[color]		= CASE @hasDiff WHEN 1 THEN N'red' WHEN 0 THEN N'blue' ELSE N'purple' END
						,	[status]	= CASE @hasDiff WHEN 1 THEN N'Failure' WHEN 0 THEN N'Success' ELSE N'Error' END
				) AS s
				FOR XML PATH ('body')
				,	ROOT ('html')
			);

	EXECUTE	msdb.dbo.sp_send_dbmail
				@profile_name			= DEFAULT
			,	@recipients				= 'pontus@starixvn.com'
			,	@copy_recipients		= ''
			,	@blind_copy_recipients	= ''
			,	@subject				= @subject
			,	@body					= @email_body
			,	@body_format			= 'HTML'
			;
	
	-- RETURN:
	SELECT	@hasDiff AS [HasDiff];
	
	DROP TABLE #__archiveDate;
	DROP TABLE #__archiveDRResult;
	DROP TABLE #__archiveDRResult_TVS_tmp;
END;
