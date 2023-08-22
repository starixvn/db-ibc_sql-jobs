/*<info serverAlias="DBSUM-bodb_Summary"></info>*/
CREATE PROCEDURE [dbo].[Task_Sum_Winloss_Old_Manual_Gen]
	@wldate	SMALLDATETIME
AS

/*
Create: 20230822@Lewis
Task: Manual ReGen Data: DBACC.bodb_Archive.dbo.sum_winloss_old_tmp --> DBSUM.bodb_Summary.dbo.sum_winloss_old  
DB: DBSUM-bodb_Summary

Description:
		1. Insert into sum_winloss_old_tmp by Task_Sum_Winloss_Old (DBACC-bodb02)
		2. Run sp to reGen for sum_winloss_old (DBSUM-bodb_Summary)

Revision:
		- 20230822@Lewis: Initial SP - MG_RNG - Duplicated data for product [RedmineID: #192923]
*/

-- ==============================================
-- Get data sum_winloss_old_tmp from DB06 to DB05
-- ==============================================
BEGIN
    SET NOCOUNT ON

	CREATE TABLE #sum_winloss_old_tmp
	(
		winlostdate			SMALLDATETIME
		,username			NVARCHAR(50)
		,custid				INT
		,roleid				INT
		,recommend			INT
		,mrecommend			INT
		,srecommend			INT
		,turnover			MONEY
		,winlost			MONEY
		,awinlost			MONEY
		,mwinlost			MONEY
		,swinlost			MONEY
		,playercomm			MONEY
		,comm				MONEY
		,acomm				MONEY
		,scomm				MONEY
		,BetCount			INT
		,grosscomm			MONEY
		,sporttype			SMALLINT
		,bettype			SMALLINT
		,netTurnover		MONEY
		,TurnoverNoDraw		MONEY
		,ExtraWinloss		MONEY NULL
		,ExtraComm			MONEY NULL
		,leagueGroupID		SMALLINT
		,ticketType			TINYINT
	)
	INSERT INTO #sum_winloss_old_tmp
	(
		winlostdate
		,username
		,custid
		,roleid
		,recommend
		,mrecommend
		,srecommend
		,turnover
		,winlost
		,awinlost
		,mwinlost
		,swinlost
		,playercomm
		,comm
		,acomm
		,scomm
		,BetCount
		,grosscomm
		,sporttype
		,bettype
		,netTurnover
		,TurnoverNoDraw
		,ExtraWinloss
		,ExtraComm
		,leagueGroupID
		,ticketType
	)
	SELECT
		winlostdate
		,username
		,custid
		,roleid
		,recommend
		,mrecommend
		,srecommend
		,turnover
		,winlost
		,awinlost
		,mwinlost
		,swinlost
		,playercomm
		,comm
		,acomm
		,scomm
		,BetCount
		,grosscomm
		,sporttype
		,bettype
		,netTurnover
		,TunroverNoDraw
		,ExtraWinloss
		,ExtraComm
		,leagueGroupID
		,ticketType
	FROM DBACC.bodb_Archive.dbo.sum_winloss_old_tmp WITH (NOLOCK)
	WHERE winlostdate = @wldate

