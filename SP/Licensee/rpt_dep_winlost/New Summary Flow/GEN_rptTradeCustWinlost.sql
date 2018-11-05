/*<info serverAlias="DBRPT-bodb_report" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_Report]
GO

ALTER PROCEDURE [dbo].[GEN_rptTradeCustWinlost]	
AS
/*
	Created: 20170726@Sophia
    Task :  Gen data for Trade cust - Cash out product
    DB: DBRPT/bodb_report    

    Revisions:  
		- 20170726@Sophia: Add new SP [RedmineID: #79346]
		- 20170815@Sophia: Regen data BETWEEN MoveBetDays - 3 AND <= MoveBetDays  [Redmine :#81411]
		- 20181031@Percy: Remove linked-server DBLIC [RedmineID: #103660]

	Explanation:   

*/
BEGIN 
SET NOCOUNT ON 

	DECLARE @DateFrom SMALLDATETIME, @DateTo SMALLDATETIME, @MoveBetsDay SMALLDATETIME
	
	SELECT  @MoveBetsDay = MAX(eventdate) 
	FROM bodb02.dbo.match14 WITH(NOLOCK)
			
	SELECT @DateFrom = DATEADD (DD, -3,  @MoveBetsDay) 
	SELECT @DateTo = @MoveBetsDay 

	----Gen data for move bet days
	DELETE dbo.rptTradeCustWinlost WITH (ROWLOCK, UPDLOCK) WHERE Winlostdate BETWEEN @DateFrom AND @DateTo

	INSERT INTO dbo.rptTradeCustWinlost (Winlostdate, CustID, Winloss, VendorID)
	SELECT	b.Winlostdate, b.custid, SUM(b.winlost) AS Winloss, t.VendorID
	FROM 	bodb_LicenseeReport.dbo.rptLicWinloss2 b WITH(NOLOCK)
		INNER JOIN bodb02.dbo.TradeCust t WITH (NOLOCK) ON b.custid = t.CustID
	WHERE 	b.winlostdate BETWEEN @DateFrom AND @DateTo
			AND b.RoleID = 1 										 									
			AND b.Sporttype = 0
			AND b.bettype IN (913, 914)
			AND (b.statusID < 101 OR b.statusID > 103)  
	GROUP BY b.Winlostdate, b.custid, t.VendorID
END
GO 