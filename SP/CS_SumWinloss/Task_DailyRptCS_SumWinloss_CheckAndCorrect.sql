/*<info serverAlias="DBSUM-bodb_Summary" executers="" viewers="" isFunction="0" isNested="0"></info>*/
use bodb_Summary
GO 

ALTER PROCEDURE [dbo].[Task_DailyRptCS_SumWinloss_CheckAndCorrect]
	@WinlostDate AS SMALLDATETIME,
	@IsCheckDataOnly BIT = 0 
AS

/*
	Created: 20190301@Sophia
	Task: SP Gen data for CS_SumWinloss   
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20190301@Sophia: Initialize SP [RedmineID: #105660]
		- 20190329@Sophia: Implement Non Sports [Redmine: #109521] 
		
	Param's Explanation:
	
*/


BEGIN 
	SET NOCOUNT ON 	

	------ Check SP Version
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)	

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
		Wagers			int,
		Stake			money,
		ValidStake		money,
		MemberWinloss	money,
		MemberComm		money,
		Agent			money,
		AgentWinloss	money,
		AgentComm		money,
		AgentStock		money,
		AgentResultA	money,
		Master			money,
		MasterWinloss	money,
		MasterComm		money,
		MasterStock		money,
		Super			money,
		SuperWinloss	money,
		SuperComm		money,
		SuperStock		money,
		HeadlineWinloss	money,
		HeadlineComm	money,
		HeadlineStock	money,
		HeadlineId		int
	)


	CREATE TABLE #CS_SumWinloss
	(
		CustID			int,
		WinlostDate		smalldatetime,
		ProductId		smallint,
		Sporttype		smallint,
		Bettype			smallint,
		IsLive			bit,
		Wagers			int,
		Stake			money,
		ValidStake		money,
		MemberWinloss	money,
		MemberComm		money,
		Agent			money,
		AgentWinloss	money,
		AgentComm		money,
		AgentStock		money,
		AgentResultA	money,
		Master			money,
		MasterWinloss	money,
		MasterComm		money,
		MasterStock		money,
		Super			money,
		SuperWinloss	money,
		SuperComm		money,
		SuperStock		money,
		HeadlineWinloss	money,
		HeadlineComm	money,
		HeadlineStock	money,
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
			MatchID,
			Bettype,
			IsLive,
			Wagers,
			Stake,
			ValidStake,
			MemberWinloss,
			MemberComm,
			Agent,
			AgentWinloss,
			AgentComm,
			AgentStock,
			AgentResultA,
			Master,
			MasterWinloss,
			MasterComm,
			MasterStock,
			Super,
			SuperWinloss,
			SuperComm,
			SuperStock,
			HeadlineWinloss,
			HeadlineComm,
			HeadlineStock,
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
				Count(TransID) As Wagers,
				SUM(Stake) AS Stake,
				SUM(ABS(winlost - actual_stake)) ValidStake,
				SUM(Winlost - actual_stake) AS MemberWinloss,
				SUM(Playercomm) AS MemberComm,
				SUM((Winlost - actual_stake)  + (ABS(winlost - actual_stake) * discount) ) AS Agent,
				SUM(Awinlost) AS AgentWinloss,
				SUM(Comm - PlayerComm) AS AgentComm,
				SUM(ABS(winlost - actual_stake) * (1 - apositiontaking)) AS AgentStock,
				SUM((Winlost - actual_stake + Playercomm)* (1 - APositiontaking)) AS AgentResultA,
				SUM(((Winlost - actual_stake) * (1-apositiontaking)) + ABS(winlost - actual_stake) * (1 - apositiontaking) * adiscount) AS Master,
				SUM(MWinlost) AS MasterWinloss,
				SUM(AComm - Comm) AS MasterComm,
				SUM(ABS(winlost - actual_stake) * (1 - apositiontaking - mpositiontaking)) AS MasterStock,	
				SUM( (Winlost - actual_stake)* (1 - apositiontaking - mpositiontaking) 
									 +  ABS(winlost - actual_stake) * (1 - apositiontaking - mpositiontaking) * sdiscount
									 ) AS Super,
				SUM(SWinlost) AS SuperWinloss,
				SUM(SComm - Acomm) AS SuperComm,
				SUM(ABS(winlost - actual_stake) * (1 - tpositiontaking)) AS SuperStock,
				SUM ( -1 * (CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake END) * e.ExtraPT) AS HeadlineWinloss,
				SUM ( -1 * (CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.scomm / (1 - b.tpositiontaking) END) * e.ExtraPT) AS HeadlineComm,
				SUM (ABS(winlost - actual_stake) * (1 - tpositiontaking - e.ExtraPT)) AS HeadlineStock,
				CS.UplineId AS HeadlineId			 
		FROM bodb02.dbo.Bettrans14 b WITH (NOLOCK) 
			INNER JOIN bodb02.dbo.CustSuper CS WITH (NOLOCK) ON b.srecommend = CS.CustID			
			INNER JOIN (SELECT ProductID, Bettype, EventType FROM bodb02.dbo.CS_F_bettypeMatrix_Sel (0,0,0,@isTest) ) x ON x.Bettype = b.Bettype
			LEFT JOIN #ExtraPT e
				ON	b.Srecommend = e.SuperID 
					AND b.winlostdate BETWEEN e.FromDate AND E.ToDate
					AND x.ProductID = e.ProductID
		WHERE b.WinlostDate = @WinlostDate
			AND b.StatusID IN (111,112,113) 		 
			AND EXISTS (SELECT 1 FROM bodb02.dbo.CS_CustSuper CSS WITH (NOLOCK) WHERE b.srecommend = CSS.CustID)
		GROUP BY
				b.CustID,
				b.WinlostDate,
				x.ProductId,
				x.EventType,
				b.matchID,
				b.Bettype,
				CASE WHEN b.bettype = 29 THEN  CASE WHEN b.livehomescore = 1 THEN 1 ELSE 0 END ELSE b.Liveindicator END ,	
				CS.UplineId
	
	--- bettrans only
	INSERT INTO #CS_SumWinloss
		(
			CustID,
			WinlostDate,
			ProductId,
			Sporttype,
			Bettype,
			IsLive,
			Wagers,
			Stake,
			ValidStake,
			MemberWinloss,
			MemberComm,
			Agent,
			AgentWinloss,
			AgentComm,
			AgentStock,
			AgentResultA,
			Master,
			MasterWinloss,
			MasterComm,
			MasterStock,
			Super,
			SuperWinloss,
			SuperComm,
			SuperStock,
			HeadlineWinloss,
			HeadlineComm,
			HeadlineStock,
			HeadlineId
		)
			
		SELECT 
				b.CustID,
				b.WinlostDate,
				b.ProductId,
				b.matchID AS Sporttype,
				b.Bettype,			
				b.isLive,																	
				SUM(Wagers) AS  Wagers ,
				SUM(Stake) AS Stake,
				SUM(ValidStake) AS ValidStake,
				SUM(MemberWinloss) AS MemberWinloss,
				SUM(MemberComm) AS MemberComm,
				SUM(Agent) AS Agent,
				SUM(AgentWinloss) AS AgentWinloss,
				SUM(AgentComm) AS AgentComm,
				SUM(AgentStock) AS AgentStock,
				SUM(AgentResultA) AS AgentResultA,
				SUM(Master) AS Master,
				SUM(MasterWinloss) AS MasterWinloss,
				SUM(MasterComm) AS MasterComm,
				SUM(MasterStock) AS MasterStock,	
				SUM(Super) AS Super,
				SUM(SuperWinloss) AS SuperWinloss,
				SUM(SuperComm) AS SuperComm,
				SUM(SuperStock) AS SuperStock,
				SUM (HeadlineWinloss) AS HeadlineWinloss,
				SUM (HeadlineComm) AS HeadlineComm,
				SUM (HeadlineStock) AS HeadlineStock,
				b.HeadlineId AS HeadlineId			 
		FROM  #Bettrans b			
		WHERE EventType = 0	
		GROUP BY
				b.CustID,
				b.WinlostDate,
				b.ProductId,
				b.MatchId,
				b.Bettype,			
				b.isLive,	
				b.HeadlineId

	--- Match
	INSERT INTO #CS_SumWinloss
		(
			CustID,
			WinlostDate,
			ProductId,
			Sporttype,
			Bettype,
			IsLive,
			Wagers,
			Stake,
			ValidStake,
			MemberWinloss,
			MemberComm,
			Agent,
			AgentWinloss,
			AgentComm,
			AgentStock,
			AgentResultA,
			Master,
			MasterWinloss,
			MasterComm,
			MasterStock,
			Super,
			SuperWinloss,
			SuperComm,
			SuperStock,
			HeadlineWinloss,
			HeadlineComm,
			HeadlineStock,
			HeadlineId
		)
			
		SELECT 
				b.CustID,
				b.WinlostDate,
				b.ProductId,
				m.Sporttype,
				b.Bettype,			
				b.isLive,																	
				SUM(Wagers) AS  Wagers ,
				SUM(Stake) AS Stake,
				SUM(ValidStake) AS ValidStake,
				SUM(MemberWinloss) AS MemberWinloss,
				SUM(MemberComm) AS MemberComm,
				SUM(Agent) AS Agent,
				SUM(AgentWinloss) AS AgentWinloss,
				SUM(AgentComm) AS AgentComm,
				SUM(AgentStock) AS AgentStock,
				SUM(AgentResultA) AS AgentResultA,
				SUM(Master) AS Master,
				SUM(MasterWinloss) AS MasterWinloss,
				SUM(MasterComm) AS MasterComm,
				SUM(MasterStock) AS MasterStock,	
				SUM(Super) AS Super,
				SUM(SuperWinloss) AS SuperWinloss,
				SUM(SuperComm) AS SuperComm,
				SUM(SuperStock) AS SuperStock,
				SUM (HeadlineWinloss) AS HeadlineWinloss,
				SUM (HeadlineComm) AS HeadlineComm,
				SUM (HeadlineStock) AS HeadlineStock,
				b.HeadlineId AS HeadlineId			 
		FROM  #Bettrans b			
			INNER JOIN bodb02.dbo.Match14 m WITH (NOLOCK) ON m.MatchID = b.MatchID
		WHERE EventType = 1	
		GROUP BY
				b.CustID,
				b.WinlostDate,
				b.ProductId,
				m.Sporttype,
				b.Bettype,			
				b.isLive,	
				b.HeadlineId


	---Outright 
	INSERT INTO #CS_SumWinloss
		(
			CustID,
			WinlostDate,
			ProductId,
			Sporttype,
			Bettype,
			IsLive,
			Wagers,
			Stake,
			ValidStake,
			MemberWinloss,
			MemberComm,
			Agent,
			AgentWinloss,
			AgentComm,
			AgentStock,
			AgentResultA,
			Master,
			MasterWinloss,
			MasterComm,
			MasterStock,
			Super,
			SuperWinloss,
			SuperComm,
			SuperStock,
			HeadlineWinloss,
			HeadlineComm,
			HeadlineStock,
			HeadlineId
		)
			
		SELECT 
				b.CustID,
				b.WinlostDate,
				b.ProductId,
				l.Sporttype,
				b.Bettype,			
				b.isLive,																	
				SUM(Wagers) AS  Wagers ,
				SUM(Stake) AS Stake,
				SUM(ValidStake) AS ValidStake,
				SUM(MemberWinloss) AS MemberWinloss,
				SUM(MemberComm) AS MemberComm,
				SUM(Agent) AS Agent,
				SUM(AgentWinloss) AS AgentWinloss,
				SUM(AgentComm) AS AgentComm,
				SUM(AgentStock) AS AgentStock,
				SUM(AgentResultA) AS AgentResultA,
				SUM(Master) AS Master,
				SUM(MasterWinloss) AS MasterWinloss,
				SUM(MasterComm) AS MasterComm,
				SUM(MasterStock) AS MasterStock,	
				SUM(Super) AS Super,
				SUM(SuperWinloss) AS SuperWinloss,
				SUM(SuperComm) AS SuperComm,
				SUM(SuperStock) AS SuperStock,
				SUM (HeadlineWinloss) AS HeadlineWinloss,
				SUM (HeadlineComm) AS HeadlineComm,
				SUM (HeadlineStock) AS HeadlineStock,
				b.HeadlineId AS HeadlineId			 
		FROM  #Bettrans b			
			INNER JOIN bodb02.dbo.outright14 m WITH (NOLOCK) ON m.orid = b.MatchID
			INNER JOIN bodb02.dbo.League l WITH (NOLOCK) ON l.leagueid = m.leagueid
		WHERE EventType = 2		
		GROUP BY
				b.CustID,
				b.WinlostDate,
				b.ProductId,
				l.Sporttype,
				b.Bettype,			
				b.isLive,	
				b.HeadlineId

	---VSOutright 
	INSERT INTO #CS_SumWinloss
		(
			CustID,
			WinlostDate,
			ProductId,
			Sporttype,
			Bettype,
			IsLive,
			Wagers,
			Stake,
			ValidStake,
			MemberWinloss,
			MemberComm,
			Agent,
			AgentWinloss,
			AgentComm,
			AgentStock,
			AgentResultA,
			Master,
			MasterWinloss,
			MasterComm,
			MasterStock,
			Super,
			SuperWinloss,
			SuperComm,
			SuperStock,
			HeadlineWinloss,
			HeadlineComm,
			HeadlineStock,
			HeadlineId
		)
			
		SELECT 
				b.CustID,
				b.WinlostDate,
				b.ProductId,
				r.Sporttype,
				b.Bettype,			
				b.isLive,																	
				SUM(Wagers) AS  Wagers ,
				SUM(Stake) AS Stake,
				SUM(ValidStake) AS ValidStake,
				SUM(MemberWinloss) AS MemberWinloss,
				SUM(MemberComm) AS MemberComm,
				SUM(Agent) AS Agent,
				SUM(AgentWinloss) AS AgentWinloss,
				SUM(AgentComm) AS AgentComm,
				SUM(AgentStock) AS AgentStock,
				SUM(AgentResultA) AS AgentResultA,
				SUM(Master) AS Master,
				SUM(MasterWinloss) AS MasterWinloss,
				SUM(MasterComm) AS MasterComm,
				SUM(MasterStock) AS MasterStock,	
				SUM(Super) AS Super,
				SUM(SuperWinloss) AS SuperWinloss,
				SUM(SuperComm) AS SuperComm,
				SUM(SuperStock) AS SuperStock,
				SUM (HeadlineWinloss) AS HeadlineWinloss,
				SUM (HeadlineComm) AS HeadlineComm,
				SUM (HeadlineStock) AS HeadlineStock,
				b.HeadlineId AS HeadlineId			 
		FROM  #Bettrans b			
			INNER JOIN bodb02.dbo.VSRaceInfo r WITH(NOLOCK) ON b.MatchId = r.EventID -- no need join VSOuright14
		WHERE EventType = 3		
		GROUP BY
				b.CustID,
				b.WinlostDate,
				b.ProductId,
				r.Sporttype,
				b.Bettype,			
				b.isLive,	
				b.HeadlineId

	END
	 
	-- Agent - RoleId = 2
	BEGIN
	INSERT INTO #CS_SumWinloss
		(
			CustID,
			WinlostDate,
			ProductId,
			Sporttype,
			Bettype,
			IsLive,
			Wagers,
			Stake,
			ValidStake,
			MemberWinloss,
			MemberComm,
			Agent,
			AgentWinloss,
			AgentComm,
			AgentStock,
			AgentResultA,
			Master,
			MasterWinloss,
			MasterComm,
			MasterStock,
			Super,
			SuperWinloss,
			SuperComm,
			SuperStock,
			HeadlineWinloss,
			HeadlineComm,
			HeadlineStock,
			HeadlineId
		)
			
		SELECT 
				c.recommend,
				b.WinlostDate,
				b.ProductId,
				b.Sporttype,
				b.Bettype,
				b.IsLive ,
				SUM(Wagers) As Wagers,
				SUM(Stake) AS Stake,
				SUM(ValidStake) ValidStake,
				SUM(MemberWinloss) AS MemberWinloss,
				SUM(MemberComm) AS MemberComm,
				SUM(Agent) AS Agent,
				SUM(AgentWinloss) AS AgentWinloss,
				SUM(AgentComm) AS AgentComm,
				SUM(AgentStock) AS AgentStock,
				SUM(AgentResultA) AS AgentResultA,
				SUM(Master) AS Master,
				SUM(MasterWinloss) AS MasterWinloss,
				SUM(MasterComm) AS MasterComm,
				SUM(MasterStock) AS MasterStock,	
				SUM(Super) AS Super,
				SUM(SuperWinloss) AS SuperWinloss,
				SUM(SuperComm) AS SuperComm,
				SUM(SuperStock) AS SuperStock,
				SUM(HeadlineWinloss) AS HeadlineWinloss,
				SUM(HeadlineComm) AS HeadlineComm,
				SUM(HeadlineStock) AS HeadlineStock,
				b.HeadlineId AS HeadlineId			 
		FROM  #CS_SumWinloss b
			INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.CustID = b.CustID	
		WHERE c.RoleID = 1	
		GROUP BY
				c.recommend,
				b.WinlostDate,
				b.ProductId,
				b.Sporttype,
				b.Bettype,
				b.IsLive ,
				b.HeadlineId
	END
				
	---- Master - RoleId = 3
	BEGIN
	INSERT INTO #CS_SumWinloss
		(
			CustID,
			WinlostDate,
			ProductId,
			Sporttype,
			Bettype,
			IsLive,
			Wagers,
			Stake,
			ValidStake,
			MemberWinloss,
			MemberComm,
			Agent,
			AgentWinloss,
			AgentComm,
			AgentStock,
			AgentResultA,
			Master,
			MasterWinloss,
			MasterComm,
			MasterStock,
			Super,
			SuperWinloss,
			SuperComm,
			SuperStock,
			HeadlineWinloss,
			HeadlineComm,
			HeadlineStock,
			HeadlineId
		)
			
		SELECT 
				c.mrecommend,
				b.WinlostDate,
				b.ProductId,
				b.Sporttype,
				b.Bettype,
				b.IsLive ,
				SUM(Wagers) As Wagers,
				SUM(Stake) AS Stake,
				SUM(ValidStake) ValidStake,
				SUM(MemberWinloss) AS MemberWinloss,
				SUM(MemberComm) AS MemberComm,
				SUM(Agent) AS Agent,
				SUM(AgentWinloss) AS AgentWinloss,
				SUM(AgentComm) AS AgentComm,
				SUM(AgentStock) AS AgentStock,
				SUM(AgentResultA) AS AgentResultA,
				SUM(Master) AS Master,
				SUM(MasterWinloss) AS MasterWinloss,
				SUM(MasterComm) AS MasterComm,
				SUM(MasterStock) AS MasterStock,	
				SUM(Super) AS Super,
				SUM(SuperWinloss) AS SuperWinloss,
				SUM(SuperComm) AS SuperComm,
				SUM(SuperStock) AS SuperStock,
				SUM(HeadlineWinloss) AS HeadlineWinloss,
				SUM(HeadlineComm) AS HeadlineComm,
				SUM(HeadlineStock) AS HeadlineStock,
				b.HeadlineId AS HeadlineId			 
		FROM  #CS_SumWinloss b
			INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.CustID = b.CustID	
		WHERE c.RoleID = 2	
		GROUP BY
				c.mrecommend,
				b.WinlostDate,
				b.ProductId,
				b.Sporttype,
				b.Bettype,
				b.IsLive ,
				b.HeadlineId
	END
	 	
							
	---- Super - RoleId = 4
	BEGIN
	INSERT INTO #CS_SumWinloss
		(
			CustID,
			WinlostDate,
			ProductId,
			Sporttype,
			Bettype,
			IsLive,
			Wagers,
			Stake,
			ValidStake,
			MemberWinloss,
			MemberComm,
			Agent,
			AgentWinloss,
			AgentComm,
			AgentStock,
			AgentResultA,
			Master,
			MasterWinloss,
			MasterComm,
			MasterStock,
			Super,
			SuperWinloss,
			SuperComm,
			SuperStock,
			HeadlineWinloss,
			HeadlineComm,
			HeadlineStock,
			HeadlineId
		)
			
		SELECT 
				c.srecommend,
				b.WinlostDate,
				b.ProductId,
				b.Sporttype,
				b.Bettype,
				b.IsLive ,
				SUM(Wagers) As Wagers,
				SUM(Stake) AS Stake,
				SUM(ValidStake) ValidStake,
				SUM(MemberWinloss) AS MemberWinloss,
				SUM(MemberComm) AS MemberComm,
				SUM(Agent) AS Agent,
				SUM(AgentWinloss) AS AgentWinloss,
				SUM(AgentComm) AS AgentComm,
				SUM(AgentStock) AS AgentStock,
				SUM(AgentResultA) AS AgentResultA,
				SUM(Master) AS Master,
				SUM(MasterWinloss) AS MasterWinloss,
				SUM(MasterComm) AS MasterComm,
				SUM(MasterStock) AS MasterStock,	
				SUM(Super) AS Super,
				SUM(SuperWinloss) AS SuperWinloss,
				SUM(SuperComm) AS SuperComm,
				SUM(SuperStock) AS SuperStock,
				SUM(HeadlineWinloss) AS HeadlineWinloss,
				SUM(HeadlineComm) AS HeadlineComm,
				SUM(HeadlineStock) AS HeadlineStock,
				b.HeadlineId AS HeadlineId			 
		FROM  #CS_SumWinloss b
			INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.CustID = b.CustID	
		WHERE c.RoleID = 3	
		GROUP BY
				c.srecommend,
				b.WinlostDate,
				b.ProductId,
				b.Sporttype,
				b.Bettype,
				b.IsLive ,
				b.HeadlineId
	END
	 

	/* Gen data */
		IF EXISTS (
		SELECT 1
		FROM #CS_SumWinloss SOURCE
			FULL OUTER JOIN CS_SumWinloss TARGET WITH (NOLOCK)
				ON	TARGET.WinlostDate	= SOURCE.WinlostDate
					AND TARGET.CustId		= SOURCE.CustId
					AND TARGET.ProductID	= SOURCE.ProductID
					AND TARGET.Sporttype	= SOURCE.Sporttype
					AND TARGET.Bettype		= SOURCE.Bettype	
					AND TARGET.IsLive		= SOURCE.IsLive	
		WHERE
				SOURCE.CustId IS NULL
				OR TARGET.CustId IS NULL
				OR TARGET.Wagers			<> SOURCE.Wagers
				OR	TARGET.Stake			<> SOURCE.Stake
				OR	TARGET.ValidStake		<> SOURCE.ValidStake
				OR	TARGET.MemberWinloss	<> SOURCE.MemberWinloss
				OR	TARGET.MemberComm		<> SOURCE.MemberComm
				OR	TARGET.Agent			<> SOURCE.Agent
				OR	TARGET.AgentWinloss		<> SOURCE.AgentWinloss
				OR	TARGET.AgentComm		<> SOURCE.AgentComm
				OR	TARGET.AgentStock		<> SOURCE.AgentStock				
				OR	TARGET.AgentResultA		<> SOURCE.AgentResultA
				OR	TARGET.Master			<> SOURCE.Master
				OR	TARGET.MasterWinloss	<> SOURCE.MasterWinloss
				OR	TARGET.MasterComm		<> SOURCE.MasterComm
				OR	TARGET.MasterStock		<> SOURCE.MasterStock
				OR	TARGET.Super			<> SOURCE.Super
				OR	TARGET.SuperWinloss		<> SOURCE.SuperWinloss
				OR	TARGET.SuperComm		<> SOURCE.SuperComm
				OR	TARGET.SuperStock		<> SOURCE.SuperStock
				OR	TARGET.HeadlineWinloss	<> SOURCE.HeadlineWinloss
				OR	TARGET.HeadlineComm		<> SOURCE.HeadlineComm
				OR	TARGET.HeadlineStock	<> SOURCE.HeadlineStock				
				OR	TARGET.HeadlineId		<> SOURCE.HeadlineId			
	)
	BEGIN
		IF @IsCheckDataOnly = 1 --just check data
		BEGIN
			SELECT 'Wrong data CS_SumWinloss on ' + CONVERT(VARCHAR(10), @WinlostDate, 112)
		END
		ELSE -- correct data	
		BEGIN
			MERGE dbo.CS_SumWinloss AS TARGET
			USING #CS_SumWinloss AS SOURCE
					ON	TARGET.WinlostDate	= SOURCE.WinlostDate
					AND TARGET.CustId		= SOURCE.CustId
					AND TARGET.ProductID	= SOURCE.ProductID
					AND TARGET.Sporttype	= SOURCE.Sporttype
					AND TARGET.Bettype		= SOURCE.Bettype	
					AND TARGET.IsLive		= SOURCE.IsLive	
			WHEN MATCHED THEN
				UPDATE SET
					TARGET.Wagers			= SOURCE.Wagers,
					TARGET.Stake			= SOURCE.Stake,
					TARGET.ValidStake		= SOURCE.ValidStake,
					TARGET.MemberWinloss	= SOURCE.MemberWinloss,
					TARGET.MemberComm		= SOURCE.MemberComm,
					TARGET.Agent			= SOURCE.Agent,
					TARGET.AgentWinloss		= SOURCE.AgentWinloss,
					TARGET.AgentComm		= SOURCE.AgentComm,	
					TARGET.AgentStock		= SOURCE.AgentStock,				
					TARGET.AgentResultA		= SOURCE.AgentResultA,
					TARGET.Master			= SOURCE.Master,
					TARGET.MasterWinloss	= SOURCE.MasterWinloss,
					TARGET.MasterComm		= SOURCE.MasterComm,
					TARGET.MasterStock		= SOURCE.MasterStock,
					TARGET.Super			= SOURCE.Super,
					TARGET.SuperWinloss		= SOURCE.SuperWinloss,
					TARGET.SuperComm		= SOURCE.SuperComm,
					TARGET.SuperStock		= SOURCE.SuperStock,
					TARGET.HeadlineWinloss	= SOURCE.HeadlineWinloss,
					TARGET.HeadlineComm		= SOURCE.HeadlineComm,	
					TARGET.HeadlineStock	= SOURCE.HeadlineStock,				
					TARGET.HeadlineId		= SOURCE.HeadlineId
			WHEN NOT MATCHED BY TARGET THEN
				INSERT
				(	WinlostDate,
					CustId,
					ProductID,
					Sporttype,
					Bettype,
					IsLive,
					Wagers,
					Stake,
					ValidStake,
					MemberWinloss,
					MemberComm,
					Agent,
					AgentWinloss,
					AgentComm,
					AgentStock,
					AgentResultA,
					Master,
					MasterWinloss,
					MasterComm,
					MasterStock,
					Super,
					SuperWinloss,
					SuperComm,
					SuperStock,
					HeadlineWinloss,
					HeadlineComm,
					HeadlineStock,
					HeadlineId
				)
				VALUES
				(	SOURCE.WinlostDate,
					SOURCE.CustId,
					SOURCE.ProductID,
					SOURCE.Sporttype,
					SOURCE.Bettype,
					SOURCE.IsLive,
					SOURCE.Wagers,
					SOURCE.Stake,
					SOURCE.ValidStake,
					SOURCE.MemberWinloss,
					SOURCE.MemberComm,
					SOURCE.Agent,
					SOURCE.AgentWinloss,
					SOURCE.AgentComm,
					SOURCE.AgentStock,
					SOURCE.AgentResultA,
					SOURCE.Master,
					SOURCE.MasterWinloss,
					SOURCE.MasterComm,
					SOURCE.MasterStock,
					SOURCE.Super,
					SOURCE.SuperWinloss,
					SOURCE.SuperComm,
					SOURCE.SuperStock,
					SOURCE.HeadlineWinloss,
					SOURCE.HeadlineComm,
					SOURCE.HeadlineStock,
					SOURCE.HeadlineId
				)
			WHEN NOT MATCHED BY SOURCE AND TARGET.WinlostDate = @Winlostdate THEN
			DELETE;
		END
	END
	 
	DROP TABLE #CS_SumWinloss
END
GO