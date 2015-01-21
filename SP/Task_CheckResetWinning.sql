USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_CheckResetWinning]    Script Date: 01/20/2015 23:51:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_CheckResetWinning]
	@winlostdate	DATETIME
AS

/*	
	Created: 20120605@Jamie
	Task: Reset Winning - Get data by Date 
	DB: DB052.BODB02
	
	Revision:
		
	Explanation's Param:

*/
BEGIN	
	SET NOCOUNT ON	
		
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED

	DECLARE @dummyBalance TABLE (custid INT, product VARCHAR(50))
	DECLARE	@totalBalance MONEY 

	
	INSERT INTO @dummyBalance 
			  SELECT	6911909	, 'SPL'			---- DWLSPL
	UNION ALL SELECT	6911911	, 'SPNL'		---- DWLSPNL
	UNION ALL SELECT	6911913	, 'Parlay'		---- DWLParlay
	UNION ALL SELECT	6911914	, 'Outright'	---- DWLOutright
	UNION ALL SELECT	6911916	, 'Casino'		---- DWLCasino
	UNION ALL SELECT	6911917	, 'Live Casino' ---- DWLLiveCasino
	UNION ALL SELECT	6911918	, 'Number Game' ---- DWLNumber
	UNION ALL SELECT	6911919	, 'Racing'		---- DWLRacing
	UNION ALL SELECT	6911920	, 'P2P'			---- DWLP2P
	UNION ALL SELECT	6913085	, 'Bingo'		---- DWLBingo

	DECLARE @Winning TABLE 
			(
				product VARCHAR(50),
				winlost MONEY					
			)	
	
	CREATE TABLE #source (custid int, bettype INT,statusid int, liveindicator BIT, winlost MONEY)
	INSERT INTO #source
	SELECT CASE WHEN custid IN (6911909,6911911,6911913,6911914,6911916,6911917,6911918,
									6911919,6911920,6913085	
				) THEN custid
				ELSE 0 END AS custid, bettype, statusid, liveindicator,
		ISNULL(SUM((winlost-actual_stake + awinlost + mwinlost + swinlost + scomm)*actualrate),0) AS winlost
	FROM bettrans WITH(NOLOCK)
	WHERE	winlostdate = @winlostdate  and ruben = 1 
		    AND statusid NOT IN (101,102,103,121)

	GROUP BY bettype, statusid, liveindicator,
		CASE WHEN custid IN (6911909,6911911,6911913,
							6911914,6911916,6911917,
							6911918,6911919,6911920,6913085	)	
			THEN custid ELSE 0 END

	---- get total balance
	SELECT @totalBalance = ISNULL(SUM(winlost),0)
	FROM #source
	WHERE custid NOT IN (SELECT custid FROM @dummyBalance)		

	INSERT INTO @Winning(product,winlost)

	---- sportsbook live & non-live
	SELECT CASE WHEN liveindicator = 1 THEN 'SPL'
				WHEN liveindicator = 0 THEN 'SPNL'
				ELSE '' ---- what the hell is it ?
			END AS Product,
			ISNULL(SUM(winlost),0) as winlost
	FROM #source
	WHERE bettype <= 999 AND bettype NOT IN (9,10,29,31,32,33,71,73) AND bettype NOT BETWEEN 81 AND 120
		AND statusid NOT IN (101,102,103,121)
	GROUP BY liveindicator 
	
	UNION ALL	
	SELECT CASE	WHEN bettype BETWEEN 31 AND 33 THEN 'Racing'
				WHEN bettype BETWEEN 81 AND 120 THEN 'Number Game'	
				WHEN bettype BETWEEN 1101 AND 1199 THEN 'Live Casino'
				WHEN bettype = 71 THEN 'Casino'
				WHEN bettype = 73 THEN 'Bingo'
				WHEN bettype = 1000 THEN 'P2P'
				WHEN bettype = 10 THEN 'Outright'
				WHEN bettype IN (9,29) THEN 'Parlay'
			END AS Product,
			ISNULL(SUM(winlost),0) as winlost
	FROM #source
	WHERE ( bettype BETWEEN 1101 AND 1199
			OR bettype BETWEEN 31 AND 33
			OR bettype BETWEEN 80 AND 120
			OR bettype IN (71,73,10,1000,9,29)			
			)
			AND statusid NOT IN (101,102,103,121)
	GROUP BY CASE	WHEN bettype BETWEEN 31 AND 33 THEN 'Racing'
				WHEN bettype BETWEEN 81 AND 120 THEN 'Number Game'	
				WHEN bettype BETWEEN 1101 AND 1199 THEN 'Live Casino'
				WHEN bettype = 71 THEN 'Casino'
				WHEN bettype = 73 THEN 'Bingo'
				WHEN bettype = 1000 THEN 'P2P'
				WHEN bettype = 10 THEN 'Outright'
				WHEN bettype IN (9,29) THEN 'Parlay'
			END	

	DECLARE	@tmpSUM TABLE (
		Product		VARCHAR(50),
		Winlost		MONEY,
		Reset		MONEY,
		Variance	MONEY

	)
	DECLARE	@totalWinLost MONEY ,
			@otherWinlost MONEY,
			@Message	  VARCHAR(8000),
			@ProductList  VARCHAR(7500)

	SELECT	@totalWinLost =0,
			@otherWinlost =0,
			@Message = '',
			@ProductList=''
	----- calculate reset

	
	;WITH rs AS
	(
		SELECT dm.Product,ISNULL(SUM(winlost),0) AS reset
		FROM #source b
			INNER JOIN @dummyBalance dm ON b.custid = dm.custid
		WHERE bettype > 20000
		GROUP BY b.custid, dm.product
	)
	INSERT INTO @tmpSUM (Product, Winlost, Reset, Variance)	
	SELECT  dm.product, ISNULL(w.winlost,0) AS winlost, ISNULL(rs.reset,0) AS reset, ROUND((ISNULL(w.winlost,0) + ISNULL(rs.reset,0)),2) AS Variance
	
	FROM @winning w	
		FULL OUTER JOIN rs rs ON w.product = rs.product
		RIGHT JOIN @dummyBalance dm ON dm.product = ISNULL(w.product, rs.product)

	SELECT * 
	FROM @tmpSUM

	SELECT	@totalWinLost = ISNULL(SUM(Winlost),0) 
	FROM	@tmpSUM

	SELECT	@otherWinlost = ROUND((@totalBalance - ISNULL(@totalWinLost,0)),2)

	SELECT	@ProductList = @ProductList + CAST ( Product AS VARCHAR(20)) +','
	FROM	@tmpSUM
	WHERE	Variance <> 0 

	
	
	IF 	@ProductList<>''
	BEGIN
		SELECT	@Message = @Message + ' Reset Winning Problem on:' + @ProductList + '. Please have a check!'	
	END

	IF  ABS(@otherWinlost) > 1.5 
		SELECT	@Message = @Message + ' Reset Winning is not ZERO with Other Amount:' + CAST ( @otherWinlost AS VARCHAR(30)) + '. Please have a check!'

	SELECT	@ProductList AS ProductList,
			@otherWinlost AS OtherWL, 
			@totalBalance AS TotalBalance, 
			@Message AS Message 
	
	IF @Message<>''
		RAISERROR(@Message,16,1)
		
	
	DROP TABLE #source
END



GO

GRANT VIEW DEFINITION ON [dbo].[Task_CheckResetWinning] TO [vnteam] AS [dbo]
GO


