/*<info serverAlias="DBSUM-bodb_Summary" executers="" viewers="" isFunction="0" isNested="1"></info>*/

CREATE PROCEDURE [dbo].[Task_DailySum_Winloss_Extra]
	@WinlostDate SMALLDATETIME, @ProductIds VARCHAR(200) = '46'
AS
/*
	Created: 20200618@Malcolm
	Task: SP Gen data for Task_DailySum_Winloss_Extra [Redmine: #135593]
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20200618@Malcolm: Initialize SP [RedmineID: #135593]
 
	Param's Explanation:
*/

BEGIN
	CREATE TABLE #Bettype (TypeId SMALLINT, ProductId SMALLINT)

	INSERT INTO #Bettype
	(
		TypeId,
		ProductId
	)
	SELECT DISTINCT BetType, ProductID
	FROM bodb02.dbo.SportBettypeMatrix m WITH(NOLOCK)
	WHERE ',' + @ProductIds + ',' LIKE '%,' + CONVERT(VARCHAR(10),ProductID) + ',%'

	CREATE TABLE #Sum_Winloss_Extra 
	(
		WinlostDate			DATETIME,
		CustId				INT,
		ProductId			SMALLINT,
		Bettype				SMALLINT,
		RoleID				INT,
		Recommend			INT,
		MRecommend			INT,
		SRecommend			INT,
		BetCount			INT,
		Turnover			MONEY,
		NetTurnover			MONEY,
		NetTurnoverSMA		MONEY,
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
		GrossCommAgent		MONEY,
		GrossCommMaster		MONEY,
		GrossCommSuper		MONEY
	)
	-- for member , roleid = 1
	BEGIN
		INSERT INTO #Sum_Winloss_Extra
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
			NetTurnoverSMA,
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
			GrossCommAgent,
			GrossCommMaster,
			GrossCommSuper
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
			SUM(ABS(stake * spositiontaking))  NetTurnOverSMA,
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
			SUM(winlost-actual_stake) Winlost,
			SUM(awinlost) AgWinLoss,
			SUM(mwinlost) MAgWinLoss,
			SUM(swinlost) SAgWinLoss,
			SUM((winlost - actual_stake) * epositiontaking) ExtraWinloss,
			SUM(playercomm)  PlayerComm,
			SUM(comm) - SUM(playercomm) AgComm,
			SUM(acomm) - SUM(comm) MAgComm,
			SUM(scomm) - SUM(acomm) SAgComm,
			-SUM(scomm) ExtraComm,
			SUM(CASE WHEN apositiontaking = 1 THEN 0 ELSE ISNULL(comm/(1-apositiontaking),0) END) GrossComm,
			SUM(CASE WHEN apositiontaking+mpositiontaking = 1 THEN 0 ELSE ISNULL(acomm/(1-apositiontaking-mpositiontaking), 0) END) GrossCommAgent,
			SUM(CASE WHEN tpositiontaking = 1 THEN 0 ELSE scomm / (1-tpositiontaking) END) GrossCommMaster,
			SUM(CASE WHEN tpositiontaking = 1 THEN 0 ELSE scomm / (1-tpositiontaking) END) GrossCommSuper
		FROM bodb02.dbo.bettrans bt WITH(NOLOCK)
			INNER JOIN #Bettype b ON bt.bettype = b.TypeId
		WHERE bt.winlostdate = @WinlostDate 
			AND bt.statusID NOT IN (0,1,102,101,103)
			AND bt.bettype < 19000
		GROUP BY custid, recommend, mrecommend, srecommend, b.ProductId,
				CASE WHEN bettype IN (71, 72) THEN bettype ELSE 0 END
	END
	-- for agent, roleid = 2
	BEGIN
		INSERT INTO #Sum_Winloss_Extra
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
			SUM(NetTurnoverSMA),
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
			SUM(GrossCommAgent)
		FROM #Sum_Winloss_Extra
		WHERE RoleID = 1
		GROUP BY WinlostDate, Recommend, MRecommend, SRecommend,ProductId, Bettype
	END

	-- for master, roleId = 3
	BEGIN
		INSERT INTO #Sum_Winloss_Extra
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
			SUM(NetTurnoverSMA),
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
			SUM(GrossCommMaster)
		FROM #Sum_Winloss_Extra
		WHERE RoleID = 1
		GROUP BY WinlostDate, MRecommend, SRecommend,ProductId, Bettype
	END
	-- for super, roleId = 4
	BEGIN
		INSERT INTO #Sum_Winloss_Extra
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
			SUM(NetTurnoverSMA),
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
			SUM(GrossCommSuper)
		FROM #Sum_Winloss_Extra
		WHERE RoleID = 1
		GROUP BY WinlostDate, SRecommend,ProductId, Bettype
	END

	/**/

	BEGIN
		MERGE dbo.Sum_Winloss_Extra AS TARGET
		USING #Sum_Winloss_Extra AS SOURCE
			ON		TARGET.WinlostDate	= SOURCE.WinlostDate
				AND TARGET.CustId		= SOURCE.CustId
				AND TARGET.ProductId	= SOURCE.ProductId
				AND TARGET.Bettype		= SOURCE.Bettype
		WHEN MATCHED THEN
			UPDATE SET 
				TARGET.RoleId			= SOURCE.RoleId,
				TARGET.recommend		= SOURCE.recommend,
				TARGET.mrecommend		= SOURCE.mrecommend,
				TARGET.srecommend		= SOURCE.srecommend,
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
				);
				
	END

	DROP TABLE #Sum_Winloss_Extra

END
GO