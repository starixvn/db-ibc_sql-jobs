/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
/*
	Created:	20210301@Max
	Task:		[TVS] Remove archived data [Redmine: #150524]
	Database:	DBTXN-bodb02
*/
BEGIN
	TRUNCATE TABLE dbo.TicketVoiding_VoidedTransaction_Archived	

	DECLARE	@Query	NVARCHAR(MAX)
		,@MaxId		BIGINT = 2138537 --MAX ID of TicketVoiding_VoidedTransaction in 2020 - PRO

	----FROM 2021-----
	BEGIN
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
		INSERT INTO	dbo.TicketVoiding_VoidedTransaction_Archived (id)
		SELECT id
		FROM	OPENQUERY(DBARC, ''\
		DECLARE	@MaxId	BIGINT = ''''' + CONVERT(NVARCHAR(MAX), @MaxId) + ''''';

		SELECT	id
		FROM	bodb_Archive.dbo.TicketVoiding_VoidedTransaction_bk AS t1 WITH (NOLOCK)
		WHERE t1.Id > @MaxId
		;'');';

		EXECUTE	sys.sp_executesql @Query;
	END

END
GO

