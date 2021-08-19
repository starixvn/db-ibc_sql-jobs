/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_rpt_CustomerWL_ExtraGMT_CheckData]
	@WinlostDate		SMALLDATETIME
	,@HasDataMismatch	TINYINT = 0 OUTPUT -- 0: No mismatch; 1: Has real currencies; 2: UUS only
	,@BetTypes			VARCHAR(MAX) = '' OUTPUT
AS

/*
	Created: 20200601@Percy
	DB: DBLIC-bodb_LicenseeReport
	Task: Gen data into rpt_CustomerWL_ExtraGMT

	Revisions:
		- 20200601@Percy: Initialize SP [RedmineID: #134867]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @tblBettype TABLE (ProductId INT, bettype SMALLINT, refTable TINYINT)
	INSERT INTO @tblBettype (ProductId, bettype, refTable)
	SELECT DISTINCT ProductId, bettype, refTable
	FROM bodb02.dbo.SportBettypeMatrix WITH (NOLOCK)
	WHERE ProductId = 21

	DECLARE @tblCustomer TABLE (custid INT, siteId INT)
	INSERT INTO @tblCustomer (custid, siteId)
	SELECT c.custid, ISNULL(s.SiteId, -1)
	FROM bodb02.dbo.Customer c WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Customer a WITH (NOLOCK) ON c.recommend = a.custid AND a.roleid = 2
		LEFT JOIN bodb_licensee.dbo.view_site_list s (NOLOCK) ON a.site = s.SiteName
	WHERE c.username IN ('BBS7777888', 'BBS7777777', 'BBS7777999')

	DECLARE @rptDate DATE
	SELECT  @rptDate = @WinlostDate

	-- Source data
	CREATE TABLE #rpt_CustomerWL_ExtraGMT_Source
	(
		RptDate						DATE
		,RptDate3rd					DATE
		,CustId						INT
		,SiteId						INT
		,ProductId					INT
		,BetTypeId					INT
		,CurrencyId					INT
		,StatusId					INT
		,BetCount					INT
		,Turnover					MONEY
		,Winloss					MONEY
		,AComm						MONEY
		,PComm						MONEY
		,ProgressiveContribution	MONEY
		,ProgressivePayout			MONEY
		,ValidBetAmount				MONEY
	)
	
	INSERT INTO #rpt_CustomerWL_ExtraGMT_Source
	(
		RptDate
		,RptDate3rd
		,CustId
		,SiteId
		,ProductId
		,BetTypeId
		,CurrencyId
		,StatusId
		,BetCount
		,Turnover
		,Winloss
		,AComm
		,PComm
		,ProgressiveContribution
		,ProgressivePayout
		,ValidBetAmount
	)
	SELECT
		RptDate		= @rptDate
		,RptDate3rd = CONVERT(DATE, b.Transdate3rd)
		,CustId		= b.custid
		,SiteId		= c.siteId
		,ProductId	= bt.ProductId
		,BetTypeId	= b.gameId
		,CurrencyId	= b.currency
		,StatusId	= b.statusId
		,BetCount	= COUNT(1)
		,Turnover	= SUM(ABS(b.stake))
		,Winloss	= SUM(b.winlost - b.actual_stake)
		,AComm		= SUM(b.comm)
		,PComm		= SUM(b.playercomm)
		,ProgressiveContribution	= 0
		,ProgressivePayout			= 0
		,ValidBetAmount				= SUM(b.NetStake)
	FROM bodb02.dbo.bettransLC14 b WITH (NOLOCK)
		INNER JOIN @tblBettype bt ON b.gameId = bt.bettype AND bt.refTable = 2
		INNER JOIN @tblCustomer c ON b.custid = c.custid
	WHERE b.winlostdate = @Winlostdate
		AND b.statusId IN (111, 112, 113)
	GROUP BY
		CONVERT(DATE, b.Transdate3rd)
		,b.custid
		,c.siteId
		,bt.ProductId
		,b.gameId
		,b.currency
		,b.statusId
	
	-- Target Data
	CREATE TABLE #rpt_CustomerWL_ExtraGMT_Target
	(
		RptDate						DATE
		,RptDate3rd					DATE
		,CustId						INT
		,SiteId						INT
		,ProductId					INT
		,BetTypeId					INT
		,CurrencyId					INT
		,StatusId					INT
		,BetCount					INT
		,Turnover					MONEY
		,Winloss					MONEY
		,AComm						MONEY
		,PComm						MONEY
		,ProgressiveContribution	MONEY
		,ProgressivePayout			MONEY
		,ValidBetAmount				MONEY
	)

	INSERT INTO #rpt_CustomerWL_ExtraGMT_Target
	(
		RptDate
		,RptDate3rd
		,CustId
		,SiteId
		,ProductId
		,BetTypeId
		,CurrencyId
		,StatusId
		,BetCount
		,Turnover
		,Winloss
		,AComm
		,PComm
		,ProgressiveContribution
		,ProgressivePayout
		,ValidBetAmount
	)
	SELECT
		RptDate
		,RptDate3rd
		,CustId
		,SiteId
		,ProductId
		,BetTypeId
		,CurrencyId
		,StatusId
		,BetCount
		,Turnover
		,Winloss
		,AComm
		,PComm
		,ProgressiveContribution
		,ProgressivePayout
		,ValidBetAmount
	FROM dbo.rpt_CustomerWL_ExtraGMT WITH (NOLOCK)
	WHERE RptDate = @rptDate

	-- Compare data
	CREATE TABLE #Log (TableName VARCHAR(300), IsSource BIT, BetTypeId INT, CurrencyId INT, Turnover MONEY, Winloss MONEY, BetCount INT, ExtraInfo VARCHAR(MAX));

	INSERT INTO #Log(TableName, IsSource, BetTypeId, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo)
	SELECT	'bettransRnG14/bettransLC14', 1, BetTypeId, CurrencyId, SUM(Turnover), SUM(Winloss), SUM(BetCount),
			(
				SELECT	SUM(AComm) AS AComm, SUM(PComm) AS PComm, SUM(ProgressiveContribution) AS ProgContrib,
						SUM(ProgressivePayout) AS ProgPayout, SUM(ValidBetAmount) AS ValidBetAmt
				FROM #rpt_CustomerWL_ExtraGMT_Source s1
				WHERE s.BetTypeId		= s1.BetTypeId
					AND s.CurrencyId	= s1.CurrencyId
				FOR XML PATH('')
			) AS ExtraInfo
	FROM #rpt_CustomerWL_ExtraGMT_Source s
	WHERE NOT EXISTS (
		SELECT 1
		FROM #rpt_CustomerWL_ExtraGMT_Target t
		WHERE s.RptDate3rd = t.RptDate3rd AND s.CustId = t.CustId AND s.SiteId = t.SiteId AND s.ProductId = t.ProductId
			AND s.BetTypeId = t.BetTypeId AND s.CurrencyId = t.CurrencyId AND s.StatusId = t.StatusId
			AND s.BetCount = t.BetCount AND s.Turnover = t.Turnover AND s.Winloss = t.Winloss
			AND s.AComm = t.AComm AND s.PComm = t.PComm AND s.ProgressiveContribution = t.ProgressiveContribution
			AND s.ProgressivePayout = t.ProgressivePayout AND s.ValidBetAmount = t.ValidBetAmount)
	GROUP BY BetTypeId, CurrencyId
			
	UNION ALL
	
	SELECT 'rpt_CustomerWL_ExtraGMT', 0, BetTypeId, CurrencyId, SUM(Turnover), SUM(Winloss), SUM(BetCount),
			(
				SELECT	SUM(AComm) AS AComm, SUM(PComm) AS PComm, SUM(ProgressiveContribution) AS ProgContrib,
						SUM(ProgressivePayout) AS ProgPayout, SUM(ValidBetAmount) AS ValidBetAmt
				FROM #rpt_CustomerWL_ExtraGMT_Target t1
				WHERE t.BetTypeId		= t1.BetTypeId
					AND t.CurrencyId	= t1.CurrencyId
				FOR XML PATH('')
			) AS ExtraInfo
	FROM #rpt_CustomerWL_ExtraGMT_Target t
	WHERE NOT EXISTS (
		SELECT 1
		FROM #rpt_CustomerWL_ExtraGMT_Source s
		WHERE s.RptDate3rd = t.RptDate3rd AND s.CustId = t.CustId AND s.SiteId = t.SiteId AND s.ProductId = t.ProductId
			AND s.BetTypeId = t.BetTypeId AND s.CurrencyId = t.CurrencyId AND s.StatusId = t.StatusId
			AND s.BetCount = t.BetCount AND s.Turnover = t.Turnover AND s.Winloss = t.Winloss
			AND s.AComm = t.AComm AND s.PComm = t.PComm AND s.ProgressiveContribution = t.ProgressiveContribution
			AND s.ProgressivePayout = t.ProgressivePayout AND s.ValidBetAmount = t.ValidBetAmount)
	GROUP BY BetTypeId, CurrencyId

	IF @@ROWCOUNT <> 0
	BEGIN
		IF EXISTS (SELECT 1 FROM #Log WHERE CurrencyId <> 20)
			SELECT @HasDataMismatch = 1
		ELSE
			SELECT @HasDataMismatch = 2 -- UUS only

		SELECT @BetTypes = STUFF(
			(
				SELECT DISTINCT ', ' + CAST(BetTypeId AS VARCHAR(10))
				FROM #Log
				FOR XML PATH('')
			), 1, 2, ''
		)

		INSERT INTO dbo.DataCheckingLog(WinlostDate, SPName, TableName, IsSource, BetTypeId, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo)
		SELECT	@WinlostDate, 
				'Task_rpt_CustomerWL_ExtraGMT_CheckData', 
				TableName, 
				IsSource,
				BetTypeId,
				CurrencyId, 
				Turnover, 
				Winloss,
				BetCount,
				ExtraInfo
		FROM #Log
	END

	DROP TABLE #Log
	DROP TABLE #rpt_CustomerWL_ExtraGMT_Source
	DROP TABLE #rpt_CustomerWL_ExtraGMT_Target
END
GO