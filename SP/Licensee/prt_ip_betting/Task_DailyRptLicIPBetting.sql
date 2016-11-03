USE [bodb_LicenseeReport]
GO
ALTER PROCEDURE [dbo].[Task_DailyRptLicIPBetting]
	@winlostdate DATETIME
AS
/*
Created by:[Henry]
Date: 2012-05-30
Task: daily summary IP betting for Licensee
DB: DBLIC.bodb_LicenseeReport
Revisions:
	@20141211: Improve performance, support gen from bettrans14 only
	20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]

[Task_DailyRptLicIPBetting_xtest] '2014-12-6'   
 */

SET NOCOUNT ON 

SELECT * INTO #tmpBetCountry FROM DBTXN.bodb02.dbo.Task_bettrans14_IP2Country WITH(NOLOCK) WHERE winlostdate = @winlostdate

IF NOT EXISTS(SELECT 1 FROM #tmpBetCountry) RETURN

--Delete before inserting
delete from dbo.rptLicIPBetting with(ROWLOCK,UPDLOCK) where winlostdate = @winlostdate

INSERT INTO dbo.rptLicIPBetting
	(
		[winlostdate]
		,[LicenseeID]
		,[countrySHORT]
		,[currency]				
		,[CustID]
		,[ip]
		,[turnover]
		,[winlost]
		,[betcount]
		,[statusID]
	)
SELECT @winlostdate,l.LicenseeID, bc.CountryShort, bettrans.currency,bettrans.custid,bettrans.ip,
		SUM(
			case when bettrans.liveawayscore = 0 and bettrans.bettype IN(33,43) then ABS(bettrans.stake/2) else ABS(bettrans.stake) end
			) as TurnOver,
		SUM(winlost-actual_stake)  winlost,
		COUNT(bettrans.transid) BetCount,		
		--114: half win, 115: half lose
		CASE 
			WHEN bettrans.statusID = 112 AND bettrans.bettype IN(1,3,7,8,17,18) AND ABS(modds) = 0.25 THEN 114 
			WHEN bettrans.statusID = 113 AND bettrans.bettype IN(1,3,7,8,17,18) AND ABS(modds) = 0.25 THEN 115
			ELSE bettrans.statusID END AS statusID
	
	FROM
		bodb02.dbo.bettrans14 bettrans WITH (NOLOCK)
		INNER JOIN #tmpBetCountry bc ON bettrans.transid = bc.transid
		INNER JOIN bodb02.dbo.customer WITH (NOLOCK) ON bettrans.custid=customer.custid
		INNER JOIN bodb02.dbo.dep_custsuper s WITH (NOLOCK) ON customer.srecommend = s.custid
		INNER JOIN bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON s.site = l.LicenseeName
	WHERE
		bettrans.winlostdate = @winlostdate AND
		bettrans.statusID IN (111,112,113) AND
		bettrans.bettype < 19000 AND
		bettrans.currency <> 20
		--AND bettrans.currency IN (2,4,13,15) --MYR,THB,RMB,IDR
	GROUP BY
		l.LicenseeID,
		bc.CountryShort,
		bettrans.currency,
		bettrans.custid,
		bettrans.ip,
		--114: half win, 115: half lose
		CASE 
			WHEN bettrans.statusID = 112 AND bettrans.bettype IN(1,3,7,8,17,18) AND ABS(modds) = 0.25 THEN 114 
			WHEN bettrans.statusID = 113 AND bettrans.bettype IN(1,3,7,8,17,18) AND ABS(modds) = 0.25 THEN 115
			ELSE bettrans.statusID END
GO
GRANT EXECUTE ON [dbo].[Task_DailyRptLicIPBetting] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_DailyRptLicIPBetting] TO [vnteam] AS [dbo]