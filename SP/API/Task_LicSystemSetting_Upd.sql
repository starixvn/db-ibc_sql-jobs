/*<info serverAlias="DBLIC-bodb_3rdProduct,DBBAL-bodb_3rdProduct" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
USE [bodb_3rdProduct]
GO

ALTER PROCEDURE [dbo].[Task_LicSystemSetting_Upd]
	@IsImported			BIT
	,@ProductId			SMALLINT
	,@FromImportedDate	SMALLDATETIME = NULL
	,@ToImportedDate	SMALLDATETIME = NULL
	,@ErrCode			INT = 0	OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20190401@Percy
	DB: DBLIC.bodb_3rdProduct, DBBAL-bodb_3rdProduct
	Task: Update LicSystemSetting when import data done

	Revisions:
		- 20190401@Percy: Initialize SP [RedmineID: #110692]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
*/

BEGIN
	SET NOCOUNT ON
	
	SELECT @ErrCode = 0, @ErrMsg = ''

	BEGIN TRY
		UPDATE dbo.LicSystemSetting WITH (ROWLOCK, UPDLOCK)
		SET SValue = CASE SName
						WHEN 'IsImported' THEN CONVERT(VARCHAR(2), @IsImported)
						WHEN 'FromImportedDate' THEN CASE WHEN @FromImportedDate IS NULL THEN SValue ELSE CONVERT(VARCHAR(10), @FromImportedDate, 120) END
						WHEN 'ToImportedDate' THEN CASE WHEN @ToImportedDate IS NULL THEN SValue ELSE CONVERT(VARCHAR(10), @ToImportedDate, 120) END
						ELSE SValue END
		WHERE ProductId = @ProductId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 101, @ErrMsg = ERROR_MESSAGE()
	END CATCH
END
GO