CREATE PROCEDURE [dbo].[Task_MBU_TO_CheckRowCount_Sel]
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

	DECLARE @query NVARCHAR(4000), @ExecuteSQL NVARCHAR(4000)
	SELECT  @query = N''		
	SELECT	@query = @query + N'SELECT matchid FROM dbo.match14 WTIH(NOLOCK) WHERE eventdate = @DateCheck'
	SELECT	@ExecuteSQL = N'EXECUTE DBAGE.bodb02.dbo.sp_executesql @query, N''@DateCheck SMALLDATETIME'', @DateCheck'

	DECLARE @__matchIds TABLE(matchid INT)

	INSERT INTO @__matchIds(matchid)
	EXECUTE	sys.sp_executesql @ExecuteSQL, N'@query NVARCHAR(MAX), @DateCheck SMALLDATETIME', @query, @DateCheck


	--//TOControl_Setting
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'TOControl_Setting' 
	FROM dbo.TOControl_Setting s WITH(NOLOCK)
	WHERE matchid IN (SELECT t.matchid FROM @__matchIds t)

	--//
	SELECT @OutputData = (
		SELECT rowcnt AS r, tableName AS t
		FROM @__tempCount
		FOR XML RAW ('r')
	)

END
GO
/*<info serverAlias="DBCUST-CustDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/