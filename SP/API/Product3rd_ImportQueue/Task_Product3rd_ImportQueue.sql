/*<info serverAlias="DBPTCS-bodb_PlaytechCS" executers="bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_PlaytechCS]
GO

ALTER PROCEDURE [dbo].[Task_Product3rd_ImportQueue]
	@XmlData	NVARCHAR(MAX),
	@StartDate	DATETIME,
	@EndDate	DATETIME,
	@JobType	TINYINT,
	@ProductId	INT,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(500) = '' OUTPUT
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

	DECLARE @Xml XML

	BEGIN TRY
		SELECT @XmlData = REPLACE(REPLACE (@XmlData, CHAR(10), ''), CHAR(13), '')
		SELECT @Xml = CONVERT (XML, @XmlData)

		INSERT INTO dbo.Product3rd_ImportQueue (CheckInTime, ProductID, XmlData, JobType, StartDate, EndDate)
		SELECT CURRENT_TIMESTAMP, @ProductId, @XmlData, @JobType, @StartDate, @EndDate
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
	END CATCH
END
GO