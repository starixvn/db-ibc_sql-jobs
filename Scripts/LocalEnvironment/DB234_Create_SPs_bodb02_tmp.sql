use bodb02_tmp
go

--drop proc [Task_Archive_Bet]
IF EXISTS (SELECT 1 FROM sys.procedures WHERE object_id = OBJECT_ID('[dbo].[Task_Archive_Bet]'))
BEGIN
	DROP PROCEDURE [dbo].[Task_Archive_Bet]
END
GO

CREATE PROCEDURE [dbo].[Task_Archive_Bet]
	@winlostdate datetime
AS
BEGIN
	SET NOCOUNT ON 

	DECLARE @bet TABLE (bettype int)
	INSERT INTO @bet
		SELECT distinct bettype
		FROM dbo.bettrans14 with (nolock)
		WHERE winlostdate = @winlostdate

	DECLARE bettypeCursor CURSOR
	READ_ONLY
	FOR select bettype from @bet

	DECLARE @bettype int
	OPEN bettypeCursor

	FETCH NEXT FROM bettypeCursor INTO @bettype
	WHILE (@@fetch_status <> -1)
	BEGIN
		IF (@@fetch_status <> -2)
		BEGIN

		INSERT INTO bodb_archive.dbo.bettrans_BK (
			transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, [status],statusID,
			winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking,
			playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam,
			creator, refno,  winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate,
			matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, tstamp,
			actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, virtualrate, oddstype, balance
		)
		SELECT transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, [status],statusID,
			winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking,
			playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam,
			creator, refno,  winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate,
			matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, tstamp,
			actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, virtualrate, oddstype, balance
		FROM dbo.bettrans14 with (nolock)
		WHERE winlostdate = @winlostdate AND bettype = @bettype
		END

		FETCH NEXT FROM bettypeCursor INTO @bettype
	END

	CLOSE bettypeCursor
	DEALLOCATE bettypeCursor

	--- ==============================================================	

		INSERT INTO DBSUM.bodb_Summary.dbo.sum_winloss_old
			(  winlostdate, username, custid, roleid, recommend, mrecommend, srecommend, turnover, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, betcount, grosscomm, sporttype, bettype  )
		SELECT winlostdate, username, custid, roleid, recommend, mrecommend, srecommend, turnover, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, betcount, grosscomm, sporttype, bettype
			FROM sum_winloss WHERE winlostdate = @winlostdate
		
	--- ==============================================================

		INSERT INTO bodb_archive.dbo.bettransm (
	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, statusID,
	winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, 
	comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, 
	apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, 
	playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, 
	matchid, matchdate, finalodds, isfinish, statuswinlost, ruben, bettype,
	spositiontaking, swinlost, sdiscount, scomm
	)
		SELECT transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, statusID,
		winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, 
			comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, 
			apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, 
			playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, 
			matchid, matchdate, finalodds, isfinish, statuswinlost, ruben, bettype,
			spositiontaking, swinlost, sdiscount, scomm
			FROM bettransm14 WHERE winlostdate = @winlostdate

	INSERT INTO bodb_archive.dbo.bettransG(transid, custid, transdate, oddsid, odds, stake, status, winlost, betteam, creator, refno, winlostdate, betfrom, checktime, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, statuswinlost, ruben, bettype, spositiontaking, swinlost, sdiscount, scomm, statusID, virtualrate, SiteID)
	SELECT transid, custid, transdate, oddsid, odds, stake, status, winlost, betteam, creator, refno, winlostdate, betfrom, checktime, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, statuswinlost, ruben, bettype, spositiontaking, swinlost, sdiscount, scomm, statusID, virtualrate, SiteID
	FROM bettransG14 WITH(NOLOCK)
	WHERE winlostdate = @winlostdate 

	
END
GO

--drop proc [Task_Archive_Statement]
IF EXISTS (SELECT 1 FROM sys.procedures WHERE object_id = OBJECT_ID('[dbo].[Task_Archive_Statement]'))
BEGIN
	DROP PROCEDURE [dbo].[Task_Archive_Statement]
END
GO

CREATE PROCEDURE [dbo].[Task_Archive_Statement]
	@winlostdate datetime
AS

