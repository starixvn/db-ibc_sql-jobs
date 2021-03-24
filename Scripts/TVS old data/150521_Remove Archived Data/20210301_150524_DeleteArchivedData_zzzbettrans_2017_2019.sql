/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
/*
	Created:	20210301@Max
	Task:		[TVS] Remove archived data [Redmine: #150524]
	Database:	DBTXN-bodb02
*/
BEGIN
	DECLARE @StartDate	DATETIME	= '2017-01-01'
		, @EndDate		DATETIME	= '2019-01-01'
	
	CREATE TABLE #DeletedList (id INT PRIMARY KEY CLUSTERED)	
	DECLARE	@Query		NVARCHAR(MAX)

	TRUNCATE TABLE #DeletedList 

	BEGIN
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
		INSERT INTO	#DeletedList (id)
		SELECT keyid
		FROM	OPENQUERY(DBARC, ''\
		DECLARE	@StartDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @StartDate, 121) + ''''';
		DECLARE	@EndDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @EndDate, 121) + ''''';

		SELECT	t1.keyid
		FROM	bodb02.dbo.zzzbettrans AS t1 WITH (NOLOCK)
			CROSS APPLY (
				SELECT TOP 1 bettype 
				FROM bodb02.dbo.SportBettypeMatrix t3 WITH (NOLOCK) 
				WHERE t1.bettype=t3.BetType 
					AND t3.ProductID IN (1,3,5,25,27,37)
			)bt
		WHERE t1.transdate >= @StartDate AND t1.transdate < @EndDate
			AND t1.VoidingHistoryId IS NULL	
		;'');';

		EXECUTE	sys.sp_executesql @Query;

		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
		INSERT INTO	#DeletedList (id)
		SELECT keyid
		FROM	OPENQUERY(DBARC, ''\
		DECLARE	@StartDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @StartDate, 121) + ''''';
		DECLARE	@EndDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @EndDate, 121) + ''''';

		SELECT	t1.keyid
		FROM	bodb02.dbo.zzzbettrans AS t1 WITH (NOLOCK)
		WHERE t1.transdate >= @StartDate AND t1.transdate < @EndDate
			AND t1.VoidingHistoryId IS NOT NULL
		;'');';

		EXECUTE	sys.sp_executesql @Query;
	END

	BEGIN
		DECLARE @ids VARCHAR(MAX), @rowcount INT = 0, @topk INT = 1000
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
			
			EXEC [dbo].[ExecRep_02] @Command = 'ALL_DB', @DeletedTarget = 'zzzbettrans', @transIds = @ids, @winlostdate = ''

			WAITFOR DELAY '00:00:00.180';
		END
		DROP TABLE #output
	END

END
GO

