USE [bodb_RMS]
GO

/****** Object:  StoredProcedure [dbo].[Task_RMS_SyncDataForBettransParlay]    Script Date: 01/19/2015 04:36:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_RMS_SyncDataForBettransParlay    Script Date: 6/25/2014 3:31:02 PM ******/
ALTER PROCEDURE [dbo].[Task_RMS_SyncDataForBettransParlay]	
AS
/*   
 Task : arrange bettransParlay data
 DB: DBRMS/bodb_RMS 
 Revisions:   
  - 20121001@viet: create SP   
  - 20130125@Johnson: move sp from DB054.bodb02 to DBRMS.bodb_RMS and use rmSettings to store setting
  - 20140121@Johnson: add system parlay into rmTransaction
  - 20140417@Johnson: add column combo into rmBettrans to store number of selections 
  - 20140620@Johnson: calculate total odds for system parlay tickets
  - 20160422@Winnie: intergrate Combo parlay
  - 20160720@Winnie: fix bug Executed as user: DB054\SQL. Conversion failed when converting the nvarchar value 'a' to data type int. [SQLSTATE 22018] (Error 245).  The step failed.
  - 20160926@Winnie: fix issue conflict refno with racing
*/  

SET NOCOUNT ON
SET DEADLOCK_PRIORITY LOW	

declare @tstamp_min binary(8), @tstamp_max binary(8), @max_transid bigint

DECLARE @bitmap VARCHAR(21) = ''
CREATE TABLE #tmpBettrans (transid BIGINT PRIMARY KEY, hdp1 SMALLMONEY, hdp2 SMALLINT, betteam NVARCHAR(10), betcheck BIGINT)

SELECT @tstamp_min = CAST(CAST(ISNULL(VValue, 0) as bigint)+1 as binary(8))
FROM dbo.rmSettings with (rowlock)
WHERE VName = 'rmBettransSync'	

SELECT @tstamp_max = isnull(max(tstamp),@tstamp_min)  from bodb02.dbo.bettrans with(nolock)