-- Member - winlost & commission
INSERT INTO bodb_Report.dbo.statement
	select custid,winlostdate accdate,sum(winlost-actual_stake) totalamt,'BET' transtype, 'Betting' transdesc
	from bettrans14 bettrans with (nolock)
	where bettype between 1 and 19999 and winlostdate = @winlostdate
	group by winlostdate,custid
	--HAVING sum(winlost-actual_stake) <> 0

INSERT INTO bodb_Report.dbo.statement
	select custid,winlostdate accdate,sum(playercomm) totalamt,'COM' transtype, 'Commission' transdesc
	from bettrans14 bettrans  with (nolock)
	where bettype between 1 and 19999 and winlostdate = @winlostdate
	group by winlostdate,custid
	HAVING sum(playercomm) <> 0

-- Agent - position & commission
INSERT INTO bodb_Report.dbo.statement
	select recommend,winlostdate accdate,sum(awinlost) totalamt,'POS' transtype, 'Position' transdesc
	from bettrans14 bettrans with (nolock)
	where bettype between 1 and 19999 and winlostdate = @winlostdate
	group by winlostdate,recommend
	HAVING sum(awinlost) <> 0

INSERT INTO bodb_Report.dbo.statement
	select recommend,winlostdate accdate,sum(comm-playercomm) totalamt,'COM' transtype, 'Commission' transdesc
	from bettrans14 bettrans  with (nolock)
	where bettype between 1 and 19999 and winlostdate = @winlostdate
	group by winlostdate,recommend
	HAVING sum(comm-playercomm) <> 0

-- Master - position & commission
INSERT INTO bodb_Report.dbo.statement
	select mrecommend,winlostdate accdate,sum(mwinlost) totalamt,'POS' transtype, 'Position' transdesc
	from bettrans14 bettrans with (nolock)
	where bettype between 1 and 19999 and winlostdate = @winlostdate
	group by winlostdate,mrecommend
	HAVING sum(mwinlost) <> 0

INSERT INTO bodb_Report.dbo.statement
	select mrecommend,winlostdate accdate,sum(acomm-comm) totalamt,'COM' transtype, 'Commission' transdesc
	from bettrans14 bettrans with (nolock)
	where bettype between 1 and 19999 and winlostdate = @winlostdate
	group by winlostdate,mrecommend
	HAVING sum(acomm-comm) <> 0

-- Super - position & commission
INSERT INTO bodb_Report.dbo.statement
	select srecommend,winlostdate accdate,sum(swinlost) totalamt,'POS' transtype, 'Position' transdesc
	from bettrans14 bettrans with (nolock)
	where bettype between 1 and 19999 and winlostdate = @winlostdate
	group by winlostdate,srecommend
	HAVING sum(swinlost) <> 0

INSERT INTO bodb_Report.dbo.statement
	select srecommend,winlostdate accdate,sum(scomm-acomm) totalamt,'COM' transtype, 'Commission' transdesc
	from bettrans14 bettrans with (nolock)
	where bettype between 1 and 19999 and winlostdate = @winlostdate
	group by winlostdate,srecommend
	HAVING sum(scomm-acomm) <> 0
GO

--drop proc [Task_Archive_Transfer]
IF EXISTS (SELECT 1 FROM sys.procedures WHERE object_id = OBJECT_ID('[dbo].[Task_Archive_Transfer]'))
BEGIN
	DROP PROCEDURE [dbo].[Task_Archive_Transfer]
END
GO

CREATE PROCEDURE [dbo].[Task_Archive_Transfer]  
	@BU_Date datetime -- BalanceUp Date  
AS  
Declare @CurrentBU_Date datetime  
SELECT TOP 1 @CurrentBU_Date = winlostdate  
FROM dbo.transfer with (nolock)  
WHERE bettype = 20000  
  
-- OpenBalance & Transfer for Statement  
INSERT INTO bodb_Report.dbo.statement  (custid, accdate, totalamt, transtype, transdesc)  
select  
	custid, 
	transdate accdate,
	sum(winlost-actual_stake) totalamt,
	typenamee transtype,
	transdesc  
from  
	dbo.Transfer t  with (nolock)  
	inner join dbo.bettype bt with (nolock) on t.bettype=bt.typeid  
