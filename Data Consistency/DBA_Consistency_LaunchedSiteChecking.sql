/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_LaunchedSiteChecking]
	@ProductId		INT		
	,@sites			VARCHAR(MAX)	
	,@IsLaunched	INT				= 1
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT 
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20181219@Vicky
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20181219@Vicky: check members of un-launched sites have tickets or not [Redmine:#106481]
	
	Param's Expanation:
		- @sites: 'Indo,KORIBC'
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @transId VARCHAR(MAX)
	DECLARE @tblMatch TABLE (matchid INT)
	--CREATE TABLE #tblrecommend  (custid INT NOT NULL PRIMARY KEY)
	CREATE TABLE #tblSite  (site VARCHAR(50) PRIMARY KEY)
	----------------------------------------------------------------------------
	
	SET @transId = ''
	
	INSERT INTO @tblMatch(matchid)
	SELECT matchid
	FROM bodb02.dbo.Match m WITH (NOLOCK) 
	WHERE Sporttype = @ProductId
	
	/*INSERT INTO #tblrecommend (custid)
	SELECT custid
	FROM bodb02.dbo.CustAgent c WITH (NOLOCK) 
	WHERE   (@IsLaunched = 0 OR site IN (SELECT val FROM dbo.f_SplitString(@sites, ',')))
		AND (@IsLaunched = 1 OR site NOT IN (SELECT val FROM dbo.f_SplitString(@sites, ',')))*/
	
	INSERT INTO #tblSite (site)
	SELECT site
	FROM bodb02.dbo.Site s WITH (NOLOCK) 
	WHERE   (@IsLaunched = 0 OR site IN (SELECT val FROM dbo.f_SplitString(@sites, ',')))
		AND (@IsLaunched = 1 OR site NOT IN (SELECT val FROM dbo.f_SplitString(@sites, ',')))
	----------------------------------------------------------------------------
	
	SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
	FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
		INNER JOIN bodb02.dbo.CustAgent c WITH (NOLOCK) ON c.custid = b.recommend
	WHERE	b.bettype < 20000
			AND b.matchid IN (SELECT matchid FROM @tblMatch)
			AND currency <> 20
			AND c.site IN (
							SELECT site 
							FROM #tblSite s
						   )
	
	IF @transId <> ''
	BEGIN
		SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'Member of un-launched sites have tickets on product ' + CAST(@ProductId AS VARCHAR)
				,@SampleData = 'bettrans.TransId in (' + @transId + ')'
	END
	
END
GO