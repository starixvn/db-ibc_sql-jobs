CREATE PROCEDURE [dbo].[Lrf_Verify_AGCasinoBalance] 
 @Date		SMALLDATETIME,   
 @excludeTest   BIT = 1
AS  

/*  Created: Winnie
	Date: 2015-02-05
    Task : AG balance report 
    DB: DBPTCS.bodb_PlaytechCS  
    Revisions:
	Param's Explanation:  
	  + @excludeTest: remove currency UUS
*/  
DECLARE @VNDCurrencyName VARCHAR(20)
DECLARE @minWinlostdate SMALLDATETIME
SELECT @minWinlostdate = MIN(winlostdate) FROM DBRPT.bodb_report.dbo.rptDepWinlost_Transfer3rdOthers WITH(NOLOCK)


	CREATE TABLE #TempData (
	LicenseeName VARCHAR(50),
	DATE		SMALLDATETIME,	
	Currency	TINYINT,
	Amount		MONEY,
	TransferIn	MONEY,
	TransferOut	MONEY,	
	ExpectedClosingBalance MONEY
)
	
		CREATE TABLE #tmpResult (Winlostdate DATETIME
							 ,Custid		  INT
							 ,Currency 		  INT
							 ,TurnOver 		  MONEY
							 ,TotalTrans	  INT	
							 ,Winlost  		  MONEY
							 ,LicenseeWinlost MONEY
							 ,PRIMARY KEY(Winlostdate,Currency,Custid)
							)

SELECT DISTINCT a.CustID,a.Currency,b.LicenseeName
INTO #temp
FROM bodb_licensee.dbo.f_SelLicenseeCust(0) a
INNER JOIN LicIntegrationSetting  b
ON a.LicenseeID=b.LicenseeId
WHERE b.AllowApiBalance=1 AND (@excludeTest=0 OR (@excludeTest=1 AND a.Currency <> 20))	


	SELECT  co.CustID,lc.Currency,lc.LicenseeName 
	INTO #tmpCust 
	FROM bodb02.dbo.Custinfo co WITH (NOLOCK)		
		INNER JOIN 	#temp lc   ON co.recommend = lc.CustId AND lc.Currency = co.Currency
		INNER JOIN [dbo].[BalanceAGCasino] d WITH ( NOLOCK) ON co.custid=d.CustId
	WHERE  (@excludeTest=0 OR (@excludeTest=1 AND lc.Currency <> 20))	
	AND d.WinlostDate =@Date



	SELECT @VNDCurrencyName = currency 
	FROM  bodb02.dbo.Exchange WITH (NOLOCK) 
	WHERE ExchangeId = 51

	SELECT ExchangeDate
		   ,ExchangeId
		   ,Code
		   ,USD
		   ,EUR
		   ,GBP
	INTO #TempExchange 
	FROM bodb02.dbo.Lrf_f_GetExchangeDaily(@Date, @Date)
	WHERE exchangeid IN (SELECT DISTINCT Currency from #tmpCust) 

	
	INSERT INTO #tmpResult (Winlostdate
							, CustId 
							 ,Currency 	
							 ,TurnOver 	
							 ,TotalTrans
							 ,Winlost  	
							 ,LicenseeWinlost 
							)

	SELECT c.Winlostdate
			,ct.CustId
		   ,ct.Currency
		   ,SUM(c.TurnOver) AS TurnOver
		   ,SUM(c.BetCount) AS TotalTrans
		   ,SUM(c.Winlost)  AS Winlost
		   ,-SUM(c.Winlost) AS LicenseeWinlost
	FROM  DBRPT.bodb_report.dbo.rptDepWinlost_AGCasino c  WITH (NOLOCK)
		INNER JOIN #tmpCust ct ON c.CustID = ct.CustID AND c.Currency = ct.Currency
	WHERE c.Winlostdate BETWEEN @Date AND @Date 
	GROUP BY c.Winlostdate	
		    ,ct.Currency	
			,ct.CustId


	--get balance
;WITH Calender AS 
(
    SELECT   @Date AS CalanderDate    
)

