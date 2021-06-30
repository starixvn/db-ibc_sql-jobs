/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_MBU_Bet_CheckRowCount_Sel]
	@DateCheck SMALLDATETIME,
	@OutputData VARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20180925@Patrick
	Task: Check consistency data for archiving process

	Revisions:
		- 20180926@Patrick:	Initial - [RedmineId: #101207]
		- 20190806@Patrick: Add transfer_bk - [RedmineId: #118277] 
		- 20191030@Billy:	Remove table [BetLucky3Result] - [Redmine: #122987]
		- 20200728@Brice:	Add 13 tables - [Redmine: #111093]
		- 20210628@Helen:	Move checking for TVS tables to another SP Task_MBU_TVS_CheckRowCount_Sel [RedmineId: #157539]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @__tempCount TABLE (rowcnt INT, tableName VARCHAR(128))

	--//sum_winloss
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'sum_winloss' 
	FROM dbo.sum_winloss WITH(NOLOCK) 
	WHERE winlostdate = @DateCheck
	
	--//bettransLC
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettransLC' 
	FROM dbo.bettransLC14 WITH(NOLOCK)
	WHERE winlostdate = @DateCheck
	
	--//bettransRnG
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettransRnG' 
	FROM dbo.bettransRnG14 WITH(NOLOCK) 
	WHERE winlostdate = @DateCheck	

	--//translog
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'translog' 
	FROM dbo.translog14 WITH(NOLOCK)
	WHERE winlostdate = @DateCheck

	--//bettransm
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettransm' 
	FROM dbo.bettransm14 WITH(NOLOCK)
	WHERE winlostdate = @DateCheck

	--//SettlementNG2_Message
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'SettlementNG2_Message' 
	FROM dbo.SettlementNG2_Message WITH(NOLOCK) 
	WHERE eventdate = @DateCheck

	--//staging_NG2
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettrans_Staging' 
	FROM dbo.bettrans_Staging b WITH(NOLOCK) 
		INNER JOIN dbo.SettlementNG2_Message m WITH(NOLOCK) ON b.SeqId = m.SeqID
	WHERE m.EventDate = @DateCheck

	--//bettrans
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettrans' 
	FROM dbo.bettrans14 WITH(NOLOCK) 
	WHERE winlostdate = @DateCheck

	--//transfer
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'transfer'
	FROM dbo.bettrans WITH(NOLOCK, INDEX=CIX_matchid_bettype)
	WHERE ruben = 1 AND matchid = 0 AND bettype > 20000  
		AND winlostdate = @DateCheck AND custid <> 0
		AND (winlost + actual_stake) <> 0

	/*
	---------------------------------20200728@Brice:	Add 13 tables - [Redmine: #111093]--------------------------------------
	--//TicketVoiding_VoidedTransaction
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_VoidedTransaction'
	FROM dbo.TicketVoiding_VoidedTransaction AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.bettrans14 AS t2 WITH (NOLOCK) join dbo.SportBettypeMatrix t3 WITH (NOLOCK) ON t2.bettype=t3.BetType
						WHERE tbl.transid = t2.transid AND t3.ProductID IN (1,3,5,25,27,37) AND t2.statusID=102 AND t2.winlostdate = @DateCheck)
			OR EXISTS (SELECT 1 FROM dbo.bettrans14 AS t2 WITH (NOLOCK) join dbo.SportBettypeMatrix t3 WITH (NOLOCK) ON t2.bettype=t3.BetType AND t3.bettype != 29
						WHERE tbl.transid = t2.refno AND t3.ProductID =1 AND t2.statusID=102 AND t2.winlostdate = @DateCheck)
			OR EXISTS (SELECT 1 FROM dbo.bettrans14 AS t2 WITH (NOLOCK) join dbo.bettransm14 t4 WITH (NOLOCK) on t2.refno=t4.refno
					WHERE tbl.transid = t2.transid AND t2.bettype in (29,2799) AND tbl.MatchId!=0 AND tbl.MatchId=t4.MatchId AND t4.statusID=102 AND t2.winlostdate = @DateCheck);
	--//TicketVoiding_Reason
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_Reason'
	FROM dbo.TicketVoiding_Reason AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.TicketVoiding_VoidingHistory AS t2 WITH (NOLOCK) CROSS JOIN dbo.TicketVoiding_RequestDetail AS t3 WITH (NOLOCK) CROSS JOIN dbo.match14 t4 WITH(NOLOCK) WHERE tbl.ReasonId=t2.ReasonId and t2.RequestId = t3.RequestId AND t3.matchid = t4.matchid AND t4.eventdate = @DateCheck);
	
	--//TicketVoiding_VoidingHistory
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_VoidingHistory'
	FROM dbo.TicketVoiding_VoidingHistory AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.TicketVoiding_RequestDetail AS t3 WITH (NOLOCK) CROSS JOIN dbo.match14 t4 WITH(NOLOCK) WHERE tbl.RequestId = t3.RequestId AND t3.matchid = t4.matchid AND t4.eventdate = @DateCheck);
	
	--//TicketVoiding_Queue
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_Queue'
	FROM dbo.TicketVoiding_Queue AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.TicketVoiding_RequestDetail AS t3 WITH (NOLOCK) CROSS JOIN dbo.match14 t4 WITH(NOLOCK) WHERE tbl.RequestId = t3.RequestId AND t3.matchid = t4.matchid AND t4.eventdate = @DateCheck);
	
	--//TicketVoiding_OperatorInfo
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_OperatorInfo'
	FROM dbo.TicketVoiding_OperatorInfo AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.TicketVoiding_RequestDetail AS t3 WITH (NOLOCK) CROSS JOIN dbo.match14 t4 WITH(NOLOCK) WHERE tbl.RequestId = t3.RequestId AND t3.matchid = t4.matchid AND t4.eventdate = @DateCheck);
	
	--//TicketVoiding_Request
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_Request'
	FROM dbo.TicketVoiding_Request AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.TicketVoiding_RequestDetail AS t3 WITH (NOLOCK) CROSS JOIN dbo.match14 t4 WITH(NOLOCK) WHERE tbl.RequestId = t3.RequestId AND t3.matchid = t4.matchid AND t4.eventdate = @DateCheck);
	
	--//TicketVoiding_AutoUnmarkSetting
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_AutoUnmarkSetting'
	FROM dbo.TicketVoiding_AutoUnmarkSetting AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 t4 WITH(NOLOCK) WHERE tbl.matchid = t4.matchid AND t4.eventdate = @DateCheck);
	
	--//TicketVoiding_AutoVoidRequest_Queue
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_AutoVoidRequest_Queue'
	FROM dbo.TicketVoiding_AutoVoidRequest_Queue AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 t4 WITH(NOLOCK) WHERE tbl.matchid = t4.matchid AND t4.eventdate = @DateCheck);
	
	--//zzzbettrans
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'zzzbettrans'
	FROM dbo.zzzbettrans AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.bettrans14 AS t2 WITH (NOLOCK) join dbo.SportBettypeMatrix t3 WITH (NOLOCK) ON t2.bettype=t3.BetType
					WHERE tbl.transid = t2.transid AND t3.ProductID IN (1,3,5,25,27,37) AND t2.statusID=102 AND t2.winlostdate = @DateCheck)
		OR EXISTS (SELECT 1 FROM dbo.bettransm14 AS t2 WITH (NOLOCK) join dbo.SportBettypeMatrix t3 WITH (NOLOCK) ON t2.bettype=t3.BetType
					WHERE tbl.transid = t2.transid AND t3.ProductID IN (1,27) AND t2.statusID=102 AND t2.winlostdate = @DateCheck);	
	
	--//zzzbettransM
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'zzzbettransM'
	FROM dbo.zzzbettransM AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.bettransm14 AS t2 WITH (NOLOCK) join dbo.SportBettypeMatrix t3 WITH (NOLOCK) ON t2.bettype=t3.BetType
					WHERE tbl.transid = t2.transid AND t3.ProductID IN (1,27) AND t2.statusID=102 AND t2.winlostdate = @DateCheck);
	
	--//TicketVoiding_RequestDetail
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_RequestDetail'
	FROM dbo.TicketVoiding_RequestDetail AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 t4 WITH(NOLOCK) WHERE tbl.matchid = t4.matchid AND t4.eventdate = @DateCheck);
	
	--//TicketVoiding_RequestDetailTicket_Single
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_RequestDetailTicket_Single'
	FROM dbo.TicketVoiding_RequestDetailTicket_Single AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.TicketVoiding_RequestDetail AS t3 WITH (NOLOCK) CROSS JOIN dbo.match14 t4 WITH(NOLOCK) WHERE tbl.RequestId = t3.RequestId AND t3.matchid = t4.matchid AND t4.eventdate = @DateCheck);
	
	--//TicketVoiding_RequestDetailTicket_SubParlay
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_RequestDetailTicket_SubParlay'
	FROM dbo.TicketVoiding_RequestDetailTicket_SubParlay AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.TicketVoiding_RequestDetail AS t3 WITH (NOLOCK) CROSS JOIN dbo.match14 t4 WITH(NOLOCK) WHERE tbl.RequestId = t3.RequestId AND t3.matchid = t4.matchid AND t4.eventdate = @DateCheck);
	
	*/
	---------------------------------/20200728@Brice:	Add 11 tables - [Redmine: #111093]--------------------------------------
	--//
	SELECT @OutputData = (
		SELECT rowcnt AS r, tableName AS t
		FROM @__tempCount
		FOR XML RAW ('r')
	)

END
GO
