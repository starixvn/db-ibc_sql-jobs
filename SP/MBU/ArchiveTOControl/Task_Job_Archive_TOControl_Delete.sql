/*<info serverAlias="DBTXN-bodb02" executers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Task_Job_Archive_TOControl_Delete
(
	 @IsDebug BIT = 0
)
 
/*
	Created: 20191128@Helen
	Task: TO Control Archive - https://nexdev.net/issues/124447
	DB: DBTXN/bodb02
	
	Revisions:
		- 20191126@Helen: Archive TO Control - delete [Redimine:98467]
		- 20220804@Patrick: Support scale-out for deposit site Redmine: [#175602]
*/
AS
BEGIN

	SET NOCOUNT ON
	
	DECLARE  @ExecuteSQL NVARCHAR(MAX) = ''
			, @query NVARCHAR(MAX) = ''
			, @start INT = 1
			, @end INT
			, @winlostdate DATETIME   
			, @winlostdate_tmp VARCHAR(12)
			, @__aliasServer VARCHAR(128) = ''

	EXEC dbo.ExecRep_10 @FunctionName = 'ScaleOut-Central', @AliasServer = @__aliasServer OUTPUT
	IF @__aliasServer <> 'DBCTG' --only run that command at central server
	BEGIN
		RETURN
	END

	CREATE TABLE #archiveDate (ID INT IDENTITY (1,1), winlostdate DATETIME)

	INSERT INTO #archiveDate (winlostdate)
	SELECT winlostdate 
	FROM dbo.Task_ArchiveDate WITH (NOLOCK)
	ORDER BY winlostdate
	
	SELECT  @query = N''		
	SELECT	@query = @query + N'EXEC Task_Archive_TOControl_Delete @winlostdate'
	SELECT	@ExecuteSQL = N'EXECUTE DBCUST.CUSTDB.dbo.sp_executesql @query, N''@winlostdate datetime'',@winlostdate'

	SET @end = (SELECT MAX(ID) FROM #archiveDate)

	-- Deployer Info
	DECLARE @msg nvarchar(200) = 'Currently at batch %d, wld: %s.'
	WHILE @start <= @end
	BEGIN
		
		SET @winlostdate = (SELECT winlostdate FROM #archiveDate WHERE ID = @start )
		SET @winlostdate_tmp  = CONVERT(VARCHAR(10),@winlostdate,101)
		
		IF @IsDebug = 1
			RAISERROR (@msg, 0, 1,@start, @winlostdate_tmp) WITH NOWAIT
		-- Result
		EXECUTE	sys.sp_executesql @ExecuteSQL, N'@query NVARCHAR(MAX), @winlostdate datetime', @query, @winlostdate
			
		SET @start = @start + 1
		
		WAITFOR DELAY '00:00:00.280'
					
	END	
	DROP TABLE #archiveDate
	
END



