/*<info serverAlias="DBARC-bodb_Archive" executers="" viewers="" isFunction="0" isNested="1"></info>*/
/*
	Created:	20210316@Max
	Task:		[TVS] Remove archived data - Copy missing data [Redmine: #150524]
	Database:	DBARC-bodb_Archive
*/
BEGIN

	DECLARE @StartDate	DATETIME	= '2021-03-05'
		, @EndDate		DATETIME	= '2021-03-12'
	
	CREATE TABLE #MissingList (
		TransId			BIGINT, 
		MessageId		INT, 
		ReasonId		INT, 
		MatchId			INT, 
		CreatedDate		DATETIME, 
		Id				INT PRIMARY KEY CLUSTERED, 
		IssueTypeID		TINYINT, 
		SubIssueTypeID	TINYINT, 
		CustID			INT
	)	
	DECLARE	@Query		NVARCHAR(MAX)

	TRUNCATE TABLE #MissingList 

	BEGIN
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
		INSERT INTO	#MissingList (	TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID)
		SELECT TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID
		FROM	OPENQUERY(DBTXN, ''\
		DECLARE	@StartDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @StartDate, 121) + ''''';
		DECLARE	@EndDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @EndDate, 121) + ''''';

		SELECT TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID
		FROM bodb02.dbo.TicketVoiding_VoidedTransaction v with (nolock)
		where v.CreatedDate >= @StartDate and v.CreatedDate < @EndDate
			and v.MatchId != 0
		;'');';

		EXECUTE	sys.sp_executesql @Query;
	END

	INSERT INTO	dbo.TicketVoiding_VoidedTransaction_bk (TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID)
	SELECT TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID
	FROM #MissingList m
	WHERE NOT EXISTS (SELECT 1 FROM dbo.TicketVoiding_VoidedTransaction_bk v WITH (NOLOCK) WHERE v.Id = m.Id)

END
GO

