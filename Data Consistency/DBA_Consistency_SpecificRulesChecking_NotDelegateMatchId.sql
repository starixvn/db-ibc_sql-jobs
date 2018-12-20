/*<info serverAlias="DBTP-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
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
	DB: DBTP/bodb_Consistency

	Revisions: 
		- 20181219@Vicky: Check Specific rules for Happy5 [Redmine:#104849]
	
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @transId BIGINT
	
	CREATE TABLE #tmpBettrans (
		transId				BIGINT
		,betid				BIGINT
		,oddsspread			MONEY
		,tpositiontaking	SMALLMONEY
		,spositiontaking	SMALLMONEY
		,mpositiontaking	SMALLMONEY
		,apositiontaking	SMALLMONEY
		,swinlost			MONEY
		,mwinlost			MONEY
		,awinlost			MONEY
		,scomm				MONEY
		,acomm				MONEY
		,comm				MONEY
		,playercomm			MONEY
		,modds				SMALLMONEY
		,bettype			SMALLINT
		,statusId			TINYINT
		,transid2			BIGINT
		,hdp2				SMALLMONEY
		,betteam			NVARCHAR(10)
	)
	DECLARE @tblMatch TABLE (matchid INT NOT NULL UNIQUE)
	
	INSERT INTO @tblMatch(matchid)
	SELECT matchid
	FROM bodb02.dbo.Match m WITH (NOLOCK) 
	WHERE Sporttype = @ProductId

	INSERT INTO #tmpBettrans(transId, betid, oddsspread, tpositiontaking, spositiontaking, mpositiontaking, apositiontaking
		,swinlost, mwinlost, awinlost
		,scomm, acomm, comm, playercomm
		,modds, bettype, statusId, transid2, hdp2,betteam)
	SELECT	transId, betid, oddsspread, tpositiontaking, spositiontaking, mpositiontaking, apositiontaking
		,swinlost, mwinlost, awinlost
		,scomm, acomm, comm, playercomm
		,modds, bettype, statusId, transid2, hdp2,betteam
	FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
		INNER JOIN @tblMatch m ON b.matchid = m.matchid
	WHERE	b.bettype < 20000

	
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
	
	IF @Rule = 'discount_comm'
	BEGIN
		
		SELECT TOP (1) @transId = transid
		FROM	#tmpBettrans
		WHERE	(ISNULL(playerdiscount, 0) = 0 	AND ISNULL(discount, 0) = 0 AND ISNULL(adiscount, 0) = 0 AND ISNULL(sdiscount, 0) = 0)
			 OR (ISNULL(playercomm, 0) = 0 		AND ISNULL(comm, 0) = 0 	AND ISNULL(acomm, 0) = 0 	 AND ISNULL(scomm, 0) = 0)

			
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