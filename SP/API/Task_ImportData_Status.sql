/*<info serverAlias="DBLIC-bodb_3rdProduct" executers="" isFunction="0" isNested="0"></info>*/
USE [bodb_3rdProduct]
GO

ALTER PROCEDURE [dbo].[Task_ImportData_Status]
AS

/*
	Created: 20190401@Percy
	Task: Check 3rd data has imported
	DB: DBLIC.bodb_3rdProduct

	Revisions:
		- 20190401@Percy: Initialize SP [RedmineID: #110692]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @IsImported BIT = 0

	SELECT  @IsImported = CONVERT(BIT, SValue) FROM dbo.LicSystemSetting WITH (NOLOCK)
	WHERE ProductId = 31 AND SName = 'IsImported'

	IF ISNULL(@IsImported, 0) = 0
	BEGIN
		RAISERROR('* LOOP * Data is being imported. Automatically retry after 15mins.', 16, 1)
		RETURN
	END
END
GO