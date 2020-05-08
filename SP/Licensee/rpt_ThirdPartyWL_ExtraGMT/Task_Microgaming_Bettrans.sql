/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/

USE [bodb_LicenseeReport]
GO

ALTER PROCEDURE [dbo].[Task_Microgaming_Bettrans] @Winlossdate DATE
AS
/*
	 Creator: 20150731@Florent
	 Task: Generate data for MicroGaming Casino
	 DB: DBLIC/bodb_LicenseeReport
	 Revisions: 		
		- 20150930@Florent: support Microgaming RNG
		- 20151208@Jim: seperate MicroGame into 2 products (#45454)
		- 20160422@Francis: add Progressive Contribution and Progressive Payout for Microgaming RNG
		- 20160907@Harper: #62820_Add ValidBetAmount for AllBet
		- 20161222@Jim: LA/ Invoice - Integrate Fishing World (GMT + 8) [Redmine:#68677]
		- 20180703@Sophia: Check @Winlossdate <= Movebetday will return because this day don't have data on Bettrans [Redmine: #97567] 
		- 20180608@Bruce: LA - Implement sum job for Pragmatic (GMT+0) [RedmineId #93958]
		- 20190321@Joseph: Remove Microgaming LC + RNG [RedmineID: #107704]
		- 20190710@Amanda: Integrate Card Club [RedmineID: #115449]
		- 20200508@Parsons: Integrate Sexy Gaming for deposit licensees [RedmineID: #132665]
	 Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON
	IF @Winlossdate IS NULL
		RETURN
	
	DECLARE @Dates AS TABLE(BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	INSERT INTO @Dates(BalanceUpDay, MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay
		
	IF EXISTS (SELECT 1 FROM @Dates WHERE MoveBetsDay >= @Winlossdate)
	   RETURN
  
	DELETE dbo.rpt_ThirdPartyWL_ExtraGMT WITH(ROWLOCK, UPDLOCK)
	WHERE RptDate = @Winlossdate

	INSERT INTO dbo.rpt_ThirdPartyWL_ExtraGMT(RptDate, RptDate3rd, SiteId, BetTypeId, CurrencyId, StatusId, BetCount, Turnover, Winloss, AComm, PComm, ProgressiveContribution, ProgressivePayout, ValidBetAmount)
	(
		SELECT CAST(b.winlostdate AS DATE)	AS Rptdate
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
			, SUM(ISNULL(p.WinAmount, 0)) AS ProgressivePayout
			, 0 AS ValidBetAmount
		FROM bodb02.dbo.bettransRnG b WITH (NOLOCK)
			LEFT JOIN DBTXN.bodb02.dbo.PayoutTrans p ON b.transid = p.RefNo
			LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
			LEFT JOIN bodb02.dbo.Site s WITH (NOLOCK) ON c.site = s.site
			LEFT JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON s.siteid = site.IbcSiteID			
		WHERE b.winlostdate = @Winlossdate
			AND b.statusID NOT IN (0, 1, 101, 102, 121)
			AND (b.gameID BETWEEN 1011 AND 1020 -- FW
				OR b.gameID BETWEEN 4101 AND 4300 -- PP
				OR b.gameID BETWEEN 1901 AND 1999 -- CC
				OR b.gameID BETWEEN 4301 AND 4600 -- SG
			)
		GROUP BY CAST(b.winlostdate AS DATE), CAST(b.Transdate3rd AS DATE), ISNULL(site.SiteID, -1), b.gameID
			, b.currency, b.statusID

		UNION

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
		FROM bodb02.dbo.bettransLC b WITH (NOLOCK)
			LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
			LEFT JOIN bodb02.dbo.Site s WITH (NOLOCK) ON c.site = s.site
			LEFT JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON s.siteid = site.IbcSiteID			
		WHERE b.winlostdate = @Winlossdate
			AND b.statusID NOT IN (0, 1, 101, 102, 121)
			AND (
					b.gameID BETWEEN 2401 AND 2499 -- AllBet
				OR  b.gameID BETWEEN 3101 AND 3199 -- SXG
				) 
		GROUP BY CAST(b.winlostdate AS DATE), CAST(b.Transdate3rd AS DATE), ISNULL(site.SiteID, -1), b.gameID
			, b.currency, b.statusID		
	)OPTION (MAXDOP 1)
END
GO