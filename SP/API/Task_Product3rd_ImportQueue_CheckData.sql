/*<info serverAlias="DBPTCS-bodb_PlaytechCS,DBBAL-bodb_PlaytechCS" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
USE [bodb_PlaytechCS]
GO

ALTER PROCEDURE [dbo].[Task_Product3rd_ImportQueue_CheckData]
	@XmlData		NVARCHAR(MAX),
	@ProductId		INT,
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(500) = '' OUTPUT
AS

/*
	Created: 20190401@Percy
	DB: DBPTCS.bodb_PlaytechCS
	Task: Import xml data for checking data monthly

	Revisions:
		- 20190401@Percy: Initialize SP [RedmineID: #110692]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Xml XML

	BEGIN TRY
		SELECT @XmlData = REPLACE(REPLACE (@XmlData, CHAR(10), ''), CHAR(13), '')
		SELECT @Xml = CONVERT (XML, @XmlData)

		INSERT INTO dbo.Product3rd_ImportQueue_CheckData (CheckInTime, ProductID, XmlData)
		SELECT CURRENT_TIMESTAMP, @ProductId, @Xml
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
	END CATCH
END
GO