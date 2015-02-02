USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Admin_Calculate_29_PreCal]    Script Date: 01/27/2015 23:48:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Admin_Calculate_29_PreCal    Script Date: 4/27/2012 11:03:35 AM ******/

/****** Object:  Stored Procedure dbo.Admin_Calculate_29_PreCal    Script Date: 8/23/2011 3:52:57 PM ******/




CREATE PROCEDURE [dbo].[Admin_Calculate_29_PreCal]
(
	@matchids VARCHAR(2000)
)
AS
/*
	Created: 
	Task : generate sub-ticket for combination
	DB: DBTrans.bodb02
	Original: 

	Revisions:
		- 20110712@Joe : created	
		- 20120426@Lukas: Get from production & exclude DB044
		- 20130822@Viet: exclude db043.
		
	Param's Explanation:
	@matchid: matchid of match to be settled
*/
BEGIN
	IF @matchids IS NULL RETURN
	IF @@SERVERNAME IN (N'DB043', N'DB044') RETURN

	-- GET List of refno concern for this match  
	--Declare @tmp_mrefno TABLE (refno bigint PRIMARY KEY CLUSTERED)  
	--INSERT INTO @tmp_mrefno (refno)
	--	SELECT refno FROM dbo.bettransm WITH (ROWLOCK) WHERE matchid = @matchid   

	DECLARE @temp_bettrans_pc TABLE (
		[transid] [bigint] NOT NULL ,  
		[refno] [bigint] PRIMARY KEY CLUSTERED,
		[stake] [money] NOT NULL,
		[N] [tinyint] NOT NULL, -- total selection (match)
		[cnt] [smallint] NOT NULL, -- total sub-ticket count
		[bitmap] [smallint] NOT NULL, -- bitmap to identify which parlay set is choosen
		[winlostdate] [smalldatetime] NOT NULL		
	)

	-- GET list of concern Ticket
	;WITH refnos AS (
		SELECT DISTINCT refno 
		FROM dbo.bettransm WITH (ROWLOCK)
		WHERE matchid IN (SELECT val FROM dbo.strSplit(@matchids, ','))
	)
	INSERT INTO @temp_bettrans_pc ([transid], [refno], [stake], [N], [cnt], [bitmap], [winlostdate])
		SELECT
			DISTINCT
			[transid], b.[refno], [stake], LEN(betteam), hdp1, hdp2, winlostdate
		FROM dbo.bettrans b WITH (ROWLOCK)  
			inner join refnos t ON b.refno = t.refno
		WHERE 
			b.matchid = 29
			AND statusID NOT IN (101,102) --('VOID','REJECT')
			AND betid = 0 -- main ticket of combination
			--AND refno IN (SELECT refno FROM refnos)

	
	-- delete record which already created Result/Detail
	DELETE T
	FROM @temp_bettrans_pc T
		INNER JOIN dbo.BetParlayResult pr ON T.refno = pr.refno
		
	

	-- Results list from both bettransm & bettransm14 (for only needed Combination Ticket)
	DECLARE @parlay_base TABLE (
			refno BIGINT, transid INT, winlostdate SMALLDATETIME, statuswinlost TINYINT, statusid TINYINT,
			matchid INT, bettype SMALLINT, odds SMALLMONEY, betteam NVARCHAR(10), hdp1 SMALLMONEY, hdp2 SMALLMONEY,
			livehomescore SMALLINT, liveawayscore SMALLINT, liveindicator BIT,
			RN TINYINT, -- set No. for selection in the combination
			CNT TINYINT, -- total selection count, base on bettransm/14
			bCNT TINYINT -- total selection count, stored in bettrans
			UNIQUE (refno, matchid)
		)

	INSERT INTO @parlay_base (
		refno, transid, winlostdate, statuswinlost, statusid,
		matchid, bettype, odds, betteam, hdp1, hdp2,
		livehomescore, liveawayscore, liveindicator
		)
		SELECT bm.refno, bm.transid, bm.winlostdate, statuswinlost, statusid,
		matchid, bettype, odds, betteam, hdp1, hdp2,
		livehomescore, liveawayscore, liveindicator
		FROM dbo.bettransm bm with (rowlock)
			INNER JOIN @temp_bettrans_pc tb ON bm.refno = tb.refno

	INSERT INTO @parlay_base (
		refno, transid, winlostdate, statuswinlost, statusid,
		matchid, bettype, odds, betteam, hdp1, hdp2,
		livehomescore, liveawayscore, liveindicator
		)
		SELECT bm.refno, bm.transid, bm.winlostdate, statuswinlost, statusid,
		matchid, bettype, odds, betteam, hdp1, hdp2,
		livehomescore, liveawayscore, liveindicator
		FROM dbo.bettransm14 bm with (rowlock)
			INNER JOIN @temp_bettrans_pc tb ON bm.refno = tb.refno

	-- prepare Seq of each refno
	;WITH sub AS (SELECT ROW_NUMBER() OVER (PARTITION BY refno ORDER BY matchid) RN, refno, matchid FROM @parlay_base)
	UPDATE pb
	SET RN = sub.RN
	FROM sub
		INNER JOIN @parlay_base pb ON sub.refno = pb.refno AND sub.matchid = pb.matchid

	-- prepare N
	;WITH sub AS (SELECT refno, count(*) cnt FROM @parlay_base GROUP BY refno)
	UPDATE pb
	SET CNT = sub.cnt, bCNT = t.N
	FROM sub
		INNER JOIN @parlay_base pb ON sub.refno = pb.refno
		INNER JOIN @temp_bettrans_pc t ON t.refno = pb.refno

	/* logic merge into above query, can remove this part later.
	UPDATE pb
	SET bCNT = sub.N
	FROM @temp_bettrans sub
	INNER JOIN @parlay_base pb ON sub.refno = pb.refno*/

	-- stop if got some ticket  CNT value is not match
	IF EXISTS (SELECT * FROM @parlay_base WHERE CNT <> bCNT)
	BEGIN
		PRINT 'ERROR cnt <> bcnt'
		RETURN -1
	END

	-- insert information into parlayDetail/Result
	INSERT INTO dbo.BetParlayDetail
		(RefNo, Serial, transid, winlostdate, statuswinlost, statusid, 
		matchid, bettype, stake, odds, betteam, hdp1, hdp2,
		livehomescore, liveawayscore, liveindicator)
	SELECT 
		pb.RefNo, rc.Serial, pb.transid, pb.winlostdate, statuswinlost, statusid, 
		matchid, bettype, tb.stake/tb.cnt, odds, betteam, hdp1, hdp2,
		livehomescore, liveawayscore, liveindicator
	FROM
		@parlay_base pb
		INNER JOIN @temp_bettrans_pc tb ON pb.refno = tb.refno
		INNER JOIN dbo.RefCombination rc ON pb.RN = rc.seq AND pb.CNT = rc.N AND (tb.bitmap&rc.bitmap) > 0
	

	INSERT INTO dbo.BetParlayResult
	(RefNo, Serial, transid, winlostdate, statusid, Stake, Odds, mOdds,
	winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm)
	SELECT
		DISTINCT tb.RefNo, rc.Serial, 0, tb.winlostdate, 0, tb.stake/tb.cnt, 0,0,
		0,0,0,0  ,0,0,0,0
	FROM
		@temp_bettrans_pc tb
		INNER JOIN dbo.RefCombination rc ON tb.N = rc.N AND (tb.bitmap&rc.bitmap) > 0	
	
END





GO

GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_29_PreCal] TO [vnteam] AS [dbo]
GO


