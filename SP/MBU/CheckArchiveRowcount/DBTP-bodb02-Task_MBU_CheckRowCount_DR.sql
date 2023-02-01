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
	-- 202206272Bobby: Wait for completing UPDATESTATISTIC tasks on AWS@DB061
	WAITFOR DELAY '02:00:00.000';

	-- TODO: Get rowcount
	DECLARE	@winlostdate	SMALLDATETIME
		,	@hasDiff		BIT
		,	@StartDate		SMALLDATETIME
		,	@EndDate		SMALLDATETIME 
		,	@waitCount		INT
		,	@DRCompleted	BIT
		;

	DECLARE	@email_body		NVARCHAR(MAX)
		,	@subject		NVARCHAR(200)
		;

	CREATE TABLE	#__archiveDate (
						rid				INT	IDENTITY(1,1) PRIMARY KEY CLUSTERED
					,	winlostdate		SMALLDATETIME
				);
	
	INSERT INTO	#__archiveDate (winlostdate)
	SELECT	TOP(10)
		winlostdate
	FROM DBTXN.bodb02.dbo.Task_ArchiveDate WITH (NOLOCK)
	ORDER BY winlostdate;
	
	SELECT 
		@StartDate = MIN(winlostdate)
		, @EndDate = MAX(winlostdate)
	FROM #__archiveDate
	
	SELECT @waitCount = 1, @DRCompleted = 0;
	WHILE(@waitCount <= 24) -- wait for MAX 2h to sum/count from DB061AWS duration
	BEGIN
		IF EXISTS(SELECT TOP(1) 1 
			FROM DB061AWS.bodb_Archive.dbo.Task_MBU_CheckRowCount_Logs with(nolock)
			WHERE SourceName='DB061AWS' 
				AND Thursday = @EndDate
		)
		BEGIN 
			SET @DRCompleted = 1;
			BREAK;
		END
		ELSE
		BEGIN
			SET @waitCount+=1;
			WAITFOR DELAY '00:05:00';
		END
	END
	
	--TODO: check for DR completion
	IF @DRCompleted = 0
		RETURN;

	BEGIN TRY
		DELETE dbo.Task_MBU_CheckRowCount_Logs WHERE SourceName='DB061AWS' AND [Thursday]=@EndDate;
		INSERT INTO dbo.Task_MBU_CheckRowCount_Logs (
			SourceName,
			TableName,
			Winlostdate,
			CheckRowCount,
			Thursday
		)
		SELECT 
			SourceName,
			TableName,
			Winlostdate,
			CheckRowCount,
			Thursday
		FROM DB061AWS.bodb_Archive.dbo.Task_MBU_CheckRowCount_Logs with(nolock)
		WHERE SourceName='DB061AWS' AND Thursday = @EndDate
	
		IF	EXISTS (
			SELECT TOP(1) 1
			FROM dbo.Task_MBU_CheckRowCount_Logs t WITH(NOLOCK)
			FULL OUTER JOIN	dbo.Task_MBU_CheckRowCount_Logs tt WITH(NOLOCK)
						ON	t.winlostdate = tt.winlostdate
						AND	t.tableName = tt.tableName AND tt.SourceName = 'DB061AWS' AND tt.Thursday=@EndDate
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
		SELECT	@subject	= N'DR: Check Range BK - Archving process check count - AWS@' + @@SERVERNAME
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
									FULL OUTER JOIN	dbo.Task_MBU_CheckRowCount_Logs AS archive WITH (NOLOCK)
												ON	active.tableName = archive.tableName
												AND	ISNULL(active.winlostdate,'') = ISNULL(archive.winlostdate,'')
												AND archive.SourceName = 'DB061AWS' AND archive.Thursday=@EndDate
									WHERE active.Thursday = @EndDate 
										AND active.SourceName = 'DBActive'
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
	
	END TRY
	BEGIN CATCH
		-- TODO: 
		SELECT ERROR_PROCEDURE() AS [ERROR_PROCEDURE]
			, ERROR_NUMBER() AS [ERROR_NUMBER]
			, ERROR_MESSAGE() AS [ERROR_MESSAGE]
	END CATCH
END;