-- ====================
-- Compare before regen
-- ====================

	CREATE TABLE #sum_winloss_old
	(
		keyid				BIGINT
		,winlostdate		SMALLDATETIME
		,username			NVARCHAR(50)
		,custid				INT
		,roleid				INT
		,recommend			INT
		,mrecommend			INT
		,srecommend			INT
		,turnover			MONEY
		,winlost			MONEY
		,awinlost			MONEY
		,mwinlost			MONEY
		,swinlost			MONEY
		,playercomm			MONEY
		,comm				MONEY
		,acomm				MONEY
		,scomm				MONEY
		,BetCount			INT
		,grosscomm			MONEY
		,sporttype			SMALLINT
		,bettype			SMALLINT
		,netTurnover		MONEY
		,TurnoverNoDraw		MONEY
		,ExtraWinloss		MONEY NULL
		,ExtraComm			MONEY NULL
		,leagueGroupID		SMALLINT
		,ticketType			TINYINT
	)
	INSERT INTO #sum_winloss_old
	(
		keyid
		,winlostdate
		,username
		,custid
		,roleid
		,recommend
		,mrecommend
		,srecommend
		,turnover
		,winlost
		,awinlost
		,mwinlost
		,swinlost
		,playercomm
		,comm
		,acomm
		,scomm
		,BetCount
		,grosscomm
		,sporttype
		,bettype
		,netTurnover
		,TurnoverNoDraw
		,ExtraWinloss
		,ExtraComm
		,leagueGroupID
		,ticketType
	)
	SELECT
		keyid
		,winlostdate
		,username
		,custid
		,roleid
		,recommend
		,mrecommend
		,srecommend
		,turnover
		,winlost
		,awinlost
		,mwinlost
		,swinlost
		,playercomm
		,comm
		,acomm
		,scomm
		,BetCount
		,grosscomm
		,sporttype
		,bettype
		,netTurnover
		,TunroverNoDraw
		,ISNULL(ExtraWinloss, 0) AS ExtraWinloss
		,ISNULL(ExtraComm, 0) AS ExtraComm
		,leagueGroupID		
		,ticketType			
	FROM dbo.sum_winloss_old s WITH (NOLOCK)
	WHERE s.winlostdate = @wldate
		AND EXISTS (SELECT 1 FROM #sum_winloss_old_tmp s_old WHERE s.custid = s_old.custid AND s.sporttype = s_old.sporttype)

	DECLARE @RowCount INT = 0
	;WITH CTE_s AS
		(
			SELECT
				winlostdate
				,custid
				,SUM(turnover) turnover
				,SUM(winlost) winlost
				,SUM(awinlost) awinlost
				,SUM(mwinlost) mwinlost
				,SUM(swinlost) swinlost
				,SUM(playercomm) playercomm
				,SUM(comm) comm
				,SUM(acomm) acomm
				,SUM(scomm) scomm
				,SUM(BetCount) BetCount
				,SUM(grosscomm) grosscomm
				,SUM(netTurnover) netTurnover
				,SUM(TurnoverNoDraw) TurnoverNoDraw
				,SUM(ExtraWinloss) AS ExtraWinloss
				,SUM(ExtraComm) AS ExtraComm	
			FROM #sum_winloss_old s WITH (NOLOCK)
			GROUP BY 
				winlostdate
				,custid
		),
	 CTE_old AS
		(
			SELECT
				winlostdate
				,custid
				,SUM(turnover) turnover
				,SUM(winlost) winlost
				,SUM(awinlost) awinlost
				,SUM(mwinlost) mwinlost
				,SUM(swinlost) swinlost
				,SUM(playercomm) playercomm
				,SUM(comm) comm
				,SUM(acomm) acomm
				,SUM(scomm) scomm
				,SUM(BetCount) BetCount
				,SUM(grosscomm) grosscomm
				,SUM(netTurnover) netTurnover
				,SUM(TurnoverNoDraw) TurnoverNoDraw
				,SUM(ExtraWinloss) AS ExtraWinloss
				,SUM(ExtraComm) AS ExtraComm	
			FROM #sum_winloss_old_tmp s WITH (NOLOCK)
			GROUP BY 
				winlostdate
				,custid
		)
		SELECT @RowCount = COUNT(1)
		FROM CTE_s s
			FULL OUTER JOIN CTE_old old
				ON		s.winlostdate	= old.winlostdate
					AND s.custid		= old.custid
		WHERE old.custid IS NULL
			OR s.custid IS NULL
			OR old.turnover				<> s.turnover
			OR old.winlost				<> s.winlost
			OR old.awinlost				<> s.awinlost
			OR old.mwinlost				<> s.mwinlost
			OR old.swinlost				<> s.swinlost
			OR old.playercomm			<> s.playercomm
			OR old.comm					<> s.comm
			OR old.acomm				<> s.acomm
			OR old.scomm				<> s.scomm
			OR old.BetCount				<> s.BetCount
			OR old.grosscomm			<> s.grosscomm
			OR old.netTurnover			<> s.netTurnover
			OR old.TurnoverNoDraw		<> s.TurnoverNoDraw
			OR old.ExtraWinloss			<> s.ExtraWinloss
			OR old.ExtraComm			<> s.ExtraComm


-- =========
-- Regen
-- =========

	IF @RowCount <> 0
	BEGIN
		MERGE dbo.sum_winloss_old AS TARGET
		USING #sum_winloss_old_tmp AS SOURCE
			ON		TARGET.winlostdate	= SOURCE.winlostdate
				AND	TARGET.custid		= SOURCE.custid
				AND TARGET.sporttype	= SOURCE.sporttype
				AND TARGET.bettype		= SOURCE.bettype
				AND TARGET.leagueGroupID = SOURCE.leagueGroupID
				AND TARGET.ticketType	= SOURCE.ticketType
		WHEN MATCHED THEN 
		UPDATE
			SET	TARGET.username			= SOURCE.username
				,TARGET.roleid			= SOURCE.roleid
				,TARGET.recommend		= SOURCE.recommend
				,TARGET.mrecommend		= SOURCE.mrecommend
				,TARGET.srecommend		= SOURCE.srecommend
				,TARGET.turnover		= SOURCE.turnover
				,TARGET.winlost			= SOURCE.winlost
				,TARGET.awinlost		= SOURCE.awinlost
				,TARGET.mwinlost		= SOURCE.mwinlost
				,TARGET.swinlost		= SOURCE.swinlost
				,TARGET.playercomm		= SOURCE.playercomm
				,TARGET.comm			= SOURCE.comm
				,TARGET.acomm			= SOURCE.acomm
				,TARGET.scomm			= SOURCE.scomm
				,TARGET.BetCount		= SOURCE.BetCount
				,TARGET.grosscomm		= SOURCE.grosscomm
				,TARGET.netTurnover		= SOURCE.netTurnover
				,TARGET.TunroverNoDraw	= SOURCE.TurnoverNoDraw
				,TARGET.ExtraWinloss	= SOURCE.ExtraWinloss
				,TARGET.ExtraComm		= SOURCE.ExtraComm
		WHEN NOT MATCHED BY TARGET THEN 
		INSERT (
				winlostdate
				,username
				,custid
				,roleid
				,recommend
				,mrecommend
				,srecommend
				,turnover
				,winlost
				,awinlost
				,mwinlost
				,swinlost
				,playercomm
				,comm
				,acomm
				,scomm
				,BetCount
				,grosscomm
				,sporttype
				,bettype
				,netTurnover
				,TunroverNoDraw
				,ExtraWinloss
				,ExtraComm
				,leagueGroupID
				,ticketType
				)
		VALUES (
				SOURCE.winlostdate
				,SOURCE.username
				,SOURCE.custid
				,SOURCE.roleid
				,SOURCE.recommend
				,SOURCE.mrecommend
				,SOURCE.srecommend
				,SOURCE.turnover
				,SOURCE.winlost
				,SOURCE.awinlost
				,SOURCE.mwinlost
				,SOURCE.swinlost
				,SOURCE.playercomm
				,SOURCE.comm
				,SOURCE.acomm
				,SOURCE.scomm
				,SOURCE.BetCount
				,SOURCE.grosscomm
				,SOURCE.sporttype
				,SOURCE.bettype
				,SOURCE.netTurnover
				,SOURCE.TurnoverNoDraw
				,SOURCE.ExtraWinloss
				,SOURCE.ExtraComm
				,SOURCE.leagueGroupID
				,SOURCE.ticketType
				);

		--Delete--
		;WITH CTE_del_mem AS
		(
			SELECT a.keyid, a.winlostdate, a.custid, a.sporttype, a.bettype, a.leagueGroupID, a.ticketType 
			FROM #sum_winloss_old a WITH (NOLOCK)
			LEFT JOIN #sum_winloss_old_tmp b WITH (NOLOCK)
				ON a.winlostdate	= b.winlostdate
				AND a.custid		= b.custid
				AND a.sporttype		= b.sporttype
				AND a.bettype		= b.bettype
				AND a.leagueGroupID = b.leagueGroupID
				AND a.ticketType	= b.ticketType
			WHERE b.winlostdate IS NULL 
				OR b.custid IS NULL
				OR b.sporttype IS NULL
				OR b.bettype IS NULL
				OR b.leagueGroupID IS NULL
				OR b.ticketType IS NULL
		)
		DELETE a
		FROM dbo.sum_winloss_old a WITH (ROWLOCK)
		JOIN CTE_del_mem b
			ON a.keyid = b.keyid
			AND a.winlostdate	= b.winlostdate
			AND a.custid		= b.custid
			AND a.sporttype		= b.sporttype
			AND a.bettype		= b.bettype
			AND a.leagueGroupID = b.leagueGroupID
			AND a.ticketType	= b.ticketType
	END
	DROP TABLE #sum_winloss_old_tmp
	DROP TABLE #sum_winloss_old
END