/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
/*
	Created:	20210301@Max
	Task:		[TVS] Remove archived data [Redmine: #150524]
	Database:	DBTXN-bodb02
*/
BEGIN

	CREATE TABLE #DeletedList (id INT PRIMARY KEY CLUSTERED,IsDone BIT)

	DECLARE	@ArchiveTable TABLE (
				rid			INT				IDENTITY(1,1)
			,	tablename	NVARCHAR(128)
			,	PRIMARY KEY CLUSTERED (rid)
			);
	INSERT INTO	@ArchiveTable (tablename)
	VALUES	('TicketVoiding_VoidedTransaction')
		,	('TicketVoiding_Reason')
		,	('TicketVoiding_VoidingHistory')
		,	('TicketVoiding_Queue')
		,	('TicketVoiding_OperatorInfo')
		,	('TicketVoiding_Request')
		,	('TicketVoiding_AutoUnmarkSetting')
		,	('TicketVoiding_AutoVoidRequest_Queue')
		,	('zzzbettrans')
		,	('zzzbettransM')
		,	('TicketVoiding_RequestDetail')
		,	('TicketVoiding_RequestDetailTicket_Single')
		,	('TicketVoiding_RequestDetailTicket_SubParlay')	
		;
	
	DECLARE	@StartTable			INT
		,	@EndTable			INT
		,	@TableName			NVARCHAR(128)
		;

	DECLARE	@Query	NVARCHAR(MAX)
		,@MaxId		BIGINT = 2138537 --MAX ID of TicketVoiding_VoidedTransaction in 2020 - PRO
		,@MaxKeyId	BIGINT = 1008734020 --MAX KeyId of zzzbettrans in 2020 - PRO

	SELECT	@StartTable	= MIN(rid)
			,	@EndTable	= MAX(rid)
	FROM	@ArchiveTable;

	WHILE	@StartTable <= @EndTable
	BEGIN
		TRUNCATE TABLE #DeletedList

		SELECT @TableName = tablename FROM @ArchiveTable WHERE rid = @StartTable 
		
		IF @TableName = 'TicketVoiding_VoidedTransaction'
		BEGIN
			SELECT	@Query = N'';
			SELECT	@Query = @Query + N'\
			INSERT INTO	#DeletedList (id, IsDone)
			SELECT id,0
			FROM	OPENQUERY(DBARC, ''\
			DECLARE	@MaxId	BIGINT = ''''' + CONVERT(NVARCHAR(MAX), @MaxId) + ''''';

			SELECT	id
			FROM	bodb_Archive.dbo.TicketVoiding_VoidedTransaction_bk AS t1 WITH (NOLOCK)
			WHERE t1.Id > @MaxId
			;'');';

			EXECUTE	sys.sp_executesql @Query;
		END

		ELSE IF @TableName = 'TicketVoiding_Reason'
		BEGIN
			SELECT	@Query = N'';
			SELECT	@Query = @Query + N'\
			INSERT INTO	#DeletedList (id, IsDone)
			SELECT ReasonId,0
			FROM	OPENQUERY(DBARC, ''\

			SELECT	ReasonId
			FROM	bodb_Archive.dbo.TicketVoiding_Reason_bk AS t1 WITH (NOLOCK)	
			;'');';

			EXECUTE	sys.sp_executesql @Query;
		END

		ELSE IF @TableName = 'TicketVoiding_VoidingHistory'
		BEGIN
			SELECT	@Query = N'';
			SELECT	@Query = @Query + N'\
			INSERT INTO	#DeletedList (id, IsDone)
			SELECT VoidingHistoryId,0
			FROM	OPENQUERY(DBARC, ''\

			SELECT	VoidingHistoryId
			FROM	bodb_Archive.dbo.TicketVoiding_VoidingHistory_bk AS t1 WITH (NOLOCK)	
			;'');';

			EXECUTE	sys.sp_executesql @Query;
		END

		ELSE IF @TableName = 'TicketVoiding_Queue'
		BEGIN
			SELECT	@Query = N'';
			SELECT	@Query = @Query + N'\
			INSERT INTO	#DeletedList (id, IsDone)
			SELECT QueueId,0
			FROM	OPENQUERY(DBARC, ''\

			SELECT	QueueId
			FROM	bodb_Archive.dbo.TicketVoiding_Queue_bk AS t1 WITH (NOLOCK)	
			;'');';

			EXECUTE	sys.sp_executesql @Query;
		END

		ELSE IF @TableName = 'TicketVoiding_OperatorInfo'
		BEGIN
			SELECT	@Query = N'';
			SELECT	@Query = @Query + N'\
			INSERT INTO	#DeletedList (id, IsDone)
			SELECT Id,0
			FROM	OPENQUERY(DBARC, ''\

			SELECT	Id
			FROM	bodb_Archive.dbo.TicketVoiding_OperatorInfo_bk AS t1 WITH (NOLOCK)	
			;'');';

			EXECUTE	sys.sp_executesql @Query;
		END

		ELSE IF @TableName = 'TicketVoiding_Request'
		BEGIN
			SELECT	@Query = N'';
			SELECT	@Query = @Query + N'\
			INSERT INTO	#DeletedList (id, IsDone)
			SELECT RequestId,0
			FROM	OPENQUERY(DBARC, ''\

			SELECT	RequestId
			FROM	bodb_Archive.dbo.TicketVoiding_Request_bk AS t1 WITH (NOLOCK)	
			;'');';

			EXECUTE	sys.sp_executesql @Query;
		END

		ELSE IF @TableName = 'TicketVoiding_AutoUnmarkSetting'
		BEGIN
			SELECT	@Query = N'';
			SELECT	@Query = @Query + N'\
			INSERT INTO	#DeletedList (id, IsDone)
			SELECT ID,0
			FROM	OPENQUERY(DBARC, ''\

			SELECT	ID
			FROM	bodb_Archive.dbo.TicketVoiding_AutoUnmarkSetting_bk AS t1 WITH (NOLOCK)	
			;'');';

			EXECUTE	sys.sp_executesql @Query;
		END

		ELSE IF @TableName = 'TicketVoiding_AutoVoidRequest_Queue'
		BEGIN
			SELECT	@Query = N'';
			SELECT	@Query = @Query + N'\
			INSERT INTO	#DeletedList (id, IsDone)
			SELECT QueueId,0
			FROM	OPENQUERY(DBARC, ''\

			SELECT	QueueId
			FROM	bodb_Archive.dbo.TicketVoiding_AutoVoidRequest_Queue_bk AS t1 WITH (NOLOCK)	
			;'');';

			EXECUTE	sys.sp_executesql @Query;
		END

		ELSE IF @TableName = 'zzzbettrans'
		BEGIN
			SELECT	@Query = N'';
			SELECT	@Query = @Query + N'\
			INSERT INTO	#DeletedList (id, IsDone)
			SELECT keyid,0
			FROM	OPENQUERY(DBARC, ''\
			DECLARE	@MaxKeyId	BIGINT = ''''' + CONVERT(NVARCHAR(MAX), @MaxKeyId) + ''''';

			SELECT	keyid
			FROM	bodb_Archive.dbo.zzzbettrans_bk AS t1 WITH (NOLOCK)
			WHERE t1.KeyId > @MaxKeyId
			;'');';

			EXECUTE	sys.sp_executesql @Query;
		END

		ELSE IF @TableName = 'zzzbettransm'
		BEGIN
			SELECT	@Query = N'';
			SELECT	@Query = @Query + N'\
			INSERT INTO	#DeletedList (id, IsDone)
			SELECT keyid,0
			FROM	OPENQUERY(DBARC, ''\

			SELECT	keyid
			FROM	bodb_Archive.dbo.zzzbettransm_bk AS t1 WITH (NOLOCK)	
			;'');';

			EXECUTE	sys.sp_executesql @Query;
		END

		ELSE IF @TableName = 'TicketVoiding_RequestDetail'
		BEGIN
			SELECT	@Query = N'';
			SELECT	@Query = @Query + N'\
			INSERT INTO	#DeletedList (id, IsDone)
			SELECT Id,0
			FROM	OPENQUERY(DBARC, ''\

			SELECT	Id
			FROM	bodb_Archive.dbo.TicketVoiding_RequestDetail_bk AS t1 WITH (NOLOCK)	
			;'');';

			EXECUTE	sys.sp_executesql @Query;
		END

		ELSE IF @TableName = 'TicketVoiding_RequestDetailTicket_Single'
		BEGIN
			SELECT	@Query = N'';
			SELECT	@Query = @Query + N'\
			INSERT INTO	#DeletedList (id, IsDone)
			SELECT Id,0
			FROM	OPENQUERY(DBARC, ''\

			SELECT	Id
			FROM	bodb_Archive.dbo.TicketVoiding_RequestDetailTicket_Single_bk AS t1 WITH (NOLOCK)	
			;'');';

			EXECUTE	sys.sp_executesql @Query;
		END

		ELSE IF @TableName = 'TicketVoiding_RequestDetailTicket_SubParlay'
		BEGIN
			SELECT	@Query = N'';
			SELECT	@Query = @Query + N'\
			INSERT INTO	#DeletedList (id, IsDone)
			SELECT Id,0
			FROM	OPENQUERY(DBARC, ''\

			SELECT	Id
			FROM	bodb_Archive.dbo.TicketVoiding_RequestDetailTicket_SubParlay_bk AS t1 WITH (NOLOCK)	
			;'');';

			EXECUTE	sys.sp_executesql @Query;
		END

		BEGIN
			DECLARE @ids VARCHAR(8000), @rowcount INT = 0, @topk INT = 500, @ids_VARIANT sql_variant
			CREATE TABLE #output (id INT)	

			SET @rowcount = 1
			WHILE @rowcount <> 0
			BEGIN
				TRUNCATE TABLE #output
				SET @ids = NULL

				DELETE TOP(@topk) t
				OUTPUT deleted.id INTO #output(id)
				FROM #DeletedList t
				SET @rowcount = @@ROWCOUNT

				SELECT @ids = COALESCE(@ids + ',' + CAST(id AS VARCHAR(50)), CAST(id AS VARCHAR(50)))
				FROM #output  
			
				set @ids_VARIANT = cast(@ids as SQL_VARIANT)
			
				EXEC [dbo].[ExecRep_02] @Command = 'ALL_DB', @DeletedTarget = @TableName, @tmp1 = @ids_VARIANT, @winlostdate = ''
			END
			DROP TABLE #output
		END

		WAITFOR DELAY '00:00:00.100';

		SET	@StartTable = @StartTable + 1;
	END

END
GO

