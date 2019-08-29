/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_BetBuilderResultChecking]
	@Rule			VARCHAR(50)		= ''
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT 
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20190514@Kathy
	Task: Data consistency
	DB: DBCONSISTENCY/bodb_Consistency

	Revisions: 
		- 20190514@Kathy: Check BetBuilder result [Redmine:#106903]
	
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Results VARCHAR(MAX)
			,@ProductName	VARCHAR(50)	
		
	SET @Results = ''
	SET @ProductName = 'BetBuilder'

	IF @Rule = 'SelectionResult'
	BEGIN
		SELECT TOP 100 @Results = @Results + 'MatchId: ' + CAST(t.MatchId AS VARCHAR) + ', ' + 'SelectionType: ' + CAST(t.SelectionType AS VARCHAR) + '; '
		FROM (
			SELECT	ms.MatchId, ms.SelectionType, ms.Result
			FROM	bodb02.dbo.SMP_MarketSelection ms WITH(NOLOCK)
			WHERE	ms.Result IS NOT NULL
			GROUP BY ms.MatchId, ms.SelectionType, ms.Result
		) t
		GROUP BY t.MatchId, t.SelectionType
		HAVING COUNT(1) > 1
	
		IF @Results <> ''
		BEGIN
			SELECT	@ErrCode = 100
					,@ErrMsg = 'A selection of a market must has the only one result on' + @ProductName
					,@SampleData = @Results
		END
	END

	ELSE IF @Rule = 'MarketResult'
	BEGIN
		SELECT	TOP 100 @Results = @Results + 'MatchId: ' + CAST(m.MatchId AS VARCHAR) + ', ' + 'MarketId: ' + CAST(m.MarketId AS VARCHAR) + '; '
		FROM	bodb02.dbo.SMP_Market m WITH(NOLOCK)
			CROSS APPLY (
				SELECT TOP 1 CASE 
							WHEN ms.Result IS NULL THEN 1
							WHEN ms.Result = 'Refund' THEN 2
							WHEN ms.Result = 'Lose' THEN 3
							WHEN ms.Result = 'Won' THEN 4
							ELSE 1
						END AS ResultPriority
						,ms.Result
				FROM	bodb02.dbo.SMP_MarketSelection ms WITH(NOLOCK)
				WHERE	ms.MatchId = m.MatchId
						AND ms.MarketId = m.MarketId
				ORDER BY ResultPriority
			) ms
		WHERE	m.ResultStatusId  IN (2,5)
				AND m.Result <> ms.Result
	
		IF @Results <> ''
		BEGIN
			SELECT	@ErrCode = 100
					,@ErrMsg = 'The result between a settled market and its selections is not correct on ' + @ProductName
					,@SampleData = @Results
		END
	END
	ELSE IF @Rule = 'Market-Selection-NULL'
	BEGIN
		SELECT	TOP 100 @Results = @Results + 'MatchId: ' + CAST(m.MatchId AS VARCHAR) + ', ' + 'MarketId: ' + CAST(m.MarketId AS VARCHAR) + '; '
		FROM	bodb02.dbo.SMP_Market m WITH(NOLOCK)
			CROSS APPLY (
				SELECT TOP 1 ms.MarketSelectionId
				FROM	bodb02.dbo.SMP_MarketSelection ms WITH(NOLOCK)
				WHERE	ms.MatchId = m.MatchId
						AND ms.MarketId = m.MarketId
						AND ms.Result IS NULL
			) ms
		WHERE	m.ResultStatusId  IN (2,5)
	
		IF @Results <> ''
		BEGIN
			SELECT	@ErrCode = 100
					,@ErrMsg = 'Settled market has its selection value is null on ' + @ProductName
					,@SampleData = @Results
		END
	END
END
GO