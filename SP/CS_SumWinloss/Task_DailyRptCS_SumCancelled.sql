/*<info serverAlias="DBSUM-bodb_Summary" executers="" viewers="" isFunction="0" isNested="0"></info>*/
use bodb_Summary
GO 

ALTER PROCEDURE [dbo].[Task_DailyRptCS_SumCancelled]
	@WinlostDate AS SMALLDATETIME
AS

/*
	Created: 20190301@Sophia
	Task: SP Gen data for CS_SumCancelled  
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20190301@Sophia: Initialize SP [RedmineID: #105660]
		- 20190329@Sophia: Implement Non Sports [Redmine: #109521] 
		
	Param's Explanation:
	
*/


BEGIN 
	SET NOCOUNT ON 	
	 

	/* Get data source */
	CREATE TABLE #Bettrans
	(
		CustID			int,
		WinlostDate		smalldatetime,
		ProductId		smallint,
		EventType		tinyint,
		MatchId			int,
		Bettype			smallint,
		IsLive			bit,
		CancelType		tinyint,
		Wagers			int,
		Stake			money,
		HeadlineId		int
	)
	
	CREATE TABLE #CS_SumCancelled
	(
		CustID			int,
		WinlostDate		smalldatetime,
		ProductId		smallint,
		Sporttype		smallint,
		Bettype			smallint,
		IsLive			bit,
		CancelType		tinyint,
		Wagers			int,
		Stake			money,
		HeadlineId		int
	)

	---- Get ExtraPT
	CREATE TABLE #ExtraPT (SuperID INT, ExtraPT DECIMAL(9,8), FromDate DATETIME, ToDate DATETIME, ProductID TINYINT)----, Sporttype SMALLINT, SubProduct VARCHAR (50) )

	INSERT INTO #ExtraPT (SuperID, ExtraPT, FromDate, ToDate, ProductID) 
	SELECT DISTINCT e.SuperID, e.ExtraPT, e.FromDate, e.ToDate, e.ProductId 
	FROM  bodb02.dbo.Acc_GroupExtraPTSetting e WITH (NOLOCK)  		
	WHERE	e.Sporttype = 0		--- General Sporttype of SB & other products
			AND e.SubProduct = '' 	--- General SubProduct of SB & other products 
			AND @WinlostDate BETWEEN e.FromDate AND e.ToDate
			AND EXISTS (Select 1 FROM bodb02.dbo.CS_CustSuper c WITH (NOLOCK) WHERE c.CustID = e.SuperId)						 

	---- End Get ExtraPT


	---- Member - RoleId = 1
	BEGIN
		INSERT INTO #Bettrans
			(
				CustID,
				WinlostDate,
				ProductId,
				EventType,
				MatchId	,
				Bettype,
				IsLive,
				CancelType,
				Wagers,
				Stake,
				HeadlineId
			)			
		SELECT 
				b.CustID,
				b.WinlostDate,
				x.ProductId,
				x.EventType,
				b.matchID,
				b.Bettype,
				CASE WHEN b.bettype = 29 THEN  CASE WHEN b.livehomescore = 1 THEN 1 ELSE 0 END ELSE b.Liveindicator END AS isLive,		
				CASE WHEN b.ExtraInfo LIKE '%p1%' AND t.c = 1   --- Abnormal bet
						 THEN 1  --- Abnormal bet
						 ELSE 2  --- Cancelled
					END AS CancelType,
				Count(TransID) As Wagers,
				SUM(Stake) AS Stake,
				CS.UplineId AS HeadlineId				 
		FROM bodb02.dbo.Bettrans b WITH (NOLOCK) 
			INNER JOIN bodb02.dbo.CustSuper CS WITH (NOLOCK) ON b.srecommend = CS.CustID			
			INNER JOIN (SELECT ProductID, Bettype, EventType FROM bodb02.dbo.CS_F_bettypeMatrix_Sel (0,0,0,0) ) x ON x.Bettype = b.Bettype
			LEFT JOIN #ExtraPT e
				ON	b.Srecommend = e.SuperID 
					AND b.winlostdate BETWEEN e.FromDate AND E.ToDate
					AND x.ProductID = e.ProductID
			CROSS APPLY (SELECT CAST(('<xml>' + ISNULL(b.ExtraInfo, '') + '</xml>') AS XML).value('data(/xml/p1/@ab)[1]','TINYINT')) AS t(c)
		WHERE b.WinlostDate = @WinlostDate
			AND b.StatusID IN (101,102,103)  			 			
			AND EXISTS (SELECT 1 FROM bodb02.dbo.CS_CustSuper CSS WITH (NOLOCK) WHERE b.srecommend = CSS.CustID)
		GROUP BY
				b.CustID,
				b.WinlostDate,
				x.ProductId,
				x.EventType,
				b.matchID,
				b.Bettype,
				CASE WHEN b.bettype = 29 THEN  CASE WHEN b.livehomescore = 1 THEN 1 ELSE 0 END ELSE b.Liveindicator END ,	
				CASE WHEN b.ExtraInfo LIKE '%p1%' AND t.c = 1   --- Abnormal bet
						 THEN 1  --- Abnormal bet
						 ELSE 2  --- Cancelled
					END,
				CS.UplineId
				
		--- Match 
		INSERT INTO #CS_SumCancelled
		(
			CustID,
			WinlostDate,
			ProductId,
			Sporttype,
			Bettype,
			IsLive,
			CancelType,
			Wagers,
			Stake,
			HeadlineId
		)
			
		SELECT 
				CustID,
				WinlostDate,
				ProductId,
				Sporttype,
				Bettype,
				IsLive,
				CancelType,
				SUM (Wagers),
				SUM (Stake),
				HeadlineId		 
		FROM #Bettrans b
			INNER JOIN bodb02.dbo.Match m WITH (NOLOCK) ON m.MatchID = b.MatchID
		WHERE EventType = 1 
		GROUP BY
				CustID,
				WinlostDate,
				ProductId,
				Sporttype,
				Bettype,
				IsLive,
				CancelType,
				HeadlineId	
		
		--- Outright
		INSERT INTO #CS_SumCancelled
		(
			CustID,
			WinlostDate,
			ProductId,
			Sporttype,
			Bettype,
			IsLive,
			CancelType,
			Wagers,
			Stake,
			HeadlineId
		)			
		SELECT 
				CustID,
				WinlostDate,
				ProductId,
				Sporttype,
				Bettype,
				IsLive,
				CancelType,
				SUM (Wagers),
				SUM (Stake),
				HeadlineId		 
		FROM #Bettrans b
			INNER JOIN bodb02.dbo.outright m WITH (NOLOCK) ON m.orid = b.MatchID
			INNER JOIN bodb02.dbo.League l WITH (NOLOCK) ON l.leagueid = m.leagueid
		WHERE EventType = 2	
		GROUP BY
				CustID,
				WinlostDate,
				ProductId,
				Sporttype,
				Bettype,
				IsLive,
				CancelType,
				HeadlineId	
				
		--- VSOutright
		INSERT INTO #CS_SumCancelled
		(
			CustID,
			WinlostDate,
			ProductId,
			Sporttype,
			Bettype,
			IsLive,
			CancelType,
			Wagers,
			Stake,
			HeadlineId
		)			
		SELECT 
				CustID,
				WinlostDate,
				ProductId,
				Sporttype,
				Bettype,
				IsLive,
				CancelType,
				SUM (Wagers),
				SUM (Stake),
				HeadlineId		 
		FROM  #Bettrans b			
			INNER JOIN bodb02.dbo.VSOutright o WITH (NOLOCK) ON o.EventID = b.MatchId
			INNER JOIN bodb02.dbo.VSRaceInfo r WITH(NOLOCK) ON o.EventID = r.EventID
		WHERE EventType = 3
		GROUP BY
				CustID,
				WinlostDate,
				ProductId,
				Sporttype,
				Bettype,
				IsLive,
				CancelType,
				HeadlineId	
				
		

	END
	 
	-- Agent - RoleId = 2
	BEGIN
	INSERT INTO #CS_SumCancelled
		(
			CustID,
			WinlostDate,
			ProductId,
			Sporttype,
			Bettype,
			IsLive,
			CancelType,
			Wagers,
			Stake,
			HeadlineId
		)
			
		SELECT 
				c.recommend,
				b.WinlostDate,
				b.ProductId,
				b.Sporttype,
				b.Bettype,
				b.IsLive ,
				b.CancelType,
				SUM(Wagers) As Wagers,
				SUM(Stake) AS Stake,
				b.HeadlineId AS HeadlineId			 
		FROM  #CS_SumCancelled b
			INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.CustID = b.CustID	
		WHERE c.RoleID = 1	
		GROUP BY
				c.recommend,
				b.WinlostDate,
				b.ProductId,
				b.Sporttype,
				b.Bettype,
				b.IsLive ,
				b.CancelType,
				b.HeadlineId
	END
				
	---- Master - RoleId = 3
	BEGIN
	INSERT INTO #CS_SumCancelled
		(
			CustID,
			WinlostDate,
			ProductId,
			Sporttype,
			Bettype,
			IsLive,
			CancelType,
			Wagers,
			Stake,
			HeadlineId
		)
			
		SELECT 
				c.mrecommend,
				b.WinlostDate,
				b.ProductId,
				b.Sporttype,
				b.Bettype,
				b.IsLive ,
				b.CancelType,
				SUM(Wagers) As Wagers,
				SUM(Stake) AS Stake,
				b.HeadlineId AS HeadlineId			 
		FROM  #CS_SumCancelled b
			INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.CustID = b.CustID	
		WHERE c.RoleID = 2	
		GROUP BY
				c.mrecommend,
				b.WinlostDate,
				b.ProductId,
				b.Sporttype,
				b.Bettype,
				b.IsLive ,
				b.CancelType,
				b.HeadlineId
	END
	 	
							
	---- Super - RoleId = 4
	BEGIN
	INSERT INTO #CS_SumCancelled
		(
			CustID,
			WinlostDate,
			ProductId,
			Sporttype,
			Bettype,
			CancelType,
			IsLive,
			Wagers,
			Stake,
			HeadlineId
		)
			
		SELECT 
				c.srecommend,
				b.WinlostDate,
				b.ProductId,
				b.Sporttype,
				b.Bettype,
				b.CancelType,
				b.IsLive ,
				SUM(Wagers) As Wagers,
				SUM(Stake) AS Stake,
				b.HeadlineId AS HeadlineId			 
		FROM  #CS_SumCancelled b
			INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.CustID = b.CustID	
		WHERE c.RoleID = 3	
		GROUP BY
				c.srecommend,
				b.WinlostDate,
				b.ProductId,
				b.Sporttype,
				b.Bettype,
				b.IsLive ,
				b.CancelType,
				b.HeadlineId
	END
	 

	/* Gen data */
	BEGIN
		MERGE dbo.CS_SumCancelled AS TARGET
		USING #CS_SumCancelled AS SOURCE
				ON	TARGET.WinlostDate	= SOURCE.WinlostDate
				AND TARGET.CustId		= SOURCE.CustId
				AND TARGET.ProductID	= SOURCE.ProductID
				AND TARGET.Sporttype	= SOURCE.Sporttype
				AND TARGET.Bettype		= SOURCE.Bettype	
				AND TARGET.IsLive		= SOURCE.IsLive							
				AND TARGET.CancelType	= SOURCE.CancelType
		WHEN MATCHED THEN
			UPDATE SET					
				TARGET.Wagers			= SOURCE.Wagers,
				TARGET.Stake			= SOURCE.Stake,			
				TARGET.HeadlineId		= SOURCE.HeadlineId
		WHEN NOT MATCHED BY TARGET THEN
			INSERT
			(	WinlostDate,
				CustId,
				ProductID,
				Sporttype,
				Bettype,
				IsLive,
				CancelType,
				Wagers,
				Stake,
				HeadlineId
			)
			VALUES
			(	SOURCE.WinlostDate,
				SOURCE.CustId,
				SOURCE.ProductID,
				SOURCE.Sporttype,
				SOURCE.Bettype,
				SOURCE.IsLive,
				SOURCE.CancelType,
				SOURCE.Wagers,
				SOURCE.Stake,
				SOURCE.HeadlineId
			)
		WHEN NOT MATCHED BY SOURCE AND TARGET.WinlostDate = @Winlostdate THEN
		DELETE;
	END

	DROP TABLE #CS_SumCancelled
END
GO