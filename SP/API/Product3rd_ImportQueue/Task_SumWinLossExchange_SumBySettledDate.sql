/*<info serverAlias="DBLIC-bodb_3rdProduct,DBBAL-bodb_3rdProduct" executers="bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_3rdProduct]
GO

ALTER PROCEDURE [dbo].[Task_SumWinLossExchange_SumBySettledDate]
	@FromSettledDate	SMALLDATETIME,
	@ToSettledDate		SMALLDATETIME
AS

/*
	Created by Percy
	Date: 2017-11-17
	DB: DBLIC.bodb_3rdProduct
	Task:

	Revisions:
		- 20171117@Percy: Initialize SP [RedmineID: #86477]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]

*/

BEGIN
	SET NOCOUNT ON

	IF @FromSettledDate IS NULL
	BEGIN
		SELECT @FromSettledDate = DATEADD(DAY, DATEDIFF(DAY, 1, GETDATE()), 0) -- begin of yesterday
		SELECT @ToSettledDate   = CONVERT(VARCHAR(10), @FromSettledDate, 120) + ' 23:59:59.997' -- end of yesterday
	END

	SELECT
		settledDate,
		SUM(ISNULL(stakeTotal, 0)) AS stakeTotal,
		SUM(ISNULL(marketTotal, 0)) AS marketTotal,
		SUM(ISNULL(commission, 0)) AS commission
	FROM dbo.Sum_winloss_Exchange WITH (NOLOCK)
	WHERE settledDate BETWEEN @FromSettledDate AND @ToSettledDate
	GROUP BY settledDate
	ORDER BY settledDate
END
GO