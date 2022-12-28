/*<info serverAlias="DBAGE-bodb02,DBEXT-bodb02" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_WLMonitored_Service_AccumulatedDataSel]
	@CustIds VARCHAR(MAX) = NULL
	,@Recommends VARCHAR(MAX) = NULL
	,@SMAIds VARCHAR(MAX) = NULL
	,@CurrentDate DATE
AS
/*	Creator: 20220617@Kathy
	Task: Accumulate data
	DB: DBAGE/BODB02
	
	Revisions:	
		- 20220617@Kathy: get data by cust [Redmine:#170467]
		- 20221228@Kathy: Monitor SMA WinLoss [Redmine:#179067]

	Param's Explanation:
		 
*/
BEGIN
	SET NOCOUNT ON
	
	CREATE TABLE #tmpCustId (CustId INT, Recommend INT)
	
	IF ISNULL(@CustIds,'') <> ''
	BEGIN
		;WITH cteCusIds
		AS (
			SELECT	DISTINCT CAST([value] AS INT) AS CustId
			FROM	STRING_SPLIT(@CustIds, ',')
		)
		INSERT INTO #tmpCustId(CustId, Recommend)
		SELECT	ci.custid, ci.recommend
		FROM	cteCusIds c
			INNER JOIN dbo.custInfo ci WITH(NOLOCK)
				ON c.CustId = ci.custid
		WHERE	ci.roleid = 1
	END			

	IF ISNULL(@Recommends,'') <> ''
	BEGIN
		;WITH cteRecommends
			AS (
			SELECT	DISTINCT CAST([value] AS INT) AS recommend
			FROM	STRING_SPLIT(@Recommends, ',')
		)
		INSERT INTO #tmpCustId (CustId, Recommend)
		SELECT	ci.custid, ci.recommend
		FROM dbo.custInfo ci WITH(NOLOCK)
			INNER JOIN cteRecommends r
				ON ci.recommend = r.recommend
		WHERE	ci.roleid = 1
	END

	IF ISNULL(@SMAIds,'') <> ''
	BEGIN
		;WITH cteSMAIds
		AS (
			SELECT	DISTINCT CAST([value] AS INT) AS CustId
			FROM	STRING_SPLIT(@SMAIds, ',')
		)
		INSERT INTO #tmpCustId(CustId, Recommend)
		SELECT	ci.custid, 0
		FROM	cteSMAIds c
			INNER JOIN dbo.custInfo ci WITH(NOLOCK)
				ON c.CustId = ci.custid
		WHERE	ci.roleid > 1
	END		

	;WITH cteDuplicateCustId
	AS (
		SELECT CustId, ROW_NUMBER() OVER (PARTITION BY CustId ORDER BY (SELECT NULL)) rn
		FROM #tmpCustId
	)
	DELETE
	FROM	cteDuplicateCustId
	WHERE	rn > 1

	SELECT	a.CustId, t.Recommend, a.AccumWL, a.UpdatedTime
	FROM	dbo.WLMonitored_AccumulatedWL a WITH(NOLOCK)
		INNER JOIN #tmpCustId t
			ON	a.CustId = t.CustId
				AND a.SettlementDate = @CurrentDate
END
GO