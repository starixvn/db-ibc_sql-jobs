/*<info serverAlias="DBTXN-bodb02" executers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Task_Job_Archive_TOControl_Delete
(
	@IsDebug BIT = 0
)
 
/*
	Created: 20191128@Helen
	Task: TO Control Archive - https://nexdev.net/issues/124447
	DB: DBTXN/bodb02
*/
AS
BEGIN
	SET NOCOUNT ON
	
	CREATE TABLE #archiveDate (ID INT IDENTITY (1,1), winlostdate DATETIME)

	CREATE TABLE #Match_tbl (winlostate DATETIME, Matchid INT)

	CREATE TABLE #Match_tbl_tmp  (winlostate DATETIME, Matchid INT)

	INSERT INTO #archiveDate (winlostdate)
	SELECT winlostdate 
	FROM dbo.Task_ArchiveDate WITH (NOLOCK)

	INSERT INTO #Match_tbl (winlostate, Matchid)
	SELECT  eventdate, matchid
	FROM dbo.match14 m WITH (NOLOCK)
		INNER JOIN #archiveDate wld ON m.eventdate = wld.winlostdate
	ORDER BY m.eventdate

	DECLARE @start INT = 1
		, @end INT
		, @winlostdate DATETIME   
		, @winlostdate_tmp VARCHAR(12)
		, @matchIDs VARCHAR(MAX)
		, @ExecuteSQL NVARCHAR(MAX) = ''
		, @query NVARCHAR(MAX) = ''
	
	SELECT  @query = N''		
	SELECT	@query = @query + N'EXEC Task_Archive_TOControl_Delete @matchIDs'
	SELECT	@ExecuteSQL = N'EXECUTE DBCUST.CUSTDB.dbo.sp_executesql @query, N''@matchIDs NVARCHAR(MAX)'',@matchIDs'
		
	SET @end = (SELECT MAX(ID) FROM #archiveDate)

	-- Deployer Info
	DECLARE @msg nvarchar(200) = 'Currently at batch %d, wld: %s.'
	WHILE @start <= @end
	BEGIN
		
		SET @winlostdate = (SELECT winlostdate FROM #archiveDate WHERE ID = @start )
		SET @winlostdate_tmp  = CONVERT(VARCHAR(10),@winlostdate,101)
		
		IF @IsDebug = 1
			RAISERROR (@msg, 0, 1,@start, @winlostdate_tmp) WITH NOWAIT
		
		WHILE (1=1)
		BEGIN
			TRUNCATE TABLE #Match_tbl_tmp

			DELETE TOP (500)
			FROM #Match_tbl OUTPUT DELETED.Matchid, DELETED.winlostate INTO #Match_tbl_tmp (Matchid,winlostate)
			
			IF @@ROWCOUNT = 0 BREAK
			
			SET @matchIDs = ''
			SET @matchIDs = STUFF((SELECT ',' + CONVERT(VARCHAR(50),matchid) FROM #Match_tbl_tmp FOR XML PATH ('')),1,1,'')
			
			IF @IsDebug = 1
				RAISERROR (@msg, 0, 1,@start, @matchIDs) WITH NOWAIT
			
			EXECUTE	sys.sp_executesql @ExecuteSQL, N'@query NVARCHAR(MAX), @matchIDs NVARCHAR(MAX)', @query, @matchIDs
			
		END	
		
		SET @start = @start + 1
		
		WAITFOR DELAY '00:00:00.280'
					
	END	

	DROP TABLE #Match_tbl
	DROP TABLE #Match_tbl_tmp
	DROP TABLE #archiveDate
END



