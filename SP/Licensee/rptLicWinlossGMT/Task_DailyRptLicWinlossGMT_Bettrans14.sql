/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DailyRptLicWinlossGMT_Bettrans14] 
	@RptDate SMALLDATETIME 
AS  
/*  
	Created: 20171130@Sophia
	Task: Daily summary for RptLicWinlossGMT from bettrans14
	DB: DBLIC.bodb_LicenseeReport
	Revisions:  
	- 20171130@Sophia: initial data. Apply for Sportsbook first [redmine: #84932]
	
	EXEC Task_DailyRptLicWinlossGMT_Bettrans14 '2017-11-30'
*/  
BEGIN
	SET NOCOUNT ON
    
	DELETE FROM dbo.rptLicWinlossGMT WITH (ROWLOCK) WHERE RptDate = @RptDate 

	--Member Level  
	INSERT INTO dbo.rptLicWinlossGMT(  
		TimeZone
		,RptDate
		,RptDateGMT
		,Username
		,Username2
		,Custid
		,Roleid
		,Recommend
		,Mrecommend
		,Srecommend
		,Bettype
		,Sporttype
		,ProductId
		,Turnover
		,Winlost
		,AWinlost
		,MWinlost
		,SWinlost
		,BetEffective
		,playercomm
		,Comm
		,AComm
		,SComm		
		,WinlostVirtual
		,CommVirtual
		,BetCount
		,Currency
		,StatusID
		,IsBA
		,IsMobile
		,Betfrom
	  )  
	SELECT 
		8 AS TimeZone	
		,b.winlostdate    
		,CONVERT(DATE,DATEADD(HOUR, 12, ISNULL(m.GlobalShowTime,b.Winlostdate)))  
		,c.username  
		,c.username2  
		,c.custid  
		, 1  
		,c.recommend  
		,c.mrecommend  
		,c.srecommend 
		,0 AS Bettype
		,0 AS Sporttype
		,0 AS ProductId
		,SUM(ABS(b.stake)) AS TurnOver  
		,SUM(winlost-actual_stake) winlost  		
		,SUM(awinlost) awinlost  
		,SUM(mwinlost) mwinlost  
		,SUM(ISNULL(swinlost,0)) swinlost  
		,CASE WHEN b.statusID IN (112,113)   
			THEN SUM(ABS(winlost-actual_stake))   
			ELSE 0  
			END BetEffective   
		,SUM(playercomm) playercomm  
		,SUM(comm) comm  
		,SUM(acomm) acomm  
		,SUM(ISNULL(scomm,0)) scomm  
		,SUM((winlost - actual_stake)*virtualrate) AS WinlostVirtual  
		,SUM((comm)*virtualrate) AS CommVirtual  
		,COUNT(b.transid) BetCount  
		,b.currency  
		--114: half win, 115: half lose  
		,CASE   
			WHEN b.statusID = 112 AND b.bettype IN(1,3,7,8,17,18) AND ABS(modds) = 0.25 THEN 114   
			WHEN b.statusID = 113 AND b.bettype IN(1,3,7,8,17,18) AND ABS(modds) = 0.25 THEN 115  
			ELSE b.statusID END AS statusID  
		,CASE   
			WHEN BA.transid IS NULL THEN 0  
			WHEN BA.transid IS NOT NULL THEN 1 END AS isBA  
		,CASE   
			WHEN b.betfrom IN ('s','m','l','r') THEN 1 ELSE 0 END AS isMobile   
		,CASE      
			WHEN b.betfrom IN ('a','d','e','u','s','m','l','g','r','x','y','z') THEN b.betfrom ELSE '' END AS betfrom   		
	FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Match14 m WITH (NOLOCK)
			ON m.MatchId = b.MatchId
		INNER JOIN bodb02.dbo.Dep_CustSuper s WITH (NOLOCK) 
			ON b.srecommend = s.CustId
		INNER JOIN bodb02.dbo.customer c WITH (NOLOCK) 
			ON b.custid = c.custid
		LEFT JOIN bodb_Licensee.dbo.LicenseeBATransaction BA WITH (NOLOCK) 
			ON b.transid = BA.transid 	 
	WHERE  
			 b.Winlostdate = @RptDate   
			AND b.statusID IN (101,111,112,113)  --REJECT, DRAW, WON, LOSE  
			AND b.bettype <= 19999   
			AND c.roleid = 1 	 
			AND (
					b.bettype < 31
					OR b.bettype BETWEEN 121 AND 999
					OR b.Bettype BETWEEN 1301 and 1399 --new tennis's bettypes
				)
			AND (b.bettype < 901 OR b.bettype > 904)
			AND (b.bettype < 911 OR b.bettype > 914) 		 			 
			 
	GROUP BY 
		b.winlostdate
		,CONVERT(DATE,DATEADD(HOUR, 12, ISNULL(m.GlobalShowTime,b.Winlostdate)))
		,c.username  
		,c.username2  
		,c.custid 
		,c.recommend  
		,c.mrecommend  
		,c.srecommend 
		,b.currency  
		,b.StatusId
		--114: half win, 115: half lose  
		,CASE   
			WHEN b.statusID = 112 AND b.bettype IN(1,3,7,8,17,18) AND ABS(modds) = 0.25 THEN 114   
			WHEN b.statusID = 113 AND b.bettype IN(1,3,7,8,17,18) AND ABS(modds) = 0.25 THEN 115  
			ELSE b.statusID END  
		,CASE   
			WHEN BA.transid IS NULL THEN 0  
			WHEN BA.transid IS NOT NULL THEN 1 END  
		,CASE   
			WHEN b.betfrom IN ('s','m','l','r') THEN 1 ELSE 0 END  
		,CASE      
			WHEN b.betfrom IN ('a','d','e','u','s','m','l','g','r','x','y','z') THEN b.betfrom ELSE '' END   
			
	--- OPTION (MAXDOP 8)

	--Agent Level (sum on member)  
	INSERT INTO dbo.rptLicWinlossGMT (  
		TimeZone
		,RptDate
		,RptDateGMT
		,Username
		,Username2
		,Custid
		,Roleid
		,Recommend
		,Mrecommend
		,Srecommend
		,Bettype
		,Sporttype
		,ProductId
		,Turnover
		,Winlost
		,AWinlost
		,MWinlost
		,SWinlost
		,BetEffective
		,playercomm
		,Comm
		,AComm
		,SComm		
		,WinlostVirtual
		,CommVirtual
		,BetCount
		,Currency
		,StatusID
		,IsBA
		,IsMobile
		,Betfrom
	)  
	SELECT  
		b.TimeZone
		,b.RptDate
		,b.RptDateGMT
		,c.Username
		,c.Username2
		,c.Custid
		,2
		,b.Recommend
		,b.Mrecommend
		,b.Srecommend
		,b.Bettype
		,b.Sporttype
		,b.ProductId
		,SUM(b.Turnover)
		,SUM(b.Winlost)
		,SUM(b.AWinlost)
		,SUM(b.MWinlost)
		,SUM(b.SWinlost)
		,SUM(b.BetEffective)
		,SUM(b.playercomm)
		,SUM(b.Comm)
		,SUM(b.AComm)
		,SUM(b.SComm)	
		,SUM(b.WinlostVirtual)
		,SUM(b.CommVirtual)
		,SUM(b.BetCount)
		,b.Currency
		,b.StatusID
		,b.IsBA
		,b.IsMobile
		,b.Betfrom
	FROM  
		dbo.rptLicWinlossGMT b WITH (NOLOCK)  
		INNER JOIN bodb02.dbo.customer c (nolock) ON b.recommend = c.custid  
	WHERE  
		b.RptDate = @RptDate  
		and b.roleid = 1  
		and c.roleid = 2  
	GROUP BY
		b.TimeZone
		,b.RptDate
		,b.RptDateGMT
		,c.Username
		,c.Username2
		,c.Custid
		,b.Recommend
		,b.Mrecommend
		,b.Srecommend
		,b.Bettype
		,b.Sporttype
		,b.ProductId 
		,b.Currency
		,b.StatusID
		,b.IsBA
		,b.IsMobile
		,b.Betfrom
 
END
GO