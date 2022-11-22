/*<info serverAlias="DBN88-bodb_N88" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_API_Queue_ImportTest]
	@DataSource	VARCHAR(200)
	,@XmlData	VARCHAR(MAX)
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	VARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20221011@Malcolm
	DB: DBN88-bodb_N88
	Task: Import data from API into API_Queue_test

	Revisions:
		- 20221011@Malcolm: Initalize SP [RedmineID: #177893]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Xml XML
	SELECT  @ErrCode = 0, @ErrMsg = ''

	BEGIN TRY
		SELECT @XmlData = REPLACE(REPLACE (@XmlData, CHAR(10), ''), CHAR(13), '')
		SELECT @Xml = CONVERT(XML, @XmlData)

		INSERT INTO dbo.API_QueueTest (CheckInTime, XmlData, DataSource)
		VALUES (GETDATE(), @Xml, @DataSource)
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
	END CATCH
END
GO