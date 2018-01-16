/*<info serverAlias="DBPTCS-bodb_PlaytechCS" executers="bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_PlaytechCS]
GO

ALTER PROCEDURE [dbo].[Task_Product3rd_ResettledBetHistory_Sel]
	@ProductId INT = 31
AS

/*
	Created by Percy
	Date: 2017-11-17
	DB: DBPTCS.bodb_PlaytechCS
	Task:

	Revisions:
		- 20171117@Percy: Initial SP [RedmineID: #86477]
*/

BEGIN
	SET NOCOUNT ON

	CREATE TABLE #UserIds (UserId VARCHAR(16), SettledDate SMALLDATETIME)

	DECLARE @CheckInTime DATETIME, @Id BIGINT

	SELECT TOP 1 @CheckInTime = CheckInTime, @Id = Id
	FROM Product3rd_ResettledBetHistory WITH (NOLOCK)
	WHERE FinishedTime IS NULL
		AND Status = 'waiting'
		AND ProductId = @ProductId
	ORDER BY Id ASC

	UPDATE dbo.Product3rd_ResettledBetHistory WITH (ROWLOCK, UPDLOCK)
	SET Status = 'running'
		OUTPUT DELETED.UserId, DELETED.SettledDate
		INTO #UserIds (UserId, SettledDate)
	WHERE Id >= @Id AND CheckInTime = @CheckInTime

	SELECT UserId, SettledDate
	FROM #UserIds

	DROP TABLE #UserIds
END
GO