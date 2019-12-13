CREATE PROCEDURE [dbo].[Task_MBU_TO_BK_CheckRowCount_Sel]
	@DateCheck SMALLDATETIME,
	@OutputData VARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20191209@Patrick
	Task: Check consistency data for archiving process

	Revisions:
		- 20191209@Patrick:	Initial - [RedmineId: #124447]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @__tempCount TABLE (rowcnt INT, tableName VARCHAR(128))
	
	--//TOControl_Setting
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'TOControl_Setting'
	FROM dbo.TOControl_Setting_bk s WITH(NOLOCK)
	WHERE winlostdate = @DateCheck

	--//
	SELECT @OutputData = (
		SELECT rowcnt AS r, tableName AS t
		FROM @__tempCount
		FOR XML RAW ('r')
	)

END
GO
/*<info serverAlias="DBARC-bodb_Archive" executers="" viewers="" isFunction="0" isNested="0"></info>*/