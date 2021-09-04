/*<info serverAlias="DBPTCS-bodb_PlaytechCS,DBBAL-bodb_PlaytechCS" executers="bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_PlaytechCS]
GO

ALTER PROCEDURE [dbo].[Task_Product3rd_ResettledBetHistory_Sel]
	@ProductId	INT = 31
AS

/*
	Created by Percy
	Date: 2017-11-17
	DB: DBPTCS.bodb_PlaytechCS,DBBAL-bodb_PlaytechCS
	Task:

	Revisions:
		- 20171117@Percy: Initialize SP [RedmineID: #86477]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
*/

BEGIN
	SET NOCOUNT ON

	SELECT Id, UserId, SettledDate
		INTO #__TempDate
	FROM Product3rd_ResettledBetHistory WITH (NOLOCK)
	WHERE FinishedTime IS NULL
		AND Status = 'waiting'
		AND ProductId = @ProductId

	SELECT
		STUFF(
			(SELECT ',' + CONVERT(VARCHAR(20), Id) FROM #__TempDate t1 WHERE t1.UserId = t2.UserId AND t1.SettledDate = t2.SettledDate FOR XML PATH (''))
			, 1, 1, '') AS Ids,
		UserId, SettledDate, CONVERT(INT, REPLACE(REPLACE(REPLACE(UserId, 'poc', ''), 'sit', ''), 'uat', '')) AS IBCCustID
	FROM #__TempDate t2
	GROUP BY UserId, SettledDate, CONVERT(INT, REPLACE(REPLACE(REPLACE(UserId, 'poc', ''), 'sit', ''), 'uat', ''))

	DROP TABLE #__TempDate
END
GO