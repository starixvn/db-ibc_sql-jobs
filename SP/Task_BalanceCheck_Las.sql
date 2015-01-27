USE [LASDB]
GO

/****** Object:  StoredProcedure [dbo].[Task_BalanceCheck_Las]    Script Date: 01/26/2015 22:49:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Task_BalanceCheck_Las]
	@winlostdate	DATE
	,@InitStepNo	TINYINT = 1
AS
/*
Created		: 20140316@Don
Task		: ?
DB			: DBLAS.lasdb

Revisions:
		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @BALANCE_BETTYPE SMALLINT = 20000

	DECLARE @memberSUM money,  @memberAmount money,
			@agentSUM money,  @agentAmount money

	SELECT	@memberSUM = SUM (winlost - actual_stake + playercomm),
			@memberAmount = SUM((winlost - actual_stake + playercomm) * e.actualrate)
	FROM  dbo.bettrans WITH(NOLOCK)
		INNER JOIN bodb02.dbo.exchange e WITH(NOLOCK) ON bettrans.currency = e.exchangeid
	WHERE ruben=1 AND winlostdate <= @winlostdate

	-- Get list of agent with information about direct parent
	;WITH cte_agentk AS (
		SELECT a.AgentId, a.AgentHId.GetAncestor(1) ParentHId
		FROM dbo.AgentInfo a WITH(NOLOCK) 
		WHERE a.AgentLevel > 1
	)
	SELECT cte_agentk.AgentId, agentinfo.AgentId ParentID
	INTO #agent
	FROM cte_agentk 
		INNER JOIN dbo.AgentInfo WITH(NOLOCK) ON cte_agentk.ParentHId = AgentInfo.AgentHId

	SELECT	@agentSUM = SUM(agentSUM)
			,@agentAmount = SUM(agentAmount) 
	FROM
		(
		-- get winlost for direct child agent
		SELECT	SUM(BP.AWinlost + BP.AComm  - BA.AComm) agentSUM,
				SUM((BP.AWinlost + BP.AComm  - BA.AComm) * e.actualrate)  agentAmount
		--FROM dbo.BetTrans_Agent BP  WITH(ROWLOCK, INDEX = IX_WinlostDate_StatusId_Bettype) 		
		FROM dbo.BetTrans_Agent BP  WITH(ROWLOCK)
			--INNER JOIN dbo.AgentInfo A WITH(NOLOCK) ON A.ParentID = BP.AgentId
			INNER JOIN dbo.#agent A WITH(NOLOCK) ON A.ParentID = BP.AgentId
			INNER JOIN dbo.BetTrans_Agent BA WITH(ROWLOCK) ON A.AgentId = BA.AgentId AND BP.TransId = BA.TransId										
			INNER JOIN bodb02.dbo.exchange e WITH(NOLOCK) ON BP.currency = e.exchangeid
		WHERE	BP.Winlostdate <= @winlostdate		
				AND BP.STatusID NOT IN (0,1)	
				AND BP.BETTYPE < @BALANCE_BETTYPE
				AND BA.Winlostdate <= @winlostdate	
				AND BA.STatusID NOT IN (0,1)	 				
				AND BA.BETTYPE < @BALANCE_BETTYPE
		GROUP BY BP.AgentId 
		UNION ALL				
		-- get winlost for direct member
		SELECT	SUM(BP.AWinlost + BP.AComm  - B.PlayerComm) Amount,
				SUM((BP.AWinlost + BP.AComm  - B.PlayerComm) * e.actualrate) agentAmount
		FROM dbo.BetTrans_Agent BP  WITH(ROWLOCK) 
			INNER JOIN dbo.bettrans B WITH(ROWLOCK) ON B.TransId = BP.TransId	
		/*FROM dbo.BetTrans_Agent BP  WITH(ROWLOCK, INDEX = IX_WinlostDate_StatusId_Bettype) 
			INNER JOIN dbo.bettrans B WITH(ROWLOCK, INDEX = IX_WinlostDate_StatusId_Bettype) ON B.TransId = BP.TransId	*/
			INNER JOIN dbo.CustInfo c WITH(NOLOCK) ON c.AgentId = BP.AgentId AND c.CustId = b.CustId
			INNER JOIN bodb02.dbo.exchange e WITH(NOLOCK) ON BP.currency = e.exchangeid
		WHERE	BP.Winlostdate <= @winlostdate	
				AND BP.STatusID NOT IN (0,1)					 							
				AND B.Winlostdate <= @winlostdate
				AND B.STatusID NOT IN (0,1)						
		GROUP BY BP.AgentId 		
		UNION ALL
		-- for balance record
		SELECT	SUM(BP.AWinlost) Amount,
				SUM(BP.AWinlost * e.actualrate) agentAmount
			--FROM dbo.BetTrans_Agent BP  WITH(ROWLOCK, INDEX = IX_WinlostDate_StatusId_Bettype) 			
			FROM dbo.BetTrans_Agent BP  WITH(ROWLOCK) 
				INNER JOIN bodb02.dbo.exchange e WITH(NOLOCK) ON BP.currency = e.exchangeid
			WHERE	BP.Winlostdate <= @winlostdate	
					AND BP.STatusID NOT IN (0,1)	
					AND BP.bettype = @BALANCE_BETTYPE  --BALANCE 								
			GROUP BY BP.AgentId 	
		) T

	INSERT INTO dbo.Task_BalanceRecord (step, winlostdate, SPCode, TotalAmt, TotalSum)
		SELECT @InitStepNo, @winlostdate, 0,
			(isnull(@memberAmount,0) + isnull(@agentAmount,0)) totalamt,
			(isnull(@memberSUM ,0)+ isnull(@agentSUM,0)) TotalSUM

	DROP TABLE #agent
END




GO

GRANT VIEW DEFINITION ON [dbo].[Task_BalanceCheck_Las] TO [vnteam] AS [dbo]
GO


