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
		,@MaxId		BIGINT = 2138537 --MAX ID of TicketVoiding_VoidedTransaction in 2020 - PRO
		,@MaxKeyId	BIGINT = 1008734020 --MAX KeyId of zzzbettrans in 2020 - PRO

	
	TRUNCATE TABLE #DeletedList
	
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

