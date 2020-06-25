/*<info serverAlias="DBSUM-bodb_Summary" executers="" viewers="" isFunction="0" isNested="1"></info>*/

CREATE PROCEDURE [dbo].[Task_DailySum_Winloss_Extra]
	@WinlostDate SMALLDATETIME,
	@ProductIds  VARCHAR(MAX) = ''
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
	WHERE ',' + @ProductIds + ','  LIKE '%,' + CONVERT(VARCHAR(10),m.ProductID) + ',% '

	CREATE TABLE #Sum_Winloss_Extra 
	(
		WinlostDate			SMALLDATETIME,
		CustId				INT,
		ProductId			SMALLINT,
		Bettype				SMALLINT,
		RoleID				TINYINT ,
		Recommend			INT,
		MRecommend			INT,
		SRecommend			INT,
		BetCount			INT,
		Turnover			MONEY,
		NetTurnover			MONEY,
		NetTurnoverAg		MONEY,
		NetTurnoverMAg		MONEY,
		NetTurnoverSAg		MONEY,
		TurnoverNoDraw		MONEY,
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
			NetTurnoverAg,
			NetTurnoverMAg,
			NetTurnoverSAg,
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
			GrossComm,
			GrossCommAg,
			GrossCommMAg,
			GrossCommSAg
		)
		SELECT
			@WinlostDate AS WinlostDate, 
			custid	AS CustId,
			b.ProductId	AS ProductId,
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
			SUM(CASE WHEN b.ProductId = 46 THEN bt.oddsspread ELSE ABS(stake) END) AS TurnoverNoDraw,
			SUM(winlost-actual_stake) AS Winlost,
			SUM(awinlost) AS AgWinLoss,
			SUM(mwinlost) AS MAgWinLoss,
			SUM(swinlost) AS SAgWinLoss,
			-SUM((winlost - actual_stake) * epositiontaking) AS ExtraWinloss,
			SUM(playercomm) AS PlayerComm,
			SUM(comm) - SUM(playercomm) AS AgComm,
			SUM(acomm) - SUM(comm) AS MAgComm,
			SUM(scomm) - SUM(acomm) AS SAgComm,
			-SUM(scomm) AS ExtraComm,
			SUM(CASE WHEN apositiontaking = 1 THEN 0 ELSE comm/(1-apositiontaking) END) AS GrossComm,
			SUM(CASE WHEN (apositiontaking+mpositiontaking) = 1 THEN 0 ELSE acomm/(1-apositiontaking-mpositiontaking) END) AS GrossCommAg,
			SUM(CASE WHEN tpositiontaking = 1 THEN 0 ELSE scomm / (1-tpositiontaking) END) AS GrossCommMAg,
			SUM(CASE WHEN tpositiontaking = 1 THEN 0 ELSE scomm / (1-tpositiontaking) END) AS GrossCommSAg
		FROM bodb02.dbo.bettrans bt WITH(NOLOCK)
			INNER JOIN #Bettype b ON bt.bettype = b.TypeId
		WHERE bt.winlostdate = @WinlostDate 
			AND bt.statusID NOT IN (102,101,103)
		GROUP BY custid, recommend, mrecommend, srecommend, b.ProductId
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
			SUM(TurnoverNoDraw),
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
		FROM #Sum_Winloss_Extra
		WHERE RoleID = 1
		GROUP BY WinlostDate,  Recommend, MRecommend, SRecommend,ProductId, Bettype
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
			SUM(TurnoverNoDraw),
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
			SUM(TurnoverNoDraw),
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
				TARGET.TurnoverNoDraw	= SOURCE.TurnoverNoDraw,
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
					SOURCE.TurnoverNoDraw,
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