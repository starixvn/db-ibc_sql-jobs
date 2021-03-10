/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
/*
	Created:	20210301@Max
	Task:		[TVS] Remove archived data [Redmine: #150524]
	Database:	DBTXN-bodb02
*/
BEGIN
	
	--('TicketVoiding_VoidedTransaction')
	--('zzzbettrans')
	DECLARE	@TableName	NVARCHAR(128)
	SELECT @TableName = 'TicketVoiding_VoidedTransaction'

	CREATE TABLE #DeletedList (id INT PRIMARY KEY CLUSTERED,IsDone BIT)	
	DECLARE	@Query	NVARCHAR(MAX)
	DECLARE @StartDate	DATETIME	= '2017-01-01'

	TRUNCATE TABLE #DeletedList 

		
	IF @TableName = 'TicketVoiding_VoidedTransaction'
	BEGIN
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
		INSERT INTO	#DeletedList (id, IsDone)
		SELECT id,0
		FROM	OPENQUERY(DBARC, ''\
		DECLARE	@StartDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @StartDate, 121) + ''''';

		SELECT	id
		FROM	bodb02.dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK)
		WHERE t1.CreatedDate < @StartDate
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
		DECLARE	@StartDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @StartDate, 121) + ''''';

		SELECT	t1.keyid
		FROM	bodb02.dbo.zzzbettrans AS t1 WITH (NOLOCK)
		WHERE t1.transdate < @StartDate	
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
			
			SELECT @ids_VARIANT = CAST(@ids as SQL_VARIANT)
			
			EXEC [dbo].[ExecRep_02] @Command = 'ALL_DB', @DeletedTarget = @TableName, @tmp1 = @ids_VARIANT, @winlostdate = ''
		END
		DROP TABLE #output
	END

END
GO

