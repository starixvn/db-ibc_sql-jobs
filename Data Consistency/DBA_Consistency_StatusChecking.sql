/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_StatusChecking]
	@ProductId		INT	
	,@Bettype		SMALLINT		= NULL	
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT 
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20180808@Kathy
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20180808@Kathy: Check status rules for poker game [Redmine:#98064]
		- 20181219@Vicky: Happy 5- Check Data Consistency [Redmine:#106481]
		- 20190715@Kathy: check status ticket for BetBuilder [Redmine:#116529]
	
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @transId VARCHAR(MAX)
			,@yesterday DATETIME

	DECLARE @tmpMatchIds TABLE (MatchId INT)

	SET @transId = ''
	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))

	IF @ProductId = 1
	BEGIN
		INSERT INTO @tmpMatchIds (MatchId)
		SELECT	m.matchid
		FROM	bodb02.dbo.match m WITH(NOLOCK)
		WHERE	m.sporttype = 1
				AND m.eventdate = @yesterday

		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
		WHERE	b.bettype = ISNULL(@Bettype, b.bettype)
				AND b.winlostdate = @yesterday			
				AND b.statusID = 0
				AND b.matchid IN (SELECT MatchId FROM @tmpMatchIds)
	END
	ELSE
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
		WHERE	b.bettype < 20000
				AND b.winlostdate = @yesterday
				AND b.statusID = 0
				AND b.matchid = @ProductId
	END

	IF @transId <> ''
	BEGIN
		SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'All yesterday tickets must be settled on product ' + CAST(@ProductId AS VARCHAR)
				,@SampleData = 'bettrans.TransId = ' + @transId
	END
END
GO