where  
	t.bettype >= 20000 --between 100 and 106 --AND transdate >= @fromdate   
	AND winlostdate >= @CurrentBU_Date AND winlostdate < @BU_Date and custid <> 0  
	group by custid, typenamee,transdesc,transdate,transid  
	having sum(winlost-actual_stake) <> 0  
   
-- Transfer Archive  
INSERT INTO bodb_Archive.dbo.Transfer_BK  
	(transid, custid, transdate, Debit, Credit, TransDesc, winlostdate, recommend, mrecommend, srecommend, bettype, currency, refno, creator)  
SELECT  
	transid, 
	custid, 
	transdate, 
	actual_stake, 
	winlost, 
	TransDesc, 
	winlostdate, 
	recommend, 
	mrecommend, 
	srecommend, 
	bettype, 
	currency, 
	refno, 
	creator  
FROM dbo.Transfer with (nolock)  
WHERE  
	bettype > 20000  
	AND winlostdate >= @CurrentBU_Date AND  winlostdate < @BU_Date  
	AND custid <> 0 AND (winlost + actual_stake) <> 0
GO

IF EXISTS (SELECT 1 FROM sys.procedures WHERE object_id = OBJECT_ID('[dbo].[ExecRep_02]'))
BEGIN
	DROP PROCEDURE [dbo].[ExecRep_02]
END
GO

CREATE PROCEDURE [dbo].[ExecRep_02]
	@tmp1 [sql_variant] = NULL,
	@tmp2 [sql_variant] = NULL,
	@tmp3 [sql_variant] = NULL,
	@winlostdate [datetime] = NULL,
	@Command [varchar](20) = NULL
WITH EXECUTE AS CALLER
AS
BEGIN
	SET NOCOUNT ON
	IF @Command IS NULL OR @winlostdate IS NULL
	BEGIN
		PRINT 'Invalid input parameters'
		RETURN
	END

	IF CONVERT(varchar(10), @winlostdate, 120) <> @winlostdate
	BEGIN
		PRINT 'Invalid input parameters'
		RETURN
	END

	IF -- below is ACCEPTED case
	(
		(@Command = 'ALL_DB') -- delete on all server
		OR
		(@Command = 'Except_DB02' AND @@ServerName <> 'DB02') 
	)
	BEGIN
		-- =================
		-- BEGIN DELETE DATA
		-- =================
		PRINT 'DELETE DATA'

		Declare @rc int
		SET @rc = 1
		WHILE @RC > 0
		BEGIN
			DELETE TOP (100000)
			FROM bettrans14 with (ROWLOCK)
			WHERE winlostdate = @winlostdate

			SET @rc = @@ROWCOUNT
		END

		SET @rc = 1
		WHILE @RC > 0
		BEGIN
			DELETE TOP (10000)
			FROM bettransm14 with (ROWLOCK)
			WHERE winlostdate = @winlostdate

			SET @rc = @@ROWCOUNT
		END

		SET @rc = 1
		WHILE @RC > 0
		BEGIN
			DELETE TOP (10000)
			FROM bettransG14 with (ROWLOCK)
			WHERE winlostdate = @winlostdate

			SET @rc = @@ROWCOUNT
		END

		SET @rc = 1
		WHILE @RC > 0
		BEGIN
			DELETE TOP (10000)
			FROM Betparlayresult with (ROWLOCK)
			WHERE winlostdate = @winlostdate

			SET @rc = @@ROWCOUNT
		END

		SET @rc = 1
		WHILE @RC > 0
		BEGIN
			DELETE TOP (5000)
			FROM sum_winloss with (ROWLOCK)
			WHERE winlostdate = @winlostdate

			SET @rc = @@ROWCOUNT
		END

		-- =====
		--  END
		-- =====
	END

	ELSE
	-- Below is UN-ACCEPTED CASE
	BEGIN
		IF @Command = 'Except_DB02' AND @@ServerName = 'DB02'
			PRINT 'DB02 Exception'	
		ELSE
		BEGIN
			PRINT 'Invalid input parameters'
			RETURN
		END
	END

	SET NOCOUNT OFF
END
GO

IF EXISTS (SELECT 1 FROM sys.procedures WHERE object_id = OBJECT_ID('[dbo].[Task_Archive_Event]'))
BEGIN
	DROP PROCEDURE [dbo].[Task_Archive_Event]
