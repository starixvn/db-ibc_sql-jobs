/*<info serverAlias="DBTP-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
GO
ALTER PROCEDURE	[dbo].[Task_MBU_CheckRowCount]
AS
/*
	Created: 20180925@Patrick
	Task: Check consistency data for archiving process
		
	Revisions:
		- 20180926@Patrick:	Initial - [Redmine: #101207]
		- 20190621@Billy:	New way to generate html - [Redmine: #111421]
		- 20191212@Patrick: Add more table TOControl_Setting [Redmine: #124447]
		- 20201022@Patrick: Change email to starixvn [Redmine: #143607]
		- 20210628@Helen:	Move checking for TVS tables to another SP Task_MBU_TVS_BK_CheckRowCount_Sel [RedmineId: #157539]
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

	CREATE TABLE	#__activeResult (
						winlostdate		SMALLDATETIME
					,	tableName		VARCHAR(128)
					,	activeRowCount	INT
					);

	CREATE TABLE	#__archiveResult (
						winlostdate		SMALLDATETIME
					,	tableName		VARCHAR(128)
					,	archiveRowCount	INT
					);

	INSERT INTO	#__archiveDate (winlostdate)
	SELECT	TOP(10)
			winlostdate
	FROM	DBTXN.bodb02.dbo.Task_ArchiveDate WITH (NOLOCK)
	ORDER BY winlostdate;
	
	SELECT @StartDate = MIN(winlostdate), @EndDate = MAX(winlostdate)
	FROM #__archiveDate
	
	SET	@rowIndex = 1;
	WHILE	EXISTS (SELECT TOP(1) 1 FROM #__archiveDate WHERE rid = @rowIndex)
	BEGIN;
		SELECT	@winlostdate = winlostdate
		FROM	#__archiveDate WITH (NOLOCK)
		WHERE	rid = @rowIndex;

		SET	@rowIndex += 1;
		IF	@winlostdate IS NULL
			CONTINUE;

		--Event in active
		SET	@xmlData = NULL;
		EXECUTE	DBPRO.bodb02.dbo.Task_MBU_Event_CheckRowCount_Sel
					@DateCheck	= @winlostdate
				,	@OutputData	= @OutputData	OUTPUT
				;

		IF	@OutputData IS NOT NULL
		BEGIN;
			SET	@xmlData = CAST(@OutputData AS XML);

			INSERT INTO	#__activeResult (winlostdate, tableName, activeRowCount)
			SELECT	@winlostdate, r.value('./@t','varchar(128)'), r.value('./@r','int')
			FROM	@xmlData.nodes('//r') AS RECORDS(r)
			OPTION (OPTIMIZE FOR (@xmlData = NULL ));
		END;

		--Bet in active
		SET	@OutputData = NULL;
		EXECUTE	DBTXN.bodb02.dbo.Task_MBU_Bet_CheckRowCount_Sel
					@DateCheck	= @winlostdate
				,	@OutputData	= @OutputData	OUTPUT
				;

		IF	@OutputData IS NOT NULL
		BEGIN;
			SET	@xmlData = CAST(@OutputData AS XML);
			INSERT INTO	#__activeResult (winlostdate, tableName, activeRowCount)
			SELECT	@winlostdate, r.value('./@t','varchar(128)'), r.value('./@r','int')
			FROM @xmlData.nodes('//r') AS RECORDS(r)
			OPTION (OPTIMIZE FOR (@xmlData = NULL ));
		END;

		--TO in active
		SET	@OutputData = NULL;
		EXECUTE	DBCUST.CustDB.dbo.Task_MBU_TO_CheckRowCount_Sel
					@DateCheck	= @winlostdate
				,	@OutputData	= @OutputData	OUTPUT
				;

		IF	@OutputData IS NOT NULL
		BEGIN;
			SET	@xmlData = CAST(@OutputData AS XML);
			INSERT INTO	#__activeResult (winlostdate, tableName, activeRowCount)
			SELECT	@winlostdate, r.value('./@t','varchar(128)'), r.value('./@r','int')
			FROM @xmlData.nodes('//r') AS RECORDS(r)
			OPTION (OPTIMIZE FOR (@xmlData = NULL ));
		END;

		--//event in archive
		SET	@OutputData = NULL;
		EXECUTE	DBARC.bodb_Archive.dbo.Task_MBU_Event_BK_CheckRowCount_Sel
					@DateCheck = @winlostdate
				,	@OutputData = @OutputData	OUTPUT
				;

		IF	@OutputData IS NOT NULL
		BEGIN;
			SET	@xmlData = CAST(@OutputData AS XML);
			INSERT INTO	#__archiveResult (winlostdate, tableName, archiveRowCount)
			SELECT	@winlostdate, r.value('./@t','varchar(128)'), r.value('./@r','int')
			FROM	@xmlData.nodes('//r') AS RECORDS(r)
			OPTION (OPTIMIZE FOR (@xmlData = NULL ));
		END;

		--//Bet in archive
		SET	@OutputData = NULL;
		EXECUTE	DBARC.bodb_Archive.dbo.Task_MBU_Bet_BK_CheckRowCount_Sel
					@DateCheck	= @winlostdate
				,	@OutputData	= @OutputData	OUTPUT
				;

		IF	@OutputData IS NOT NULL
		BEGIN;
			SET @xmlData = CAST(@OutputData AS XML);
			INSERT #__archiveResult(winlostdate, tableName, archiveRowCount)
			SELECT @winlostdate, r.value('./@t','varchar(128)'), r.value('./@r','int')
			FROM @xmlData.nodes('//r') AS RECORDS(r)
			OPTION (OPTIMIZE FOR (@xmlData = NULL ));
		END;

		--//TO in archive
		SET	@OutputData = NULL;
		EXECUTE	DBARC.bodb_Archive.dbo.Task_MBU_TO_BK_CheckRowCount_Sel
					@DateCheck	= @winlostdate
				,	@OutputData	= @OutputData	OUTPUT
				;

		IF	@OutputData IS NOT NULL
		BEGIN;
			SET @xmlData = CAST(@OutputData AS XML);
			INSERT #__archiveResult(winlostdate, tableName, archiveRowCount)
			SELECT @winlostdate, r.value('./@t','varchar(128)'), r.value('./@r','int')
			FROM @xmlData.nodes('//r') AS RECORDS(r)
			OPTION (OPTIMIZE FOR (@xmlData = NULL ));
		END;
	END;
	----------- Get Result for TVS --------
	--// TVS Table in active
	SET	@OutputData = NULL;
	EXECUTE	DBTXN.bodb02.dbo.Task_MBU_TVS_CheckRowCount_Sel	
			@StartDate	= @StartDate
			, @EndDate = @EndDate
			, @OutputData = @OutputData	OUTPUT

	IF	@OutputData IS NOT NULL
	BEGIN;
		SET	@xmlData = CAST(@OutputData AS XML);
		INSERT INTO	#__activeResult (winlostdate, tableName, activeRowCount)
		SELECT	r.value('./@ADate','SMALLDATETIME'), r.value('./@t','varchar(128)'), r.value('./@r','int')
		FROM @xmlData.nodes('//r') AS RECORDS(r)
		OPTION (OPTIMIZE FOR (@xmlData = NULL ));
	END
		
	--// TVS Table in archive
	SET	@OutputData = NULL;
	EXECUTE	DBARC.bodb_Archive.dbo.Task_MBU_TVS_BK_CheckRowCount_Sel
				@StartDate	= @StartDate
				, @EndDate = @EndDate
				,	@OutputData	= @OutputData	OUTPUT

	IF	@OutputData IS NOT NULL
	BEGIN;
		SET @xmlData = CAST(@OutputData AS XML);
		INSERT #__archiveResult(winlostdate, tableName, archiveRowCount)
		SELECT r.value('./@ADate','SMALLDATETIME'), r.value('./@t','varchar(128)'), r.value('./@r','int')
		FROM @xmlData.nodes('//r') AS RECORDS(r)
		OPTION (OPTIMIZE FOR (@xmlData = NULL ));
	END
			
	IF	EXISTS (
		SELECT TOP(1) 1
		FROM			#__activeResult t
		FULL OUTER JOIN	#__archiveResult tt
					ON	ISNULL(t.winlostdate,'') = ISNULL(tt.winlostdate,'')
					AND	t.tableName = tt.tableName
		WHERE	ISNULL(t.activeRowCount, 0) <> ISNULL(tt.archiveRowCount, 0)
	)
	BEGIN;
		SET	@hasDiff = 1;
	END;
	ELSE
	BEGIN;
		SET	@hasDiff = 0;
	END;

	-- Build html
	SELECT	@subject	= N'Archving process check count - KBT@' + @@SERVERNAME
		,	@email_body = (
				SELECT	
						[@style]		= N'width: 100%;'
					,	[h1/@align]		= N'center'
					,	[h1]			= N'Archiving Data Row Count Check!'
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
									,	NULL, [th]	= N'Archive RowCount'
									,	NULL, [th]	= N'Delta'
								WHERE	@hasDiff IS NOT NULL
								FOR XML PATH ('tr')
								,	TYPE
								)
							,	(
								SELECT	NULL, [td]	= ISNULL(CAST(ISNULL(active.winlostdate, archive.winlostdate) AS DATE),'')
									,	NULL, [td]	= ISNULL(active.tableName, archive.tableName)
									,	NULL, [td]	= ISNULL(active.activeRowCount, 0)
									,	NULL, [td]	= ISNULL(archive.archiveRowCount, 0)
									,	NULL, [td]	= ISNULL(active.activeRowCount, 0) - ISNULL(archive.archiveRowCount, 0)
								FROM			#__activeResult AS active WITH (NOLOCK)
								FULL OUTER JOIN	#__archiveResult AS archive WITH (NOLOCK)
											ON	active.tableName = archive.tableName
											AND	ISNULL(active.winlostdate,'') = ISNULL(archive.winlostdate,'')
								ORDER BY	CASE WHEN ISNULL(active.activeRowCount, 0) <> ISNULL(archive.archiveRowCount, 0) THEN 0 ELSE 1 END
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

END;
GO
