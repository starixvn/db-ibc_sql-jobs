/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
/*
	Created:	20210301@Max
	Task:		[TVS] Remove archived data [Redmine: #150524]
	Database:	DBTXN-bodb02
*/
BEGIN
	TRUNCATE TABLE dbo.TicketVoiding_VoidedTransaction_Archived	

	DECLARE	@Query	NVARCHAR(MAX)
	DECLARE @StartDate	DATETIME	= '2019-01-01'
		, @EndDate		DATETIME	= '2021-01-01'

	BEGIN
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
		INSERT INTO	dbo.TicketVoiding_VoidedTransaction_Archived (id)
		SELECT id
		FROM	OPENQUERY(DBARC, ''\
		DECLARE	@StartDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @StartDate, 121) + ''''';
		DECLARE	@EndDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @EndDate, 121) + ''''';

		SELECT	id
		FROM	bodb_Archive.dbo.TicketVoiding_VoidedTransaction_bk AS t1 WITH (NOLOCK)
		WHERE t1.CreatedDate >= @StartDate AND t1.CreatedDate < @EndDate
		;'');';

		EXECUTE	sys.sp_executesql @Query;
	END

END
GO

