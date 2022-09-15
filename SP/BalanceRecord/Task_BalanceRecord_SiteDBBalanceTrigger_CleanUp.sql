/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/  
ALTER PROCEDURE [dbo].[Task_BalanceRecord_SiteDBBalanceTrigger_CleanUp] 

AS
/*
    Created: 20220913@Helen
    Task: 
    DB: DBBAH/bodb02
    Revisions:
		- 20220912@Helen: scaleout project [176932]
		
*/
BEGIN
	
	SET NOCOUNT ON

	DECLARE @MaxID BIGINT = 0
	SET @MaxID = (SELECT CONVERT(BIGINT,VValue) FROM bodb02.dbo.SystemSettings WITH (NOLOCK) WHERE VName = 'BalanceRecord_SiteDB_Sync')

	--Keep 10000 very first rows in the table
	IF @MaxID - 10000 <= 0
		RETURN
	
	SET @MaxID = @MaxID - 10000

	DECLARE  @ExecuteSQL NVARCHAR(MAX) = ''
			, @query NVARCHAR(MAX) = ''

	SELECT  @query = N''		
	SELECT	@query = @query + N'EXEC SiteDB_Task_BalanceRecord_SiteDBBalanceTrigger_CleanUp @MaxID'
	
	SELECT	@ExecuteSQL = N'EXECUTE SITEDB01.bodb02.dbo.sp_executesql @query, N''@MaxID BIGINT'',@MaxID'
	
	PRINT @ExecuteSQL
	EXECUTE	sys.sp_executesql @ExecuteSQL, N'@query NVARCHAR(MAX), @MaxID BIGINT', @query, @MaxID

END



