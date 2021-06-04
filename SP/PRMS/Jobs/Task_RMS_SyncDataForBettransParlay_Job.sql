/*<info serverAlias="DBRMS-bodb_RMS" executers="bodbRMSNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_RMS_SyncDataForBettransParlay_Job]	
AS

/*
	Created:
	DB: DBRMS-bodb_RMS
	Task: arrange bettransParlay data

	Revisions:   
		- 20121001@viet: create SP   
		- 20130125@Johnson: move sp from DB054.bodb02 to DBRMS.bodb_RMS and use rmSettings to store setting
		- 20140121@Johnson: add system parlay into rmTransaction
		- 20140417@Johnson: add column combo into rmBettrans to store number of selections 
		- 20140620@Johnson: calculate total odds for system parlay tickets
		- 20160422@Winnie: intergrate Combo parlay
		- 20160720@Winnie: fix bug Executed as user: DB054\SQL. Conversion failed when converting the nvarchar value 'a' to data type int. [SQLSTATE 22018] (Error 245).  The step failed.
		- 20160926@Winnie: fix issue conflict refno with racing RedmineID: #64286
		- 20190214@Jacob: Add Bet Builder RedmineID: #108694
		- 20191128@Johnson: remove rmTransaction [redmine:#124442]
		- 20191211@Jacob: Extra PT - Add new structure to support extra pt column on bettrans table #124194
		- 20200510@Percy: Add Penalty Shootout Combo [RedmineID: #133961]
		- 20201214@Danny: Separate Data of Virtual Soccer & Virtual Basketball [RedmineID: #145926]
		- 20210225@Danny: Incorporate BetBuilder - Basketball on PRMS [RedmineID: #150652]
		- 20210319@Danny: Incorporate Cricket AIO into PRMS [RedmineID: #151319]
		- 20210604@Danny: Add New League Group for Saba Sports [RedmineID: #156453]
*/

