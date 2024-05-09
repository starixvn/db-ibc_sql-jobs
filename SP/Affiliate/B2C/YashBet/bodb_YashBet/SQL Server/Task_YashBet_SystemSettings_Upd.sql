/*<info serverAlias="DBYASHBET-bodb_YashBet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_YashBet_SystemSettings_Upd]
	@SName		VARCHAR(50)
	,@SValue	VARCHAR(200)
AS

/*
	Created: 20240115@Sally
	DB: DBYASHBET-bodb_YashBet
	Task: Job - Archive data for TpBetRecord

	Revisions:
		- 20240115@Sally: Initialize function [RedmineID: #198909]
*/

BEGIN
	SET NOCOUNT ON

	UPDATE dbo.SystemSettings WITH (ROWLOCK)
	SET SValue = @SValue
	WHERE SName = @SName
END
GO
