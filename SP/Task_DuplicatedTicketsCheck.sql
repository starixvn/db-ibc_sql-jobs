Use bodb_report 
Go
ALTER PROCEDURE [dbo].[Task_DuplicatedTicketsCheck]	
AS
/*
Created: 20150211@Sophia
Task : Job run to check duplicate tickets on bettrans table and insert the result into DuplicateTicket table to view report later
DB: DBRPT/bodb_report
Original: Acc_CheckDuplicateTickets

Revisions:
	 - 20151009@Sophia: group by IP [#45176]
Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON	

	DECLARE @TransId BIGINT, @MaxTransId BIGINT

	SELECT @TransId = CONVERT(BIGINT,VValue) FROM bodb02.dbo.SystemSettings WITH (NOLOCK) WHERE VName = 'DuplTicketLastID'
	SELECT @MaxTransId = MAX(TransId) FROM bodb02.dbo.Bettrans WITH (NOLOCK)


 	; WITH AllTicket AS(	 
	SELECT  b.custid, 
			b.odds, 
			b.stake, 
			b.balance, 
			b.bettype,
			b.winlostdate, 
			b.matchid,
			b.ip		 
	FROM	bodb02.dbo.bettrans b WITH(NOLOCK , Index = PK_bettrans)
	WHERE	b.TransID BETWEEN @TransId - 5000 AND @MaxTransId
			AND b.bettype < 19000
			AND b.matchid > 0
			AND b.custid NOT IN (50057, 879241, 103873, 851668, 878902) --betdaq
			AND b.custid NOT IN (1077687) -- Betfair
			AND b.recommend NOT IN (11196380) -- foobet	
			AND b.recommend NOT IN (5707545, 52466) -- exclude members under BARM,8RM
			AND b.currency NOT IN (20, 27, 28)
			AND b.statusID NOT IN (101, 102) 
	)
	SELECT  b.custid, 
			b.odds, 
			b.stake, 
			b.balance, 
			b.bettype,
			b.winlostdate, 
			b.matchid,
			b.ip 		
	INTO	#TempData
	FROM	AllTicket b							
	GROUP BY	b.custid, 
				b.odds, 
				b.stake, 
				b.balance, 
				b.bettype,
				b.winlostdate, 
				b.matchid,
				b.ip
	HAVING COUNT(*) > 1
	 

	--------------------------------------------------------
	INSERT INTO dbo.DuplicatedTicket (transid, transdate, winlostdate)
	SELECT  b.transid, b.transdate, b.winlostdate
	FROM	bodb02.dbo.bettrans b WITH(NOLOCK)
		INNER JOIN #TempData t 
			ON	b.custid = t.custid 
			AND b.odds = t.odds
			AND b.stake = t.stake
			AND ISNULL(b.balance,0) = ISNULL(t.balance,0) 
			AND b.bettype = t.bettype
			AND b.winlostdate = t.winlostdate
			AND b.matchid = t.matchid
			AND b.ip = t.ip
	WHERE NOT EXISTS (SELECT 1 FROM dbo.DuplicatedTicket d WITH (NOLOCK) WHERE d.TransID = b.TransId)	
	DROP TABLE #TempData
	
	
	UPDATE bodb02.dbo.SystemSettings WITH (UPDLOCK, ROWLOCK) 
	SET	   VValue = @MaxTransId
	WHERE  VName = 'DuplTicketLastID'

	
	UPDATE bodb02.dbo.SystemSettings WITH (UPDLOCK, ROWLOCK) 
	SET	   VValue = CURRENT_TIMESTAMP
	WHERE  VName = 'DuplTicketLastDate' 
		
END

GO 

