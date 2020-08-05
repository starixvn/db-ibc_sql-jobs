/*<info serverAlias="DBARC-bodb_Archive" executers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Task_Job_Archive_TOControl_Copy
(
	@IsDebug BIT = 0
)

/*
	Created: 20191128@Helen
	Task: TO Control Archive - https://nexdev.net/issues/124447
	DB: DBARC/bodb_Archive
	
	Revisions:
		- 20191126@Helen: Archive TO Control - copy [Redimine:98467]
		- 20200122@Max: Support Separate setting and notification into Live/Non-Live major and minor bettypes [Redmine: #126841]
		- 20200714@Max: SMA TO Control - Add block increasing TO Limit feature to specific SMAs - [Redmine: #136254]
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
			

	CREATE TABLE #archiveDate (ID INT IDENTITY (1,1), winlostdate DATETIME)

	INSERT INTO #archiveDate (winlostdate)
	SELECT winlostdate 
	FROM DBTXN.bodb02.dbo.Task_ArchiveDate WITH (NOLOCK)
	ORDER BY winlostdate
	
	SELECT  @query = N''		
	SELECT	@query = @query + N'EXEC Task_Archive_TOControl_Copy @winlostdate'
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
		INSERT INTO dbo.TOControl_Setting_bk (CustID, matchid, MaxTurnOver, TotalTurnOver, IsNotified, HouseTurnover, PercentLevel, IsGroupHeadLine,winlostdate, ProfileID, IsGlobalLockTOLimit, IsEventLockTOLimit)
		EXECUTE	sys.sp_executesql @ExecuteSQL, N'@query NVARCHAR(MAX), @winlostdate datetime', @query, @winlostdate
			
		SET @start = @start + 1
		
		WAITFOR DELAY '00:00:00.280'
					
	END	
	DROP TABLE #archiveDate

END
GO


