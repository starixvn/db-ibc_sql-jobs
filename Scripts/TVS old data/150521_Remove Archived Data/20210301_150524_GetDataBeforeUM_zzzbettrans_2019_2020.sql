/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
/*
	Created:	20210301@Max
	Task:		[TVS] Remove archived data [Redmine: #150524]
	Database:	DBTXN-bodb02
*/
BEGIN
	TRUNCATE TABLE dbo.zzzbettrans_Archived	

	DECLARE	@Query	NVARCHAR(MAX)
	DECLARE @StartDate	DATETIME	= '2019-01-01'
		, @EndDate		DATETIME	= '2021-01-01'

	BEGIN
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
		INSERT INTO	dbo.zzzbettrans_Archived (id)
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
		INSERT INTO	dbo.zzzbettrans_Archived (id)
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

END
GO