BEGIN
	SET NOCOUNT ON

	SET DEADLOCK_PRIORITY LOW

	DECLARE @min_tstamp BINARY(8), @max_tstamp BINARY(8)
	SELECT  @min_tstamp = CONVERT(BINARY(8), CONVERT(BIGINT, ISNULL(VValue, 0)) + 1)
	FROM dbo.rmSettings WITH (ROWLOCK)
	WHERE VName = 'rmBettrans'

	SELECT  @max_tstamp = MAX(tstamp) FROM bodb02.dbo.bettrans WITH (NOLOCK)
	SELECT  @max_tstamp = ISNULL(@max_tstamp, @min_tstamp)

	DECLARE @MoveBetsDay SMALLDATETIME, @BalanceUpDay SMALLDATETIME, @ErrCode INT, @ErrMsg VARCHAR(4000)
	DECLARE @tblErrMsg TABLE (TableName VARCHAR(300), ErrMsg VARCHAR(4000))

	DECLARE @MBBU TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	INSERT INTO @MBBU (BalanceUpDay, MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @MoveBetsDay = MoveBetsDay, @BalanceUpDay = BalanceUpDay FROM @MBBU

	CREATE TABLE #sporttype (refno BIGINT, sporttype INT, Saba INT ,odds smallmoney, stake money, matchid INT)
	CREATE CLUSTERED INDEX CIX_refno ON #sporttype (refno)

	IF @min_tstamp = 0x0000000000000001 -- renew all data
	BEGIN
		TRUNCATE TABLE dbo.rmBettrans

		INSERT INTO dbo.rmBettrans
		(
			transid,custid,transdate,oddsid,hdp1,hdp2,odds,stake,status,winlost,awinlost,mwinlost,playercomm,comm,acomm
			,apositiontaking,mpositiontaking,tpositiontaking,playerdiscount,discount,adiscount,livehomescore,liveawayscore
			,liveindicator,betteam,creator,refno,comstatus,winlostdate,betfrom,betcheck,checktime,oddsspread,actualrate,matchid
			,recommend,mrecommend,ruben,betid,statuswinlost,modds,bettype,betdaqid,actual_stake,currency,ip,transdesc
			,sdiscount,scomm,spositiontaking,swinlost,srecommend,Username,CurrencyName,virtualrate,oddstype,statusID,currency2
			,balance,SecAcceptFlag,epositiontaking,transid2,combo,odds2,TotalBet
		)
		SELECT
			transid,custid,transdate,oddsid,hdp1,hdp2,odds,stake,status,winlost,awinlost,mwinlost,playercomm,comm,acomm
			,apositiontaking,mpositiontaking,tpositiontaking,playerdiscount,discount,adiscount,livehomescore,CASE WHEN bettype IN (38, 376) THEN 1 ELSE liveawayscore END
			,liveindicator,betteam,creator,refno,comstatus,winlostdate,betfrom,betcheck,checktime,oddsspread,actualrate,matchid
			,recommend,mrecommend,ruben,betid,statuswinlost,modds,bettype,betdaqid,actual_stake,currency,ip,transdesc
			,sdiscount,scomm,spositiontaking,swinlost,srecommend,Username,CurrencyName,virtualrate,oddstype,statusID,currency2
			,balance,SecAcceptFlag,epositiontaking,1,hdp2,odds,1
		FROM bodb02.dbo.bettrans WITH (NOLOCK)
		WHERE bettype IN (29, 38, 376)

	
		-- Update some columns for bettype = 38
		IF EXISTS (SELECT 1 FROM dbo.rmBettrans WITH (NOLOCK) WHERE bettype = 38)
		BEGIN
			-- transid2 (sporttype)
			UPDATE b WITH (ROWLOCK)
			SET b.transid2 = m.sporttype
			FROM dbo.rmBettrans b
			INNER JOIN bodb02.dbo.match m WITH (NOLOCK) ON b.matchid = m.matchid
			WHERE b.bettype =38
		END


		-- Update some columns for bettype = 29
		IF EXISTS (SELECT 1 FROM dbo.rmBettrans WITH (NOLOCK) WHERE bettype = 29)
		BEGIN

			-- bettransm
			INSERT INTO #sporttype (refno, sporttype, Saba, odds, stake, matchid)
			SELECT bm.refno, m.sporttype, CASE WHEN  l.LeagueGroupID IN (42, 74, 108) THEN 1 ELSE -1 END Saba, bm.odds, bm.stake, CASE WHEN m.ChildMatchType = 200 THEN m.ParentID ELSE bm.matchid END
			FROM dbo.rmBettrans b WITH (NOLOCK)
				INNER JOIN bodb02.dbo.bettransm bm WITH (NOLOCK) ON b.refno = bm.refno
				INNER JOIN bodb02.dbo.match m WITH (NOLOCK) ON bm.matchid = m.matchid
				INNER JOIN bodb02.dbo.League l WITH(NOLOCK) ON m.leagueid = l.leagueid
			WHERE b.bettype = 29  AND (bm.winlostdate > @MoveBetsDay or bm.winlostdate IS NULL)
			
			-- bettransm14
			INSERT INTO #sporttype (refno, sporttype, Saba, odds, stake, matchid)
			SELECT bm.refno, m.sporttype, CASE WHEN  l.LeagueGroupID IN (42, 74, 108) THEN 1 ELSE -1 END Saba, bm.odds, bm.stake, CASE WHEN m.ChildMatchType = 200 THEN m.ParentID ELSE bm.matchid END
			FROM dbo.rmBettrans b WITH (NOLOCK)
				INNER JOIN bodb02.dbo.bettransm14 bm WITH (NOLOCK) ON b.refno = bm.refno
				INNER JOIN bodb02.dbo.match14 m WITH (NOLOCK) ON bm.matchid = m.matchid
				INNER JOIN bodb02.dbo.League l WITH(NOLOCK) ON m.leagueid = l.leagueid
			WHERE b.bettype = 29 AND bm.winlostdate BETWEEN @BalanceUpDay AND @MoveBetsDay 

			-- bettrans_bk
			INSERT INTO #sporttype (refno, sporttype, Saba, odds, stake, matchid)
			SELECT bm.refno, m.sporttype, CASE WHEN  l.LeagueGroupID IN (42, 74, 108) THEN 1 ELSE -1 END Saba, bm.odds, bm.stake, CASE WHEN m.ChildMatchType = 200 THEN m.ParentID ELSE bm.matchid END
			FROM dbo.rmBettrans b WITH (NOLOCK)
				INNER JOIN dbo.rmBettransm_bk bm WITH (NOLOCK) ON b.refno = bm.refno
				INNER JOIN dbo.rmMatch_bk m WITH (NOLOCK) ON bm.matchid = m.matchid
				INNER JOIN bodb02.dbo.League l WITH(NOLOCK) ON m.leagueid = l.leagueid
			WHERE b.bettype = 29 AND bm.winlostdate BETWEEN DATEADD(DAY, -20, @BalanceUpDay) AND DATEADD(DAY, -1, @BalanceUpDay)


			-- transid2 (sporttype)
			UPDATE b WITH (ROWLOCK)
			SET b.transid2 = s.sporttype
			FROM dbo.rmBettrans b
			CROSS APPLY (
					SELECT CASE
								-------------------------------
								WHEN COUNT(DISTINCT st.sporttype) = 1 AND MIN(st.sporttype) NOT IN (1,2) THEN MIN(st.sporttype)
								------------------------------- 
								WHEN COUNT(DISTINCT st.sporttype) = 1 AND MIN(st.sporttype) = 1 AND SUM(DISTINCT st.Saba) = 0 THEN -3 
								WHEN COUNT(DISTINCT st.sporttype) = 1 AND MIN(st.sporttype) = 1 AND SUM(DISTINCT st.Saba) > 0 THEN -4
								WHEN COUNT(DISTINCT st.sporttype) = 1 AND MIN(st.sporttype) = 1 AND SUM(DISTINCT st.Saba) < 0 THEN  1
								------------------------------
								WHEN COUNT(DISTINCT st.sporttype) = 1 AND MIN(st.sporttype) = 2 AND SUM(DISTINCT st.Saba) = 0 THEN -1
								WHEN COUNT(DISTINCT st.sporttype) = 1 AND MIN(st.sporttype) = 2 AND SUM(DISTINCT st.Saba) > 0 THEN -5
								WHEN COUNT(DISTINCT st.sporttype) = 1 AND MIN(st.sporttype) = 2 AND SUM(DISTINCT st.Saba) < 0 THEN  2
								------------------------------
								WHEN COUNT(DISTINCT st.sporttype) <> 1 AND MIN(st.sporttype) = 1 THEN -3
								ELSE -1 END AS sporttype 
					FROM #sporttype st
					WHERE st.refno = b.refno
				) s
			WHERE b.bettype = 29

			-- TotalBet
			UPDATE b WITH (ROWLOCK)
			SET b.TotalBet = t.TotalBet
			FROM dbo.rmBettrans b
				CROSS APPLY (
					SELECT SUM(rcs.cnt) AS TotalBet
					FROM bodb02.dbo.RefCombinationSet rcs WITH (NOLOCK)
					WHERE rcs.N = b.hdp2
						AND (b.betteam & rcs.bitmapR) > 0
				) t
			WHERE b.bettype = 29

			-- odds2
			CREATE TABLE #tmp (transid BIGINT, stake MONEY, N TINYINT, bitmapR INT, odds SMALLMONEY, SetStake MONEY, RN TINYINT)
			CREATE CLUSTERED INDEX CIX_transid ON #tmp (transid)

			INSERT INTO #tmp (transid, stake, N, bitmapR, odds, SetStake, RN)
			SELECT b.transid, b.stake, b.hdp2, b.betteam, bm.odds, bm.stake AS SetStake
				,ROW_NUMBER() OVER(PARTITION BY b.transid ORDER BY bm.matchid) AS RN
			FROM dbo.rmBettrans b WITH (NOLOCK)
				CROSS APPLY (
					SELECT bm.odds, bm.stake, bm.matchid
					FROM #sporttype bm WITH (NOLOCK)
					WHERE bm.refno = b.refno
				) bm
			WHERE b.bettype = 29

			;WITH CTE_ParlayStake AS
			(
				SELECT transid, RN, SetStake FROM #tmp
			)
			,CTE_odds AS
			(
				SELECT transid, CASE WHEN stake = 0 THEN 0 ELSE SUM(odds * SetStake) / stake END AS odds2
				FROM (
					SELECT t.transid, t.stake, ps.SetStake, EXP(SUM(LOG(t.odds))) AS odds
					FROM #tmp t
						INNER JOIN bodb02.dbo.RefCombinationSet rcs WITH (NOLOCK) ON t.N = rcs.N AND (t.bitmapR & rcs.bitmapR) > 0
						INNER JOIN bodb02.dbo.RefCombination rc WITH (NOLOCK) ON rcs.N = rc.N AND rcs.R = rc.R AND t.RN = rc.Seq
						INNER JOIN CTE_ParlayStake ps ON t.transid = ps.transid AND rc.R = ps.RN
					GROUP BY t.transid, t.stake, ps.SetStake, rc.Serial
				) r
				GROUP BY transid, stake
			)
			UPDATE b WITH (ROWLOCK)
			SET b.odds2 = o.odds2
			FROM dbo.rmBettrans b
				INNER JOIN CTE_odds o ON b.transid = o.transid
			WHERE b.bettype = 29
		END
		
		DROP TABLE #tmp
	END
	ELSE
	BEGIN
		CREATE TABLE #rmBettrans
		(
			transid				bigint primary key
			,custid				int
			,transdate			datetime
			,oddsid				int
			,hdp1				smallmoney
			,hdp2				smallmoney
			,odds				smallmoney
			,stake				money
			,status				nvarchar(10)
			,winlost			money
			,awinlost			money
			,mwinlost			money
			,playercomm			money
			,comm				money
			,acomm				money
			,apositiontaking	smallmoney
			,mpositiontaking	smallmoney
			,tpositiontaking	smallmoney
			,playerdiscount		decimal(9,8)
			,discount			decimal(9,8)
			,adiscount			decimal(9,8)
			,livehomescore		smallint
			,liveawayscore		smallint
			,liveindicator		bit
			,betteam			nvarchar(10)
			,creator			int
			,refno				bigint
			,comstatus			nvarchar(20)
			,winlostdate		smalldatetime
			,betfrom			nvarchar(1)
			,betcheck			nvarchar(50)
			,checktime			datetime
			,oddsspread			smallmoney
			,actualrate			float
			,matchid			int
			,recommend			int
			,mrecommend			int
			,ruben				tinyint
			,betid				bigint
			,statuswinlost		tinyint
			,modds				smallmoney
			,bettype			smallint
			,betdaqid			bigint
			,actual_stake		money
			,currency			tinyint
			,ip					nvarchar(15)
			,transdesc			nvarchar(1000)
			,sdiscount			decimal(9,8)
			,scomm				money
			,spositiontaking	smallmoney
			,swinlost			money
			,srecommend			int
			,Username			nvarchar(50)
			,CurrencyName		nvarchar(50)
			,virtualrate		float
			,oddstype			tinyint
			,statusID			tinyint
			,currency2			tinyint
			,balance			money
			,SecAcceptFlag		bit
			,transid2			bigint
			,combo				int
			,odds2				money
			,TotalBet			int
			,epositiontaking	smallmoney
		)
		
		INSERT INTO #rmBettrans
		(
			transid,custid,transdate,oddsid,hdp1,hdp2,odds,stake,status,winlost,awinlost,mwinlost,playercomm,comm,acomm
			,apositiontaking,mpositiontaking,tpositiontaking,playerdiscount,discount,adiscount,livehomescore,liveawayscore
			,liveindicator,betteam,creator,refno,comstatus,winlostdate,betfrom,betcheck,checktime,oddsspread,actualrate,matchid
			,recommend,mrecommend,ruben,betid,statuswinlost,modds,bettype,betdaqid,actual_stake,currency,ip,transdesc
			,sdiscount,scomm,spositiontaking,swinlost,srecommend,Username,CurrencyName,virtualrate,oddstype,statusID,currency2
			,balance,SecAcceptFlag,epositiontaking,transid2,combo,odds2,TotalBet
		)
		SELECT
			transid,custid,transdate,oddsid,hdp1,hdp2,odds,stake,status,winlost,awinlost,mwinlost,playercomm,comm,acomm
			,apositiontaking,mpositiontaking,tpositiontaking,playerdiscount,discount,adiscount,livehomescore,CASE WHEN bettype IN (38, 376) THEN 1 ELSE liveawayscore END
			,liveindicator,betteam,creator,refno,comstatus,winlostdate,betfrom,betcheck,checktime,oddsspread,actualrate,matchid
			,recommend,mrecommend,ruben,betid,statuswinlost,modds,bettype,betdaqid,actual_stake,currency,ip,transdesc
			,sdiscount,scomm,spositiontaking,swinlost,srecommend,Username,CurrencyName,virtualrate,oddstype,statusID,currency2
			,balance,SecAcceptFlag,epositiontaking,1,hdp2,odds,1
		FROM bodb02.dbo.bettrans WITH (NOLOCK)
		WHERE tstamp BETWEEN @min_tstamp AND @max_tstamp
			AND bettype IN (29, 38, 376)

			
		-- Update some columns for bettype = 38
		IF EXISTS (SELECT 1 FROM #rmBettrans WHERE bettype = 38)
		BEGIN
			-- transid2 (sporttype)
			UPDATE b
			SET b.transid2 = m.sporttype
			FROM #rmBettrans b
			INNER JOIN bodb02.dbo.match m WITH (NOLOCK) ON b.matchid = m.matchid
			WHERE b.bettype =38
		END

		-- Update some columns for bettype = 29
		IF EXISTS (SELECT 1 FROM #rmBettrans WHERE bettype = 29)
		BEGIN
			CREATE NONCLUSTERED INDEX IX_bettype ON #rmBettrans (bettype, hdp2)

			-- bettransm
			INSERT INTO #sporttype (refno, sporttype, Saba, odds, stake, matchid)
			SELECT bm.refno, m.sporttype, CASE WHEN  l.LeagueGroupID IN (42, 74, 108) THEN 1 ELSE -1 END Saba, bm.odds, bm.stake, CASE WHEN m.ChildMatchType = 200 THEN m.ParentID ELSE bm.matchid END
			FROM #rmBettrans b 
				INNER JOIN bodb02.dbo.bettransm bm WITH (NOLOCK) ON b.refno = bm.refno
				INNER JOIN bodb02.dbo.match m WITH (NOLOCK) ON bm.matchid = m.matchid
				INNER JOIN bodb02.dbo.League l WITH(NOLOCK) ON m.leagueid = l.leagueid
			WHERE b.bettype = 29  AND (bm.winlostdate > @MoveBetsDay or bm.winlostdate IS NULL)
			
			-- bettransm14
			INSERT INTO #sporttype (refno, sporttype, Saba, odds, stake, matchid)
			SELECT bm.refno, m.sporttype, CASE WHEN  l.LeagueGroupID IN (42, 74, 108) THEN 1 ELSE -1 END Saba, bm.odds, bm.stake, CASE WHEN m.ChildMatchType = 200 THEN m.ParentID ELSE bm.matchid END
			FROM #rmBettrans b 
				INNER JOIN bodb02.dbo.bettransm14 bm WITH (NOLOCK) ON b.refno = bm.refno
				INNER JOIN bodb02.dbo.match14 m WITH (NOLOCK) ON bm.matchid = m.matchid
				INNER JOIN bodb02.dbo.League l WITH(NOLOCK) ON m.leagueid = l.leagueid
			WHERE b.bettype = 29 AND bm.winlostdate BETWEEN @BalanceUpDay AND @MoveBetsDay 

			-- bettrans_bk
			INSERT INTO #sporttype (refno, sporttype, Saba, odds, stake, matchid)
			SELECT bm.refno, m.sporttype, CASE WHEN  l.LeagueGroupID IN (42, 74, 108) THEN 1 ELSE -1 END Saba, bm.odds, bm.stake, CASE WHEN m.ChildMatchType = 200 THEN m.ParentID ELSE bm.matchid END
			FROM #rmBettrans b 
				INNER JOIN dbo.rmBettransm_bk bm WITH (NOLOCK) ON b.refno = bm.refno
				INNER JOIN dbo.rmMatch_bk m WITH (NOLOCK) ON bm.matchid = m.matchid
				INNER JOIN bodb02.dbo.League l WITH(NOLOCK) ON m.leagueid = l.leagueid
			WHERE b.bettype = 29 AND bm.winlostdate BETWEEN DATEADD(DAY, -20, @BalanceUpDay) AND DATEADD(DAY, -1, @BalanceUpDay)


			-- transid2 (sporttype)
			UPDATE b
			SET b.transid2 = s.sporttype
			FROM #rmBettrans b
			CROSS APPLY (
					SELECT CASE
								-------------------------------
								WHEN COUNT(DISTINCT st.sporttype) = 1 AND MIN(st.sporttype) NOT IN (1,2) THEN MIN(st.sporttype)
								------------------------------- 
								WHEN COUNT(DISTINCT st.sporttype) = 1 AND MIN(st.sporttype) = 1 AND SUM(DISTINCT st.Saba) = 0 THEN -3 
								WHEN COUNT(DISTINCT st.sporttype) = 1 AND MIN(st.sporttype) = 1 AND SUM(DISTINCT st.Saba) > 0 THEN -4
								WHEN COUNT(DISTINCT st.sporttype) = 1 AND MIN(st.sporttype) = 1 AND SUM(DISTINCT st.Saba) < 0 THEN  1
								------------------------------
								WHEN COUNT(DISTINCT st.sporttype) = 1 AND MIN(st.sporttype) = 2 AND SUM(DISTINCT st.Saba) = 0 THEN -1
								WHEN COUNT(DISTINCT st.sporttype) = 1 AND MIN(st.sporttype) = 2 AND SUM(DISTINCT st.Saba) > 0 THEN -5
								WHEN COUNT(DISTINCT st.sporttype) = 1 AND MIN(st.sporttype) = 2 AND SUM(DISTINCT st.Saba) < 0 THEN  2
								------------------------------
								WHEN COUNT(DISTINCT st.sporttype) <> 1 AND MIN(st.sporttype) = 1 THEN -3
								ELSE -1 END AS sporttype 
					FROM #sporttype st
					WHERE st.refno = b.refno
				) s
			WHERE b.bettype = 29

			-- TotalBet
			UPDATE b
			SET b.TotalBet = t.TotalBet
			FROM #rmBettrans b
				CROSS APPLY (
					SELECT SUM(rcs.cnt) AS TotalBet
					FROM bodb02.dbo.RefCombinationSet rcs WITH (NOLOCK)
					WHERE rcs.N = b.hdp2
						AND (b.betteam & rcs.bitmapR) > 0
				) t
			WHERE b.bettype = 29

			-- odds2
			CREATE TABLE #tmp2 (transid BIGINT, stake MONEY, N TINYINT, bitmapR INT, odds SMALLMONEY, SetStake MONEY, RN TINYINT)
			CREATE CLUSTERED INDEX CIX_transid ON #tmp2 (transid)

			INSERT INTO #tmp2 (transid, stake, N, bitmapR, odds, SetStake, RN)
			SELECT b.transid, b.stake, b.hdp2, b.betteam, bm.odds, bm.stake AS SetStake
				,ROW_NUMBER() OVER(PARTITION BY b.transid ORDER BY bm.matchid) AS RN
			FROM #rmBettrans b
				CROSS APPLY (
					SELECT bm.odds, bm.stake, bm.matchid
					FROM #sporttype bm WITH (NOLOCK)
					WHERE bm.refno = b.refno
				) bm
			WHERE b.bettype = 29

			;WITH CTE_ParlayStake AS
			(
				SELECT transid, RN, SetStake FROM #tmp2
			)
			,CTE_odds AS
			(
				SELECT transid, CASE WHEN stake = 0 THEN 0 ELSE SUM(odds * SetStake) / stake END AS odds2
				FROM (
					SELECT t.transid, t.stake, ps.SetStake, EXP(SUM(LOG(t.odds))) AS odds
					FROM #tmp2 t
						INNER JOIN bodb02.dbo.RefCombinationSet rcs WITH (NOLOCK) ON t.N = rcs.N AND (t.bitmapR & rcs.bitmapR) > 0
						INNER JOIN bodb02.dbo.RefCombination rc WITH (NOLOCK) ON rcs.N = rc.N AND rcs.R = rc.R AND t.RN = rc.Seq
						INNER JOIN CTE_ParlayStake ps ON t.transid = ps.transid AND rc.R = ps.RN
					GROUP BY t.transid, t.stake, ps.SetStake, rc.Serial
				) r
				GROUP BY transid, stake
			)
			UPDATE b
			SET b.odds2 = o.odds2
			FROM #rmBettrans b
				INNER JOIN CTE_odds o ON b.transid = o.transid
			WHERE b.bettype = 29

			DROP TABLE #tmp2
		END

		;MERGE dbo.rmBettrans AS t
		USING #rmBettrans AS s ON t.transid = s.transid
		WHEN MATCHED THEN UPDATE
			SET custid = s.custid
				,transdate = s.transdate
				,oddsid = s.oddsid
				,hdp1 = s.hdp1
				,hdp2 = s.hdp2
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
				,betteam = s.betteam
				,creator = s.creator
				,refno = s.refno
				,comstatus = s.comstatus
				,winlostdate = s.winlostdate
				,betfrom = s.betfrom
				,betcheck = s.betcheck
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
				,epositiontaking = s.epositiontaking
				,transid2 = s.transid2
				,combo = s.combo
				,odds2 = s.odds2
				,TotalBet = s.TotalBet
		WHEN NOT MATCHED THEN
			INSERT
			(
				transid,custid,transdate,oddsid,hdp1,hdp2,odds,stake,status,winlost,awinlost,mwinlost,playercomm,comm,acomm
				,apositiontaking,mpositiontaking,tpositiontaking,playerdiscount,discount,adiscount,livehomescore,liveawayscore
				,liveindicator,betteam,creator,refno,comstatus,winlostdate,betfrom,betcheck,checktime,oddsspread,actualrate,matchid
				,recommend,mrecommend,ruben,betid,statuswinlost,modds,bettype,betdaqid,actual_stake,currency,ip,transdesc
				,sdiscount,scomm,spositiontaking,swinlost,srecommend,Username,CurrencyName,virtualrate,oddstype,statusID,currency2
				,balance,SecAcceptFlag,epositiontaking,transid2,combo,odds2,TotalBet
			)
			VALUES
			(
				s.transid,s.custid,s.transdate,s.oddsid,s.hdp1,s.hdp2,s.odds,s.stake,s.status,s.winlost,s.awinlost,s.mwinlost,s.playercomm,s.comm,s.acomm
				,s.apositiontaking,s.mpositiontaking,s.tpositiontaking,s.playerdiscount,s.discount,s.adiscount,s.livehomescore,s.liveawayscore
				,s.liveindicator,s.betteam,s.creator,s.refno,s.comstatus,s.winlostdate,s.betfrom,s.betcheck,s.checktime,s.oddsspread,s.actualrate,s.matchid
				,s.recommend,s.mrecommend,s.ruben,s.betid,s.statuswinlost,s.modds,s.bettype,s.betdaqid,s.actual_stake,s.currency,s.ip,s.transdesc
				,s.sdiscount,s.scomm,s.spositiontaking,s.swinlost,s.srecommend,s.Username,s.CurrencyName,s.virtualrate,s.oddstype,s.statusID,s.currency2
				,s.balance,s.SecAcceptFlag,s.epositiontaking,s.transid2,s.combo,s.odds2,s.TotalBet
			);

		DROP TABLE #rmBettrans
	END

	DROP TABLE #sporttype

	UPDATE dbo.rmSettings WITH (ROWLOCK)
	SET VValue = CONVERT(VARCHAR(200), CONVERT(BIGINT, @max_tstamp))
	WHERE VName = 'rmBettrans'
END
GO