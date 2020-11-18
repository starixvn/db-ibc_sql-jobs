
    
    SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_Copy_oldData
						@winlostdate		DATETIME
					,	@TableName			NVARCHAR(128)	= ''
AS
/*
	Created:	20200720@Brice
	Task:		Archive on DBARC - [Redmine: #111093]
	Database:	DBARC.bodb_Archive

	Revisions:
		- 20200720@Brice:	Initialize [Redmine: #111093]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE	@Query		NVARCHAR(MAX)
		;

	---------------Table 1: TicketVoiding_RequestDetail_bk --------------------
	IF	@TableName = N'TicketVoiding_RequestDetail_bk'
	BEGIN;
		INSERT INTO	dbo.TicketVoiding_RequestDetail_bk
			(  Id, RequestId, MatchId, LeagueId, HomeId, AwayId, KickOffTime, LiveAwayScore, TransIds, RequestType)
		SELECT	Id, RequestId, MatchId, LeagueId, HomeId, AwayId, KickOffTime, LiveHomeScore, LiveAwayScore, IssueDetail, TransIds, RequestType
		FROM	bodb02.dbo.TicketVoiding_RequestDetail AS t1 WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM ##match_bk AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid);

	END;


	---------------Table 2: zzzbettransM_bk --------------------
	ELSE IF	@TableName = N'zzzbettransM_bk'
	BEGIN;

		INSERT INTO	dbo.zzzbettransM_bk
			(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, STATUS, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, VoidingHistoryId)
		SELECT	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, STATUS, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, VoidingHistoryId
		FROM	bodb02.dbo.zzzbettransM AS t1 WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM ##bettransm_bk AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid);
	END;


	---------------Table 3: zzzbettrans_bk --------------------
	ELSE IF	@TableName = N'zzzbettrans_bk'
	BEGIN;
		INSERT INTO	dbo.zzzbettrans_bk
			(	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, STATUS, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, VoidingHistoryId)
		SELECT	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, STATUS, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, VoidingHistoryId
		FROM	bodb02.dbo.zzzbettrans AS t1 WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM ##bettrans_bk AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid)
				OR EXISTS (SELECT 1 FROM ##bettransm_bk AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid);

	END;


	---------------Table 4: TicketVoiding_AutoVoidRequest_Queue_bk --------------------
	ELSE IF	@TableName = N'TicketVoiding_AutoVoidRequest_Queue_bk'
	BEGIN;
		INSERT INTO	dbo.TicketVoiding_AutoVoidRequest_Queue_bk
			(	QueueId, RequestId, MatchId, [Action], StatusId, UserId, Starttime, Exectime, Duration, IP, ErrMsg, sporttype)

		SELECT	QueueId, RequestId, MatchId, [Action], StatusId, UserId, Starttime, Exectime, Duration, IP, ErrMsg, sporttype
		FROM	bodb02.dbo.TicketVoiding_AutoVoidRequest_Queue AS t1 WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM ##match_bk AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid);

	END;

	---------------Table 5: TicketVoiding_AutoUnmarkSetting_bk --------------------
	ELSE IF	@TableName = N'TicketVoiding_AutoUnmarkSetting_bk'
	BEGIN;
		INSERT INTO	dbo.TicketVoiding_AutoUnmarkSetting_bk
			(	ID, Matchid, Bettype, IsConfirm, CreatedDate, UserId, MarkedBy, betid)

		SELECT	ID, Matchid, Bettype, IsConfirm, CreatedDate, UserId, MarkedBy, betid
		FROM	bodb02.dbo.TicketVoiding_AutoUnmarkSetting AS t1 WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM ##match_bk AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid);
	END;

	---------------Table 6: TicketVoiding_Request_bk -----------------------------
	-- Need confirm: No sync column [SettlementStatus]?
	ELSE IF	@TableName = N'TicketVoiding_Request_bk'
	BEGIN;
		INSERT INTO	dbo.TicketVoiding_Request_bk
			(	RequestId, Sporttype, SubIssueTypeId, ActionId, Provider, Source, DecidedBy, MistakenBy, Remark, CheckedBy, UserId, CreatedDate, LastModifiedBy, LastModifiedDate, IssueTypeId, IsTest)

		SELECT	RequestId, Sporttype, SubIssueTypeId, ActionId, Provider, Source, DecidedBy, MistakenBy, Remark, CheckedBy, UserId, CreatedDate, LastModifiedBy, LastModifiedDate, IssueTypeId, IsTest
		FROM	bodb02.dbo.TicketVoiding_Request AS t1 WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.TicketVoiding_RequestDetail AS t2 WITH (NOLOCK) CROSS JOIN ##match_bk t3 WITH(NOLOCK) WHERE t1.RequestId = t2.RequestId AND t2.matchid = t3.matchid);

	END;


	---------------Table 7: TicketVoiding_OperatorInfo_bk -----------------------------
	ELSE IF	@TableName = N'TicketVoiding_OperatorInfo_bk'
	BEGIN;
		INSERT INTO	dbo.TicketVoiding_OperatorInfo_bk
			(	 RequestId, OperatorId, OperatorTypeId, Id)
		SELECT	RequestId, OperatorId, OperatorTypeId, Id
		FROM	bodb02.dbo.TicketVoiding_OperatorInfo AS t1 WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.TicketVoiding_RequestDetail AS t2 WITH (NOLOCK) CROSS JOIN ##match_bk t3 WITH(NOLOCK) WHERE t1.RequestId = t2.RequestId AND t2.matchid = t3.matchid);
	END;


	---------------Table 8:  TicketVoiding_Queue_bk -----------------------------
	ELSE IF	@TableName = N'TicketVoiding_Queue_bk'
	BEGIN;
		INSERT INTO	dbo.TicketVoiding_Queue_bk
			(	QueueId, RequestId, MatchId, VoidingHistoryId, TransIds, StatusId, UserId, Starttime, Exectime, Duration, IP, VoidingTypeId, TotalTicket, ErrMsg, FailedTransIds, NegativeBalanceUsers)
		SELECT	QueueId, RequestId, MatchId, VoidingHistoryId, TransIds, StatusId, UserId, Starttime, Exectime, Duration, IP, VoidingTypeId, TotalTicket, ErrMsg, FailedTransIds, NegativeBalanceUsers
		FROM	bodb02.dbo.TicketVoiding_Queue AS t1 WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.TicketVoiding_RequestDetail AS t2 WITH (NOLOCK) CROSS JOIN ##match_bk t3 WITH(NOLOCK) WHERE t1.RequestId = t2.RequestId AND t2.matchid = t3.matchid);

	END;


	---------------Table 9:  TicketVoiding_VoidingHistory_bk -----------------------------
	ELSE IF	@TableName = N'TicketVoiding_VoidingHistory_bk'
	BEGIN;
		INSERT INTO	dbo.TicketVoiding_VoidingHistory_bk
			(	VoidingHistoryId, RequestId, MessageId, StatusId, ReasonId, UserId, CreatedDate, ModifiedDate, TransIds)
		SELECT	VoidingHistoryId, RequestId, MessageId, StatusId, ReasonId, UserId, CreatedDate, ModifiedDate, TransIds
		FROM	bodb02.dbo.TicketVoiding_VoidingHistory AS t1 WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.TicketVoiding_RequestDetail AS t2 WITH (NOLOCK) CROSS JOIN ##match_bk t3 WITH(NOLOCK) WHERE t1.RequestId = t2.RequestId AND t2.matchid = t3.matchid);

	END;


	---------------Table 10:  TicketVoiding_Reason_bk -----------------------------
	ELSE IF	@TableName = N'TicketVoiding_Reason_bk'
	BEGIN;
		INSERT INTO	dbo.TicketVoiding_Reason_bk
			(	ReasonId, ReasonEnglish, ReasonChineseSimplified)
		VALUES (6015,'Soccer - Abnormal bet','足球 - 非正常投注'),(6016,'Soccer - Danger Accept In Red Card','足球 - 有红牌的危险时段中误被接受')
	
		INSERT INTO	dbo.TicketVoiding_Reason_bk
			(	ReasonId, ReasonEnglish, ReasonChineseSimplified)
		SELECT	ReasonId, ReasonEnglish, ReasonChineseSimplified
		FROM	bodb02.dbo.TicketVoiding_Reason AS t1 WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.TicketVoiding_VoidingHistory AS t2 WITH (NOLOCK) CROSS JOIN bodb02.dbo.TicketVoiding_RequestDetail AS t3 WITH (NOLOCK) CROSS JOIN ##match_bk t4 WITH(NOLOCK) WHERE t1.ReasonId=t2.ReasonId and t2.RequestId = t3.RequestId AND t3.matchid = t4.matchid);
	END;


	---------------Table 11:  TicketVoiding_VoidedTransaction_bk -----------------------------
	ELSE IF	@TableName = N'TicketVoiding_VoidedTransaction_bk'
	BEGIN;
	
		INSERT INTO	dbo.TicketVoiding_VoidedTransaction_bk
			(	TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID)
		select TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID
		FROM	dbtrans.bodb02.dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK) where createdDate <'2020-01-01'
		except
		select TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID
		FROM	bodb02.dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK) where createdDate <'2020-01-01'		
	
		--process for ticket single and main parlay and metrix gaming
		INSERT INTO	dbo.TicketVoiding_VoidedTransaction_bk
			(	TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID)
		SELECT	TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID
		FROM	bodb02.dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM ##bettrans_bk AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid)
				OR EXISTS (SELECT 1 FROM ##bettrans_bk2 AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid);
		
		--process for ticket sub parlay (sportbook and virtual sport)
		INSERT INTO	dbo.TicketVoiding_VoidedTransaction_bk
			(	TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID)
		SELECT	TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID
		FROM	bodb02.dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM ##bettrans_bk3 AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid);
	END;

	
	---------------Table 12:  TicketVoiding_RequestDetailTicket_Single_bk -----------------------------
	ELSE IF	@TableName = N'TicketVoiding_RequestDetailTicket_Single_bk'
	BEGIN;
		INSERT INTO	dbo.TicketVoiding_RequestDetailTicket_Single_bk
			(	Id, RequestId, IssueTypeId, SubIssueTypeId,TransId, MatchId)
		SELECT	Id, RequestId, IssueTypeId, SubIssueTypeId,TransId, MatchId
		FROM	bodb02.dbo.TicketVoiding_RequestDetailTicket_Single AS t1 WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.TicketVoiding_RequestDetail AS t2 WITH (NOLOCK) CROSS JOIN ##match_bk t3 WITH(NOLOCK) WHERE t1.RequestId = t2.RequestId AND t2.matchid = t3.matchid);
	END;
	
	
	---------------Table 13: TicketVoiding_RequestDetailTicket_SubParlay_bk -----------------------------
	ELSE IF	@TableName = N'TicketVoiding_RequestDetailTicket_SubParlay_bk'
	BEGIN;
		INSERT INTO	dbo.TicketVoiding_RequestDetailTicket_SubParlay_bk
			(	Id, RequestId, IssueTypeId, SubIssueTypeId,TransId, MatchId)
		SELECT	Id, RequestId, IssueTypeId, SubIssueTypeId,TransId, MatchId
		FROM	bodb02.dbo.TicketVoiding_RequestDetailTicket_SubParlay AS t1 WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.TicketVoiding_RequestDetail AS t2 WITH (NOLOCK) CROSS JOIN ##match_bk t3 WITH(NOLOCK) WHERE t1.RequestId = t2.RequestId AND t2.matchid = t3.matchid);
	END;
END
GO

    
