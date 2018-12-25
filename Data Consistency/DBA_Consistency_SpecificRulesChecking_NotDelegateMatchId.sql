/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_SpecificRulesChecking_NotDelegateMatchId]
	@ProductId		INT
	,@Rule			VARCHAR(50)
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20181219@Vicky
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20181219@Vicky: Check Specific rules for Happy5 [Redmine:#104849]
	
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @transId BIGINT
	
	CREATE TABLE #tmpBettrans (
		transId				BIGINT
		,betteam			NVARCHAR(10)
		,playerdiscount		DECIMAL(9,8)
		,discount			DECIMAL(9,8)
		,adiscount			DECIMAL(9,8)
		,sdiscount			DECIMAL(9,8)
		,playercomm			MONEY
		,comm				MONEY
		,acomm				MONEY
		,scomm				MONEY
	)
	DECLARE @tblMatch TABLE (matchid INT)
	
	INSERT INTO @tblMatch(matchid)
	SELECT matchid
	FROM bodb02.dbo.Match m WITH (NOLOCK) 
	WHERE Sporttype = @ProductId

	INSERT INTO #tmpBettrans(transId 
		,playerdiscount,discount,adiscount,sdiscount
		,scomm, acomm, comm, playercomm
		,betteam)
	SELECT	transId
		,playerdiscount,discount,adiscount,sdiscount
		,scomm, acomm, comm, playercomm
		,betteam
	FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
	WHERE	b.bettype < 20000
			AND b.matchid IN (SELECT matchid FROM @tblMatch)

	
	IF @Rule = 'betteam'
	BEGIN
		-- betteam value
		SELECT TOP (1) @transId = transid
		FROM	#tmpBettrans
		WHERE	ISNULL(betteam,'') = ''
			
		IF @transId IS NOT NULL	
		BEGIN
			SELECT	@ErrCode = 100
					,@ErrMsg = 'Wrong betteam value on product ' + CAST(@ProductId AS VARCHAR)
					,@SampleData = 'bettrans.TransId = ' + CAST(@transId AS VARCHAR)
		END
		RETURN
	END
	
	IF @Rule = 'no_discount_comm'
	BEGIN
		
		SELECT TOP (1) @transId = transid
		FROM	#tmpBettrans
		WHERE	ISNULL(playerdiscount, 0) <> 0
				OR ISNULL(discount, 0) <> 0
				OR ISNULL(adiscount, 0) <> 0
				OR ISNULL(sdiscount, 0) <> 0
				OR ISNULL(playercomm, 0) <> 0
				OR ISNULL(comm, 0) <> 0
				OR ISNULL(acomm, 0) <> 0
				OR ISNULL(scomm, 0) <> 0
			
		IF @transId IS NOT NULL
		BEGIN
			SELECT	@ErrCode = 100
					,@ErrMsg = 'Wrong discount or comm value on product ' + CAST(@ProductId AS VARCHAR)
					,@SampleData = 'bettrans.TransId = ' + CAST(@transId AS VARCHAR)
			
		END
		RETURN
	END
END
GO