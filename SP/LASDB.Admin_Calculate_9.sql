USE [LASDB]
GO

/****** Object:  StoredProcedure [dbo].[Admin_Calculate_9]    Script Date: 01/27/2015 23:24:38 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Admin_Calculate_9    Script Date: 3/14/2014 4:26:27 PM ******/

CREATE PROCEDURE [dbo].[Admin_Calculate_9]	
	@winlostdate	SMALLDATETIME
	,@strXML		VARCHAR(MAX)	= ''
	,@statusID		TINYINT			= 0
WITH RECOMPILE  
AS  
/*
Created		: 20140116@Don
Task		: Settle bettrans based on bettransm (for mix parlay)
DB			: DBLAS.lasdb

Revisions:
	- 20140310@Don: Use [CREATE TABLE #baP(...)] instead of [SELECT ... INTO #baP]

Param's Explanation:
	- @strXML: list of [transid-modds-losecnt] of a match to be settled
*/
BEGIN
	SET NOCOUNT ON

	IF @@SERVERNAME NOT IN ('DB052', 'DB231') RETURN

	Declare @subStart datetime
	Declare @commWinRate smallmoney, @commLostRate smallmoney

	-- get modds from XML string
	Declare @xml XML
	Declare @modds AS TABLE (transid bigint PRIMARY KEY, modds smallmoney, loseCnt tinyint)
	
	SET @xml = convert(xml, @strXML)
	INSERT INTO @modds (transid, modds, loseCnt)
	SELECT T.C.value('./@t', 'bigint'), -- transid
		isnull(T.C.value('./@m', 'smallmoney'),0), -- modds
		isnull(T.C.value('./@l', 'tinyint'),0) -- lostCnt
	FROM @xml.nodes('/root/r') as T(C)	
	-- get modds from XML string

	CREATE TABLE #tmp_bettrans  (
		[transid] [bigint] NOT NULL ,  
		[refno] [bigint] unique clustered NOT NULL ,  
		[stake] [money] NOT NULL ,  
		[status] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,  
		[winlost] [money] NULL ,  	
		[winlostdate] [smalldatetime] NULL ,  	
		[playerdiscount] [float] NULL ,  	
		[playercomm] [money] NULL ,  	
		[TPositionTaking] [smallmoney] NULL ,
		Tdiscount [float] NULL,  
		[TWinLost] [money] NULL ,  
		TComm [money] NULL,  
		[ruben] [tinyint] NULL ,  
		[modds] [money] null,
		[statusID] [tinyint] NULL,
		[DoubleCommLosing] BIT NULL
	)   
	--create index temp_index on #tmp_bettrans (TransID)  
	-- GET list of concern Ticket
	SET @subStart = CURRENT_TIMESTAMP
	INSERT INTO #tmp_bettrans ([transid], [refno], [stake], [status],
			[winlost], 	[winlostdate], 	[playerdiscount], [playercomm],  
			[TPositionTaking], Tdiscount, [TWinLost], TComm,
			[ruben], [modds],[statusID], [DoubleCommLosing])
		SELECT
			b.[transid], b.[refno], [stake], [status],
			[winlost], 	[winlostdate], 	[playerdiscount], [playercomm], 
			[TPositionTaking], Tdiscount, [TWinLost], TComm,
			[ruben], b.[modds],[statusID], [DoubleCommLosing]
		FROM dbo.bettrans b WITH (ROWLOCK)
			INNER JOIN @modds t on b.transid = t.transid
		WHERE 
			b.matchid = 9 
			AND bettype = 9    
			AND statusID NOT IN (101,102)

	Declare @odds money, @DownlinePT smallmoney

	IF OBJECT_ID('tempdb..#baP') IS NOT NULL
	BEGIN
		DROP TABLE #baP
	END

	CREATE TABLE #baP(
		transid BIGINT, agentid INT, agentlevel SMALLINT, doublecommlosing BIT, stake MONEY
		,awinlost MONEY, acomm MONEY, apositiontaking SMALLMONEY, adiscount DECIMAL(9, 8), downlinept SMALLMONEY
		,status VARCHAR(10), statusid TINYINT, refno BIGINT, winlostdate SMALLDATETIME
	)
	CREATE CLUSTERED INDEX IX_transid on #baP (transid, agentlevel desc)

	--get the needed data to settle for agent
	INSERT INTO #baP(
			transid, agentid, agentlevel, doublecommlosing, stake
			,awinlost, acomm, apositiontaking, adiscount, downlinept
			,status, statusid, refno, winlostdate
	)
		SELECT 
			ba.transid, ba.[AgentId], a.[AgentLevel], b.[DoubleCommLosing], b.[Stake]
			,AWinLost, ba.AComm, APositionTaking, ADiscount, cast(0 as smallmoney) as DownlinePT
			,ba.Status, ba.StatusId, b.RefNo, b.WinLostDate
		--INTO #baP 
		FROM #tmp_bettrans B WITH (NOLOCK) JOIN BetTrans_Agent ba WITH (ROWLOCK) ON 
			b.TransId=ba.TransId JOIN AgentInfo a WITH (NOLOCK) ON a.AgentID=ba.AgentID	
	
	/*		
	--create index		
	CREATE CLUSTERED INDEX IX_tmp on #baP (transid,AgentLevel desc)		
	*/
			
	DECLARE @prevtransid BIGINT =0 
		
	-- settle for agent in temporary table
	UPDATE #baP 
	SET 
		@DownlinePT= case when @prevtransid <> #baP.transid 
							then APositionTaking
							else APositionTaking + @DownlinePT -- accumulated PT for upper agent --> for calculating agent commision
							end,		

		DownlinePT = @DownlinePT,		
		@prevtransid = #baP.transid,
			
		statusID = @statusID,
		status = CASE @statusID
			WHEN 0 THEN 'running'
			WHEN 103 THEN 'Refund'
			WHEN 111 THEN 'DRAW'
			WHEN 112 THEN 'WON'
			WHEN 113 THEN 'LOSE'
			END,

		winlostdate = @winlostdate,

		@odds = CASE
				WHEN loseCnt > 0 THEN 0
				WHEN @statusID = 0 THEN 0
				ELSE m.modds
				END,
					
		@commWinRate = CASE [DoubleCommLosing]  -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
		WHEN 0 THEN 1
		WHEN 1 THEN 0 
		ELSE 1 END,   
		@commLostRate = CASE [DoubleCommLosing]
		WHEN 0 THEN 1
		WHEN 1 THEN 2 
		ELSE 1 END,--'s','m'
					
		awinlost = CASE 
			WHEN @statusID = 113 and loseCnt > 0  THEN  stake*apositiontaking
			WHEN @statusID IN (112, 113) THEN -stake*apositiontaking*(@odds-1)
			ELSE 0
			END,

		acomm	= CASE @statusID
				WHEN 112 THEN @commWinRate  * adiscount*stake*(1-@DownlinePT)
				WHEN 113 THEN @commLostRate * adiscount*stake*(1-@DownlinePT)
				ELSE 0 END
				
	FROM #baP INNER JOIN @modds m ON #baP.transid = m.transid
	OPTION (MAXDOP 1) --should use this for quirky update to avoid parallelism problem	
			
	UPDATE T
	SET
		statusID = @statusID,
		status = CASE @statusID
			WHEN 0 THEN 'running'
			WHEN 103 THEN 'Refund'
			WHEN 111 THEN 'DRAW'
			WHEN 112 THEN 'WON'
			WHEN 113 THEN 'LOSE'
			END,
		ruben = CASE @statusID
			WHEN 0 THEN 0
			ELSE 1
			END,
		winlostdate = @winlostdate,
		@odds = T.modds = CASE
			WHEN loseCnt > 0 THEN 0
			WHEN @statusID = 0 THEN 0
			ELSE m.modds
			END,
		
		@commWinRate = CASE [DoubleCommLosing]  -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
		WHEN 0 THEN 1
		WHEN 1 THEN 0 
		ELSE 1 END,   
		@commLostRate = CASE [DoubleCommLosing]
		WHEN 0 THEN 1
		WHEN 1 THEN 2 
		ELSE 1 END,--'s','m'
		
		winlost = CASE
			WHEN loseCnt > 0 THEN 0
			WHEN @statusID = 0 THEN 0
			ELSE stake*@odds
			END,
		
		playercomm	= CASE @statusID 
					WHEN 112 THEN @commWinRate  * stake*playerdiscount
					WHEN 113 THEN @commLostRate * stake*playerdiscount
					ELSE 0 END,	

		[TWinLost] = AgentWinlost.AWinlost,
		[TComm] =  CASE @statusID
				WHEN 112 THEN @commWinRate  * Tdiscount*stake*(1-[TPositionTaking])
				WHEN 113 THEN @commLostRate * Tdiscount*stake*(1-[TPositionTaking])
				ELSE 0 END

	FROM #tmp_bettrans T 
			INNER JOIN @modds m ON T.TransID = m.transid
			INNER JOIN (SELECT TransId, sum(AWinLost) aWinlost
						FROM #baP 
						GROUP BY TransId) AgentWinlost ON T.TransID=AgentWinlost.TransId 
	-------------------------------------------------------------------------------------  

	-- UPDATE BACK TO BETTRANS  

	SET @subStart = CURRENT_TIMESTAMP
		UPDATE b WITH(ROWLOCK,UPDLOCK)
		SET status = s.status ,  
			statusID = s.statusID,
			ruben = s.ruben,
			winlostdate = s.winlostdate,
			modds = s.modds,  
			winlost  = s.winlost,  		
			playercomm = s.playercomm,  
			TWinLost = s.Twinlost,  
			TComm  = s.TComm  		
		FROM dbo.bettrans b 
				INNER JOIN 	#tmp_bettrans s  ON b.transid = s.transid

		UPDATE BetTrans_Agent with (ROWLOCK, UPDLOCK)
		SET 
			winlostdate = #baP.winlostdate,

			aWinLost = #baP.AWinLost,
			aComm = #baP.aComm,			
			Status = #baP.Status,
			StatusID = #baP.StatusId			
		FROM BetTrans_Agent 
				join #baP ON BetTrans_Agent.TransId = #baP.TransId AND BetTrans_Agent.AgentId = #baP.AgentId

	DROP TABLE #tmp_bettrans
	DROP TABLE #baP
	---------------------------------------------------------------  
END

GO

GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_9] TO [vnteam] AS [dbo]
GO


