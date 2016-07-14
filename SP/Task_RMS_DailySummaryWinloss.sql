USE [bodb_RMS]
GO

/****** Object:  StoredProcedure [dbo].[Task_RMS_DailySummaryWinloss]    Script Date: 01/27/2015 04:26:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_RMS_DailySummaryWinloss]
	@winlostdate	DATETIME,
	@ErrCode		INT = 0				OUTPUT,
	@ErrMsg			VARCHAR(1000) = ''	OUTPUT 
AS
	/*
		Created: Johnson
		Date: 2012-11-01
		Task: Copy won parlay tickets into RMS
		DB: DBRMS/bodb_RMS
		
		Revisions:
			- 20130124@Johnson: get data from rmTransaction_BK instead rmTransaction
			- 20130227@Jamie: Check tickets on rmTransaction before SUM
			- 20130228@Jamie: Get data from bettrans14 directly
			- 20130814@Johnson: import data into rmSumWinloss2
			- 20130918@Johnson: change to use table rmSumWinloss instead of rmSumWinloss2
			- 20130924@Johnson: add column recommend into rmSumWinloss
			- 20160510@Winnie: Add combo parlay
		Parameter's Explanation:
	*/
SET NOCOUNT ON
	
	IF NOT EXISTS (SELECT top 1 1 FROM bodb02.dbo.bettrans14 WITH(NOLOCK) WHERE bettype IN(9,29) AND matchid IN(9,29)  AND winlostdate = @winlostdate)
	BEGIN
		SELECT	 @ErrMsg= 'WARNING:Data is not moved to bettrans14.'
				,@ErrCode = 101
		RETURN
	END
	
	IF EXISTS (SELECT top 1 1 FROM bodb02.dbo.bettrans WITH(NOLOCK) WHERE bettype IN(9,29)  AND matchid IN(9,29)  AND winlostdate = @winlostdate)
	BEGIN
		SELECT	 @ErrMsg= 'WARNING:Data is still in bettrans.'
				,@ErrCode = 102
		RETURN
	END
	CREATE TABLE  #TemprmSumWinloss(
	[winlostdate] [smalldatetime] NOT NULL,
	[custid] [int] NOT NULL,
	[sporttype] [tinyint] NULL,
	[statusid] [tinyint] NOT NULL,
	[combo] [tinyint] NOT NULL,
	[username] [varchar](30) NOT NULL,
	[currency] [tinyint] NULL,
	[stake] [money] NULL,
	[winlost] [money] NULL,
	[company_stake] [money] NULL,
	[company_winlost] [money] NULL,
	[actualrate] [float] NULL,
	[odds] [smallmoney] NULL,
	[betcount] [int] NULL,
	[recommend] [int] NULL,
	ParlayType [tinyint] NULL	
	)
	CREATE TABLE #tmpbettrans(
	Transid BIGINT NOT NULL PRIMARY KEY,
	[winlostdate] [smalldatetime] NOT NULL,
	[custid] [int] NOT NULL,
	[statusid] [tinyint] NOT NULL,	
	[username] [varchar](30) NOT NULL,
	[currency] [tinyint] NULL,
	[stake] [money] NULL,
	[winlost] [money] NULL,
	[actualrate] [float] NULL,
	[odds] [smallmoney] NULL,	
	[recommend] [int] NULL,
	bettype SMALLINT NULL,
	tpositiontaking SMALLMONEY NULL,
	hdp2 SMALLMONEY NULL,
	betcheck NVARCHAR(50) NULL,
	transid2 BIGINT NULL,
	modds   SMALLMONEY NULL,
	betteam NVARCHAR(10) NULL,
	refno BIGINT NOT NULL,
	matchId INT NULL,
	)
	IF NOT EXISTS (SELECT TOP 1 1 FROM rmSumWinloss WITH(NOLOCK) WHERE winlostdate = @winlostdate)
	BEGIN
	INSERT INTO #tmpbettrans(
	Transid ,
	[winlostdate] ,
	[custid] ,	
	[statusid] ,	
	[username],
	[currency],
	[stake] ,
	[winlost] ,	
	[actualrate],
	[odds] ,
	[recommend] ,
	bettype,
	tpositiontaking ,
	hdp2 ,
	betcheck,
	modds,
	betteam,
	refno,
	matchId
	)
	SELECT
	Transid ,
	[winlostdate] ,
	[custid] ,	
	[statusid] ,	
	[username],
	[currency],
	[stake] ,
	[winlost] ,	
	[actualrate],
	[odds] ,	
	[recommend] ,
	bettype,
	tpositiontaking ,
	hdp2 ,
	betcheck,
	modds,
	betteam,
	refno,
	matchId
	FROM
	bodb02.dbo.bettrans14 b WITH(NOLOCK) 
	WHERE	b.winlostdate = @winlostdate
				AND matchid IN(9,29)
				AND bettype IN(9,29)
				AND b.statusid IN (111,112,113)
	UPDATE bb
	SET bb.transid2 = aa.transid2
	FROM #tmpbettrans  bb (NOLOCK) INNER JOIN 
	(SELECT b.refno,
	CASE WHEN COUNT(DISTINCT(sporttype))=1 THEN MIN(sporttype)
	WHEN COUNT(DISTINCT(sporttype))<>1 AND MIN(sporttype)=1 THEN  -3
	ELSE -1
	END AS transid2
	FROM #tmpbettrans b (NOLOCK)
	INNER JOIN bodb02.dbo.bettransm a(NOLOCK) ON a.refno=b.refno
	INNER JOIN bodb02.dbo.match c(NOLOCK) ON a.matchid=c.matchid	
	GROUP BY b.refno) aa ON aa.refno=bb.refno	
			
		
	IF @@ERROR > 0
		BEGIN			
			SELECT	 @ErrMsg = 'FAILED:Process summary data failed for :' + CAST(@winlostdate AS VARCHAR(10))
					,@ErrCode = 201
			RETURN
		END		
		
		INSERT INTO #TemprmSumWinloss (winlostdate
				,custid
				,sporttype
				,statusid
				,combo
				,username
				,currency
				,stake
				,winlost
				,company_stake
				,company_winlost
				,actualrate
				,odds
				,betcount
				,recommend
				,ParlayType				
				)
		SELECT	 winlostdate
				,b.custid
				,transid2
				,statusid
				,CASE WHEN bettype=9 THEN RIGHT(betcheck,len(betcheck)-1) ELSE b.hdp2 END  AS combo
				,username
				,currency
				,SUM(stake)
				,SUM(winlost)
				,SUM(stake*(1-tpositiontaking))
				,SUM(-(winlost-stake)*(1-tpositiontaking))
				,actualrate
				,SUM(modds)
				,count(1)
				,recommend 
				,CASE WHEN bettype=9 THEN 1 
					  WHEN bettype=29 AND betteam='1' THEN 2
					  ELSE 3 END AS ParlayType	
		FROM #tmpbettrans b			
		GROUP BY winlostdate, b.custid, transid2, statusid, username, currency, actualrate,
				CASE WHEN bettype=9 THEN RIGHT(betcheck,len(betcheck)-1) ELSE b.hdp2 END,
				recommend,
				CASE WHEN bettype=9 THEN 1 
					  WHEN bettype=29 AND betteam='1' THEN 2
					  ELSE 3 END 
				
		IF @@ERROR > 0
		BEGIN			
			SELECT	 @ErrMsg = 'FAILED:Process summary data failed for :' + CAST(@winlostdate AS VARCHAR(10))
					,@ErrCode = 201
			RETURN
		END		

		INSERT INTO rmSumWinloss (winlostdate
				,custid
				,sporttype
				,statusid
				,combo
				,username
				,currency
				,stake
				,winlost
				,company_stake
				,company_winlost
				,actualrate
				,odds
				,betcount
				,recommend
				,ParlayType
				)
			SELECT winlostdate
				,custid
				,sporttype
				,statusid
				,combo
				,username
				,currency
				,SUM(stake)
				,SUM(winlost)
				,SUM(company_stake)
				,SUM(company_winlost)
				,actualrate
				,SUM(odds)
				,SUM(betcount)
				,recommend
				,ParlayType				
			FROM #TemprmSumWinloss
			GROUP BY winlostdate, custid, sporttype, statusid, username, currency, actualrate,ParlayType,combo,recommend
		
		IF @@ERROR > 0
		BEGIN			
			SELECT	 @ErrMsg = 'FAILED:Process summary data failed for :' + CAST(@winlostdate AS VARCHAR(10))
					,@ErrCode = 201
			RETURN
		END			
	END	
	
GO