END
GO

CREATE PROCEDURE [dbo].[Task_Archive_Event]
	@winlostdate datetime
AS
	INSERT INTO bodb_archive.dbo.odds_bk(oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, odds1b, odds2b, odds1c, odds2c, odds1e, odds2e, odds1f, odds2f, odds1d, odds2d, odds1hka, odds2hka, odds1hkb, odds2hkb, odds1hkc, odds2hkc, odds1hke, odds2hke, odds1hkf, odds2hkf, odds1hkd, odds2hkd, oddsspreada, oddsspreadb, oddsspreadd, oddsspreade, oddsspreadf, oddsspreadc, autobookie, gapodds1, gapodds2, maxstake1, maxstake2, minstake1, minstake2, diffbalance, maxodds, minodds, oddsstatus, liveindicator, changetime, risk, stakerange, newoffersetup, livehomescore, liveawayscore, creator, com1, comx, com2, cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32, cs33, cs23, cs13, cs03, cs43, cs42, cs41, cs40, cs44, cs14, cs24, cs04, cs34, cs50, cs05, comstatus, csstatus, commaxbet, csmaxbet, com1total, comxtotal, com2total, bal00, bal10, bal11, bal01, bal20, bal21, bal22, bal12, bal02, bal30, bal31, bal32, bal33, bal23, bal13, bal03, bal40, bal41, bal42, bal43, bal44, bal34, bal24, bal14, bal04, bal50, bal05, maxbet, ht, autoreject, allowance, autosuspend, multiple, stakerange2, risk2, allowance2, site2, site3, site4, hometotal, awaytotal, sporttype)
		SELECT oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, odds1b, odds2b, odds1c, odds2c, odds1e, odds2e, odds1f, odds2f, odds1d, odds2d, odds1hka, odds2hka, odds1hkb, odds2hkb, odds1hkc, odds2hkc, odds1hke, odds2hke, odds1hkf, odds2hkf, odds1hkd, odds2hkd, oddsspreada, oddsspreadb, oddsspreadd, oddsspreade, oddsspreadf, oddsspreadc, autobookie, gapodds1, gapodds2, maxstake1, maxstake2, minstake1, minstake2, diffbalance, maxodds, minodds, oddsstatus, liveindicator, changetime, risk, stakerange, newoffersetup, livehomescore, liveawayscore, creator, com1, comx, com2, cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32, cs33, cs23, cs13, cs03, cs43, cs42, cs41, cs40, cs44, cs14, cs24, cs04, cs34, cs50, cs05, comstatus, csstatus, commaxbet, csmaxbet, com1total, comxtotal, com2total, bal00, bal10, bal11, bal01, bal20, bal21, bal22, bal12, bal02, bal30, bal31, bal32, bal33, bal23, bal13, bal03, bal40, bal41, bal42, bal43, bal44, bal34, bal24, bal14, bal04, bal50, bal05, maxbet, ht, autoreject, allowance, autosuspend, multiple, stakerange2, risk2, allowance2, site2, site3, site4, hometotal, awaytotal, sporttype
		FROM odds14 WHERE matchid in (select matchid from match14 where eventdate = @winlostdate)
	
	INSERT INTO bodb_archive.dbo.match_bk(matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore,
			finalhomescore, finalawayscore, creator, matchcode, kickofftime, closedtime, showtime,
			hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype,
			homeid2, awayid2, DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral, GoalRecord)
		SELECT
			matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore,
			finalhomescore, finalawayscore, creator, matchcode, kickofftime, closedtime, showtime,
			hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype,
			homeid2, awayid2, DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral, GoalRecord
		FROM match14 WHERE eventdate = @winlostdate
	
	INSERT INTO bodb_archive.dbo.bingoBall_bk
		([Matchid], [Seq], [Number], [UpdateTime])
	SELECT
		[Matchid], [Seq], [Number], [UpdateTime]
	FROM BingoBall14
	WHERE MatchID in (SELECT MatchID from Match14 where eventdate = @winlostdate)
	
	INSERT INTO bodb_archive.dbo.outright_bk
		(orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, creator, bal, risk, 
        DisplayMode, PlaceOdds, Placing, IsFavor, IsSCR, ProgramID, 
		FOddsStatus, SCRTime)
		SELECT orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, creator, bal, risk, 
                      DisplayMode, PlaceOdds, Placing, IsFavor, IsSCR, ProgramID, FOddsStatus, SCRTime
		FROM outright14 WHERE eventdate = @winlostdate

	INSERT INTO bodb_Archive.dbo.match_remark
		(
		[matchid], [calculate], [multiple], [calrefund], [refund], [calStatus], [IsTotalBetDenied_1], [IsTotalBetDenied_3], [IsTotalBetDenied_7], [IsTotalBetDenied_8],
		[LiveTimer], [HomeRedCard], [AwayRedCard], [LivePeriod], [HedgeForecast], [IsTotalBetDenied_20], [IsTotalBetDenied_21], [IsNeutral], [StreamingID], [IsInternal], [IsHTCal],
		[LiveDeleteChecker], [HomeColor], [AwayColor], [ConfirmHT], [ConfirmFT], [PausePeriod], [TimerSuspend], [IsPending], [isUndecided], [StdDelBetCheck],
		HomeSubstitutes,AwaySubstitutes,StartTeam,HomePenalty,AwayPenalty,HomeYellowCard,AwayYellowCard
		)
	
	SELECT
		[matchid], [calculate], [multiple], [calrefund], [refund], [calStatus], [IsTotalBetDenied_1], [IsTotalBetDenied_3], [IsTotalBetDenied_7], [IsTotalBetDenied_8],
		[LiveTimer], [HomeRedCard], [AwayRedCard], [LivePeriod], [HedgeForecast], [IsTotalBetDenied_20], [IsTotalBetDenied_21], [IsNeutral], [StreamingID], [IsInternal], [IsHTCal],
		[LiveDeleteChecker], [HomeColor], [AwayColor], [ConfirmHT], [ConfirmFT], [PausePeriod], [TimerSuspend], [IsPending], [isUndecided], [StdDelBetCheck],
		HomeSubstitutes,AwaySubstitutes,StartTeam,HomePenalty,AwayPenalty,HomeYellowCard,AwayYellowCard
	FROM match_remark WITH (NOLOCK)
	WHERE MatchID in (SELECT MatchID from Match14 WITH (NOLOCK) where eventdate = @winlostdate)
	
	DELETE FROM odds14  WHERE matchid in (select matchid from match14 where eventdate = @winlostdate)
	DELETE FROM BingoBall14 WHERE matchid in (select matchid from match14 where eventdate = @winlostdate)
	DELETE FROM match_Remark WHERE matchid in (select matchid from match14 where eventdate = @winlostdate)
	DELETE FROM outright14 WHERE eventdate = @winlostdate
	DELETE FROM match14 WHERE eventdate = @winlostdate

	--EXEC ExecRep_02 @winlostdate

	--DELETE FROM bettranssum WHERE winlostdate = @winlostdate
