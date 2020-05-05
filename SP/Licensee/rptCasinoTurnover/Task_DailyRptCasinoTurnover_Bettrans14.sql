/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_DailyRptCasinoTurnover_Bettrans14]
	@winlostdate DATETIME
AS
/*
Created:20181129@Joseph
Task: daily summary for casino turnover
DB: DBLIC.bodb_LicenseeReport
Revisions:
	- 20181129@Joseph: Create [Redmine: #95178]
	- 20200423@Hogan: Add new product Sexy Gaming [RedmineID: #132829]
*/  
BEGIN
	SET NOCOUNT ON
    
	DELETE FROM dbo.rptCasinoTurnover WITH (rowlock) WHERE winlostdate = @winlostdate  	

	INSERT INTO dbo.rptCasinoTurnover(  
	 [WinlostDate]
      ,[CustId]
      ,[Recommend]
      ,[ProductId]
      ,[StatusId]
      ,[Currency]
      ,[BetCount]
      ,[Turnover]
      ,[Winlost]
      ,[ValidBetAmount]
	  )  
	( 
		-- RNG Casino and Macau Games
		SELECT @winlostdate  
	   ,bettrans.custid  
	   ,bettrans.recommend
	   ,p3rd.ProductID
	   ,bettrans.statusID
	   ,bettrans.currency 
	   ,COUNT(bettrans.transid) AS BetCount  
		,SUM(bettrans.stake) AS Turnover
		,SUM(bettrans.winlost-bettrans.actual_stake) AS  winlost  
		,SUM(bettrans.stake) AS ValidBetAmount 
		FROM
			bodb02.dbo.bettransRnG14 bettrans WITH (NOLOCK)
			INNER JOIN bodb02.dbo.SportBettypeMatrix matrix WITH(NOLOCK) ON bettrans.gameid = matrix.bettype
			INNER JOIN bodb02.dbo.Products p WITH(NOLOCK) ON p.ProductID = matrix.productId
			INNER JOIN bodb_licensee.dbo.product3rd p3rd WITH (NOLOCK) ON p.ProductPrefix = p3rd.ProductPrefix
		WHERE
			bettrans.winlostdate = @winlostdate AND
			bettrans.statusID IN (111,112,113) AND -- DRAW, WON, LOSE
			matrix.ProductID IN (6, 22) -- RNG Casino, Macau Games
		GROUP BY
			bettrans.custid
			,bettrans.recommend
			,p3rd.ProductID
			,bettrans.statusID
			,bettrans.currency
		
		UNION ALL

		-- All Bet
		SELECT @winlostdate  
		,bettrans.custid  
		,bettrans.recommend
		,p3rd.ProductID
		,bettrans.statusID
		,bettrans.currency 
		,COUNT(bettrans.transid) AS BetCount  
		,SUM(bettrans.stake) AS Turnover
		,SUM(bettrans.winlost-bettrans.actual_stake) AS  winlost  
		,SUM(ISNULL(bettrans.netstake, 0)) AS ValidBetAmount 
		FROM
			bodb02.dbo.bettransLC14 bettrans WITH (NOLOCK)
			INNER JOIN bodb02.dbo.SportBettypeMatrix matrix WITH(NOLOCK) ON bettrans.gameid = matrix.bettype
			INNER JOIN bodb02.dbo.Products p WITH(NOLOCK) ON p.ProductID = matrix.productId
			INNER JOIN bodb_licensee.dbo.product3rd p3rd WITH (NOLOCK) ON p.ProductPrefix = p3rd.ProductPrefix
		WHERE
			bettrans.winlostdate = @winlostdate AND
			bettrans.statusID IN (111,112,113) AND -- DRAW, WON, LOSE
			matrix.ProductID IN (21,45) -- AllBet
		GROUP BY
			bettrans.custid
			,bettrans.recommend
			,p3rd.ProductID
			,bettrans.statusID
			,bettrans.currency
	)
	
END
GO
