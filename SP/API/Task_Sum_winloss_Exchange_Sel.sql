/*<info serverAlias="DBLIC-bodb_3rdProduct" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
USE [bodb_3rdProduct]
GO

ALTER PROCEDURE [dbo].[Task_Sum_winloss_Exchange_Sel]
	@FromDate	SMALLDATETIME
	,@ToDate	SMALLDATETIME
AS

/*
	Created: 20190322@Percy
	DB: DBLIC.bodb_3rdProduct
	Task: Exchange - Get data to for comparsion

	Revisions:
		- 20190322@Percy: Initialize SP [RedmineID: #110692]
*/

BEGIN
	SET NOCOUNT ON

	SELECT
		userId, eventID, marketID
		,SUM(stakeTotal)		AS stakeTotal
		,SUM(profitLoss)		AS profitLoss
		,SUM(marketTotal)		AS marketTotal
		,SUM(commission)		AS commission
		,SUM(agentCommission)	AS agentCommission
	FROM dbo.Sum_winloss_Exchange WITH (NOLOCK)
	WHERE settledDate >= @FromDate AND settledDate < DATEADD(DAY, 1, @ToDate)
	GROUP BY
		userId, eventID, marketID
	HAVING
		SUM(stakeTotal) <> 0
		OR SUM(profitLoss) <> 0
		OR SUM(marketTotal) <> 0
		OR SUM(commission) <> 0
		OR SUM(agentCommission) <> 0
END
GO