GO

IF EXISTS (SELECT 1 FROM sys.procedures WHERE object_id = OBJECT_ID('[dbo].[BalanceCheck]'))
BEGIN
	DROP PROCEDURE [dbo].[BalanceCheck]
END
GO

CREATE PROCEDURE [dbo].[BalanceCheck]
WITH EXECUTE AS CALLER
AS
--exec companybalance2
SELECT '1 companybalance2' command,
	sum((winlost-actual_stake+awinlost+mwinlost+swinlost +scomm)*e.actualrate) totalamt,
	sum((winlost-actual_stake+awinlost+mwinlost+swinlost +scomm)) TotalSUM
from Transfer t with (nolock) 
	inner join DB232.custdb_tmp.dbo.exchange e with (nolock) ON t.currency=e.exchangeid 
UNION ALL
--exec admin_rpt_sabalance
SELECT '2 admin_rpt_sabalance' command,
	SUM(e.actualrate * IsNull(bal,0)) bal,
	SUM( IsNull(bal,0)) bal2
FROM DB232.custdb_tmp.dbo.customer c (nolock)
	LEFT OUTER JOIN (
					SELECT srecommend,
					  IsNull(sum(case when custid=srecommend then winlost-actual_stake else swinlost+scomm-acomm end),0)
					+ IsNull(sum(case when custid=mrecommend then winlost-actual_stake else mwinlost+acomm-comm end),0)
					+ IsNull(sum(case when custid=recommend  then winlost-actual_stake else awinlost+comm-playercomm end),0)
					+ IsNull(sum(case when custid <> recommend and custid <> mrecommend and custid <> srecommend and ruben=1 then winlost-actual_stake+playercomm else 0 end),0) Bal
					FROM dbo.transfer t (nolock) GROUP BY t.srecommend
				) bal ON c.custid = bal.srecommend
