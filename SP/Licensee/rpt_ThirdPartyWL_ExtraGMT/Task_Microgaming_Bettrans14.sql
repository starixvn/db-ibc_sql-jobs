/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_LicenseeReport]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Microgaming_Bettrans14] 
	@Fromdate	DATE
	, @Todate	DATE 
AS
/*
	 Creator: 20150731@Florent
	 Task: Generate data for MicroGaming from bettrans14
	 DB: DBLIC/bodb_LicenseeReport
	 Revisions: 		
	 - 20151208@Jim: separate MicroGame into 2 products (#45454)
	 - 20160422@Francis: add Progressive Contribution and Progressive Payout for Microgaming RNG
	 - 20160907@Harper: #62820_Add ValidBetAmount for AllBet
	 - 20161222@Jim: LA/ Invoice - Integrate Fishing World (GMT + 8) [Redmine:#68677]
	 - 20170523@Paul: Add sport type 205 [Redmine:#72914]
	 - 20180608@Bruce: LA - Implement sum job for Pragmatic (GMT+0) [RedmineId #93958]
	 - 20190321@Joseph: Remove Microgaming LC + RNG [RedmineID: #107704]
	 Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON
	IF @Fromdate IS NULL OR @Todate IS NULL
		RETURN	
	IF NOT EXISTS(SELECT TOP 1 1 FROM bodb02.dbo.bettrans14 WITH (NOLOCK)
				WHERE winlostdate BETWEEN @Fromdate AND @Todate	)
		RETURN
	
	DECLARE @Winlostdate DATE
	SET @Winlostdate = @Fromdate

	WHILE (@Winlostdate <= @Todate)
	BEGIN
		IF EXISTS (SELECT TOP 1 1 FROM dbo.rpt_ThirdPartyWL_ExtraGMT WITH (NOLOCK) WHERE RptDate = @Winlostdate)
		BEGIN
			DELETE dbo.rpt_ThirdPartyWL_ExtraGMT WITH (ROWLOCK, UPDLOCK) WHERE RptDate = @Winlostdate
		END

		INSERT INTO dbo.rpt_ThirdPartyWL_ExtraGMT(RptDate, RptDate3rd, SiteId, BetTypeId, CurrencyId, StatusId, BetCount, Turnover, Winloss, AComm, PComm, ProgressiveContribution, ProgressivePayout, ValidBetAmount)
		(SELECT CAST(b.winlostdate AS DATE)	AS Rptdate
			, CAST(b.Transdate3rd AS DATE)	AS RptDate3rd
			, ISNULL(site.SiteID, -1) AS siteid
			, b.gameID	 AS BetTypeId		
			, b.currency
			, b.statusID
			, COUNT(1) AS BetCount
			, SUM(ABS(b.stake)) AS Turnover
			, SUM(winlost - actual_stake) AS Winloss		
			, SUM(b.comm) AS AComm
			, SUM(b.playercomm) AS PComm
			, 0 AS ProgressiveContribution
			, SUM(ISNULL(p.WinAmount,0)) AS ProgressivePayout
			, 0 AS ValidBetAmount
		FROM bodb02.dbo.bettransRnG14 b WITH (NOLOCK)
			LEFT JOIN DBTXN.bodb02.dbo.PayoutTrans p ON b.transid = p.RefNo			
			LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
			LEFT JOIN bodb02.dbo.Site s WITH (NOLOCK) ON c.site = s.site
			LEFT JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON s.siteid = site.IbcSiteID			
		WHERE b.winlostdate = @Winlostdate
			AND b.statusID NOT IN (0, 1, 101, 102, 121)
			AND (b.gameID BETWEEN 1011 AND 1020 -- FW
				OR b.gameID BETWEEN 4101 AND 4300 -- PP
			)
		GROUP BY CAST(b.winlostdate AS DATE), CAST(b.Transdate3rd AS DATE), ISNULL(site.SiteID, -1), b.gameID
			, b.currency, b.statusID	
			
		UNION ALL-- AllBet

		SELECT CAST(b.winlostdate AS DATE)	AS Rptdate
			, CAST(b.Transdate3rd AS DATE)	AS RptDate3rd
			, ISNULL(site.SiteID, -1) AS siteid
			, b.gameID AS BetTypeId		
			, b.currency
			, b.statusID
			, COUNT(1) AS BetCount
			, SUM(ABS(b.stake)) AS Turnover
			, SUM(winlost - actual_stake) AS Winloss		
			, SUM(b.comm) AS AComm
			, SUM(b.playercomm) AS PComm
			, 0 AS ProgressiveContribution
			, 0 AS ProgressivePayout
			, SUM(ISNULL(b.NetStake, 0)) AS ValidBetAmount
		FROM bodb02.dbo.bettransLC14 b WITH (NOLOCK)
			LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
			LEFT JOIN bodb02.dbo.Site s WITH (NOLOCK) ON c.site = s.site
			LEFT JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON s.siteid = site.IbcSiteID			
		WHERE b.winlostdate = @Winlostdate
			AND b.statusID NOT IN (0, 1, 101, 102, 121)
			AND b.gameID BETWEEN 2401 AND 2499
		GROUP BY CAST(b.winlostdate AS DATE), CAST(b.Transdate3rd AS DATE), ISNULL(site.SiteID, -1), b.gameID
			, b.currency, b.statusID	
		)
		OPTION (MAXDOP 1)

		SET @Winlostdate = DATEADD(D, 1, @Winlostdate)
	END
END
GO