SELECT [Date] = CONVERT(VARCHAR(10),CalanderDate,120),b.Currency 
INTO #TempDate
FROM Calender ,(SELECT DISTINCT Currency from #tmpCust) AS b
OPTION (MAXRECURSION 0)
IF(@Date>=@minWinlostdate)--get from transfer3rdOthers
BEGIN
INSERT INTO #TempData( LicenseeName ,DATE,	Currency,Amount,TransferIn,	TransferOut,ExpectedClosingBalance)	
SELECT LicenseeName,a.[Date],
a.currency,SUM(ISNULL(t.WinLost,0)) AS Amount,SUM(ISNULL(r.TransferIn,0)) AS TransferIn ,SUM(ABS(ISNULL(r.TransferOut,0))) AS TransferOut,
SUM(ISNULL(b.ClosingBalance,0)) AS ExpectedClosingBalance

FROM #TempDate a
LEFT JOIN BalanceAGCasino b WITH (NOLOCK) ON a.[Date]=b.WinlostDate AND a.currency=b.Currency 
LEFT JOIN #tmpResult t   on  a.[Date]=t.WinlostDate AND a.currency=t.Currency AND b.CustId=t.CustId
LEFT JOIN DBRPT.bodb_report.dbo.rptDepWinlost_Transfer3rdOthers r WITH (NOLOCK)  ON a.currency=r.currency AND a.Date=r.[winlostdate] AND b.CustId=r.CustId AND r.[PartnerId]=3
INNER JOIN #tmpCust ct ON b.CustID = ct.CustID --AND b.Currency = ct.Currency
WHERE a.Date=@Date 
GROUP BY a.[Date]
,a.currency
,ct.LicenseeName


END
ELSE ---get from transfer3rdOthers_bk
BEGIN
INSERT INTO #TempData(LicenseeName,DATE,	Currency,Amount,TransferIn,	TransferOut,ExpectedClosingBalance)	
SELECT LicenseeName,a.[Date],
a.currency,SUM(ISNULL(t.Winlost,0)) AS Amount,SUM(ISNULL(r.TransferIn,0)) AS TransferIn ,SUM(ABS(ISNULL(r.TransferOut,0))) AS TransferOut,
SUM(ISNULL(b.ClosingBalance,0)) AS ExpectedClosingBalance

FROM #TempDate a
LEFT JOIN BalanceAGCasino b WITH (NOLOCK) ON a.[Date]=b.WinlostDate AND a.currency=b.Currency 
LEFT JOIN #tmpResult t  on  a.[Date]=t.WinlostDate AND a.currency=t.Currency AND b.CustId=t.CustId
LEFT JOIN DBRPT.bodb_report.dbo.rptDepWinlost_Transfer3rdOthers_bk r WITH (NOLOCK)  ON a.currency=r.currency AND a.Date=r.[winlostdate] AND b.CustId=r.CustId AND r.[PartnerId]=3
INNER JOIN #tmpCust ct ON b.CustID = ct.CustID AND b.Currency = ct.Currency
WHERE a.Date =@Date 
GROUP BY a.[Date]
,a.currency
,ct.LicenseeName

END 
;WITH CTE
AS
(
SELECT c.LicenseeName,c.date ,c.currency
,CASE WHEN c.currency=51  THEN  @VNDCurrencyName
				 ELSE e.Code 
				 END CurrencyName,	
ISNULL(
(SELECT TOP 1 SUM(ISNULL(m.ClosingBalance,0)) FROM BalanceAGCasino m  WITH (NOLOCK)  WHERE m.WinlostDate<@Date AND m.Currency=c.Currency GROUP BY m.winlostdate  ORDER BY  m.winlostdate  desc),
--0
(SELECT TOP 1 SUM(ISNULL(m.OpeningBalance,0)) FROM BalanceAGCasino m WITH (NOLOCK) WHERE m.WinlostDate=@Date AND m.Currency=c.Currency GROUP BY m.winlostdate)
) AS OpeningBalance,
c.TransferIn  ,c.TransferOut TransferOut,
ISNULL(
(SELECT TOP 1 SUM(ISNULL(m.ClosingBalance,0)) FROM BalanceAGCasino m  WITH (NOLOCK)  WHERE m.WinlostDate<@Date AND m.Currency=c.Currency GROUP BY m.winlostdate  ORDER BY  m.winlostdate  desc),
--0
(SELECT TOP 1 SUM(ISNULL(m.OpeningBalance,0)) FROM BalanceAGCasino m WITH (NOLOCK) WHERE m.WinlostDate=@Date AND m.Currency=c.Currency GROUP BY m.winlostdate)
)
+ c.TransferIn - c.TransferOut +c.Amount AS ClosingBalance,
c.ExpectedClosingBalance,c.Amount AS Winloss
 from #TempData c  
 LEFT JOIN #TempExchange e ON c.currency = e.ExchangeId
WHERE c.Date= @Date   -- get for startdate
--
)
SELECT * FROM CTE

	DROP TABLE #TempDate
	DROP TABLE #TempData


	---------

	DROP TABLE #tmpCust
	DROP TABLE #TempExchange

