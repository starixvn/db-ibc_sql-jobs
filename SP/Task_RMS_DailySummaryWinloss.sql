/*<info serverAlias="DBRMS-bodb_RMS" executers="bodbRMSNet" viewers="" isFunction="0" isNested="0"></info>*/

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
			- 20160920@Winnie: hot fix NULL in sporttype  RedmineID: #64286
			- 20160922@Winnie: fix ticket bettype 29 old format & confict refno with racing  RedmineID: #64286
			- 20180927@Jacob: Apply Extra PT and Super Comm to Report.  RedmineID: #100951 		
			- 20190214@Jacob: Add Bet Builder RedmineID: #108694
			- 20191211@Jacob: Extra PT - Add new structure to support extra pt column on bettrans table #124194
		Parameter's Explanation:

		EXEC [Task_RMS_DailySummaryWinloss] @winlostdate = '20180915'
	*/
SET NOCOUNT ON
		
	IF NOT EXISTS (SELECT top 1 1 FROM bodb02.dbo.bettrans14 WITH(NOLOCK) WHERE ((bettype = 29 AND matchid = 29)  OR bettype = 38) AND winlostdate = @winlostdate)
	BEGIN
		SELECT	 @ErrMsg= 'WARNING:Data is not moved to bettrans14.'
				,@ErrCode = 101
		RETURN
	END
	
	IF EXISTS (SELECT top 1 1 FROM bodb02.dbo.bettrans WITH(NOLOCK) WHERE ((bettype = 29  AND matchid = 29)  OR bettype = 38)  AND winlostdate = @winlostdate)
	BEGIN
		SELECT	 @ErrMsg= 'WARNING:Data is still in bettrans.'
				,@ErrCode = 102
		RETURN
	END
	
	CREATE TABLE  #TemprmSumWinloss(
	[winlostdate] [smalldatetime] NOT NULL,
	[custid] [int] NOT NULL,
	[sporttype] [SMALLINT] NULL,
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
	ParlayType [tinyint] NULL,
	[scomm] [money] NULL,
	[extra_comm] [money] NULL,
	[extra_stake] [money] NULL,
	[extra_winlost] [money] NULL
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
	[scomm] [money] NULL,
	[actualrate] [float] NULL,
	[odds] [smallmoney] NULL,	
	[recommend] [int] NULL,
	[srecommend] [int] NULL,
	bettype SMALLINT NULL,
	tpositiontaking SMALLMONEY NULL,
	hdp2 SMALLMONEY NULL,
	betcheck NVARCHAR(50) NULL,
	transid2 BIGINT NULL,
	modds   SMALLMONEY NULL,
	betteam NVARCHAR(10) NULL,
	refno BIGINT NOT NULL,
	matchId INT NULL,
	epositiontaking SMALLMONEY
	)
	CREATE NONCLUSTERED INDEX [IX_refno] ON [dbo].#tmpbettrans 
	(
		[refno] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	

	CREATE TABLE #tmpbettransm(	
	refno BIGINT NOT NULL,
	sporttype INT NULL)	
	
	CREATE CLUSTERED INDEX [IX_refno] ON [dbo].#tmpbettransm 
	(
		[refno] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	
	
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
	[scomm] ,	
	[actualrate],
	[odds] ,
	[recommend] ,
	[srecommend] ,
	bettype,
	tpositiontaking ,
	hdp2 ,
	betcheck,
	modds,
	betteam,
	refno,
	matchId,
	epositiontaking
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
	[scomm] ,
	[actualrate],
	[odds] ,	
	[recommend] ,
	[srecommend] ,
	bettype,
	tpositiontaking ,
	hdp2 ,
	betcheck,
	modds,
	betteam,
	refno,
	matchId,
	epositiontaking
	FROM
	bodb02.dbo.bettrans14 b WITH(NOLOCK) 
	WHERE	b.winlostdate = @winlostdate
				AND ((matchid = 29 AND bettype = 29) OR bettype = 38)
				AND b.statusid IN (111,112,113)
				
	INSERT INTO #tmpbettransm(	refno ,	sporttype)
	SELECT a.refno,m.sporttype 
	FROM #tmpbettrans b (NOLOCK)
	INNER JOIN DBARC.bodb_Archive.dbo.bettransm a WITH (NOLOCK) ON a.refno=b.refno
	INNER JOIN DBARC.bodb_Archive.dbo.match_bk m(NOLOCK) ON a.matchid=m.matchid	
	WHERE m.sporttype<=99  AND b.bettype = 29
	
	INSERT INTO #tmpbettransm(	refno ,	sporttype)
	SELECT a.refno,m.sporttype 
	FROM #tmpbettrans b (NOLOCK)
	INNER JOIN bodb02.dbo.bettransm a(NOLOCK) ON a.refno=b.refno
	INNER JOIN bodb02.dbo.match m(NOLOCK) ON a.matchid=m.matchid	
	WHERE m.sporttype<=99 AND b.bettype = 29
	
	INSERT INTO #tmpbettransm(	refno ,	sporttype)
	SELECT a.refno,m.sporttype 
	FROM #tmpbettrans b (NOLOCK)
	INNER JOIN bodb02.dbo.bettransm14 a(NOLOCK) ON a.refno=b.refno
	INNER JOIN bodb02.dbo.match14 m(NOLOCK) ON a.matchid=m.matchid	
	WHERE m.sporttype<=99 AND b.bettype = 29
	
	-- Join Bettransm to get sporttype(transid2) for bettype = 29
	UPDATE bb
	SET bb.transid2 = aa.transid2
	FROM #tmpbettrans  bb INNER JOIN 
	(SELECT b.refno,
	CASE WHEN COUNT(DISTINCT(sporttype))=1 THEN MIN(sporttype)
	WHEN COUNT(DISTINCT(sporttype))<>1 AND MIN(sporttype)=1 THEN  -3
	ELSE -1
	END AS transid2
	FROM #tmpbettransm b 
	GROUP BY b.refno) aa ON aa.refno=bb.refno	
	
	-- sporttype(transid2) always is 1 for bettype = 38
	UPDATE #tmpbettrans SET transid2 = 1
	WHERE bettype = 38
	
	
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
		,scomm
		,extra_comm
		,extra_stake
		,extra_winlost
		)
	SELECT	 winlostdate
		,b.custid
		,transid2
		,statusid
		,CASE WHEN bettype=29 AND betcheck IS NULL THEN LEN(betteam)
			ELSE hdp2 END AS combo
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
		,CASE WHEN bettype=29 AND betteam='1' THEN 2
				WHEN bettype=29 AND betteam <> '1' THEN 3
				WHEN bettype=38 THEN 4
				ELSE 0 END AS ParlayType
		,SUM(scomm)
		,SUM(scomm * ISNULL(b.epositiontaking, 0) / (1 - tpositiontaking))
		,SUM(stake * ISNULL(b.epositiontaking, 0))
		,SUM(-(winlost-stake)*ISNULL(b.epositiontaking, 0))				
	FROM #tmpbettrans b														
	GROUP BY winlostdate, b.custid, transid2, statusid, username, currency, actualrate,
				CASE WHEN bettype=29 AND betcheck IS NULL THEN LEN(betteam)
				ELSE hdp2 END, 
			recommend,
			CASE WHEN bettype=29 AND betteam='1' THEN 2
				WHEN bettype=29 AND betteam <> '1' THEN 3
				WHEN bettype=38 THEN 4
				ELSE 0 END
		
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
				,[scomm]
				,[extra_comm]
				,[extra_stake]
				,[extra_winlost]
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
				,SUM(scomm)
				,SUM(extra_comm)		
				,SUM(extra_stake)		
				,SUM(extra_winlost)				
			FROM #TemprmSumWinloss
			GROUP BY winlostdate, custid, sporttype, statusid, username, currency, actualrate,ParlayType,combo,recommend
			
		
		IF @@ERROR > 0
		BEGIN			
			SELECT	 @ErrMsg = 'FAILED:Process summary data failed for :' + CAST(@winlostdate AS VARCHAR(10))
					,@ErrCode = 201
			RETURN
		END			
	END	
		drop table #tmpbettrans
		drop table #TemprmSumWinloss
		drop table #tmpbettransm

GO


