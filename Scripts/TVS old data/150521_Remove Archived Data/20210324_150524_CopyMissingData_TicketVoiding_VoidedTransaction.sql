/*<info serverAlias="DBARC-bodb_Archive" executers="" viewers="" isFunction="0" isNested="1"></info>*/
/*
	Created:	20210324@Max
	Task:		[TVS] Remove archived data - Copy missing data [Redmine: #150524]
	Database:	DBARC-bodb_Archive
*/
BEGIN

	DECLARE @TransIds	VARCHAR(MAX) = '105762738820,106022039973,110614494150,107825434294,107825434897,107825435296,107825439494,107825488740,107864892705'
		,@Query		NVARCHAR(MAX)

	BEGIN
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
		INSERT INTO	dbo.TicketVoiding_VoidedTransaction_bk
			(	TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID)
		SELECT	TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID

		FROM	OPENQUERY(DBTXN, ''\
		DECLARE	@TransIds	NVARCHAR(MAX) = ''''' + CONVERT(VARCHAR(MAX), @TransIds) + ''''';

		SELECT v.TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID
		FROM bodb02.dbo.TicketVoiding_VoidedTransaction v with (nolock)
			CROSS APPLY (
					SELECT	val AS TransId
					FROM	bodb02.dbo.f_SplitString(@TransIds, '''','''')
					WHERE val = v.TransId
			) r
		;'');';

		EXECUTE	sys.sp_executesql @Query;
	END

END
GO

