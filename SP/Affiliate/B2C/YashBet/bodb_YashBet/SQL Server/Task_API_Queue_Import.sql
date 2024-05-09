/*<info serverAlias="DBYASHBET-bodb_YashBet" executers="wsv_lap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_API_Queue_Import]
	@DataSource	VARCHAR(200)
	,@XmlData	VARCHAR(MAX)
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	VARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBYASHBET-bodb_YashBet
	Task: Import data from API into API_Queue

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Xml XML
	SELECT  @ErrCode = 0, @ErrMsg = ''

	BEGIN TRY
		SELECT @XmlData = REPLACE(REPLACE (@XmlData, CHAR(10), ''), CHAR(13), '')
		SELECT @Xml = CONVERT(XML, @XmlData)

		INSERT INTO dbo.API_Queue (CheckInTime, XmlData, DataSource)
		VALUES (GETDATE(), @Xml, @DataSource)
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
	END CATCH
END
GO