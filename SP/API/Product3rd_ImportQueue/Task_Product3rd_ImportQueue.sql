/*<info serverAlias="DBPTCS-bodb_PlaytechCS,DBBAL-bodb_PlaytechCS" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Product3rd_ImportQueue]
	@XmlData		NVARCHAR(MAX),
	@StartDate		DATETIME = NULL,
	@EndDate		DATETIME = NULL,
	@JobType		TINYINT = 0,
	@ProductId		INT = 0,
	@IsForceUpdate	BIT = 0,
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(500) = '' OUTPUT
AS

/*
	Created: 20171117@Percy
	DB: DBPTCS.bodb_PlaytechCS, DBBAL-bodb_PlaytechCS
	Task: Insert XML Data into Product3rd_ImportQueue

	Revisions:
		- 20171117@Percy: Initialize SP [RedmineID: #86477]
		- 20200417@Percy: Add default param's value [RedmineID: #129873]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Xml XML

	BEGIN TRY
		SELECT @XmlData = REPLACE(REPLACE (@XmlData, CHAR(10), ''), CHAR(13), '')
		SELECT @Xml = CONVERT (XML, @XmlData)

		INSERT INTO dbo.Product3rd_ImportQueue (CheckInTime, ProductID, XmlData, JobType, StartDate, EndDate, IsForceUpdate)
		SELECT CURRENT_TIMESTAMP, @ProductId, @Xml, @JobType, @StartDate, @EndDate, @IsForceUpdate
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
	END CATCH
END
GO