INNER JOIN DB232.custdb_tmp.dbo.exchange e (nolock) ON c.currency = e.exchangeid
WHERE c.roleid = 4
GO

IF EXISTS (SELECT 1 FROM sys.procedures WHERE object_id = OBJECT_ID('[dbo].[ExecRep_00]'))
BEGIN
	DROP PROCEDURE [dbo].[ExecRep_00]
END
GO

CREATE PROCEDURE [dbo].[ExecRep_00]
	@winlostdate datetime
AS
--SET NOCOUNT ON
-- called from procedure BBU
Declare @loop varchar(1)
SET @loop = 'y'

WHILE @loop = 'y'
BEGIN
	BEGIN TRANSACTION
	DELETE TOP (10000) bettrans WITH(ROWLOCK,UPDLOCK)
	WHERE winlostdate < @winlostdate

	IF @@ROWCOUNT = 0 SET @loop = 'n'
	COMMIT TRANSACTION
END
GO

IF EXISTS (SELECT 1 FROM sys.procedures WHERE object_id = OBJECT_ID('[dbo].[Task_BalanceUp]'))
BEGIN
	DROP PROCEDURE [dbo].[Task_BalanceUp]
END
GO

CREATE PROCEDURE [dbo].[Task_BalanceUp]
	@fdate as datetime,
	@continue as bit = 0
AS

