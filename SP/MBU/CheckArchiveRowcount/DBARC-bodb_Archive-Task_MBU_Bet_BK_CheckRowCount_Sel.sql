/*<info serverAlias="DBARC-bodb_Archive" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_MBU_Bet_BK_CheckRowCount_Sel]
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
		- 20210628@Helen:	Move checking for TVS tables to another SP Task_MBU_TVS_BK_CheckRowCount_Sel [RedmineId: #157539]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @__tempCount TABLE (rowcnt INT, tableName VARCHAR(128))

	DECLARE @__winlostdate SMALLDATETIME
	SET @__winlostdate = @DateCheck

	--//sum_winloss
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'sum_winloss' 
	FROM DBAGE.bodb_Summary.dbo.sum_winloss_old WITH(NOLOCK) 
	WHERE winlostdate = @__winlostdate

	--//bettransLC
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettransLC' 
	FROM dbo.bettransLC_bk WITH(NOLOCK)
	WHERE winlostdate = @__winlostdate

	--//bettransRnG
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettransRnG' 
	FROM dbo.bettransRnG_bk WITH(NOLOCK) 
	WHERE winlostdate = @__winlostdate

	--//translog
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'translog' 
	FROM dbo.translog_BK WITH(NOLOCK)
	WHERE winlostdate = @__winlostdate

	--//bettransm
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettransm' 
	FROM dbo.bettransm WITH(NOLOCK)
	WHERE winlostdate = @__winlostdate

	--//SettlementNG2_Message
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'SettlementNG2_Message' 
	FROM dbo.SettlementNG2_Message_bk WITH(NOLOCK) 
	WHERE eventdate = @__winlostdate

	--//staging_NG2
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettrans_Staging' 
	FROM dbo.bettrans_Staging_bk b WITH(NOLOCK) 
		INNER JOIN dbo.SettlementNG2_Message_bk m WITH(NOLOCK) ON b.SeqId = m.SeqID
	WHERE m.EventDate = @__winlostdate

	--//bettrans
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettrans' 
	FROM dbo.bettrans_bk WITH(NOLOCK) 
	WHERE winlostdate = @__winlostdate

	--//transfer
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'transfer'
	FROM dbo.transfer_bk WITH(NOLOCK)
	WHERE winlostdate = @__winlostdate
	
	/*
	---------------------------------20200728@Brice:	Add 13 tables - [Redmine: #111093]--------------------------------------
	DECLARE @tbl01 TABLE(refno BIGINT)
	INSERT INTO @tbl01(refno)
	SELECT refno
	FROM dbo.bettrans_bk AS t2 WITH (NOLOCK)
		INNER JOIN bodb02.dbo.SportBettypeMatrix t3 WITH (NOLOCK) ON t2.bettype=t3.BetType AND t3.bettype != 29
	WHERE t2.statusID=102 AND t2.winlostdate = @__winlostdate AND t3.ProductID =1 and t2.refno !=100000000000

	--//TicketVoiding_VoidedTransaction
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_VoidedTransaction'
	FROM dbo.TicketVoiding_VoidedTransaction_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.bettrans_bk AS t2 WITH (NOLOCK) join bodb02.dbo.SportBettypeMatrix t3 WITH (NOLOCK) ON t2.bettype=t3.BetType
						WHERE tbl.transid = t2.transid AND t3.ProductID IN (1,3,5,25,27,37) AND t2.statusID=102 AND t2.winlostdate = @__winlostdate)
			OR EXISTS (SELECT 1 FROM @tbl01 t2 WHERE tbl.TransId = t2.refno)
			OR EXISTS (SELECT 1 FROM dbo.bettrans_bk AS t2 WITH (NOLOCK) join dbo.bettransm t4 WITH (NOLOCK) on t2.refno=t4.refno
					WHERE tbl.transid = t2.transid AND t2.bettype in (29,2799) AND tbl.MatchId!=0 AND tbl.MatchId=t4.MatchId AND t4.statusID=102 AND t2.winlostdate = @__winlostdate)
	
	--//TicketVoiding_Reason
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_Reason'
	FROM dbo.TicketVoiding_Reason_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.TicketVoiding_VoidingHistory_bk AS t2 WITH (NOLOCK) CROSS JOIN dbo.TicketVoiding_RequestDetail_bk AS t3 WITH (NOLOCK) CROSS JOIN dbo.match_bk t4 WITH(NOLOCK) WHERE tbl.ReasonId=t2.ReasonId and t2.RequestId = t3.RequestId AND t3.matchid = t4.matchid AND t4.eventdate = @__winlostdate);
	
	--//TicketVoiding_VoidingHistory
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_VoidingHistory'
	FROM dbo.TicketVoiding_VoidingHistory_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.TicketVoiding_RequestDetail_bk AS t3 WITH (NOLOCK) CROSS JOIN dbo.match_bk t4 WITH(NOLOCK) WHERE tbl.RequestId = t3.RequestId AND t3.matchid = t4.matchid AND t4.eventdate = @__winlostdate);
	
	--//TicketVoiding_Queue
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_Queue'
	FROM dbo.TicketVoiding_Queue_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.TicketVoiding_RequestDetail_bk AS t3 WITH (NOLOCK) CROSS JOIN dbo.match_bk t4 WITH(NOLOCK) WHERE tbl.RequestId = t3.RequestId AND t3.matchid = t4.matchid AND t4.eventdate = @__winlostdate);
	
	--//TicketVoiding_OperatorInfo
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_OperatorInfo'
	FROM dbo.TicketVoiding_OperatorInfo_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.TicketVoiding_RequestDetail_bk AS t3 WITH (NOLOCK) CROSS JOIN dbo.match_bk t4 WITH(NOLOCK) WHERE tbl.RequestId = t3.RequestId AND t3.matchid = t4.matchid AND t4.eventdate = @__winlostdate);
	
	--//TicketVoiding_Request
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_Request'
	FROM dbo.TicketVoiding_Request_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.TicketVoiding_RequestDetail_bk AS t3 WITH (NOLOCK) CROSS JOIN dbo.match_bk t4 WITH(NOLOCK) WHERE tbl.RequestId = t3.RequestId AND t3.matchid = t4.matchid AND t4.eventdate = @__winlostdate);
	
	--//TicketVoiding_AutoUnmarkSetting
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_AutoUnmarkSetting'
	FROM dbo.TicketVoiding_AutoUnmarkSetting_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match_bk t4 WITH(NOLOCK) WHERE tbl.matchid = t4.matchid AND t4.eventdate = @__winlostdate);
	
	--//TicketVoiding_AutoVoidRequest_Queue
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_AutoVoidRequest_Queue'
	FROM dbo.TicketVoiding_AutoVoidRequest_Queue_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match_bk t4 WITH(NOLOCK) WHERE tbl.matchid = t4.matchid AND t4.eventdate = @__winlostdate);
	
	--//zzzbettrans
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'zzzbettrans'
	FROM dbo.zzzbettrans_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.bettrans_bk AS t2 WITH (NOLOCK) join bodb02.dbo.SportBettypeMatrix t3 WITH (NOLOCK) ON t2.bettype=t3.BetType
					WHERE tbl.transid = t2.transid AND t3.ProductID IN (1,3,5,25,27,37) AND t2.statusID=102 AND t2.winlostdate = @__winlostdate)
		OR EXISTS (SELECT 1 FROM dbo.bettransm AS t2 WITH (NOLOCK) WHERE tbl.transid = t2.transid AND t2.statusID=102 AND t2.winlostdate = @__winlostdate);	
	--//zzzbettransM
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'zzzbettransM'
	FROM dbo.zzzbettransM_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.bettransm AS t2 WITH (NOLOCK) WHERE tbl.transid = t2.transid AND t2.statusID=102 AND t2.winlostdate = @__winlostdate);	
		
	--//TicketVoiding_RequestDetail
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_RequestDetail'
	FROM dbo.TicketVoiding_RequestDetail_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match_bk t4 WITH(NOLOCK) WHERE tbl.matchid = t4.matchid AND t4.eventdate = @__winlostdate);
	
	--//TicketVoiding_RequestDetailTicket_Single
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_RequestDetailTicket_Single'
	FROM dbo.TicketVoiding_RequestDetailTicket_Single_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.TicketVoiding_RequestDetail_bk AS t3 WITH (NOLOCK) CROSS JOIN dbo.match_bk t4 WITH(NOLOCK) WHERE tbl.RequestId = t3.RequestId AND t3.matchid = t4.matchid AND t4.eventdate = @__winlostdate);
	
	--//TicketVoiding_RequestDetailTicket_SubParlay
	INSERT INTO @__tempCount(rowcnt, tableName)
	select COUNT(1), 'TicketVoiding_RequestDetailTicket_SubParlay'
	FROM dbo.TicketVoiding_RequestDetailTicket_SubParlay_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.TicketVoiding_RequestDetail_bk AS t3 WITH (NOLOCK) CROSS JOIN dbo.match_bk t4 WITH(NOLOCK) WHERE tbl.RequestId = t3.RequestId AND t3.matchid = t4.matchid AND t4.eventdate = @__winlostdate);
	---------------------------------/20200728@Brice:	Add 11 tables - [Redmine: #111093]--------------------------------------
	*/
	--//
	SELECT @OutputData = (
		SELECT rowcnt AS r, tableName AS t
		FROM @__tempCount
		FOR XML RAW ('r')
	)

END

GO