IF @tstamp_min = 0x0000000000000001 -- 1: renew all data
BEGIN
	TRUNCATE TABLE dbo.rmBettrans
	
	INSERT INTO dbo.rmBettrans (transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, 
		apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, 
		liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
		recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, 
		scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, 
		SecAcceptFlag, transid2, combo
	)
	SELECT transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, 
			apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, 
			liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
			recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, 
			scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, 
			SecAcceptFlag, transid2, CASE when matchid = 9 then RIGHT(betcheck,LEN(betcheck)-1) 
										  WHEN bettype=29 AND betcheck IS NULL THEN LEN(betteam) ELSE hdp2 end
	FROM bodb02.dbo.bettrans with (NOLOCK)
	WHERE matchid in (9,29)
		 
	-- bettype 29 old	
	INSERT INTO #tmpBettrans (transid, hdp1, hdp2,betcheck)
	SELECT	transid, 0, LEN(betteam),hdp2 -- number of match
	FROM	dbo.rmBettrans
	WHERE	bettype = 29
			AND betcheck IS NULL
	
	UPDATE tmpb
	SET @bitmap = REPLICATE('1', hdp2 - 1) + '0'
		,betteam = (SELECT result FROM dbo.f_BinaryToDecimal(REVERSE(@bitmap)))	
	FROM #tmpBettrans tmpb

	UPDATE b WITH(ROWLOCK, UPDLOCK)
	SET hdp1  = tmp.hdp1
		,hdp2 = tmp.hdp2
		,betteam = tmp.betteam
		,betcheck = tmp.betcheck 	
	FROM	dbo.rmbettrans b
	INNER JOIN #tmpBettrans tmp
		ON	b.transid = tmp.transid
			AND b.matchid = 29
			AND b.bettype = 29
	
	-- end bettype 29 old

	;WITH ParlayTotalBet AS(
		SELECT TransID, SUM (rcs.cnt) AS TotalBet
		FROM rmBettrans b WITH(NOLOCK)
			INNER JOIN bodb02.dbo.RefCombinationSet rcs WITH(NOLOCK) ON b.hdp2 = rcs.N
		WHERE b.bettype=29 AND (b.betteam & rcs.bitmapR) > 0
		GROUP BY b.transid
	)
	UPDATE b
	SET b.TotalBet = pt.TotalBet		
	FROM rmBettrans b 
	INNER JOIN ParlayTotalBet pt ON b.TransID = pt.TransID
	WHERE b.bettype=29 

	;WITH tmpbettrans AS(
		SELECT b.hdp2 AS selection_cnt, CAST(b.betteam as int) AS bitmapR, bm.odds, bm.stake AS SetStake, bm.refno, b.transid
			,RN = ROW_NUMBER() OVER (PARTITION BY bm.refno ORDER BY bm.matchid) --RN			
		FROM rmBettrans b WITH (NOLOCK) 
			INNER JOIN
					(	select refno, odds, stake,a.matchid
						from bodb02.dbo.bettransm a WITH(NOLOCK)
						inner join bodb02.dbo.match m WITH(NOLOCK) ON a.matchid=m.matchid
						where m.sporttype<=99
						union all
						select refno, odds, stake,a.matchid
						from bodb02.dbo.bettransm14 a WITH(NOLOCK)
						inner join bodb02.dbo.match14 m WITH(NOLOCK) ON a.matchid=m.matchid
						where m.sporttype<=99
					)bm ON bm.refno = b.refno
			WHERE b.bettype=29  
	),
	ParlayStake AS (SELECT refno, RN, SetStake FROM tmpbettrans)
	SELECT EXP(SUM(LOG(odds))) AS Odds, b.transid, ps.SetStake
	INTO #tmp2
	FROM tmpbettrans b WITH (NOLOCK)
		INNER JOIN bodb02.dbo.RefCombinationSet rcs WITH (NOLOCK) ON b.selection_cnt = rcs.N AND (b.bitmapR & rcs.bitmapR) > 0  
		INNER JOIN bodb02.dbo.RefCombination rc  WITH (NOLOCK) ON rcs.N = rc.N AND rcs.R = rc.R AND b.RN = rc.seq
		INNER JOIN ParlayStake ps ON ps.refno = b.refno AND ps.RN = rc.R
	GROUP BY b.transid, ps.SetStake, serial

	;WITH tmp AS(
		SELECT b.transid AS transid , CASE WHEN b.stake = 0 THEN 0 ELSE SUM (r.odds * r.SetStake)/b.stake END AS Odds2
		FROM rmBettrans b WITH(NOLOCK)
			INNER JOIN #tmp2 r ON b.transid = r.transid 
		GROUP BY b.transid, b.stake, b.TotalBet
	)
	UPDATE b
	SET b.odds2 = t.Odds2
	FROM rmBettrans b	
		INNER JOIN tmp t ON b.transid = t.transid	
	
	UPDATE bb
	SET bb.transid2 = aa.transid2
	FROM rmBettrans bb (NOLOCK) INNER JOIN 
	(SELECT b.refno,
	CASE WHEN COUNT(DISTINCT(sporttype))=1 THEN MIN(sporttype)
	WHEN COUNT(DISTINCT(sporttype))<>1 AND MIN(sporttype)=1 THEN  -3
	ELSE -1
	END AS transid2
	FROM rmBettrans b (NOLOCK)
	INNER JOIN bodb02.dbo.bettransm a(NOLOCK) ON a.refno=b.refno
	INNER JOIN bodb02.dbo.match c(NOLOCK) ON a.matchid=c.matchid
	WHERE c.sporttype<=99	
	GROUP BY b.refno) aa ON aa.refno=bb.refno
