USE [LASDB]
GO

/****** Object:  StoredProcedure [dbo].[Task_GENData_rptLASWinlost_bettrans14]    Script Date: 01/27/2015 03:58:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_GENData_rptLASWinlost_bettrans14    Script Date: 8/14/2014 3:53:15 PM ******/

CREATE PROCEDURE [dbo].[Task_GENData_rptLASWinlost_bettrans14]
	@winlostdate DATE
AS

/*	Creator: Victor
	Task : Summary data to rptLASWinlost & rptLASWinlost_Agent
	DB: DBLAS.LASDB
	Date: 2014-03-19
		             
	Param's Explanation:
	• @winlostdate: The date need to summary
	
	Revisions:	
		- 20140522@Victor: Outstanding must be zero in the past
		- 20140522@Victor: Get Tranfer data in bettrans instead of bettrans14
		- 20140527@Victor: Turnover formula must based on Stake amount
		- 20140804@Victor: Support Legend Cash model
*/

DECLARE @date datetime
SELECT @date = @winlostdate  
  
DECLARE @Today SMALLDATETIME
SELECT @Today = DATEADD(dd, DATEDIFF(d, 0, CURRENT_TIMESTAMP), 0)

CREATE TABLE #StatementData (
	CustId INT,
	Turnover MONEY,
	Outstanding MONEY,
	WLAmt MONEY,
	CommAmt MONEY,
	TransferAmt MONEY,
	Deposit MONEY,
	Withdrawal MONEY,
	Adjustment MONEY,
	Bonus MONEY,
	Transfer3rd MONEY
	
)

IF @date >= DATEADD(dd, DATEDIFF(d, 0, CURRENT_TIMESTAMP)-1, 0) --yesterday
BEGIN
	UPDATE dbo.SystemSettings
	SET vvalue = '1'
	WHERE vname = 'isCalculatingDEPdata'
END

-- rptLASWinlost (member)
INSERT INTO #StatementData (CustId, Turnover, Outstanding, WLAmt, CommAmt, TransferAmt, Deposit, Withdrawal, Adjustment, Bonus, Transfer3rd)
SELECT b.CustId, 
	SUM(CASE WHEN BetType < 19001 THEN Stake ELSE 0 END) as Turnover, -- Turnover
	SUM(CASE WHEN bettype < 19001 AND ruben = 0 THEN Actual_Stake ELSE 0 END), -- Outstanding
	SUM(CASE WHEN BetType < 19001 AND ruben = 1 THEN WinLost - Actual_Stake ELSE 0 END) as WL, -- Winlost
	SUM(CASE WHEN bettype < 19001 AND Ruben = 1 THEN PlayerComm ELSE 0 END) AS Comm, -- Comm
	0, 0, 0, 0, 0, 0 -- TransferAmt, Deposit, Withdrawal, Adjustment, Bonus, Transfer3rd	
FROM dbo.bettrans14 b WITH(ROWLOCK)
WHERE b.WinLostDate = @date
	AND EXISTS (SELECT 1 FROM dbo.CustInfo c (NOLOCK) WHERE c.CustId = b.CustId)
GROUP BY b.CustID

-- member's transfer tickets
MERGE #StatementData as dest
USING (	SELECT custid, SUM(winlost - actual_Stake) AS TransferAmt, 
			SUM(CASE WHEN bettype = 22001 THEN b.WinLost - b.Actual_Stake ELSE 0 END) AS Deposit, -- Deposit
			SUM(CASE WHEN bettype IN (22002,22003) THEN b.WinLost - b.Actual_Stake ELSE 0 END) AS Withdrawal, -- Withdrawal
			SUM(CASE WHEN bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN b.WinLost - b.Actual_Stake ELSE 0 END) AS Adjustment, -- Adjustment
			SUM(CASE WHEN bettype = 22004 THEN b.WinLost - b.Actual_Stake ELSE 0 END) AS Bonus, -- Bonus
			SUM(CASE WHEN bettype IN (22006,22007) THEN b.WinLost - b.Actual_Stake ELSE 0 END) AS Transfer3rd -- Transfer3rd
		FROM LASDB.dbo.bettrans b WITH (ROWLOCK) 
		WHERE EXISTS (SELECT 1 FROM dbo.CustInfo c (NOLOCK) WHERE c.CustId = b.CustId)
			AND bettype > 20000 AND ruben = 1
			AND Winlostdate = @date
		GROUP BY custid)
AS src (custid, TransferAmt, Deposit, Withdrawal, Adjustment, Bonus, Transfer3rd)
ON src.custid = dest.custid
WHEN MATCHED THEN
	UPDATE SET dest.TransferAmt = src.TransferAmt,
				dest.Deposit = src.Deposit,
				dest.Withdrawal = src.Withdrawal,
				dest.Adjustment = src.Adjustment,
				dest.Bonus = src.Bonus,
				dest.Transfer3rd = src.Transfer3rd
WHEN NOT MATCHED THEN
	INSERT (CustId,Turnover,Outstanding,WLAmt,CommAmt,TransferAmt,Deposit,Withdrawal,Adjustment,Bonus,Transfer3rd)
	VALUES(src.custid, 0,0,0,0,src.transferAmt,src.Deposit,src.Withdrawal,src.Adjustment,src.Bonus,src.Transfer3rd);


