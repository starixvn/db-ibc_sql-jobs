/*<info serverAlias="DBRMS-bodb_RMS" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_RMS_SumData_rmSumByEventBettype]
	@winlostdate	SMALLDATETIME
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		VARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20200512@Percy
	DB: DBRMS-bodb_RMS
	Task: RMS - Sum data of rmSumByEventBettype

	Revisions:
		- 20200512@Percy: Initialize SP [RedmineID: #130275]
*/

BEGIN
	SET NOCOUNT ON
END
GO