/*
Created: 
Task : 

DB: DBTRANS.bodb02
Original:

Revisions:
	-- 20110523@Henry: change bettype to new range
	-- 20110826@Sophia: Add Linked Server DB02 for table match, odd, livescore. Change Server to DBTRANS instead of DB02.
	
Param's Explanation: 

*/	
BEGIN
	SET @fdate = CONVERT(nvarchar(10), @fdate, 120)
	IF (DATEPART(weekday, @fdate) <> 2) AND (@continue = 0)
	BEGIN
		PRINT 'Input date is not Monday'
		PRINT 'If you really want to continue, call with @continue = 1'
		RETURN
	END

	--- DATA VERIFY
	IF EXISTS (SELECT * FROM DB232.custdb_tmp.dbo.Customer with (nolock) WHERE (recommend is null or mrecommend is null or srecommend is null) AND roleid <= 2)
	BEGIN
		SELECT 'Some Customer/Agent records have NULL AgentID' Result
		SELECT custid, username, roleid, recommend, mrecommend, srecommend, currency
			FROM DB232.custdb_tmp.dbo.customer with (nolock)
			WHERE roleid <= 2
			AND (recommend is NULL or mrecommend is NULL or srecommend is NULL)
		RETURN
	END
	IF EXISTS (SELECT * FROM DB232.custdb_tmp.dbo.customer with (nolock) WHERE (recommend is NULL or mrecommend is null or srecommend is null) AND roleid = 3)
	BEGIN
		SELECT 'Some Master records have NULL AgentID' Result
		SELECT custid, username, roleid, recommend, mrecommend, srecommend, currency
			FROM DB232.custdb_tmp.dbo.customer with (nolock)
			WHERE roleid = 3
			AND (recommend is NULL or mrecommend is NULL or srecommend is NULL)
		RETURN
	END
	IF EXISTS (SELECT * FROM DB232.custdb_tmp.dbo.customer with (nolock) WHERE (recommend is NULL or mrecommend is null or srecommend is null) AND roleid = 4)
	BEGIN
		SELECT 'Some SuperAgent records have NULL AgentID' Result
		SELECT custid, username, roleid, recommend, mrecommend, srecommend, currency
			FROM DB232.custdb_tmp.dbo.customer with (nolock)
			WHERE roleid = 4
			AND (recommend is NULL or mrecommend is NULL or srecommend is NULL)
		RETURN
	END
	IF EXISTS (SELECT * FROM Transfer with (nolock) WHERE (srecommend is null or mrecommend is null or recommend is null) AND winlostdate < @fdate)
	BEGIN
		SELECT 'Some records in BetTrans have NULL AgentID' Result
		SELECT transid, custid, recommend, mrecommend, srecommend, currency
			FROM bettrans with (nolock)
			WHERE (recommend is NULL or mrecommend is NULL or srecommend is NULL) AND winlostdate < @fdate
		RETURN
	END

	IF EXISTS (SELECT * FROM Transfer with (nolock) WHERE (swinlost is null or mwinlost is null or awinlost is null or winlost is null) AND winlostdate < @fdate)
	BEGIN
		SELECT 'Some records in BetTrans have NULL winlost' Result
		RETURN
	END
	IF EXISTS (SELECT * FROM Transfer with (nolock) WHERE (scomm is null or acomm is null or comm is null or playercomm is null) AND winlostdate < @fdate)
	BEGIN
		SELECT 'Some records in BetTrans have NULL commission' Result
		RETURN
	END

	IF EXISTS (SELECT * FROM Transfer with (nolock) WHERE (scomm <> acomm OR swinlost <> 0) AND bettype <= 9 AND winlostdate < @fdate AND srecommend <= 100)
	BEGIN
		SELECT 'Some records in BetTrans have incorrect Company SuperAgent setting' Result
		SELECT transid, srecommend, sdiscount, adiscount, spositiontaking, scomm, acomm, swinlost 
			FROM bettrans with (nolock)
			WHERE (scomm <> acomm OR swinlost <> 0) AND bettype <= 19000 AND winlostdate < @fdate AND srecommend <= 100
		RETURN
	END

	--- START --- START --- START ---
	--- START --- START --- START ---
	--- START --- START --- START ---
	-- verify @fdate
	Declare @testdate datetime
	SET @testdate = CONVERT(varchar(10), @fdate, 120)
	IF @testdate <> @fdate
	BEGIN
		SELECT 'ERROR: Input parameter is DATE value with TIME.' Result
		RETURN
	END

	EXEC dbo.balancecheck
	-- doing backup
	--Declare @suffix varchar(10)
	--SET @suffix = 'bbu' + RIGHT(CONVERT(varchar(10), @fdate,120),5)
	--EXEC dbo.Task_BackupFULL @suffix
	-- doing backup : end

	-- =====================
	--   CALCULATE BALANCE
	-- =====================
	BEGIN TRANSACTION
		delete from dbo.balancetable;
		DELETE FROM balancetable_tmp
		-- Member
		insert into dbo.balancetable(custid, amount)
		select 	bettrans.custid custid, 
			sum(winlost-actual_stake + playercomm) amount
		from
			dbo.bettrans with (nolock)
			--INNER JOIN dbo.custinfo c with (nolock) ON bettrans.custid = c.custid
		where
			ruben = 1 and
			winlostdate < @fdate and
			bettrans.custid <> bettrans.recommend and
			bettrans.custid <> bettrans.mrecommend and
			bettrans.custid <> bettrans.srecommend
		group by bettrans.custid;

		-- Agent
		insert into dbo.balancetable (custid, amount)
		select	bettrans.recommend custid,
			sum(case
			when bettrans.custid=bettrans.recommend then winlost-actual_stake
			else awinlost+comm-playercomm
			end) amount
		from
			dbo.bettrans with (nolock)
			--INNER JOIN dbo.custinfo c with (nolock) ON bettrans.custid = c.custid
		where
			ruben=1 and 
			winlostdate < @fdate
		group by bettrans.recommend;

		-- Master
		insert into dbo.balancetable (custid, amount)
		select	bettrans.mrecommend custid,
			sum(case
			when bettrans.custid=bettrans.mrecommend then winlost-actual_stake
			else mwinlost+acomm-comm
			end) amount
		from
			dbo.bettrans with (nolock)
			--INNER JOIN dbo.custinfo c with (nolock) ON bettrans.custid = c.custid
		where
			ruben=1 and 
			winlostdate < @fdate
		group by bettrans.mrecommend;

		-- Super
		insert into dbo.balancetable (custid, amount)
		select	bettrans.srecommend custid,
			sum(case
			when bettrans.custid=bettrans.srecommend then winlost-actual_stake
			else swinlost+scomm-acomm
			end) amount
		from
			dbo.bettrans with (nolock)
			--INNER JOIN dbo.custinfo c with (nolock) ON bettrans.custid = c.custid
		where
			ruben=1 and 
			winlostdate < @fdate
		group by bettrans.srecommend;
	COMMIT TRANSACTION

	BEGIN TRANSACTION
		-- Delete NO-Balance record
		delete from balancetable where amount = 0
		AND awinlost = 0 AND mwinlost = 0 AND swinlost = 0
		AND playercomm = 0 AND comm = 0 AND acomm = 0 AND scomm = 0
			--abs(amount) < 0.01

		-- Update needed value
		update balancetable
		set
			recommend = c.recommend,
			mrecommend= c.mrecommend,
			srecommend= c.srecommend,
			currency  = c.currency,
			UserName  = c.username,
			CurrencyName = e.currency,
			actualrate = e.actualrate
		from DB232.custdb_tmp.dbo.custinfo c, DB232.custdb_tmp.dbo.exchange e
		where
			c.custid = balancetable.custid
			AND c.currency = e.exchangeid

		-- copy data, ready for insertion
		INSERT INTO dbo.balancetable_tmp
		SELECT @fdate, * FROM dbo.balancetable
		WHERE custid > 0
		
		EXEC ExecRep_00 @fdate
		
	COMMIT TRANSACTION

	-- =====================
	--   CLEAN OLD RECORDS
	-- =====================

		-- move to ExecRep_00
		-- delete from bettrans where ruben=1 and winlostdate < @fdate 
		

	--insert into sbo.dbo.match select * from match where matchid not in (select distinct matchid from bettrans where bettype between 1 and 8) and kickofftime < @fdate
	--insert into sbo.dbo.odds select * from odds where matchid not in (select matchid from match)
	/*
	delete from DB02.bodb02.dbo.match where matchid not in (select distinct matchid from bettrans where bettype <= 19000) 	and kickofftime < @fdate
	delete from DB02.bodb02.dbo.odds where matchid not in (select matchid from match)
	delete from DB02.bodb02.dbo.liveScore where matchid not in (select matchid from match (nolock) union all select matchid from match14 (nolock))
	*/
	WAITFOR DELAY '000:00:10.000'

	-- ======================
	--   INSERT NEW BALANCE
	-- ======================

	SET NOCOUNT ON

	Declare @loop varchar(1)
	SET @loop = 'y'
	WHILE @loop = 'y'
	BEGIN
		BEGIN TRANSACTION
		DELETE TOP(10000) FROM dbo.balanceTable_tmp
		
		IF @@ROWCOUNT = 0 SET @loop = 'n'
		COMMIT TRANSACTION

		WAITFOR DELAY '000:00:10.00'
	END

	SET NOCOUNT OFF


	EXEC dbo.balancecheck
END
GO

GO
ALTER TRIGGER [dbo].[step2_balance_insert]
   ON  [dbo].[balanceTable_tmp]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
		insert into dbo.Transfer 
			(transdate, winlostdate, custid, checktime,
			winlost, actual_stake, 
			awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm,
			bettype, [statusID], transdesc, refno, creator,
			recommend, mrecommend, srecommend, currency,
			username, currencyname, actualrate)
		select 	winlostdate, winlostdate, custid, CURRENT_TIMESTAMP,
			(case when amount < 0 then 0 else amount end),
			(case when amount < 0 then abs(amount) else 0 end),
			awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm,
			20000, 141, 'OPENING BALANCE', 260000000000, 148,
			recommend, mrecommend, srecommend, currency,
			UserName, CurrencyName, actualrate
		from deleted
		WHERE NOT (amount = 0
	AND awinlost = 0 AND mwinlost = 0 AND swinlost = 0
	AND playercomm = 0 AND comm = 0 AND acomm = 0 AND scomm = 0)

END
GO

--enabled trigger in table balance_tmp before run balanceup process
--ENABLE TRIGGER step1_change_winlostdate ON balanceTable_tmp
GO
ENABLE TRIGGER step2_balance_insert ON balanceTable_tmp
GO