---- Update data to rptLASWinlost
DELETE FROM #StatementData WHERE Turnover = 0 AND Outstanding = 0 AND WLAmt = 0 AND CommAmt = 0 AND TransferAmt = 0
								AND Deposit = 0 AND Withdrawal = 0 AND Adjustment = 0 AND Bonus = 0 AND Transfer3rd = 0

DELETE FROM SummaryLasDB.dbo.rptLASWinlost WHERE WinlostDate = @winlostdate

INSERT INTO SummaryLasDB.dbo.rptLASWinlost (WinlostDate, CustID, Turnover, Outstanding, Winloss, Commission, TransferAmt, Deposit, Withdrawal, Adjustment, Bonus, Transfer3rd)
SELECT @winlostdate, CustID, a.Turnover, a.Outstanding, a.WLAmt, a.CommAmt, a.TransferAmt, a.Deposit, a.Withdrawal, a.Adjustment, a.Bonus, a.Transfer3rd 
FROM #StatementData a 

-- rptLASWinlost_Agent
TRUNCATE TABLE #StatementData

---- Licensee WL & Comm
INSERT INTO #StatementData (CustId, Turnover, Outstanding, WLAmt, CommAmt, TransferAmt)
SELECT b2.recommend, 0, 0, SUM(-(b.WinLost - b.Actual_Stake)*(1-b.TPositionTaking)) as WL, SUM(-b.TComm)  AS Comm, 0
FROM dbo.bettrans14 b WITH(ROWLOCK)
	INNER JOIN bodb02.dbo.bettrans14 b2 WITH(NOLOCK) ON b2.transid = b.TransId
WHERE b.BetType < 19001 AND b.Ruben = 1 AND b.WinLostDate = @winlostdate
	AND EXISTS (SELECT 1 FROM dbo.CustInfo c (NOLOCK) WHERE c.CustId = b.CustId)
GROUP BY b2.recommend

---- AgentN WL & Comm
INSERT INTO #StatementData (CustId, Turnover, Outstanding, WLAmt, CommAmt, TransferAmt)
SELECT c.AgentId, 0, 0, SUM(ba.AWinLost) as WL, SUM(ba.AComm - b.PlayerComm) AS Comm, 0
FROM dbo.bettrans14 b WITH(ROWLOCK)
	INNER JOIN dbo.bettrans14_Agent ba WITH(ROWLOCK) ON ba.TransID = b.TransId
	INNER JOIN dbo.CustInfo c ON c.AgentId = ba.AgentId
WHERE b.BetType < 19001 AND b.Ruben = 1 AND b.WinLostDate = @winlostdate
GROUP BY c.AgentId

---- AgentK WL & Comm
CREATE TABLE #AgentKList (AgentID INT, ParentID INT) 

INSERT INTO #AgentKList (AgentID, ParentID)
SELECT A.AgentID, PA.AgentID ParentId
FROM dbo.AgentInfo A WITH(NOLOCK)
	INNER JOIN dbo.AgentInfo PA WITH(NOLOCK) ON PA.AgentHId = A.AgentHId.GetAncestor(1)
WHERE A.AgentLevel > 2

INSERT INTO #StatementData (CustId, Turnover, Outstanding, WLAmt, CommAmt, TransferAmt)
SELECT bp.AgentId, 0, 0, SUM(bp.AWinLost) as WL, SUM(bp.AComm - ba.AComm) AS Comm, 0
FROM dbo.bettrans14_Agent bp WITH(ROWLOCK)
	INNER JOIN #AgentKList A WITH (NOLOCK) ON A.ParentID = BP.AgentId
	INNER JOIN dbo.bettrans14_Agent ba WITH(ROWLOCK) ON ba.TransId = bp.TransId AND ba.AgentId = A.AgentID
WHERE bp.BetType < 19001 AND bp.WinLostDate = @winlostdate AND bp.StatusId NOT IN (0,1)
GROUP BY BP.AgentId

DROP TABLE #AgentKList

---- Agent Transfer
MERGE #StatementData AS dest
USING (SELECT b.CustId, 
			SUM(b.WinLost - b.Actual_Stake) AS TransferAmt
		FROM dbo.bettrans b WITH (ROWLOCK)
		WHERE bettype > 20000 
			AND b.Ruben = 1
			AND EXISTS (SELECT 1 FROM AgentInfo A WITH(NOLOCK) WHERE A.AgentId = b.CustId)
			AND b.WinLostDate = @Winlostdate
		GROUP BY b.CustId)
		AS src (CustId, TransferAmt)
		ON (dest.CustId = src.CustId)
WHEN MATCHED THEN
	UPDATE SET dest.TransferAmt = src.TransferAmt
WHEN NOT MATCHED THEN
	INSERT (CustId, Turnover, Outstanding, WLAmt, CommAmt, TransferAmt)
	VALUES (src.CustID, 0, 0, 0, 0, src.TransferAmt);

---- Update data to rptLASWinlost_Agent
DELETE FROM #StatementData WHERE WLAmt = 0 AND CommAmt = 0 AND TransferAmt = 0

DELETE FROM SummaryLasDB.dbo.rptLASWinlost_Agent WHERE WinlostDate = @winlostdate

INSERT INTO SummaryLasDB.dbo.rptLASWinlost_Agent (Winlostdate, AgentID, Winloss, Commission, TransferAmt)
SELECT @winlostdate, a.CustID, a.WLAmt, a.CommAmt, a.TransferAmt 
FROM #StatementData a 

DROP TABLE #StatementData

UPDATE dbo.SystemSettings
SET vvalue = '0'
WHERE vname = 'isCalculatingDEPdata'
GO


