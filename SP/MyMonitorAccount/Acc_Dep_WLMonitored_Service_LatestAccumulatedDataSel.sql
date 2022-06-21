/*<info serverAlias="DBAGE-bodb02,DBEXT-bodb02" executers="bodbDownlineNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_Dep_WLMonitored_Service_LatestAccumulatedDataSel]
	@LastCheckTime DATETIME
	,@BatchNo INT
AS
/*	Creator: 20220617@Kathy
	Task: Accumulate data
	DB: DBAGE/BODB02
	
	Revisions:	
		- 20220617@Kathy: get latest data [Redmine:#170467]

	Param's Explanation:
		 
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @MaxUpdatedTimeOfBatch DATETIME

	;WITH cteMaxUpdatedTimeOfBatch
	AS (
		SELECT	TOP (@BatchNo) UpdatedTime AS MaxUpdatedTimeOfBatch
		FROM	dbo.Dep_WLMonitored_AccumulatedWL WITH(NOLOCK)
		WHERE	UpdatedTime > @LastCheckTime
		ORDER BY UpdatedTime
	)
	SELECT	@MaxUpdatedTimeOfBatch = MAX(MaxUpdatedTimeOfBatch)
	FROM	cteMaxUpdatedTimeOfBatch

	;WITH cteLatestAccumWL
	AS(
		SELECT	CustId, AccumWL, SettlementDate, UpdatedTime, ROW_NUMBER() OVER(PARTITION BY CustId ORDER BY SettlementDate DESC) RN
		FROM	dbo.Dep_WLMonitored_AccumulatedWL WITH(NOLOCK)
		WHERE	UpdatedTime > @LastCheckTime 
				AND UpdatedTime <= @MaxUpdatedTimeOfBatch
	)
	SELECT	CustId, AccumWL, SettlementDate, UpdatedTime
	FROM	cteLatestAccumWL
	WHERE	RN = 1
	
END
GO