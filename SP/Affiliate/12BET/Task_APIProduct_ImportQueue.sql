/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_APIProduct_ImportQueue]
	@ProductId	INT,
	@XmlData	NVARCHAR(MAX),
	@JobType	TINYINT = 0,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Import Data Job - Import xml data

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102322]

	Param's Explanation:
		- JobType:
			0: Data for import
			1: Data for check sum
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Xml XML
	
	BEGIN TRY
		SELECT @Xml = CONVERT(XML, @XmlData)

		INSERT INTO dbo.APIProduct_ImportQueue (ProductId, XmlData, JobType, CheckInTime)
		VALUES (@ProductId, @Xml, @JobType, GETDATE())

		SELECT @ErrCode = 0, @ErrMsg = ''
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 101, @ErrMsg = ERROR_MESSAGE()

		RETURN
	END CATCH
END
GO