/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_N88_SystemSettings_Upd]
	@SName		VARCHAR(50)
	,@SValue	VARCHAR(200)
AS

/*
	Created: 20220222@Percy
	DB: DBN88-bodb_N88
	Task: Job - Archive data for TpBetRecord

	Revisions:
		- 20220222@Percy: Initialize SP [RedmineID: #167823]
*/

BEGIN
	SET NOCOUNT ON

	UPDATE dbo.SystemSettings WITH (ROWLOCK)
	SET SValue = @SValue
	WHERE SName = @SName
END
GO