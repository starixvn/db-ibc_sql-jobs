/*<info serverAlias="DBSUM-bodb_Summary" executers="vnteam" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_Summary]
GO

ALTER PROCEDURE [dbo].[Task_DailyRptPokerGamesSumWinLoss_CheckData]
	@WinlostDate		SMALLDATETIME,
	@IsCheckDataOnly	BIT = 0
AS

/*
	Created: 20180912@Sophia
	Task: SP Gen data for RptPokerGamesSumWinLoss   
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20180912@Sophia: Initialize SP [RedmineID: #101376]

	Param's Explanation:
*/

BEGIN 
	SET NOCOUNT ON
		
	DECLARE @MoveBetsDay SMALLDATETIME, @BalanceUpDay SMALLDATETIME
		
	SELECT @MoveBetsDay = MAX(eventdate)
	FROM bodb02.dbo.match14 WITH(NOLOCK)
		
	SELECT TOP 1 @BalanceUpDay = winlostdate
	FROM bodb02.dbo.bettrans WITH (NOLOCK)
	WHERE matchid = 0 AND bettype = 20000
		
	IF @winlostdate NOT BETWEEN @BalanceUpDay AND @MoveBetsDay
	BEGIN
		SELECT 999 AS ErrCode, 'Parameter Winlostdate is invalid!' AS ErrMsg
		RETURN
	END

	DECLARE @ProductIds VARCHAR(50)
	SELECT  @ProductIds = 33 ---- Poker Games only
	
	DECLARE @Bettype TABLE (Bettype SMALLINT)	
	INSERT INTO @Bettype (Bettype)
	SELECT Bettype
	FROM bodb02.dbo.f_SportBettypeMatrixByProduct_Sel(@ProductIds, 0) s


	/* Get data source */
	CREATE TABLE #RptPokerGamesSumWinLoss_Source
	(
		WinlostDate	smalldatetime,
		CustID		int,
		Bettype		smallint,
		RoleID		tinyint,
		Recommend	int,
		MRecommend	int,
		SRecommend	int,
		BetCount	int,
		RoundCount	int,
		Turnover	money,
		NetTurnover	money,
		TotalComm	money,
		WinLoss		money,
		InsGemMemberWinLoss	money,
		PlayerComm	money,
		AgWinLoss	money,
		AgComm		money,
		MAgWinLoss	money,
		MAgComm		money,
		SAgWinLoss	money,
		SAgComm		money
	)

	-- Member - RoleId = 1
	BEGIN
		INSERT INTO #RptPokerGamesSumWinLoss
		(
			WinlostDate,
			CustID,
			Bettype,
			RoleID,
			Recommend,
			MRecommend,
			SRecommend,
			BetCount,
			RoundCount,
			Turnover,
			NetTurnover,
			TotalComm,
			WinLoss,
			InsGemMemberWinLoss,
			PlayerComm,
			AgWinLoss,
			AgComm,
			MAgWinLoss,
			MAgComm,
			SAgWinLoss,
			SAgComm
		)

		SELECT
			WinlostDate,
			CustID,
			Bettype,
			1 AS RoleID,
			Recommend,
			MRecommend,
			SRecommend,
			COUNT (TransID) AS BetCount,
			SUM(ISNULL(BetId,0)) AS RoundCount,
			SUM(ABS(b.stake)) as Turnover, 
			SUM(CASE WHEN b.bettype = 1499 THEN ABS(b.stake) ELSE ISNULL(CAST(('<xml>' + b.ExtraInfo + '</xml>') AS XML).value('data(/xml/p33/@to)[1]','MONEY'), 0) END ) AS NetTurnover,
			SUM(ISNULL(b.oddsspread,0)) AS TotalComm,
			SUM(b.winlost - b.actual_stake) AS WinLoss,
			SUM(ISNULL(b.TransID2,0)/ CONVERT(DECIMAL(19,8),10000)) AS InsGemMemberWinLoss,
			SUM(ISNULL(b.playercomm,0)) AS PlayerComm,
			SUM(b.awinlost) AS AgWinLoss,
			SUM(ISNULL(b.comm,0)) AS AgComm,
			SUM(b.mwinlost) AS MAgWinLoss,
			SUM(ISNULL(b.acomm,0)) AS MAgComm,
			SUM(b.swinlost) AS SAgWinLoss,
			SUM(ISNULL(b.scomm,0)) SAgComm
		FROM bodb02.dbo.Bettrans14 b WITH (NOLOCK)
		WHERE b.WinlostDate = @WinlostDate
			AND b.StatusID IN (111,112,113) 
			AND EXISTS (SELECT 1 FROM @Bettype t WHERE t.bettype = b.bettype)			
		GROUP BY
			WinlostDate,
			CustID,
			Bettype,
			Recommend,
			MRecommend,
			SRecommend
	END

	-- Agent - RoleId = 2
	BEGIN
		INSERT INTO #RptPokerGamesSumWinLoss
		(
			WinlostDate,
			CustID,
			Bettype,
			RoleID,
			Recommend,
			MRecommend,
			SRecommend,
			BetCount,
			RoundCount,
			Turnover,
			NetTurnover,
			TotalComm,
			WinLoss,
			InsGemMemberWinLoss,
			PlayerComm,
			AgWinLoss,
			AgComm,
			MAgWinLoss,
			MAgComm,
			SAgWinLoss,
			SAgComm
		)

		SELECT	
			WinlostDate,
			Recommend AS CustID,
			Bettype,
			2 AS RoleID,
			Recommend,
			MRecommend,
			SRecommend,			
			SUM(BetCount) AS BetCount,
			SUM(RoundCount) AS RoundCount,
			SUM(Turnover) AS Turnover,
			SUM(NetTurnover) AS NetTurnover,
			SUM(TotalComm) AS TotalComm,
			SUM(WinLoss) AS WinLoss,
			SUM(InsGemMemberWinLoss) AS InsGemMemberWinLoss,
			SUM(PlayerComm) AS PlayerComm,
			SUM(AgWinLoss) AS AgWinLoss,
			SUM(AgComm) AS AgComm,
			SUM(MAgWinLoss) AS MAgWinLoss,
			SUM(MAgComm) AS MAgComm,
			SUM(SAgWinLoss) AS SAgWinLoss,
			SUM(SAgComm) AS SAgComm		
		FROM #rptProgressiveGamesContribution
		WHERE RoleId = 1 
		GROUP BY
			WinlostDate,
			Bettype,		
			Recommend,
			MRecommend,
			SRecommend
	END
				
	-- Master - RoleId = 3
	BEGIN
		INSERT INTO #RptPokerGamesSumWinLoss
		(
			WinlostDate,
			CustID,
			Bettype,
			RoleID,
			Recommend,
			MRecommend,
			SRecommend,
			BetCount,
			RoundCount,
			Turnover,
			NetTurnover,
			TotalComm,
			WinLoss,
			InsGemMemberWinLoss,
			PlayerComm,
			AgWinLoss,
			AgComm,
			MAgWinLoss,
			MAgComm,
			SAgWinLoss,
			SAgComm
		)
		SELECT	
			WinlostDate,
			Mrecommend AS CustID,
			Bettype,
			3 AS RoleID,
			0 AS Recommend,
			MRecommend,
			SRecommend,			
			SUM(BetCount) AS BetCount,
			SUM(RoundCount) AS RoundCount,
			SUM(Turnover) AS Turnover,
			SUM(NetTurnover) AS NetTurnover,
			SUM(TotalComm) AS TotalComm,
			SUM(WinLoss) AS WinLoss,
			SUM(InsGemMemberWinLoss) AS InsGemMemberWinLoss,
			SUM(PlayerComm) AS PlayerComm,
			SUM(AgWinLoss) AS AgWinLoss,
			SUM(AgComm) AS AgComm,
			SUM(MAgWinLoss) AS MAgWinLoss,
			SUM(MAgComm) AS MAgComm,
			SUM(SAgWinLoss) AS SAgWinLoss,
			SUM(SAgComm) AS SAgComm		
		FROM #rptProgressiveGamesContribution
		WHERE RoleId = 1 
		GROUP BY
			WinlostDate,
			Bettype,	
			MRecommend,
			SRecommend
	END	
							
	-- Super - RoleId = 4
	BEGIN
		INSERT INTO #RptPokerGamesSumWinLoss
		(
			WinlostDate,
			CustID,
			Bettype,
			RoleID,
			Recommend,
			MRecommend,
			SRecommend,
			BetCount,
			RoundCount,
			Turnover,
			NetTurnover,
			TotalComm,
			WinLoss,
			InsGemMemberWinLoss,
			PlayerComm,
			AgWinLoss,
			AgComm,
			MAgWinLoss,
			MAgComm,
			SAgWinLoss,
			SAgComm
		)
		SELECT	
			WinlostDate,
			Mrecommend AS CustID,
			Bettype,
			4 AS RoleID,
			0 AS Recommend,
			0 AS MRecommend,
			SRecommend,			
			SUM(BetCount) AS BetCount,
			SUM(RoundCount) AS RoundCount,
			SUM(Turnover) AS Turnover,
			SUM(NetTurnover) AS NetTurnover,
			SUM(TotalComm) AS TotalComm,
			SUM(WinLoss) AS WinLoss,
			SUM(InsGemMemberWinLoss) AS InsGemMemberWinLoss,
			SUM(PlayerComm) AS PlayerComm,
			SUM(AgWinLoss) AS AgWinLoss,
			SUM(AgComm) AS AgComm,
			SUM(MAgWinLoss) AS MAgWinLoss,
			SUM(MAgComm) AS MAgComm,
			SUM(SAgWinLoss) AS SAgWinLoss,
			SUM(SAgComm) AS SAgComm		
		FROM #rptProgressiveGamesContribution
		WHERE RoleId = 1 
		GROUP BY
			WinlostDate,
			Bettype,	
			SRecommend
	END

	/* Get data target */
	CREATE TABLE #RptPokerGamesSumWinLoss_Target
	(
		WinlostDate	smalldatetime,
		CustID		int,
		Bettype		smallint,
		RoleID		tinyint,
		Recommend	int,
		MRecommend	int,
		SRecommend	int,
		BetCount	int,
		RoundCount	int,
		Turnover	money,
		NetTurnover	money,
		TotalComm	money,
		WinLoss		money,
		InsGemMemberWinLoss	money,
		PlayerComm	money,
		AgWinLoss	money,
		AgComm		money,
		MAgWinLoss	money,
		MAgComm		money,
		SAgWinLoss	money,
		SAgComm		money
	)

	BEGIN
		INSERT INTO #RptPokerGamesSumWinLoss_Target
		(
			WinlostDate,
			CustID,
			Bettype,
			RoleID,
			Recommend,
			MRecommend,
			SRecommend,
			BetCount,
			RoundCount,
			Turnover,
			NetTurnover,
			TotalComm,
			WinLoss,
			InsGemMemberWinLoss,
			PlayerComm,
			AgWinLoss,
			AgComm,
			MAgWinLoss,
			MAgComm,
			SAgWinLoss,
			SAgComm
		)
		SELECT
			WinlostDate,
			CustID,
			Bettype,
			RoleID,
			Recommend,
			MRecommend,
			SRecommend,
			BetCount,
			RoundCount,
			Turnover,
			NetTurnover,
			TotalComm,
			WinLoss,
			InsGemMemberWinLoss,
			PlayerComm,
			AgWinLoss,
			AgComm,
			MAgWinLoss,
			MAgComm,
			SAgWinLoss,
			SAgComm
		FROM dbo.RptPokerGamesSumWinLoss WITH (NOLOCK)
		WHERE WinlostDate = @WinlostDate
	END

	/* Compare data */
	CREATE NONCLUSTERED INDEX IX_CustID ON #RptPokerGamesSumWinLoss_Source (WinlostDate, CustId, Bettype)
	CREATE NONCLUSTERED INDEX IX_CustID ON #RptPokerGamesSumWinLoss_Target (WinlostDate, CustId, Bettype)

	IF EXISTS (
		SELECT 1
		FROM #RptPokerGamesSumWinLoss_Source SOURCE
			FULL OUTER JOIN #RptPokerGamesSumWinLoss_Target TARGET
				ON SOURCE.CustId = TARGET.CustId AND SOURCE.Bettype = TARGET.Bettype AND SOURCE.WinlostDate = TARGET.WinlostDate
		WHERE
				SOURCE.CustId IS NULL
				OR TARGET.CustId IS NULL
				OR TARGET.RoleId			<> SOURCE.RoleId
				OR TARGET.Recommend			<> SOURCE.Recommend
				OR TARGET.MRecommend		<> SOURCE.MRecommend
				OR TARGET.SRecommend		<> SOURCE.SRecommend
				OR TARGET.Betcount			<> SOURCE.Betcount
				OR TARGET.RoundCount		<> SOURCE.RoundCount
				OR TARGET.Turnover			<> SOURCE.Turnover
				OR TARGET.NetTurnover		<> SOURCE.NetTurnover
				OR TARGET.TotalComm			<> SOURCE.TotalComm
				OR TARGET.WinLoss			<> SOURCE.WinLoss
				OR TARGET.InsGemMemberWinLoss	<> SOURCE.InsGemMemberWinLoss
				OR TARGET.PlayerComm		<> SOURCE.PlayerComm
				OR TARGET.AgWinLoss			<> SOURCE.AgWinLoss
				OR TARGET.AgComm			<> SOURCE.AgComm
				OR TARGET.MAgWinLoss		<> SOURCE.MAgWinLoss
				OR TARGET.MAgComm			<> SOURCE.MAgComm
				OR TARGET.SAgWinLoss		<> SOURCE.SAgWinLoss				
	)
	BEGIN
		IF @IsCheckDataOnly = 1 --just check data
		BEGIN
			SELECT 'Wrong data on ' + CONVERT(VARCHAR(10), @WinlostDate, 112)
		END
		ELSE -- correct data
		BEGIN
			MERGE dbo.RptPokerGamesSumWinLoss AS TARGET
			USING #RptPokerGamesSumWinLoss_Source AS SOURCE
					ON	TARGET.WinlostDate	= SOURCE.WinlostDate
					AND TARGET.CustId		= SOURCE.CustId
					AND TARGET.Bettype		= SOURCE.Bettype
			WHEN MATCHED THEN
			UPDATE SET
				TARGET.RoleId			= SOURCE.RoleId,
				TARGET.Recommend		= SOURCE.Recommend,
				TARGET.MRecommend		= SOURCE.MRecommend,
				TARGET.SRecommend		= SOURCE.SRecommend,
				TARGET.Betcount			= SOURCE.Betcount,
				TARGET.RoundCount		= SOURCE.RoundCount,
				TARGET.Turnover			= SOURCE.Turnover,
				TARGET.NetTurnover		= SOURCE.NetTurnover,	
				TARGET.TotalComm		= SOURCE.TotalComm,
				TARGET.WinLoss			= SOURCE.WinLoss,
				TARGET.InsGemMemberWinLoss	= SOURCE.InsGemMemberWinLoss,
				TARGET.PlayerComm		= SOURCE.PlayerComm,
				TARGET.AgWinLoss		= SOURCE.AgWinLoss,
				TARGET.AgComm			= SOURCE.AgComm,
				TARGET.MAgWinLoss		= SOURCE.MAgWinLoss,
				TARGET.MAgComm			= SOURCE.MAgComm,
				TARGET.SAgWinLoss		= SOURCE.SAgWinLoss,
				TARGET.SAgComm			= SOURCE.SAgComm
			WHEN NOT MATCHED BY TARGET THEN
				INSERT
				(
					WinlostDate, CustID, Bettype, RoleID, Recommend, MRecommend, SRecommend, BetCount, RoundCount,
					Turnover, NetTurnover, TotalComm, WinLoss, InsGemMemberWinLoss, PlayerComm,	
					AgWinLoss, AgComm, MAgWinLoss, MAgComm, SAgWinLoss, SAgComm
				)
				VALUES
				(
					SOURCE.WinlostDate, SOURCE.CustID, SOURCE.Bettype, SOURCE.RoleID, SOURCE.Recommend, SOURCE.MRecommend, SOURCE.SRecommend, SOURCE.BetCount, SOURCE.RoundCount,
					SOURCE.Turnover, SOURCE.NetTurnover, SOURCE.TotalComm, SOURCE.WinLoss, SOURCE.InsGemMemberWinLoss, SOURCE.PlayerComm,	
					SOURCE.AgWinLoss, SOURCE.AgComm, SOURCE.MAgWinLoss, SOURCE.MAgComm, SOURCE.SAgWinLoss, SOURCE.SAgComm
				)
			WHEN NOT MATCHED BY SOURCE AND TARGET.WinlostDate = @Winlostdate THEN
				DELETE;
		END
	END

	DROP TABLE #RptPokerGamesSumWinLoss_Source
	DROP TABLE #RptPokerGamesSumWinLoss_Target
END
GO 