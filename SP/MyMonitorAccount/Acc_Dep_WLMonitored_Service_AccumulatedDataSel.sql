/*<info serverAlias="DBAGE-bodb02,DBEXT-bodb02" executers="bodbDownlineNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_Dep_WLMonitored_Service_AccumulatedDataSel]
	@CustIds VARCHAR(MAX)
	,@CurrentDate DATE
AS
/*	Creator: 20220617@Kathy
	Task: Accumulate data
	DB: DBAGE/BODB02
	
	Revisions:	
		- 20220617@Kathy: get data by cust [Redmine:#170467]

	Param's Explanation:
		 
*/
BEGIN
	SET NOCOUNT ON
	
	CREATE TABLE #tmpCustId (CustId INT)

	INSERT INTO #tmpCustId(CustId)
	SELECT	DISTINCT [value]
	FROM	STRING_SPLIT(@CustIds, ',')

	SELECT	a.CustId, a.AccumWL, a.UpdatedTime
	FROM	dbo.Dep_WLMonitored_AccumulatedWL a WITH(NOLOCK)
		INNER JOIN #tmpCustId t
			ON	a.CustId = t.CustId
				AND a.SettlementDate = @CurrentDate
END
GO