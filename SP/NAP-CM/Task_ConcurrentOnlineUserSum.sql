/*<info serverAlias="DBONUSER-ON_USER" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE dbo.Task_ConcurrentOnlineUserSum
	@SumDate DATE = NULL
AS
/*
	Created: 20230323@Malcolm
	Task : Sum Concurrent Online Users [RedmineID: #183462]
	DB: DBONUSER/ON_USER

	Revisions:
		- 20230323@Malcolm: Initial SPs [redmine:#183462]

	Param's Explanation:
		GroupingType = 1 : SiteLabel
					 = 2 : SiteLabel, SiteId
					 = 3 : SiteLabel, SiteId, RoleId
					 = 4 : Time
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @MaxDetailDate DATE
	DECLARE @CurrentDate DATETIME = DATEADD(HOUR, 12, GETDATE())
	DECLARE @PreviousDate DATE = DATEADD(DAY, -1, CONVERT(DATE, @CurrentDate))

	CREATE TABLE #Site (SiteId INT PRIMARY KEY, SiteName NVARCHAR(50), SiteLabel VARCHAR(50))

	CREATE TABLE #Result 
	(
		Grouping_Hour		TINYINT
		,Grouping_SiteLabel TINYINT
		,Grouping_SiteId	TINYINT
		,Grouping_RoleId	TINYINT
		,[Hour]				SMALLINT
		,SiteLabel			VARCHAR(50)
		,SiteId				INT
		,RoleId				TINYINT
		,RealUserCount		INT
		,TestingUserCount	INT
	)

	CREATE TABLE #UncalResult 
	(
		Grouping_CreatedDate TINYINT
		,Grouping_SiteLabel	  TINYINT
		,Grouping_SiteId	  TINYINT
		,Grouping_RoleId	  TINYINT
		,CreatedDate		  DATETIME
		,SiteLabel			  VARCHAR(50)
		,SiteId				  INT
		,RoleId				  TINYINT
		,RealUserCount		  INT
		,TestingUserCount	  INT
	)

	INSERT INTO #Site (SiteId, SiteName, SiteLabel)
	SELECT SiteId, Site, SiteLabel
	FROM bodb02.dbo.Site WITH(NOLOCK) 
	WHERE SiteLabel IS NOT NULL AND IsActive = 1 AND IsLicensee = 0

	SELECT TOP(1) @MaxDetailDate = CONVERT(DATE, CreatedDate) FROM dbo.ConcurrentOnlineUserDetail WITH(NOLOCK) ORDER BY CreatedDate DESC

	IF @MaxDetailDate IS NULL OR @MaxDetailDate <= @PreviousDate OR (@SumDate IS NOT NULL AND @SumDate >= @MaxDetailDate)
		RETURN

	--Sum Daily
	IF NOT EXISTS (SELECT 1 FROM dbo.ConcurrentOnlineUserDaily WITH(NOLOCK) WHERE CaptureDate = @PreviousDate)
	   OR @SumDate IS NOT NULL
	BEGIN
		IF @SumDate IS NOT NULL
		BEGIN
			DELETE dbo.ConcurrentOnlineUserHourly WITH(ROWLOCK, UPDLOCK)
			WHERE CaptureDate = @SumDate

			DELETE dbo.ConcurrentOnlineUserDaily WITH(ROWLOCK, UPDLOCK)
			WHERE CaptureDate = @SumDate

			SET @PreviousDate = @SumDate
		END

		INSERT INTO #UncalResult 
		(
			Grouping_CreatedDate
			,Grouping_SiteLabel
			,Grouping_SiteId
			,Grouping_RoleId
			,CreatedDate
			,SiteLabel
			,SiteId
			,RoleId
			,RealUserCount		
			,TestingUserCount	
		)
		SELECT 
			GROUPING(d.CreatedDate)				AS Grouping_CreatedDate
			,GROUPING(s.SiteLabel)				AS Grouping_SiteLabel
			,GROUPING(s.SiteId)					AS Grouping_SiteId
			,GROUPING(d.RoleId)					AS Grouping_RoleId
			,d.CreatedDate						AS CreatedDate
			,s.SiteLabel						AS SiteLabel
			,s.SiteId							AS SiteId
			,d.RoleId							AS RoleId
			,SUM(RealUserCount)					AS RealUserCount
			,SUM(TestingUserCount)				AS TestingUserCount
		FROM dbo.ConcurrentOnlineUserDetail d WITH(NOLOCK)	
			INNER JOIN #Site s ON s.SiteId = d.SiteId
		WHERE d.CreatedDate >= @PreviousDate AND d.CreatedDate < DATEADD(DAY, 1, @PreviousDate)
		GROUP BY 
			GROUPING SETS
			(
				(d.CreatedDate)
				,(d.CreatedDate, s.SiteLabel)
				,(d.CreatedDate, s.SiteLabel, s.SiteId)
				,(d.CreatedDate, s.siteLabel, s.SiteId, d.RoleId)
			)		 

		INSERT INTO #Result 
		(
			Grouping_Hour
			,Grouping_SiteLabel
			,Grouping_SiteId
			,Grouping_RoleId
			,[Hour]
			,SiteLabel
			,SiteId
			,RoleId
			,RealUserCount		
			,TestingUserCount	
		)
		SELECT 
			GROUPING(DATEPART(HH, CreatedDate)) AS Grouping_Hour
			,GROUPING(u.SiteLabel)				AS Grouping_SiteLabel
			,GROUPING(u.SiteId)					AS Grouping_SiteId
			,GROUPING(u.RoleId)					AS Grouping_RoleId
			,DATEPART(HH, CreatedDate)			AS [Hour]
			,u.SiteLabel						AS SiteLabel
			,u.SiteId							AS SiteName
			,u.RoleId							AS RoleId
			,MAX(RealUserCount)					AS RealUserCount
			,MAX(TestingUserCount)				AS TestingUserCount
		FROM #UncalResult u
		WHERE u.CreatedDate >= @PreviousDate AND u.CreatedDate < DATEADD(DAY, 1, @PreviousDate) 
		GROUP BY 
			GROUPING SETS 
			(
				(DATEPART(HH, u.CreatedDate), u.SiteLabel, u.SiteId, u.RoleId)
				,(DATEPART(HH, u.CreatedDate), u.SiteLabel, u.SiteId)
				,(DATEPART(HH, u.CreatedDate), u.SiteLabel)
				,(u.SiteLabel, u.SiteId, u.RoleId)
				,(u.SiteLabel, u.SiteId)
				,(u.SiteLabel)
				,()
				,(DATEPART(HH, u.CreatedDate))
			)

		DELETE r
		FROM #Result r
		WHERE (Grouping_Hour = 0 AND [Hour] IS NULL)
			OR (Grouping_SiteLabel = 0 AND SiteLabel IS NULL)
			OR (Grouping_SiteId = 0 AND SiteId IS NULL)
			OR (Grouping_RoleId = 0 AND RoleId IS NULL)

		INSERT INTO dbo.ConcurrentOnlineUserHourly
		(
			CaptureDate
			,[Hour]
			,SiteLabel
			,SiteId
			,RoleId
			,RealUserCount		
			,TestingUserCount	
			,GroupingType
		)
		SELECT 
			@PreviousDate AS CaptureDate
			,r.[Hour]
			,r.SiteLabel
			,r.SiteId
			,r.RoleId
			,r.RealUserCount
			,r.TestingUserCount
			,CASE WHEN r.Grouping_RoleId	= 0	THEN 3 
				  WHEN r.Grouping_SiteId	= 0	THEN 2
				  WHEN r.Grouping_SiteLabel = 0 THEN 1
				  WHEN r.Grouping_Hour		= 0 THEN 4
			ELSE NULL END AS [GroupingType]
		FROM #Result r
		WHERE r.Grouping_Hour = 0
	
		INSERT INTO dbo.ConcurrentOnlineUserDaily 
		(
			CaptureDate
			,SiteLabel
			,Siteid
			,RoleId
			,RealUserCount		
			,TestingUserCount
			,GroupingType
		)
		SELECT 
			@PreviousDate AS CaptureDate
			,r.SiteLabel
			,r.SiteId
			,r.RoleId
			,r.RealUserCount
			,r.TestingUserCount
			,CASE WHEN r.Grouping_RoleId	= 0	THEN 3 
				  WHEN r.Grouping_SiteId	= 0	THEN 2
				  WHEN r.Grouping_SiteLabel = 0 THEN 1
			ELSE 4 END AS [GroupingType]
		FROM #Result r
		WHERE r.Grouping_Hour = 1
	END

	DROP TABLE #Site
	DROP TABLE #Result
	DROP TABLE #UncalResult
END