END
ELSE 
BEGIN
	select @max_transid = ISNULL(MAX(transid),0) from rmBettrans (NOLOCK) 
	SELECT	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, 
			apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, 
			liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
			recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, 
			scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, 
			SecAcceptFlag, transid2, CASE when matchid = 9 then RIGHT(betcheck,LEN(betcheck)-1)
										  WHEN bettype=29 AND betcheck IS NULL THEN LEN(betteam) ELSE hdp2 END combo
	INTO #temp			
	FROM bodb02.dbo.bettrans with (NOLOCK)
	WHERE tstamp between @tstamp_min and @tstamp_max
		AND matchid in (9,29)
		
	UPDATE bb
	SET bb.transid2 = aa.transid2
	FROM #temp  bb (NOLOCK) INNER JOIN 
	(SELECT b.refno,
	CASE WHEN COUNT(DISTINCT(sporttype))=1 THEN MIN(sporttype)
	WHEN COUNT(DISTINCT(sporttype))<>1 AND MIN(sporttype)=1 THEN  -3
	ELSE -1
	END AS transid2
	FROM #temp b (NOLOCK)
	INNER JOIN bodb02.dbo.bettransm a(NOLOCK) ON a.refno=b.refno
	INNER JOIN bodb02.dbo.match c(NOLOCK) ON a.matchid=c.matchid	
	WHERE c.sporttype<=99
	GROUP BY b.refno) aa ON aa.refno=bb.refno	
		
	MERGE dbo.rmBettrans as d
		USING #temp s on d.transid = s.transid	
		WHEN MATCHED THEN 
			UPDATE SET 
				custid = s.custid
				,transdate = s.transdate
				,oddsid = s.oddsid				
				,odds = s.odds
				,stake = s.stake
				,status = s.status
				,winlost = s.winlost
				,awinlost = s.awinlost
				,mwinlost = s.mwinlost
				,playercomm = s.playercomm
				,comm = s.comm
				,acomm = s.acomm
				,apositiontaking = s.apositiontaking
				,mpositiontaking = s.mpositiontaking
				,tpositiontaking = s.tpositiontaking
				,playerdiscount = s.playerdiscount
				,discount = s.discount
				,adiscount = s.adiscount
				,livehomescore = s.livehomescore
				,liveawayscore = s.liveawayscore
				,liveindicator = s.liveindicator				
				,creator = s.creator
				,refno = s.refno
				,comstatus = s.comstatus
				,winlostdate = s.winlostdate
				,betfrom = s.betfrom				
				,checktime = s.checktime
				,oddsspread = s.oddsspread
				,actualrate = s.actualrate
				,matchid = s.matchid
				,recommend = s.recommend
				,mrecommend = s.mrecommend
				,ruben = s.ruben
				,betid = s.betid
				,statuswinlost = s.statuswinlost
				,modds = s.modds
				,bettype = s.bettype
				,betdaqid = s.betdaqid
				,actual_stake = s.actual_stake
				,currency = s.currency
				,ip = s.ip
				,transdesc = s.transdesc
				,sdiscount = s.sdiscount
				,scomm = s.scomm
				,spositiontaking = s.spositiontaking
				,swinlost = s.swinlost
				,srecommend = s.srecommend
				,Username = s.Username
				,CurrencyName = s.CurrencyName
				,virtualrate = s.virtualrate
				,oddstype = s.oddstype
				,statusID = s.statusID
				,currency2 = s.currency2
				,balance = s.balance
				,SecAcceptFlag = s.SecAcceptFlag
				,transid2 = s.transid2
				,combo = s.combo
		WHEN NOT MATCHED THEN 
		INSERT (transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, 
			apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, 
			liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
			recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, 
			scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, 
			SecAcceptFlag, transid2, combo
			)
		VALUES (
			transid, s.custid, s.transdate, s.oddsid, s.hdp1, s.hdp2, s.odds, s.stake, s.status, s.winlost, s.awinlost, s.mwinlost, s.playercomm, 
			s.comm, s.acomm, s.apositiontaking, s.mpositiontaking, s.tpositiontaking, s.playerdiscount, s.discount, s.adiscount, s.livehomescore, 
			s.liveawayscore, s.liveindicator, s.betteam, s.creator, s.refno, s.comstatus, s.winlostdate, s.betfrom, s.betcheck, s.checktime, 
			s.oddsspread, s.actualrate, s.matchid, s.recommend, s.mrecommend, s.ruben, s.betid, s.statuswinlost, s.modds, s.bettype, s.betdaqid, 
			s.actual_stake, s.currency, s.ip, s.transdesc, s.sdiscount, s.scomm, s.spositiontaking, s.swinlost, s.srecommend, s.Username, 
			s.CurrencyName, s.virtualrate, s.oddstype, s.statusID, s.currency2, s.balance, s.SecAcceptFlag, s.transid2, s.combo
			)
	;--end MERGE	

	; -- END OF MERGE rmTransaction	
	
	IF EXISTS(SELECT TOP 1 1 FROM #temp WHERE matchid = 29)
	BEGIN	
		--bettype 29 Old
	INSERT INTO #tmpBettrans (transid, hdp1, hdp2,betcheck)
	SELECT	transid, 0, LEN(betteam),hdp2 -- number of match
	FROM	#temp 
	WHERE	bettype = 29
			AND betcheck IS NULL
	
	UPDATE tmpb
	SET betteam = (SELECT result FROM dbo.f_BinaryToDecimal(REVERSE(REPLICATE('1', hdp2 - 1) + '0')))	
	FROM #tmpBettrans tmpb

	UPDATE b WITH(ROWLOCK, UPDLOCK)
	SET hdp1  = tmp.hdp1
		,hdp2 = tmp.hdp2
		,betteam = tmp.betteam
		,betcheck = tmp.betcheck 
	FROM	dbo.rmbettrans b
	INNER JOIN #tmpBettrans tmp
		ON	b.transid = tmp.transid
			AND b.matchid = 29
			AND b.bettype = 29

		-- end bettype 29 old
		;WITH ParlayTotalBet AS(
			SELECT b.TransID, SUM (rcs.cnt) AS TotalBet
			FROM rmBettrans b WITH(NOLOCK)
				INNER JOIN bodb02.dbo.RefCombinationSet rcs WITH(NOLOCK) ON b.hdp2 = rcs.N
				INNER JOIN #temp c ON b.transid=c.transid
			WHERE b.bettype=29 AND (b.betteam & rcs.bitmapR) > 0 AND b.transid>@max_transid	
			GROUP BY b.transid
		)
		UPDATE b
		SET b.TotalBet = pt.TotalBet		
		FROM rmBettrans b 
		INNER JOIN ParlayTotalBet pt ON b.TransID = pt.TransID
	
		;WITH tmpbettrans AS(
			SELECT b.hdp2 AS selection_cnt, b.betteam AS bitmapR, bm.odds, bm.stake AS SetStake, bm.refno, b.transid
				,RN = ROW_NUMBER() OVER (PARTITION BY bm.refno ORDER BY bm.matchid) --RN
			FROM rmBettrans b WITH (NOLOCK) 
				INNER JOIN
						(	select refno, odds, stake,a.matchid
							from bodb02.dbo.bettransm a WITH(NOLOCK)
							inner join bodb02.dbo.match m WITH(NOLOCK) ON a.matchid=m.matchid
							where m.sporttype<=99							
							union all
							select refno, odds, stake,a.matchid
							from bodb02.dbo.bettransm14 a WITH(NOLOCK)
							inner join bodb02.dbo.match14 m WITH(NOLOCK) ON a.matchid=m.matchid
							where m.sporttype<=99
						)bm ON bm.refno = b.refno
				INNER JOIN #temp c ON b.transid=c.transid	
				WHERE  b.bettype=29 AND b.transid>@max_transid				
		),
		ParlayStake AS (SELECT refno, RN, SetStake FROM tmpbettrans)
		SELECT EXP(SUM(LOG(odds))) AS Odds, b.transid, ps.SetStake
		INTO #tmp
		FROM tmpbettrans b 
			INNER JOIN bodb02.dbo.RefCombinationSet rcs WITH(NOLOCK) ON b.selection_cnt = rcs.N AND (b.bitmapR & rcs.bitmapR) > 0  
			INNER JOIN bodb02.dbo.RefCombination rc WITH(NOLOCK) ON rcs.N = rc.N AND rcs.R = rc.R AND b.RN = rc.seq
			INNER JOIN ParlayStake ps ON ps.refno = b.refno AND ps.RN = rc.R
		GROUP BY b.transid, ps.SetStake, serial
		
		;WITH tmp AS(
			SELECT b.transid AS transid , CASE WHEN b.stake = 0 THEN 0 ELSE SUM (r.odds * r.SetStake)/b.stake END AS Odds2
			FROM rmBettrans b WITH(NOLOCK)
				INNER JOIN #tmp r ON b.transid = r.transid 
			GROUP BY b.transid, b.stake, b.TotalBet
		)
		UPDATE b
		SET b.odds2 = t.Odds2
		FROM rmBettrans b	
			INNER JOIN tmp t ON b.transid = t.transid		
	END	
			
	MERGE	dbo.rmTransaction as dt
	USING	#temp s on dt.transid = s.transid	
	WHEN NOT MATCHED THEN 
	INSERT(transid, refno, custid, combo)
	VALUES(s.transid,s.refno,s.custid,s.combo);
	END

	UPDATE dbo.rmSettings with(rowlock, updlock)
	SET VValue = CAST(CAST(@tstamp_max as bigint) as varchar(200))
	WHERE VName = 'rmBettransSync'	

SET NOCOUNT OFF