USE [bodb_LicenseeReport]
GO
ALTER PROCEDURE [dbo].[GEN_rptBetting_Parlay] 
	@date SMALLDATETIME = NULL
	,@date2 SMALLDATETIME = NULL
AS
/*   
 Created: 20150910@Sophia  
 DB: DBLIC.bodb_licenseeReport  
 Task: Gen data from bettrans before Move bets
 Original:  GEN_rptBetting_Parlay14
 Revisions:   
	- 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
    - 20170712@Harper: Implement new Product Betradar VS [Redmine: #78241]

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @tmp_bettrans AS TABLE (
		transid BIGINT
		,transdate DATETIME
		,winlostdate DATETIME
		,livehomescore SMALLINT
		,bettype INT
		,custid INT
		,stake MONEY
		,actual_stake MONEY
		,winlost MONEY
		,awinlost MONEY
		,acomm MONEY
		,playercomm MONEY
		,comm MONEY
		,matchid INT
		,currency INT
		,recommend INT
		,statusid SMALLINT
		,virtualrate FLOAT
		,isBA SMALLINT
		,tpositiontaking SMALLMONEY
		)

	INSERT INTO @tmp_bettrans (
		transid
		,transdate
		,winlostdate
		,livehomescore
		,bettype
		,custid
		,stake
		,actual_stake
		,winlost
		,awinlost
		,acomm
		,playercomm
		,comm
		,matchid
		,currency
		,recommend
		,statusid
		,virtualrate
		,isBA
		,tpositiontaking
		)
	SELECT b.transid
		,b.transdate
		,b.winlostdate
		,b.livehomescore
		,b.bettype
		,b.custid
		,ABS(b.stake) stake
		,b.actual_stake
		,b.winlost
		,b.awinlost
		,b.acomm
		,b.playercomm
		,b.comm
		,b.matchid
		,b.currency
		,b.recommend
		,b.statusid
		,b.virtualrate
		,0 isBA
		,b.tpositiontaking
	FROM bodb02.dbo.bettrans b WITH (NOLOCK)
		INNER JOIN bodb_Licensee.dbo.licenseecust lc WITH (NOLOCK)
		ON b.Recommend = lc.CustID
	WHERE b.bettype IN (9, 29, 2799)
		AND b.MatchID > 0
		AND b.custid > 0
		AND b.statusid NOT IN (0, 101, 102, 121)
		AND b.winlostdate BETWEEN @date
			AND @date2

	---BA   
	DECLARE @BATransids AS TABLE (transID BIGINT)

	INSERT @BATransids
	SELECT transid
	FROM @tmp_bettrans b
		INNER JOIN bodb_Licensee.dbo.LicenseeBAHistory h(NOLOCK)
		ON b.custid = h.custid
	WHERE tpositiontaking = 0

	UPDATE @tmp_bettrans
	SET IsBA = 1
	WHERE transid IN (
			SELECT transid
			FROM @BATransids
			)

	DELETE dbo.rpt_BettingParlay
	WHERE rptDate BETWEEN @date
			AND @date2

	INSERT INTO dbo.rpt_BettingParlay (
		[rptDate]
		,[SiteID]
		,[Bettype]
		,[CurrencyID]
		,[Status]
		,[IsLive]
		,[BetCount]
		,[MemberCount]
		,[Turnover]
		,[WinLoss]
		,[WinLossA]
		,[CommissionP]
		,[CommissionA]
		,[WinLossVirtual]
		,[isBA]
		)
	SELECT b.winlostdate AS rptDate
		,ISNULL(site.SiteID, - 1) siteid
		,b.bettype
		,b.Currency AS CurrencyID
		,b.statusid STATUS
		,b.livehomescore IsLive
		,COUNT(*) Betcount
		,COUNT(DISTINCT b.custid) MemberCount
		,SUM(b.stake) Turnover
		,SUM(b.winlost - b.actual_stake) winloss
		,SUM(b.awinlost) winlossA
		,SUM(b.playercomm) commissionP
		,SUM(b.comm) commissionA
		,SUM((b.winlost - b.actual_stake) * b.virtualrate) WinLossVirtual
		,b.isBA
	FROM @tmp_bettrans b
		LEFT JOIN bodb02.dbo.customer ag(NOLOCK)
		ON b.recommend = ag.custid
			AND ag.roleid = 2
		LEFT JOIN bodb02.dbo.Site ibcsite(NOLOCK)
		ON ag.site = ibcsite.site
		LEFT JOIN bodb_Licensee.dbo.view_site_list [site](NOLOCK)
		ON ibcsite.siteid = site.IbcSiteID
	GROUP BY b.winlostdate
		,ISNULL(site.SiteID, - 1)
		,b.bettype
		,b.currency
		,b.statusid
		,b.livehomescore
		,b.isBA
END
GO
GRANT VIEW DEFINITION ON [dbo].[GEN_rptBetting_Parlay] TO [vnteam] AS [dbo]