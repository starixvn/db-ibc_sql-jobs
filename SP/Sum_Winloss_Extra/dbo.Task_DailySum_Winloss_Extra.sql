/*<info serverAlias="DBSUM-bodb_Summary" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_DailySum_Winloss_Extra]
	@WinlostDate SMALLDATETIME,
	@ProductIds  VARCHAR(MAX) = ''
AS
/*
	Created: 20200618@Malcolm
	Task: SP Gen data for Task_DailySum_Winloss_Extra [Redmine: #135593]
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20200618@Malcolm: Initialize SP [RedmineID: #135593]
		- 20200831@Sophia: Exclude CustID = 0 [Redmine: #140745]
		- 20211122@Percy: Enhance gross comm formula [RedmineID: #164479]
 
	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @GrossComm_CutOffDate SMALLDATETIME

	SELECT @GrossComm_CutOffDate = f.CutoffDate
	FROM bodb02.dbo.f_GetCutOffDate() f
	WHERE f.TypeName = 'GrossComm'

	CREATE TABLE #Bettype (TypeId SMALLINT, ProductId SMALLINT)

	INSERT INTO #Bettype
	(
		TypeId,
		ProductId
	)
	SELECT DISTINCT BetType, ProductID
	FROM bodb02.dbo.SportBettypeMatrix m WITH(NOLOCK)
	WHERE ',' + @ProductIds + ','  LIKE '%,' + CONVERT(VARCHAR(10),m.ProductID) + ',%'

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
			SUM(CASE WHEN bt.winlostdate < @GrossComm_CutOffDate THEN bt.oddsspread ELSE 0 END) AS TurnoverNoDraw,
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
			SUM(CASE WHEN bt.winlostdate < @GrossComm_CutOffDate OR bt.apositiontaking = 1 THEN 0 ELSE ISNULL(comm/(1-apositiontaking), 0) END) AS GrossComm,
			SUM(CASE WHEN bt.winlostdate < @GrossComm_CutOffDate OR bt.apositiontaking + bt.mpositiontaking = 1 THEN 0 ELSE ISNULL(acomm/(1-apositiontaking-mpositiontaking), 0) END) AS GrossCommAg,
			SUM(CASE WHEN bt.winlostdate < @GrossComm_CutOffDate OR bt.tpositiontaking = 1 THEN 0 ELSE ISNULL(scomm/(1-tpositiontaking), 0) END) AS GrossCommMAg,
			SUM(CASE WHEN bt.winlostdate < @GrossComm_CutOffDate OR bt.tpositiontaking = 1 THEN 0 ELSE ISNULL(scomm/(1-tpositiontaking), 0) END) AS GrossCommSAg
		FROM bodb02.dbo.bettrans bt WITH(NOLOCK)
			INNER JOIN #Bettype b ON bt.bettype = b.TypeId
		WHERE bt.winlostdate = @WinlostDate 
			AND bt.statusID NOT IN (102,101,103)
		GROUP BY custid, recommend, mrecommend, srecommend, b.ProductId

		;WITH CTE_NetTO_GrossComm AS (
			SELECT b.custid, b.gameID AS Bettype, bt.ProductId
				,SUM(b.BetStake) AS TurnoverNoDraw
				,SUM(b.BetStake * b.discount) AS GrossComm
				,SUM(b.BetStake * b.discount) AS GrossCommAg
				,SUM(b.BetStake * b.discount) AS GrossCommMAg
				,SUM(b.BetStake * b.discount) AS GrossCommSAg
			FROM bodb02.dbo.bettransRnG b WITH (NOLOCK)
				INNER JOIN #Bettype bt ON b.gameID = bt.TypeId
			WHERE b.winlostdate = @WinlostDate 
				AND b.statusID IN (111, 112, 113)
			GROUP BY b.custid, b.gameID, bt.ProductId
		)
		UPDATE t
		SET t.TurnoverNoDraw = ISNULL(c.TurnoverNoDraw, 0)
			,t.GrossComm = ISNULL(c.GrossComm, 0)
			,t.GrossCommAg = ISNULL(c.GrossCommAg, 0)
			,t.GrossCommMAg = ISNULL(c.GrossCommMAg, 0)
			,t.GrossCommSAg = ISNULL(c.GrossCommSAg, 0)
		FROM #Sum_Winloss_Extra t
			INNER JOIN CTE_NetTO_GrossComm c ON t.CustId = c.custid AND t.ProductId = c.ProductId AND t.Bettype = c.Bettype
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
	---Exclude CustID = 0 which is obsoleted
	DELETE #Sum_Winloss_Extra WHERE CustId = 0 

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