/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_DiscountChecking]
	@ProductId		INT		
	,@tablename		VARCHAR(50)		= NULL	
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
		- 20180808@Kathy: Check discount rules for poker game [Redmine:#98064]
		- 20181219@Vicky: Happy 5- Check Data Consistency [Redmine:#106481]
		- 20190715@Kathy: check discount rule for BetBuilder [Redmine:#116529]
		- 20200624@Max: Update Rule for Saba.Club, Modify Rule check Discount [Redmine: #136362]
		- 20230419@July: Mofidy rule for bettransRNG/bettransLC/translog table [Redmine: #136362]
	
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @transId VARCHAR(MAX)
			,@Today DATETIME 

	DECLARE @tmpMatchIds TABLE (MatchId INT)

	SET @transId = ''
	SET @Today = CAST(GETDATE() AS DATE)

	IF @ProductId IN (211,244,243,236,239,170,176,225) OR @tablename = 'bettransLC'
	BEGIN	
		SET @tablename = 'bettransLC'

		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM	bodb02.dbo.bettransLC b WITH (NOLOCK)
		WHERE	b.ProductID = @ProductId
				AND (b.sdiscount < b.adiscount
					OR b.adiscount < b.discount
					OR b.discount < b.playerdiscount
				)
	
	END
	ELSE IF @ProductId IN (165,200,247,234,237,238,167,172,174,248) OR @tablename = 'bettransRNG'
	BEGIN	
		SET @tablename = 'bettransRNG'

		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM	bodb02.dbo.bettransRNG b WITH (NOLOCK)
		WHERE	b.ProductID = @ProductId
				AND (b.sdiscount < b.adiscount
					OR b.adiscount < b.discount
					OR b.discount < b.playerdiscount
				)
	
	END
	ELSE 
	BEGIN
		SET @tablename = 'bettrans'

		IF @ProductId = 1
		BEGIN
			INSERT INTO @tmpMatchIds (MatchId)
			SELECT	m.matchid
			FROM	bodb02.dbo.match m WITH(NOLOCK)
			WHERE	m.sporttype = 1
					AND m.eventdate = @Today
			
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
			WHERE	b.bettype = ISNULL(@Bettype, b.bettype)
					AND (b.sdiscount < b.adiscount
						OR b.adiscount < b.discount
						OR b.discount < b.playerdiscount
					)
					AND b.matchid IN (SELECT MatchId FROM @tmpMatchIds)
					AND b.winlostdate = @Today
					AND b.srecommend NOT IN (SELECT custid FROM bodb02.dbo.Dep_CustSuper WITH (NOLOCK))
		END
		ELSE --Virtual Games(245),Table Games(222),Sports Lottery(169)
		BEGIN
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
			WHERE	b.bettype < 20000
					AND (b.sdiscount < b.adiscount
						OR b.adiscount < b.discount
						OR b.discount < b.playerdiscount
					)
					AND b.matchid = @ProductId
					AND b.srecommend NOT IN (SELECT custid FROM bodb02.dbo.Dep_CustSuper WITH (NOLOCK))
		END
	END
	
	IF @transId <> ''
	BEGIN
		SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'sdiscount < adiscount or adiscount < discount or discount < playerdiscount on product ' + CAST(@ProductId AS VARCHAR)
				,@SampleData = @tablename + '.TransId in (' + @transId + ')'

	END

END
GO