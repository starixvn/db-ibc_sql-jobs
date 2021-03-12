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
		SELECT id
		FROM	OPENQUERY(DBARC, ''\
		DECLARE	@StartDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @StartDate, 121) + ''''';
		DECLARE	@EndDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @EndDate, 121) + ''''';

		SELECT	id
		FROM	bodb02.dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK)
		WHERE t1.transdate >= @StartDate AND t1.transdate < @EndDate
		;'');';

		EXECUTE	sys.sp_executesql @Query;
	END

	BEGIN
		DECLARE @ids VARCHAR(MAX), @rowcount INT = 0, @topk INT = 500
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
			
			EXEC [dbo].[ExecRep_02] @Command = 'ALL_DB', @DeletedTarget = 'TicketVoiding_VoidedTransaction', @transIds = @ids, @winlostdate = ''
		END
		DROP TABLE #output
	END

END
GO

