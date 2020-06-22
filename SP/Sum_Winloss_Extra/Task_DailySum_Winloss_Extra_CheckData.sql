/*<info serverAlias="DBSUM-bodb_Summary" executers="" viewers="" isFunction="0" isNested="1"></info>*/
USE [bodb_Summary]
GO

CREATE PROCEDURE [dbo].[Task_DailySum_Winloss_Extra_CheckData]
	@WinlostDate		SMALLDATETIME,
	@IsCheckDataOnly	BIT = 0,
	@ProductIds         VARCHAR(200)
AS

/*
	Created: 20200619@Malcolm
	Task: SP check data for Winloss_Extra [Redmine: #135593]
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20200619@Malcolm: Initialize SP [RedmineID: #135593]
 
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

	DECLARE @Bettype TABLE (ProductId INT, TypeId INT)

	INSERT INTO @Bettype
	(
		ProductId,
		TypeId
	)
	SELECT DISTINCT ProductID, BetType
	FROM bodb02.dbo.SportBettypeMatrix m WITH(NOLOCK)
	WHERE ',' + @ProductIds + ',' LIKE '%,' + CONVERT(VARCHAR(10),m.ProductID) + ',%'


	/* Get data source */
	CREATE TABLE #Sum_Winloss_Extra_Source
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
			@WinlostDate, 
			custid,
			b.ProductId,
			CASE WHEN bt.bettype IN (71, 72) THEN bt.bettype ELSE  0 END Bettype,
			1,
		    recommend,
		    mrecommend,
			srecommend,
			COUNT(1) BetCount,
			SUM(ABS(bt.stake)) TurnOver,
			0 AS NetTurnOver,
			SUM( CASE	WHEN bt.StatusID IN (112,113) AND bt.MOdds IN (-0.25, 0.25) 
							---- Sportsbook
							AND (bt.Bettype < 999 OR bt.bettype BETWEEN 1301 AND 1399 OR bt.bettype BETWEEN 9001 AND 9399)
							AND bt.Bettype NOT IN (71,72)
							AND bt.Bettype NOT BETWEEN 81 AND 120			
							THEN ABS(stake)/2
						WHEN bt.StatusID = 111  
							AND (
								---- Sportsbook
									(bt.Bettype < 999 OR bt.bettype BETWEEN 1301 AND 1399 OR bt.bettype BETWEEN 9001 AND 9399)
									AND bt.Bettype NOT IN (71,72)
									AND bt.Bettype NOT BETWEEN 81 AND 120
							)
							THEN 0
						WHEN   bt.Bettype BETWEEN 2401 AND 2499   -- Allbet
							OR bt.Bettype BETWEEN 3001 AND 3099   -- SA Gaming
							OR bt.Bettype BETWEEN 3101 AND 3199   -- Sexy Gaming
							OR bt.Bettype BETWEEN 3300 AND 3399   -- BBIN	
							OR bt.Bettype BETWEEN 3201 AND 3299   -- IBCBet Live Casino
							OR bt.Bettype BETWEEN 5601 AND 5699   -- ION 	 
							THEN bt.oddsspread
						ELSE ABS(bt.stake) 
					END) AS TurnoverNoDrawm,
			SUM(winlost-actual_stake)  Winlost,
			SUM(awinlost) AgWinLoss,
			SUM(mwinlost) MAgWinLoss,
			SUM(ISNULL(swinlost,0)) SAgWinLoss,
			SUM((winlost - actual_stake) * epositiontaking) ExtraWinloss,
			SUM(playercomm)  PlayerComm,
			SUM(comm) - SUM(playercomm) AgComm,
			SUM(acomm) - SUM(comm) MAgComm,
			SUM(scomm) - SUM(acomm) SAgComm,
			-SUM(scomm) ExtraComm,
			SUM(CASE WHEN apositiontaking = 1 THEN 0 ELSE ISNULL(comm/(1-apositiontaking),0) END) GrossComm			
		FROM bodb02.dbo.bettrans14 bt WITH(NOLOCK)
			INNER JOIN @Bettype b ON bt.bettype = b.TypeId
		WHERE bt.winlostdate = @WinlostDate 
			AND bt.statusID NOT IN (0,1,102,101,103)
			AND bt.bettype < 19000
		GROUP BY custid, recommend, mrecommend, srecommend, b.ProductId,
				CASE WHEN bettype IN (71, 72) THEN bettype ELSE 0 END
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
			@WinlostDate, 
			ag.custid,
			b.ProductId,
			CASE WHEN bt.bettype IN (71, 72) THEN bt.bettype ELSE  0 END Bettype,
			2,
			c.recommend,
			c.mrecommend,
			c.srecommend,
			COUNT(1) BetCount,
			SUM(ABS(stake)) TurnOver,
			SUM(ABS(stake * apositiontaking))  NetTurnOver,
			SUM( CASE	WHEN bt.StatusID IN (112,113) AND bt.MOdds IN (-0.25, 0.25) 
							---- Sportsbook
							AND (bt.Bettype < 999 OR bt.bettype BETWEEN 1301 AND 1399 OR bt.bettype BETWEEN 9001 AND 9399)
							AND bt.Bettype NOT IN (71,72)
							AND bt.Bettype NOT BETWEEN 81 AND 120			
							THEN ABS(stake)/2
						WHEN bt.StatusID = 111  
							AND (
								---- Sportsbook
									(bt.Bettype < 999 OR bt.bettype BETWEEN 1301 AND 1399 OR bt.bettype BETWEEN 9001 AND 9399)
									AND bt.Bettype NOT IN (71,72)
									AND bt.Bettype NOT BETWEEN 81 AND 120
							)
							THEN 0
						WHEN   bt.Bettype BETWEEN 2401 AND 2499   -- Allbet
							OR bt.Bettype BETWEEN 3001 AND 3099   -- SA Gaming
							OR bt.Bettype BETWEEN 3101 AND 3199   -- Sexy Gaming
							OR bt.Bettype BETWEEN 3300 AND 3399   -- BBIN	
							OR bt.Bettype BETWEEN 3201 AND 3299   -- IBCBet Live Casino
							OR bt.Bettype BETWEEN 5601 AND 5699   -- ION 	 
							THEN bt.oddsspread
						ELSE ABS(bt.stake) 
					END) AS TurnoverNoDrawm,
			SUM(winlost-actual_stake)  Winlost,
			SUM(awinlost) AgWinLoss,
			SUM(mwinlost) MAgWinLoss,
			SUM(swinlost) SAgWinLoss,
			SUM((winlost - actual_stake) * epositiontaking) AS ExtraWinloss,
			SUM(playercomm)  PlayerComm,
			SUM(comm) - SUM(playercomm) AgComm,
			SUM(acomm) - SUM(comm) MAgComm,
			SUM(scomm) - SUM(acomm) SAgComm,
			-SUM(scomm) ExtraComm,
			SUM(CASE WHEN apositiontaking+mpositiontaking = 1 THEN 0 ELSE ISNULL(acomm/(1-apositiontaking-mpositiontaking), 0) END) GrossComm
		FROM bodb02.dbo.bettrans14 bt WITH(NOLOCK)
			INNER JOIN @Bettype b ON bt.bettype = b.TypeId
			INNER JOIN bodb02.dbo.Customer c WITH(NOLOCK) ON c.custid = bt.custid
			INNER JOIN bodb02.dbo.Customer ag WITH(NOLOCK) ON ag.custid = c.recommend
		WHERE bt.winlostdate = @WinlostDate 
			AND bt.statusID NOT IN (0,1,102,101,103)
			AND bt.bettype < 19000
			AND c.roleid = 1 
		GROUP BY ag.custid, c.recommend, c.mrecommend, c.srecommend, b.ProductId,
				CASE WHEN bettype IN (71, 72) THEN bettype ELSE 0 END
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
			@WinlostDate, 
			ma.custid,
			b.ProductId,
			CASE WHEN bt.bettype IN (71, 72) THEN bt.bettype ELSE  0 END Bettype,
			3 RoleId,
			0 recommend,
			c.mrecommend,
			c.srecommend,
			COUNT(1) BetCount,
			SUM(ABS(stake)) TurnOver,
			SUM(ABS(stake * mpositiontaking))  NetTurnOver,
			SUM( CASE	WHEN bt.StatusID IN (112,113) AND bt.MOdds IN (-0.25, 0.25) 
							---- Sportsbook
							AND (bt.Bettype < 999 OR bt.bettype BETWEEN 1301 AND 1399 OR bt.bettype BETWEEN 9001 AND 9399)
							AND bt.Bettype NOT IN (71,72)
							AND bt.Bettype NOT BETWEEN 81 AND 120			
							THEN ABS(stake)/2
						WHEN bt.StatusID = 111  
							AND (
								---- Sportsbook
									(bt.Bettype < 999 OR bt.bettype BETWEEN 1301 AND 1399 OR bt.bettype BETWEEN 9001 AND 9399)
									AND bt.Bettype NOT IN (71,72)
									AND bt.Bettype NOT BETWEEN 81 AND 120
							)
							THEN 0
						WHEN   bt.Bettype BETWEEN 2401 AND 2499   -- Allbet
							OR bt.Bettype BETWEEN 3001 AND 3099   -- SA Gaming
							OR bt.Bettype BETWEEN 3101 AND 3199   -- Sexy Gaming
							OR bt.Bettype BETWEEN 3300 AND 3399   -- BBIN	
							OR bt.Bettype BETWEEN 3201 AND 3299   -- IBCBet Live Casino
							OR bt.Bettype BETWEEN 5601 AND 5699   -- ION 	 
							THEN bt.oddsspread
						ELSE ABS(bt.stake) 
					END) AS TurnoverNoDrawm,
			SUM(winlost-actual_stake)  Winlost,
			SUM(awinlost) AgWinLoss,
			SUM(mwinlost) MAgWinLoss,
			SUM(swinlost) SAgWinLoss,
			SUM((winlost - actual_stake) * epositiontaking) AS ExtraWinloss,
			SUM(playercomm)  PlayerComm,
			SUM(comm) - SUM(playercomm) AgComm,
			SUM(acomm) - SUM(comm) MAgComm,
			SUM(scomm) - SUM(acomm) SAgComm,
			-SUM(scomm) ExtraComm,
			SUM(CASE WHEN tpositiontaking = 1 THEN 0 ELSE scomm / (1-tpositiontaking) END) GrossComm

		FROM bodb02.dbo.bettrans14 bt WITH(NOLOCK)
			INNER JOIN @Bettype b ON bt.bettype = b.TypeId
			INNER JOIN bodb02.dbo.Customer c WITH(NOLOCK) ON c.custid = bt.custid
			INNER JOIN bodb02.dbo.Customer ma WITH(NOLOCK) ON ma.custid = c.mrecommend
		WHERE bt.winlostdate = @WinlostDate 
			AND bt.statusID NOT IN (0,1,102,101,103)
			AND bt.bettype < 19000
			AND c.roleid = 1 
		GROUP BY ma.custid, c.mrecommend, c.srecommend, b.ProductId,
				CASE WHEN bettype IN (71, 72) THEN bettype ELSE 0 END
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
			@WinlostDate, 
			s.custid,
			b.ProductId,
			CASE WHEN bt.bettype IN (71, 72) THEN bt.bettype ELSE  0 END Bettype,
			4 RoleId,
			0 recommend,
			0 mrecommend,
			c.srecommend,
			COUNT(1) BetCount,
			SUM(ABS(stake)) TurnOver,
			SUM(ABS(stake * spositiontaking))  NetTurnOver,
			SUM( CASE	WHEN bt.StatusID IN (112,113) AND bt.MOdds IN (-0.25, 0.25) 
							---- Sportsbook
							AND (bt.Bettype < 999 OR bt.bettype BETWEEN 1301 AND 1399 OR bt.bettype BETWEEN 9001 AND 9399)
							AND bt.Bettype NOT IN (71,72)
							AND bt.Bettype NOT BETWEEN 81 AND 120			
							THEN ABS(stake)/2
						WHEN bt.StatusID = 111  
							AND (
								---- Sportsbook
									(bt.Bettype < 999 OR bt.bettype BETWEEN 1301 AND 1399 OR bt.bettype BETWEEN 9001 AND 9399)
									AND bt.Bettype NOT IN (71,72)
									AND bt.Bettype NOT BETWEEN 81 AND 120
							)
							THEN 0
						WHEN   bt.Bettype BETWEEN 2401 AND 2499   -- Allbet
							OR bt.Bettype BETWEEN 3001 AND 3099   -- SA Gaming
							OR bt.Bettype BETWEEN 3101 AND 3199   -- Sexy Gaming
							OR bt.Bettype BETWEEN 3300 AND 3399   -- BBIN	
							OR bt.Bettype BETWEEN 3201 AND 3299   -- IBCBet Live Casino
							OR bt.Bettype BETWEEN 5601 AND 5699   -- ION 	 
							THEN bt.oddsspread
						ELSE ABS(bt.stake) 
					END) AS TurnoverNoDrawm,
			SUM(winlost-actual_stake)  Winlost,
			SUM(awinlost) AgWinLoss,
			SUM(mwinlost) MAgWinLoss,
			SUM(swinlost) SAgWinLoss,
			SUM((winlost - actual_stake) * epositiontaking) AS ExtraWinloss,
			SUM(playercomm)  PlayerComm,
			SUM(comm) - SUM(playercomm) AgComm,
			SUM(acomm) - SUM(comm) MAgComm,
			SUM(scomm) - SUM(acomm) SAgComm,
			-SUM(scomm) ExtraComm,
			SUM(CASE WHEN tpositiontaking = 1 THEN 0 ELSE scomm / (1-tpositiontaking) END) GrossComm

		FROM bodb02.dbo.bettrans14 bt WITH(NOLOCK)
			INNER JOIN @Bettype b ON bt.bettype = b.TypeId
			INNER JOIN bodb02.dbo.Customer c WITH(NOLOCK) ON c.custid = bt.custid
			INNER JOIN bodb02.dbo.Customer s WITH(NOLOCK) ON s.custid = c.srecommend
		WHERE bt.winlostdate = @WinlostDate 
			AND bt.statusID NOT IN (0,1,102,101,103)
			AND bt.bettype < 19000
			AND c.roleid = 1 
		GROUP BY s.custid, c.srecommend, b.ProductId,
				CASE WHEN bettype IN (71, 72) THEN bettype ELSE 0 END
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
					TARGET.TunroverNoDraw	= SOURCE.TunroverNoDraw,
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