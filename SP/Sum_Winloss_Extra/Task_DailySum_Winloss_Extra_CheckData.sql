/*<info serverAlias="DBSUM-bodb_Summary" executers="" viewers="" isFunction="0" isNested="1"></info>*/
USE [bodb_Summary]
GO

CREATE PROCEDURE [dbo].[Task_DailySum_Winloss_Extra_CheckData]
	@WinlostDate		SMALLDATETIME,
	@ProductIds         VARCHAR(MAX),
	@IsCheckDataOnly	BIT = 0
AS

/*
	Created: 20200619@Malcolm
	Task: SP check data for Winloss_Extra [Redmine: #135593]
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20200619@Malcolm: Initialize SPs [RedmineID: #135593]
 
	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON
		
	DECLARE @MoveBetsDay SMALLDATETIME, @BalanceUpDay SMALLDATETIME
		
	DECLARE @MoveBetAndBalanceUp TABLE( MoveBetsDay SMALLDATETIME, BalanceUpDay SMALLDATETIME)

	INSERT INTO @MoveBetAndBalanceUp (BalanceUpDay, MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay
		
	IF @winlostdate NOT BETWEEN @BalanceUpDay AND @MoveBetsDay
	BEGIN
		SELECT 999 AS ErrCode, 'Parameter Winlostdate is invalid!' AS ErrMsg
		RETURN
	END

	DECLARE @Bettype TABLE (ProductId INT, TypeId INT)

	INSERT INTO @Bettype
	(
		TypeId,
		ProductId
	)
	SELECT DISTINCT BetType, ProductID
	FROM bodb02.dbo.SportBettypeMatrix m WITH(NOLOCK)
	WHERE ',' + @ProductIds + ',' LIKE '%,' + CONVERT(VARCHAR(10), m.ProductId) + ',%'


	/* Get data source */
	CREATE TABLE #Sum_Winloss_Extra_Source
	(
		WinlostDate			SMALLDATETIME,
		CustId				INT,
		ProductId			SMALLINT,
		Bettype				SMALLINT,
		RoleID				TINYINT,
		Recommend			INT,
		MRecommend			INT,
		SRecommend			INT,
		BetCount			INT,
		Turnover			MONEY,
		NetTurnover         MONEY,
		NetTurnoverAg		MONEY,
		NetTurnoverMAg		MONEY,
		NetTurnoverSAg		MONEY,
		TunroverNoDraw		MONEY,
		WinLoss				MONEY,
		AgWinLoss			MONEY,
		MAgWinLoss			MONEY,
		SAgWinLoss			MONEY,
		ExtraWinloss		MONEY,
		PlayerComm			MONEY,
		AgComm				MONEY,
		MAgComm				MONEY,
		SAgComm				MONEY,
		ExtraComm			MONEY,
		GrossComm			MONEY,
		GrossCommAg			MONEY,
		GrossCommMAg		MONEY,
		GrossCommSAg		MONEY
	)

	-- for member , roleid = 1
	BEGIN
		INSERT INTO #Sum_Winloss_Extra_Source
		(
			WinlostDate,
			CustId,
			ProductId,
			Bettype,
			RoleID,
			Recommend,
			MRecommend,
			SRecommend,
			BetCount,
			Turnover,
			NetTurnover,
			NetTurnoverAg,
			NetTurnoverMAg,
			NetTurnoverSAg,
			TunroverNoDraw,
			WinLoss,
			AgWinLoss,		
			MAgWinLoss,
			SAgWinLoss,
			ExtraWinloss,
			PlayerComm,
			AgComm,
			MAgComm,
			SAgComm,
			ExtraComm,
			GrossComm,
			GrossCommAg,
			GrossCommMAg,
			GrossCommSAg
		)
		SELECT
			@WinlostDate AS WinlostDate, 
			custid AS CustId,
			b.ProductId AS ProductId,
			0 AS Bettype,
			1 AS RoleId,
		    recommend AS recommend,
		    mrecommend AS mrecommend,
			srecommend AS srecommend,
			COUNT(1) AS BetCount,
			SUM(ABS(bt.stake)) AS Turnover,
			0 AS NetTurnover,
			SUM(ABS(stake * apositiontaking)) AS NetTurnoverAg,
			sum(ABS(stake * mpositiontaking)) AS NetTurnoverMAg,
			SUM(ABS(stake * spositiontaking)) AS NetTurnoverSAg,
			SUM(CASE WHEN b.ProductId = 46 THEN bt.oddsspread ELSE ABS(stake) END) AS TurnoverNoDrawn,
			SUM(winlost-actual_stake)  AS Winlost,
			SUM(awinlost) AS AgWinLoss,
			SUM(mwinlost) AS MAgWinLoss,
			SUM(swinlost) AS SAgWinLoss,
			-SUM((winlost - actual_stake) * epositiontaking) AS ExtraWinloss,
			SUM(playercomm) AS PlayerComm,
			SUM(comm) - SUM(playercomm) AS AgComm,
			SUM(acomm) - SUM(comm) AS MAgComm,
			SUM(scomm) - SUM(acomm) AS SAgComm,
			-SUM(scomm) AS ExtraComm,
			SUM(CASE WHEN apositiontaking = 1 THEN 0 ELSE ISNULL(comm/(1-apositiontaking),0) END) GrossComm,	
			SUM(CASE WHEN (apositiontaking+mpositiontaking) = 1 THEN 0 ELSE acomm/(1-apositiontaking-mpositiontaking) END) AS GrossCommAg,
			SUM(CASE WHEN tpositiontaking = 1 THEN 0 ELSE scomm / (1-tpositiontaking) END) AS GrossCommMAg,
			SUM(CASE WHEN tpositiontaking = 1 THEN 0 ELSE scomm / (1-tpositiontaking) END) AS GrossCommSAg
		FROM bodb02.dbo.bettrans14 bt WITH(NOLOCK)
			INNER JOIN @Bettype b ON bt.bettype = b.TypeId
		WHERE bt.winlostdate = @WinlostDate 
			AND bt.statusID NOT IN (102,101,103)
		GROUP BY custid, recommend, mrecommend, srecommend, b.ProductId
	END
	-- for agent, roleid = 2
	BEGIN
		INSERT INTO #Sum_Winloss_Extra_Source
		(
			WinlostDate,
			CustId,
			ProductId,
			Bettype,
			RoleID,
			Recommend,
			MRecommend,
			SRecommend,
			BetCount,
			Turnover,
			NetTurnover,
			TunroverNoDraw,
			WinLoss,
			AgWinLoss,		
			MAgWinLoss,
			SAgWinLoss,
			ExtraWinloss,
			PlayerComm,
			AgComm,
			MAgComm,
			SAgComm,
			ExtraComm,
			GrossComm
		)
		SELECT			 
			WinlostDate,
			Recommend AS CustId,
			ProductId,
			Bettype,
			2 AS RoleId,
			Recommend,
			MRecommend,
			SRecommend,
			SUM(BetCount),
			SUM(Turnover),
			SUM(NetTurnoverAg),
			SUM(TunroverNoDraw),
			SUM(WinLoss),
			SUM(AgWinLoss),		
			SUM(MAgWinLoss),
			SUM(SAgWinLoss),
			SUM(ExtraWinloss),
			SUM(PlayerComm),
			SUM(AgComm),
			SUM(MAgComm),
			SUM(SAgComm),
			SUM(ExtraComm),
			SUM(GrossCommAg)
		FROM #Sum_Winloss_Extra_Source
		WHERE RoleID = 1
		GROUP BY WinlostDate, Recommend, MRecommend, SRecommend,ProductId, Bettype
	END

	-- for master, roleId = 3
	BEGIN
		INSERT INTO #Sum_Winloss_Extra_Source
		(
			WinlostDate,
			CustId,
			ProductId,
			Bettype,
			RoleID,
			Recommend,
			MRecommend,
			SRecommend,
			BetCount,
			Turnover,
			NetTurnover,
			TunroverNoDraw,
			WinLoss,
			AgWinLoss,		
			MAgWinLoss,
			SAgWinLoss,
			ExtraWinloss,
			PlayerComm,
			AgComm,
			MAgComm,
			SAgComm,
			ExtraComm,
			GrossComm
		)
		SELECT
			WinlostDate,
			MRecommend AS CustId,
			ProductId,
			Bettype,
			3 AS RoleId,
			0 AS Recommend,
			MRecommend,
			SRecommend,
			SUM(BetCount),
			SUM(Turnover),
			SUM(NetTurnoverMAg),
			SUM(TunroverNoDraw),
			SUM(WinLoss),
			SUM(AgWinLoss),		
			SUM(MAgWinLoss),
			SUM(SAgWinLoss),
			SUM(ExtraWinloss),
			SUM(PlayerComm),
			SUM(AgComm),
			SUM(MAgComm),
			SUM(SAgComm),
			SUM(ExtraComm),
			SUM(GrossCommMAg)
		FROM #Sum_Winloss_Extra_Source
		WHERE RoleID = 1
		GROUP BY WinlostDate, MRecommend, SRecommend,ProductId, Bettype
	END
	-- for super, roleId = 4
	BEGIN
		INSERT INTO #Sum_Winloss_Extra_Source
		(
			WinlostDate,
			CustId,
			ProductId,
			Bettype,
			RoleID,
			Recommend,
			MRecommend,
			SRecommend,
			BetCount,
			Turnover,
			NetTurnover,
			TunroverNoDraw,
			WinLoss,
			AgWinLoss,		
			MAgWinLoss,
			SAgWinLoss,
			ExtraWinloss,
			PlayerComm,
			AgComm,
			MAgComm,
			SAgComm,
			ExtraComm,
			GrossComm
		)
		SELECT			
			WinlostDate,
			SRecommend AS CustId,
			ProductId,
			Bettype,
			4 AS RoleId,
			0 AS Recommend,
			0 AS MRecommend,
			SRecommend,
			SUM(BetCount),
			SUM(Turnover),
			SUM(NetTurnoverSAg),
			SUM(TunroverNoDraw),
			SUM(WinLoss),
			SUM(AgWinLoss),		
			SUM(MAgWinLoss),
			SUM(SAgWinLoss),
			SUM(ExtraWinloss),
			SUM(PlayerComm),
			SUM(AgComm),
			SUM(MAgComm),
			SUM(SAgComm),
			SUM(ExtraComm),
			SUM(GrossCommSAg)
		FROM #Sum_Winloss_Extra_Source
	    WHERE RoleID = 1
		GROUP BY WinlostDate, SRecommend,ProductId, Bettype
	END


	/* Get data target */
	CREATE TABLE #Sum_Winloss_Extra_Target 
	(
		WinlostDate		DATETIME,
		CustId			INT,
		ProductId		SMALLINT,
		Bettype			SMALLINT,
		RoleID			INT,
		Recommend		INT,
		MRecommend		INT,
		SRecommend		INT,
		BetCount		INT,
		Turnover		MONEY,
		NetTurnover		MONEY,
		TunroverNoDraw	MONEY,
		WinLoss			MONEY,
		AgWinLoss		MONEY,
		MAgWinLoss		MONEY,
		SAgWinLoss		MONEY,
		ExtraWinloss	MONEY,
		PlayerComm		MONEY,
		AgComm			MONEY,
		MAgComm			MONEY,
		SAgComm			MONEY,
		ExtraComm		MONEY,
		GrossComm		MONEY
	)

	BEGIN
		INSERT INTO #Sum_Winloss_Extra_Target
		(
			WinlostDate,
			CustId,
			ProductId,
			Bettype,
			RoleID,
			Recommend,
			MRecommend,
			SRecommend,
			BetCount,
			Turnover,
			NetTurnover,
			TunroverNoDraw,
			WinLoss,
			AgWinLoss,		
			MAgWinLoss,
			SAgWinLoss,
			ExtraWinloss,
			PlayerComm,
			AgComm,
			MAgComm,
			SAgComm,
			ExtraComm,
			GrossComm
		)
		SELECT
			WinlostDate,
			CustId,
			ProductId,
			Bettype,
			RoleID,
			Recommend,
			MRecommend,
			SRecommend,
			BetCount,
			Turnover,
			NetTurnover,
			TurnoverNoDraw,
			WinLoss,
			AgWinLoss,		
			MAgWinLoss,
			SAgWinLoss,
			ExtraWinloss,
			PlayerComm,
			AgComm,
			MAgComm,
			SAgComm,
			ExtraComm,
			GrossComm
		FROM dbo.sum_winloss_extra WITH (NOLOCK)
		WHERE WinlostDate = @WinlostDate
	END

	/* Compare data */
	CREATE NONCLUSTERED INDEX IX_CustID ON #Sum_Winloss_Extra_Source (CustId, ProductId, bettype)
	CREATE NONCLUSTERED INDEX IX_CustID ON #Sum_Winloss_Extra_Target (CustId, ProductId, bettype)

	IF EXISTS (
		SELECT 1
		FROM #Sum_Winloss_Extra_Source s
			FULL OUTER JOIN #Sum_Winloss_Extra_Target t
				ON s.CustId = t.CustId AND s.ProductId = t.ProductId AND s.Bettype = t.Bettype AND s.WinlostDate = t.WinlostDate
		WHERE
				s.CustId			IS NULL
				OR t.CustId			IS NULL
				OR s.RoleID			<> t.RoleID
				OR s.Recommend		<> t.Recommend
				OR s.MRecommend		<> t.MRecommend
				OR s.SRecommend		<> t.SRecommend
				OR s.BetCount		<> t.BetCount
				OR s.Turnover		<> t.Turnover
				OR s.NetTurnover	<> t.NetTurnover
				OR s.TunroverNoDraw <> t.TunroverNoDraw
				OR s.WinLoss		<> t.WinLoss
				OR s.AgWinLoss		<> t.AgWinLoss
				OR s.MAgWinLoss		<> t.MAgWinLoss
				OR s.SAgWinLoss		<> t.SAgWinLoss
				OR s.ExtraWinloss	<> t.ExtraWinloss
				OR s.PlayerComm		<> t.PlayerComm
				OR s.AgComm			<> t.AgComm
				OR s.MAgComm		<> t.MAgComm
				OR s.SAgComm		<> t.SAgComm
				OR s.ExtraComm		<> t.ExtraComm
				OR s.ExtraComm		<> t.ExtraComm
	)
	BEGIN
		IF @IsCheckDataOnly = 1 --just check data
		BEGIN
			SELECT 'Wrong data on ' + CONVERT(VARCHAR(10), @WinlostDate, 112)
		END
		ELSE -- correct data
		BEGIN
			MERGE dbo.Sum_Winloss_Extra AS TARGET
			USING #Sum_Winloss_Extra_Source AS SOURCE
				ON		TARGET.WinlostDate	= SOURCE.WinlostDate
					AND TARGET.CustId		= SOURCE.CustId
					AND TARGET.ProductId	= SOURCE.ProductId
					AND TARGET.Bettype		= SOURCE.Bettype
			WHEN MATCHED THEN
				UPDATE SET
					TARGET.RoleId			= SOURCE.RoleId,
					TARGET.Recommend		= SOURCE.Recommend,
					TARGET.MRecommend		= SOURCE.MRecommend,
					TARGET.SRecommend		= SOURCE.SRecommend,
					TARGET.Betcount			= SOURCE.Betcount,
					TARGET.Turnover			= SOURCE.Turnover,
					TARGET.NetTurnover		= SOURCE.NetTurnover,
					TARGET.TurnoverNoDraw	= SOURCE.TunroverNoDraw,
					TARGET.WinLoss			= SOURCE.WinLoss,
					TARGET.AgWinLoss		= SOURCE.AgWinLoss,
					TARGET.MAgWinLoss		= SOURCE.MAgWinLoss,
					TARGET.SAgWinLoss		= SOURCE.SAgWinLoss,
					TARGET.ExtraWinloss		= SOURCE.ExtraWinloss,
					TARGET.PlayerComm		= SOURCE.PlayerComm,
					TARGET.AgComm			= SOURCE.AgComm,
					TARGET.MAgComm			= SOURCE.MAgComm,
					TARGET.SAgComm			= SOURCE.SAgComm,
					TARGET.ExtraComm		= SOURCE.ExtraComm,
					TARGET.GrossComm		= SOURCE.GrossComm

			WHEN NOT MATCHED BY TARGET THEN
				INSERT
				(
					WinlostDate,
					CustId,
					ProductId,
					Bettype,
					RoleID,
					Recommend,
					MRecommend,
					SRecommend,
					BetCount,
					Turnover,
					NetTurnover,
					TurnoverNoDraw,
					WinLoss,
					AgWinLoss,
					MAgWinLoss,
					SAgWinLoss,
					ExtraWinloss,
					PlayerComm,
					AgComm,
					MAgComm,
					SAgComm,
					ExtraComm,
					GrossComm
				)
				VALUES
				(
					SOURCE.WinlostDate,
					SOURCE.CustId,
					SOURCE.ProductId,
					SOURCE.Bettype,
					SOURCE.RoleID,
					SOURCE.Recommend,
					SOURCE.MRecommend,
					SOURCE.SRecommend,
					SOURCE.BetCount,
					SOURCE.Turnover,
					SOURCE.NetTurnover,
					SOURCE.TunroverNoDraw,
					SOURCE.WinLoss,
					SOURCE.AgWinLoss,
					SOURCE.MAgWinLoss,
					SOURCE.SAgWinLoss,
					SOURCE.ExtraWinloss,
					SOURCE.PlayerComm,
					SOURCE.AgComm,
					SOURCE.MAgComm,
					SOURCE.SAgComm,
					SOURCE.ExtraComm,
					SOURCE.GrossComm
				)
			WHEN NOT MATCHED BY SOURCE AND TARGET.WinlostDate = @Winlostdate THEN
				DELETE;
		END
	END

	DROP TABLE #Sum_Winloss_Extra_Source
	DROP TABLE #Sum_Winloss_Extra_Target
END
GO