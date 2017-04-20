USE [bodb_LicenseeReport]
GO

ALTER PROCEDURE [dbo].[Task_DailyRptLicWinloss2_Bettrans] 
	@winlostdate DATETIME  
AS  
/*  
	Created: 20150911@Patrick
	Task: daily summary for Licensee  from bettrans
	DB: DBLIC.bodb_LicenseeReport
	Revisions:  
	- 20151113@Jim: separate Microgaming into 2 products
	- 20151231@Patrick: Add more field buybackamt & BABuyBackAmt
	- 20160105@Bobby: #49196 - Implement OneRnG product
	- 20160301@Victor: Redefine betfrom value [Redmine: #50939]
	- 20160415@Victor: Support Voidbridge product [Redmine: #55057]
	- 20160721@Jim: Add product Allbet [Redmine: #59624]
	- 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
	- 20160727@Jim:  LRF - Commercial terms changed for Bet Trade [Redmine: #61342]
	- 20160913@Jim : LRF - Implement Colossus Bets [Redmine: #63785]
	- 20161115@Jim: LRF - Integrate new product Fishing World [RedmineID : #66737]
	- 20170322@Paul: Implement Cash Out [RedmineID :#71727]	

	EXEC Task_DailyRptLicWinloss2_Bettrans '2017-04-07'
*/  
BEGIN
	SET NOCOUNT ON
    
	DELETE FROM dbo.rptLicWinloss2 WITH (rowlock) WHERE winlostdate = @winlostdate 

	--Member Level  
	INSERT INTO dbo.rptLicWinloss2(  
	  [winlostdate]  
	  ,[username]  
	  ,[username2]  
	  ,[custid]  
	  ,[roleid]  
	  ,[recommend]  
	  ,[mrecommend]  
	  ,[srecommend]  
	  ,[turnover]  
	  ,[winlost]  
	  ,[BetEffective]  
	  ,[awinlost]  
	  ,[mwinlost]  
	  ,[swinlost]  
	  ,[playercomm]  
	  ,[comm]  
	  ,[acomm]  
	  ,[scomm]  
	  ,[winlostvirtual]  
	  ,[commvirtual]  
	  ,[BetCount]  
	  ,[Currency]  
	  ,[sporttype]  
	  ,[bettype]  
	  ,[statusID]  
	  ,[isBA]  
	  ,[isMobile]  
	  ,[betfrom]  
	  ,[BuyBackAmt]
	  ,[BABuyBackAmt]
	  )  
	SELECT @winlostdate  
	   ,customer.username  
	   ,customer.username2  
	   ,customer.custid  
	   ,1  
	   ,customer.recommend  
	   ,customer.mrecommend  
	   ,customer.srecommend  
	 ,SUM(    
	  CASE WHEN bettrans.liveawayscore = 0 AND bettrans.bettype IN(33,43)   
		THEN ABS(bettrans.stake/2) ELSE ABS(bettrans.stake)   
		END  
	  ) AS TurnOver  
	 ,SUM(winlost-actual_stake)  winlost  
	 ,CASE WHEN bettrans.statusID IN (112,113)   
		THEN SUM(ABS(winlost-actual_stake))   
		ELSE 0  
		END BetEffective   
	 ,SUM(awinlost) awinlost  
	 ,SUM(mwinlost) mwinlost  
	 ,SUM(ISNULL(swinlost,0)) swinlost  
	 ,SUM(playercomm) playercomm  
	 ,SUM(comm) comm  
	 ,SUM(acomm) acomm  
	 ,SUM(ISNULL(scomm,0)) scomm  
	 ,SUM((winlost - actual_stake)*virtualrate) AS WinlostVirtual  
	 ,SUM ((comm)*virtualrate) AS CommVirtual  
	 ,COUNT(bettrans.transid) BetCount  
	 ,bettrans.currency  
	 ,CASE
		WHEN bettype IN (71,72) THEN 251 --casino  
		WHEN bettype = 1000 THEN 253 --games  
		WHEN bettype BETWEEN 81 AND 120 THEN 161 --Number Game   
		WHEN bettype BETWEEN 1101 AND 1199 THEN 162 -- Live casino  
		WHEN (bettype BETWEEN 1201 AND 1299 ) THEN 180  --Virtual Sport  
		WHEN bettype BETWEEN 51 AND 69 THEN 201  
		WHEN bettype IN (31,32,33,41,42,43) THEN 151  
		WHEN bettype BETWEEN 1501  AND 1599 THEN 202 -- Keno  
		WHEN bettype BETWEEN 1800 AND 1899 THEN 250 -- AGC  
		WHEN bettype BETWEEN 1700 AND 1799 THEN 255 -- GD  
		WHEN bettype BETWEEN 1900 AND 1999 THEN 249 -- VG  
		WHEN bettype BETWEEN 2001 AND 2007 THEN 203
		WHEN bettype BETWEEN 2008 AND 2009 THEN 205
		WHEN bettype BETWEEN 2101 AND 2199 THEN 208
		WHEN bettype BETWEEN 2201 AND 2299 THEN 209
		WHEN bettype BETWEEN 2301 AND 2399 THEN 210
		WHEN bettype BETWEEN 4001 AND 7999 THEN 212 -- VB
		WHEN bettype BETWEEN 2401 AND 2499 THEN 211 -- AB
		WHEN bettype BETWEEN 18000 AND 18006 THEN 204 --CB
		WHEN bettype BETWEEN 1011 AND 1020 THEN 219
	  ELSE 0 END sporttype  
	 ,CASE WHEN bettype IN (71,72,1000,901,902,903,904,911,912,913,914) THEN bettype ELSE 0 END bettype  
	 --114: half win, 115: half lose  
	 ,CASE   
	  WHEN bettrans.statusID = 112 AND bettrans.bettype IN(1,3,7,8,17,18) AND ABS(modds) = 0.25 THEN 114   
	  WHEN bettrans.statusID = 113 AND bettrans.bettype IN(1,3,7,8,17,18) AND ABS(modds) = 0.25 THEN 115  
	  ELSE bettrans.statusID END AS statusID  
	 ,CASE   
	  WHEN BA.transid IS NULL THEN 0  
	  WHEN BA.transid IS NOT NULL THEN 1 END AS isBA  
	 ,CASE   
	  WHEN bettrans.betfrom IN ('s','m','l') THEN 1 ELSE 0 END AS isMobile   
	 ,CASE      
	  WHEN bettrans.betfrom IN ('a','d','e','u','s','m','l') THEN bettrans.betfrom ELSE '' END AS betfrom   
	 ,SUM(CASE WHEN bettrans.bettype IN (902, 912) AND transid2 = 0 THEN actual_stake ELSE 0 END) AS BuyBackAmt
	 ,SUM(CASE WHEN bettrans.bettype IN (902, 912) AND transid2 = 1 THEN actual_stake ELSE 0 END) AS BABuyBackAmt	 
	FROM  
	 bodb02.dbo.bettrans bettrans WITH (NOLOCK)
	 INNER JOIN bodb02.dbo.Dep_CustSuper s WITH(NOLOCK) ON bettrans.srecommend = s.CustId
	 INNER JOIN bodb02.dbo.customer WITH (NOLOCK) ON bettrans.custid=customer.custid
	 LEFT JOIN bodb_Licensee.dbo.LicenseeBATransaction BA WITH (NOLOCK) ON bettrans.transid = BA.transid 	 
	WHERE  
	 bettrans.winlostdate = @winlostdate AND  
	 bettrans.statusID IN (101,111,112,113) AND --REJECT, DRAW, WON, LOSE  
	 bettrans.bettype<=19999  
	GROUP BY  
	 customer.custid  
	 ,customer.recommend  
	 ,customer.mrecommend  
	 ,customer.srecommend  
	 ,customer.username  
	 ,customer.username2  
	 ,bettrans.currency  
	 ,bettrans.statusID  
	 ,CASE
		WHEN bettype IN (71,72) THEN 251 --casino  
		WHEN bettype = 1000 THEN 253 --games  
		WHEN bettype BETWEEN 81 AND 120 THEN 161 --Number Game   
		WHEN bettype BETWEEN 1101 AND 1199 THEN 162 -- Live casino  
		WHEN (bettype BETWEEN 1201 AND 1299 ) THEN 180  --Virtual Sport  
		WHEN bettype BETWEEN 51 AND 69 THEN 201  
		WHEN bettype IN (31,32,33,41,42,43) THEN 151  
		WHEN bettype BETWEEN 1501  AND 1599 THEN 202  
		WHEN bettype BETWEEN 1800 AND 1899 THEN 250 -- AGC  
		WHEN bettype BETWEEN 1700 AND 1799 THEN 255 -- GD  
		WHEN bettype BETWEEN 1900 AND 1999 THEN 249 -- VG  
		WHEN bettype BETWEEN 2001 AND 2007 THEN 203
		WHEN bettype BETWEEN 2008 AND 2009 THEN 205
		WHEN bettype BETWEEN 2101 AND 2199 THEN 208
		WHEN bettype BETWEEN 2201 AND 2299 THEN 209
		WHEN bettype BETWEEN 2301 AND 2399 THEN 210		
		WHEN bettype BETWEEN 4001 AND 7999 THEN 212 -- VB
		WHEN bettype BETWEEN 2401 AND 2499 THEN 211 -- AB
		WHEN bettype BETWEEN 18000 AND 18006 THEN 204 --CB
		WHEN bettype BETWEEN 1011 AND 1020 THEN 219
	  ELSE 0 END  
	 ,CASE WHEN bettype IN (71,72,1000,901,902,903,904,911,912,913,914) THEN bettype ELSE 0 END  
	 ,CASE   
	  WHEN bettrans.statusID = 112 AND bettrans.bettype IN(1,3,7,8,17,18) AND ABS(modds) = 0.25 THEN 114   
	  WHEN bettrans.statusID = 113 AND bettrans.bettype IN(1,3,7,8,17,18) AND ABS(modds) = 0.25 THEN 115  
	  ELSE bettrans.statusID END  
	 ,CASE   
	  WHEN BA.transid IS NULL THEN 0  
	  WHEN BA.transid IS NOT NULL THEN 1 END  
	 ,CASE   
	  WHEN bettrans.betfrom IN ('s','m','l') THEN 1 ELSE 0 END  
	 ,CASE      
	  WHEN bettrans.betfrom IN ('a','d','e','u','s','m','l') THEN bettrans.betfrom ELSE '' END
	 OPTION (MAXDOP 8)

	--Agent Level (sum on member)  
	INSERT INTO dbo.rptLicWinloss2  (  
		[winlostdate]
	  ,[username]  
	  ,[username2]  
	  ,[custid]  
	  ,[roleid]  
	  ,[recommend]  
	  ,[mrecommend]  
	  ,[srecommend]  
	  ,[turnover]  
	  ,[winlost]  
	  ,[BetEffective]  
	  ,[awinlost]  
	  ,[mwinlost]  
	  ,[swinlost]  
	  ,[playercomm]  
	  ,[comm]  
	  ,[acomm]  
	  ,[scomm]  
	  ,[winlostvirtual]  
	  ,[commvirtual]  
	  ,[BetCount]  
	  ,[Currency]  
	  ,[sporttype]  
	  ,[bettype]  
	  ,[statusID]  
	  ,[isBA]  
	  ,[isMobile]  
	  ,[betfrom]
	  ,[BuyBackAmt]
	  ,[BABuyBackAmt]
	)  
	SELECT  
	@winlostdate  
	,c.username  
	,c.username2  
	,c.custid  
	,2 AS roleid  
	,b.recommend  
	,b.mrecommend  
	,b.srecommend  
	,SUM(turnover)  
	,SUM(winlost)  
	,SUM(BetEffective)  
	,SUM(awinlost)  
	,SUM(mwinlost)  
	,SUM(swinlost)  
	,SUM(playercomm)  
	,SUM(comm)  
	,SUM(acomm)  
	,SUM(scomm)  
	,SUM(winlostvirtual)  
	,SUM(commvirtual)  
	,SUM(BetCount)  
	,b.currency  
	,b.sporttype  
	,b.bettype  
	,b.statusID  
	,b.isBA  
	,b.isMobile  
	,b.betfrom
	,SUM(BuyBackAmt) 
	,SUM(BABuyBackAmt)		
	FROM  
		dbo.rptLicWinloss2 b (nolock)  
		INNER JOIN bodb02.dbo.customer c (nolock) ON b.recommend = c.custid  
	WHERE  
		b.winlostdate = @winlostdate  
		and b.roleid = 1  
		and c.roleid = 2  
	GROUP BY  
		c.username  
	,c.username2  
	,c.custid  
	,b.recommend  
	,b.mrecommend  
	,b.srecommend  
		,b.currency  
		,b.sporttype  
		,b.bettype  
		,b.statusID  
	,b.isBA  
	,b.isMobile  
	,b.betfrom  
		 
	--Master Level (sum on member)  
	INSERT INTO dbo.rptLicWinloss2  
			(  
		[winlostdate]  
	  ,[username]  
	  ,[username2]  
	  ,[custid]  
	  ,[roleid]  
	  ,[recommend]  
	  ,[mrecommend]  
	  ,[srecommend]  
	  ,[turnover]  
	  ,[winlost]  
	  ,[BetEffective]  
	  ,[awinlost]  
	  ,[mwinlost]  
	  ,[swinlost]  
	  ,[playercomm]  
	  ,[comm]  
	  ,[acomm]  
	  ,[scomm]  
	  ,[winlostvirtual]  
	  ,[commvirtual]  
	  ,[BetCount]  
	  ,[Currency]  
	  ,[sporttype]  
	  ,[bettype]  
	  ,[statusID]  
	  ,[isBA]  
	  ,[isMobile]  
	  ,[betfrom] 
	  ,[BuyBackAmt] 
	  ,[BABuyBackAmt]
			)  
	SELECT  
		@winlostdate  
	 ,c.username  
	 ,c.username2  
	 ,c.custid  
	 ,3 AS roleid  
	 ,0  
	 ,b.mrecommend  
	 ,b.srecommend  
		,SUM(turnover)  
		,SUM(winlost)  
	 ,SUM(BetEffective)  
		,SUM(awinlost)  
		,SUM(mwinlost)  
		,SUM(swinlost)  
		,SUM(playercomm)  
		,SUM(comm)  
		,SUM(acomm)  
		,SUM(scomm)  
		,SUM(winlostvirtual)  
		,SUM(commvirtual)  
		,SUM(BetCount)  
		,b.currency  
		,b.sporttype  
		,b.bettype  
		,b.statusID  
	 ,b.isBA  
	 ,b.isMobile  
	 ,b.betfrom
	 ,SUM(BuyBackAmt)  
	 ,SUM(BABuyBackAmt) 
	FROM  
		dbo.rptLicWinloss2 b (NOLOCK)  
		INNER JOIN bodb02.dbo.customer c (NOLOCK) ON b.mrecommend = c.custid  
	WHERE  
		b.winlostdate = @winlostdate  
		AND b.roleid = 1  
		AND c.roleid = 3  
	GROUP BY  
		c.username  
	 ,c.username2  
	 ,c.custid  
	 ,b.mrecommend  
	 ,b.srecommend  
		,b.currency  
		,b.sporttype  
		,b.bettype  
		,b.statusID  
	 ,b.isBA  
	 ,b.isMobile  
	 ,b.betfrom 	
  
	--Super Level (Sum on member)  
	INSERT INTO dbo.rptLicWinloss2  
			(  
			[winlostdate]  
	  ,[username]  
	  ,[username2]  
	  ,[custid]  
	  ,[roleid]  
	  ,[recommend]  
	  ,[mrecommend]  
	  ,[srecommend]  
	  ,[turnover]  
	  ,[winlost]  
	  ,[BetEffective]  
	  ,[awinlost]  
	  ,[mwinlost]  
	  ,[swinlost]  
	  ,[playercomm]  
	  ,[comm]  
	  ,[acomm]  
	  ,[scomm]  
	  ,[winlostvirtual]  
	  ,[commvirtual]  
	  ,[BetCount]  
	  ,[Currency]  
	  ,[sporttype]  
	  ,[bettype]  
	  ,[statusID]  
	  ,[isBA]  
	  ,[isMobile]  
	  ,[betfrom]  
	  ,[BuyBackAmt]
	  ,[BABuyBackAmt]	
			)  
	SELECT  
	 @winlostdate  
	 ,c.username  
	 ,c.username2  
	 ,c.custid  
	 ,4 AS roleid  
	 ,0  
	 ,0  
	 ,b.srecommend  
	 ,SUM(turnover)  
	 ,SUM(winlost)  
	 ,SUM(BetEffective)  
	 ,SUM(awinlost)  
	 ,SUM(mwinlost)  
	 ,SUM(swinlost)  
	 ,SUM(playercomm)  
	 ,SUM(comm)  
	 ,SUM(acomm)  
	 ,SUM(scomm)  
	 ,SUM(winlostvirtual)  
	 ,SUM(commvirtual)  
	 ,SUM(BetCount)  
	 ,b.currency  
	 ,b.sporttype  
	 ,b.bettype  
	 ,b.statusID  
	 ,b.isBA  
	 ,b.isMobile  
	 ,b.betfrom 
	 ,SUM(BuyBackAmt)
	 ,SUM(BABuyBackAmt) 
	FROM  
		dbo.rptLicWinloss2 b (nolock)  
		INNER join bodb02.dbo.customer c (nolock) ON b.srecommend = c.custid  
	WHERE  
		b.winlostdate = @winlostdate  
		and b.roleid = 1  
		and c.roleid = 4  
	GROUP BY  
		c.username  
	 ,c.username2  
	 ,c.custid  
	 ,b.srecommend  
		,b.currency  
		,b.sporttype  
		,b.bettype  
		,b.statusID  
	 ,b.isBA  
	 ,b.isMobile  
	 ,b.betfrom	
END
GRANT VIEW DEFINITION ON [dbo].[Task_DailyRptLicWinloss2_Bettrans] TO [vnteam] AS [dbo]
GO