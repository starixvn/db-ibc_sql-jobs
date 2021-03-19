SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE [dbo].[ExecRep_02]
	@tmp1 sql_variant = NULL,
	@tmp2 sql_variant = NULL,
	@tmp3 sql_variant = NULL,
	@winlostdate datetime = NULL,
	@Command varchar(20) = NULL,
	@deletedTarget varchar(50) = NULL,
	@transIds VARCHAR(MAX) = NULL,
	@rowcount INT = 0 OUTPUT
AS
/*
	Created by:[]
	Date:
	Task: call from Joe : ClearData14 working routine
	DB: DBTXN.BODB02
	Revisions:
		- 20151012@Sophia:	Add delete BettransLC14 and BettransRNG14
		- 20160526@Victor:	Add delete TransLog14
		- 20170725@Sophia:	Change Datatype of TransID [Redmine: #73545]
		- 20170914@Patrick:	Integrate with Lucky3 [RedmineId: #83190]
		- 20171004@Lukas:	Add @deletedTarget for deleting data for one by one table
		- 20180725@Billy:	Change the way of deleting data (except [bettransm14]) - [Redmine: #98857]
		- 20181106@Sophia:	Add delete Transfer_Coll [Redmine: #98621]
		- 20190704@Billy:	Add [MarkedTransaction] to Friday Routine - [Redmine: #115199]
		- 20190828@Billy:	Add table [bettransInfo] to Friday Routine - [Redmine: #119219]
		- 20191030@Billy:	Remove table [BetLucky3Result] from Friday Routine - [Redmine: #122987]
		- 20191126@Patrick: Add more conndition remove data on DB054/DB055 - [Redmine: #124104]
		- 20200227@Patrick: Implement remove data of Intg_GameRoundBetStake after BU day - 1 [Redmine: #126981]
		- 20201119@Brice: Enhance MBU process related to removing data on bettransm14 [Redmine: #143763]
		- 20210225@Max: [TVS] Remove archived data [Redmine: #150524]
*/
-- =======================
-- Parameter check\control
-- =======================
BEGIN 

	SET NOCOUNT ON

	-- 20190828@Billy: Temp variable table for deleting [bettransInfo14]
	DECLARE	@__tmpTransId AS TABLE (
				id		BIGINT		PRIMARY KEY CLUSTERED
			);

	DECLARE @xml XML
	DECLARE @MarkedTrans TABLE (TransId BIGINT, MatchId INT)
	
	IF @Command IS NULL OR @winlostdate IS NULL
	BEGIN
		PRINT 'Invalid input parameters'
		RETURN
	END

	IF CONVERT(varchar(10), @winlostdate, 120) <> @winlostdate
	BEGIN
		PRINT 'Invalid input parameters'
		RETURN
	END

	IF -- below is ACCEPTED case
	(
		(@Command = 'ALL_DB') -- delete on all server
		OR
		(@Command = 'Except_DBTRANS' AND @@ServerName <> 'DBTRANS') 
	)
	BEGIN

		DECLARE @rc INT, @rn INT, @rn2 INT

		IF	@deletedTarget = 'bettrans14' --- delete bettrans14
		BEGIN
			SET @rowcount = 0

			-- if specific command come, do it and quit
			IF CONVERT(varchar(50), @tmp1) = 'Delete bettrans14 by custid range'
			BEGIN
				DELETE	@__tmpTransId;

				DELETE	B14
				OUTPUT	Deleted.transid
				INTO	@__tmpTransId (id)
				FROM	dbo.bettrans14 AS B14 WITH (ROWLOCK)
				WHERE	winlostdate = @winlostdate
					AND	custid BETWEEN CAST(@tmp2 AS int) AND CAST(@tmp3 AS int)

				-- 20190828@Billy: Add [bettransInfo] table
				DELETE	tbl
				FROM		@__tmpTransId AS tmp
				INNER JOIN	dbo.BettransInfo14 AS tbl WITH (ROWLOCK)
						ON	tmp.id = tbl.transid;

				RETURN
			END

			DELETE	@__tmpTransId;

			DELETE	TOP(2500) B14
			OUTPUT	Deleted.transid
			INTO	@__tmpTransId (id)
			FROM	dbo.bettrans14 AS B14 WITH (ROWLOCK, INDEX = IX_bettrans14)
			WHERE	winlostdate = @winlostdate;

			SET @rowcount = @@ROWCOUNT;

			-- 20190828@Billy: Add [bettransInfo] table
			DELETE	tbl
			FROM		@__tmpTransId AS tmp
			INNER JOIN	dbo.BettransInfo14 AS tbl WITH (ROWLOCK)
					ON	tmp.id = tbl.transid;

			RETURN
		END --- end of deleting bettrans14

		IF @deletedTarget = 'bettransm14' --deleting bettransm14
        BEGIN
			IF @transIds IS NOT NULL 
			BEGIN
				DELETE FROM @__tmpTransId
				SELECT @rowcount = 0;

				DECLARE @xmlData XML
				SET @xmlData = CONVERT(XML, REPLACE('<root><r t="' + @transIds + '"/></root>', '^', '"/><r t="'))

				INSERT INTO @__tmpTransId (id)
				SELECT T.C.value('./@t', 'BIGINT') AS transid
				FROM @xmlData.nodes('//r') AS T(C)
				OPTION (OPTIMIZE FOR (@xmlData = NULL))

				DELETE FROM dbo.bettransm14 WITH(ROWLOCK)
				WHERE transid IN (SELECT t.id FROM @__tmpTransId t)
			END
			ELSE
			BEGIN
				DELETE FROM dbo.bettransm14 WITH(ROWLOCK)
				WHERE winlostdate = @winlostdate
			END
			
			RETURN;
        END; --end of deleting bettransM14

		IF	@deletedTarget = 'sum_winloss' --- delete sum_winloss
		BEGIN;
			SELECT	@rowcount = 0;

			BEGIN TRANSACTION;

			DELETE	TOP(2500)
			FROM	dbo.sum_winloss WITH (ROWLOCK)
			WHERE	winlostdate <= @winlostdate;

			SELECT	@rowcount = @@ROWCOUNT;

			COMMIT TRANSACTION;

			RETURN;
		END; --- end of deleting sum_winloss

		IF	@deletedTarget = 'bettransG14' --- delete bettransG14
		BEGIN;
			SELECT	@rowcount = 0;

			BEGIN TRANSACTION;

			DELETE	TOP(2500)
			FROM	dbo.bettransG14 WITH (ROWLOCK)
			WHERE	winlostdate = @winlostdate;

			SELECT	@rowcount = @@ROWCOUNT;

			COMMIT TRANSACTION;

			RETURN;
		END; --- end of deleting bettransG14

		IF	@deletedTarget = 'translog14' --- delete translog14
		BEGIN;
			SELECT	@rowcount = 0;

			BEGIN TRANSACTION;

			DELETE	TOP(2500)
			FROM	dbo.translog14 WITH (ROWLOCK)
			WHERE	winlostdate = @winlostdate;

			SELECT	@rowcount = @@ROWCOUNT;

			COMMIT TRANSACTION;

			RETURN;
		END;  --- end of deleting translog14

		IF	@deletedTarget = 'bettransLC14' --- delete bettransLC14
		BEGIN;
			SELECT	@rowcount = 0;

			BEGIN TRANSACTION;

			DELETE	TOP(2500)
			FROM	dbo.bettransLC14 WITH (ROWLOCK)
			WHERE	winlostdate = @winlostdate;

			SELECT	@rowcount = @@ROWCOUNT;

			COMMIT TRANSACTION;

			RETURN;
		END;  --- end of deleting bettransLC14

		IF	@deletedTarget = 'bettransRNG14' --- delete bettransRNG14
		BEGIN;
			SELECT	@rowcount = 0;

			BEGIN TRANSACTION;

			DELETE	TOP(2500)
			FROM	dbo.bettransRNG14 WITH (ROWLOCK)
			WHERE	winlostdate = @winlostdate;

			SELECT	@rowcount = @@ROWCOUNT;

			COMMIT TRANSACTION;

			RETURN;
		END; --- end of deleting bettransRNG14

		IF	@deletedTarget = 'Transfer_Coll' --- delete Transfer_Coll
		BEGIN
			IF EXISTS (SELECT 1 FROM sys.objects WHERE Object_Name(Object_ID) = 'Transfer_Coll')
			BEGIN;
				SELECT	@rowcount = 0;

				BEGIN TRANSACTION;

				DELETE	TOP(2500)
				FROM	dbo.Transfer_Coll WITH (ROWLOCK)
				WHERE	winlostdate = @winlostdate;

				SELECT	@rowcount = @@ROWCOUNT;

				COMMIT TRANSACTION;

			RETURN;
			END
		END; --- end of deleting Transfer_Coll

		-- Delete Marked Transaction --
		IF	@deletedTarget = 'MarkedTransaction'
		BEGIN;
			IF	OBJECT_ID('MarkedTransaction') IS NOT NULL
			BEGIN;
				SELECT	@rowcount = 0;

				SET @xml = CONVERT(XML, @TransIds)
				INSERT INTO @MarkedTrans(TransID, MatchId)
				SELECT	T.C.value('./@transid', 'bigint')
						,T.C.value('./@matchid', 'int')
				FROM	@xml.nodes('/root/r') AS T(C)
				OPTION (OPTIMIZE FOR (@xml = NULL ))

				BEGIN TRANSACTION;

				DELETE	tbl WITH (ROWLOCK)
				FROM		dbo.MarkedTransaction AS tbl WITH (ROWLOCK)
				INNER JOIN	@MarkedTrans m ON m.TransId = tbl.TransId AND m.MatchId = tbl.MatchId

				SELECT	@rowcount = @@ROWCOUNT;

				COMMIT TRANSACTION;
			END;
		END;
		-- END -- Delete Marked Transaction --

		IF @deletedTarget = 'Intg_GameRoundBetStake'
		BEGIN
		IF	OBJECT_ID('Intg_GameRoundBetStake') IS NOT NULL
			BEGIN
				SELECT	@rowcount = 0;
				DELETE TOP(2500) 
				FROM dbo.Intg_GameRoundBetStake WITH(ROWLOCK) 
				WHERE CreateDate >= @winlostdate AND CreateDate < DATEADD(DAY, 1, @winlostdate)

				SELECT	@rowcount = @@ROWCOUNT;

			END
			RETURN
		END

		IF	@deletedTarget = 'others' --- for deleting all other small tables
		BEGIN
			IF	OBJECT_ID('bettranssum') IS NOT NULL
			BEGIN
				DELETE FROM bettranssum WHERE winlostdate = @winlostdate
			END
			RETURN
		END --- end of deleting others tables

		/*------TVS--------*/
		IF	@deletedTarget = 'TicketVoiding_VoidedTransaction'
		BEGIN
			IF	OBJECT_ID('TicketVoiding_VoidedTransaction') IS NOT NULL
			BEGIN;
				SELECT	@rowcount = 0;

				BEGIN TRANSACTION;

				DELETE	tbl WITH (ROWLOCK)
				FROM		dbo.TicketVoiding_VoidedTransaction AS tbl WITH (ROWLOCK)
				INNER JOIN	dbo.strSplit (@transIds, ',') AS s
						ON	tbl.id = CONVERT(INT, s.val);

				SELECT	@rowcount = @@ROWCOUNT;

				COMMIT TRANSACTION;
			END
			RETURN
		END		

		IF	@deletedTarget = 'TicketVoiding_Reason'
		BEGIN
			IF	OBJECT_ID('TicketVoiding_Reason') IS NOT NULL
			BEGIN;
				SELECT	@rowcount = 0;

				BEGIN TRANSACTION;

				DELETE	tbl WITH (ROWLOCK)
				FROM		dbo.TicketVoiding_Reason AS tbl WITH (ROWLOCK)
				INNER JOIN	dbo.strSplit (@transIds, ',') AS s
						ON	tbl.ReasonId = CONVERT(INT, s.val);

				SELECT	@rowcount = @@ROWCOUNT;

				COMMIT TRANSACTION;
			END
			RETURN
		END	

		IF	@deletedTarget = 'TicketVoiding_VoidingHistory'
		BEGIN
			IF	OBJECT_ID('TicketVoiding_VoidingHistory') IS NOT NULL
			BEGIN;
				SELECT	@rowcount = 0;

				BEGIN TRANSACTION;

				DELETE	tbl WITH (ROWLOCK)
				FROM		dbo.TicketVoiding_VoidingHistory AS tbl WITH (ROWLOCK)
				INNER JOIN	dbo.strSplit (@transIds, ',') AS s
						ON	tbl.VoidingHistoryId = CONVERT(INT, s.val);

				SELECT	@rowcount = @@ROWCOUNT;

				COMMIT TRANSACTION;
			END
			RETURN
		END	
		
		IF	@deletedTarget = 'TicketVoiding_Queue'
		BEGIN
			IF	OBJECT_ID('TicketVoiding_Queue') IS NOT NULL
			BEGIN;
				SELECT	@rowcount = 0;

				BEGIN TRANSACTION;

				DELETE	tbl WITH (ROWLOCK)
				FROM		dbo.TicketVoiding_Queue AS tbl WITH (ROWLOCK)
				INNER JOIN	dbo.strSplit (@transIds, ',') AS s
						ON	tbl.QueueId = CONVERT(INT, s.val);

				SELECT	@rowcount = @@ROWCOUNT;

				COMMIT TRANSACTION;
			END
			RETURN
		END		

		IF	@deletedTarget = 'TicketVoiding_OperatorInfo'
		BEGIN
			IF	OBJECT_ID('TicketVoiding_OperatorInfo') IS NOT NULL
			BEGIN;
				SELECT	@rowcount = 0;

				BEGIN TRANSACTION;

				DELETE	tbl WITH (ROWLOCK)
				FROM		dbo.TicketVoiding_OperatorInfo AS tbl WITH (ROWLOCK)
				INNER JOIN	dbo.strSplit (@transIds, ',') AS s
						ON	tbl.id = CONVERT(INT, s.val);

				SELECT	@rowcount = @@ROWCOUNT;

				COMMIT TRANSACTION;
			END
			RETURN
		END	
		
		IF	@deletedTarget = 'TicketVoiding_Request'
		BEGIN
			IF	OBJECT_ID('TicketVoiding_Request') IS NOT NULL
			BEGIN;
				SELECT	@rowcount = 0;

				BEGIN TRANSACTION;

				DELETE	tbl WITH (ROWLOCK)
				FROM		dbo.TicketVoiding_Request AS tbl WITH (ROWLOCK)
				INNER JOIN	dbo.strSplit (@transIds, ',') AS s
						ON	tbl.RequestId = CONVERT(INT, s.val);

				SELECT	@rowcount = @@ROWCOUNT;

				COMMIT TRANSACTION;
			END
			RETURN
		END	

		IF	@deletedTarget = 'TicketVoiding_AutoUnmarkSetting'
		BEGIN
			IF	OBJECT_ID('TicketVoiding_AutoUnmarkSetting') IS NOT NULL
			BEGIN;
				SELECT	@rowcount = 0;

				BEGIN TRANSACTION;

				DELETE	tbl WITH (ROWLOCK)
				FROM		dbo.TicketVoiding_AutoUnmarkSetting AS tbl WITH (ROWLOCK)
				INNER JOIN	dbo.strSplit (@transIds, ',') AS s
						ON	tbl.id = CONVERT(INT, s.val);

				SELECT	@rowcount = @@ROWCOUNT;

				COMMIT TRANSACTION;
			END
			RETURN
		END	
		
		IF	@deletedTarget = 'TicketVoiding_AutoVoidRequest_Queue'
		BEGIN
			IF	OBJECT_ID('TicketVoiding_AutoVoidRequest_Queue') IS NOT NULL
			BEGIN;
				SELECT	@rowcount = 0;

				BEGIN TRANSACTION;

				DELETE	tbl WITH (ROWLOCK)
				FROM		dbo.TicketVoiding_AutoVoidRequest_Queue AS tbl WITH (ROWLOCK)
				INNER JOIN	dbo.strSplit (@transIds, ',') AS s
						ON	tbl.QueueId = CONVERT(INT, s.val);

				SELECT	@rowcount = @@ROWCOUNT;

				COMMIT TRANSACTION;
			END
			RETURN
		END		

		IF	@deletedTarget = 'zzzbettrans'
		BEGIN
			IF	OBJECT_ID('zzzbettrans') IS NOT NULL
			BEGIN;
				SELECT	@rowcount = 0;

				BEGIN TRANSACTION;

				DELETE	tbl WITH (ROWLOCK)
				FROM		dbo.zzzbettrans AS tbl WITH (ROWLOCK)
				INNER JOIN	dbo.strSplit (@transIds, ',') AS s
						ON	tbl.keyid = CONVERT(INT, s.val);

				SELECT	@rowcount = @@ROWCOUNT;

				COMMIT TRANSACTION;
			END
			RETURN
		END	
		
		IF	@deletedTarget = 'zzzbettransM'
		BEGIN
			IF	OBJECT_ID('zzzbettransM') IS NOT NULL
			BEGIN;
				SELECT	@rowcount = 0;

				BEGIN TRANSACTION;

				DELETE	tbl WITH (ROWLOCK)
				FROM		dbo.zzzbettransM AS tbl WITH (ROWLOCK)
				INNER JOIN	dbo.strSplit (@transIds, ',') AS s
						ON	tbl.keyid = CONVERT(INT, s.val);

				SELECT	@rowcount = @@ROWCOUNT;

				COMMIT TRANSACTION;
			END
			RETURN
		END	
		
		IF	@deletedTarget = 'TicketVoiding_RequestDetail'
		BEGIN
			IF	OBJECT_ID('TicketVoiding_RequestDetail') IS NOT NULL
			BEGIN;
				SELECT	@rowcount = 0;

				BEGIN TRANSACTION;

				DELETE	tbl WITH (ROWLOCK)
				FROM		dbo.TicketVoiding_RequestDetail AS tbl WITH (ROWLOCK)
				INNER JOIN	dbo.strSplit (@transIds, ',') AS s
						ON	tbl.id = CONVERT(INT, s.val);

				SELECT	@rowcount = @@ROWCOUNT;

				COMMIT TRANSACTION;
			END
			RETURN
		END	

		IF	@deletedTarget = 'TicketVoiding_RequestDetailTicket_Single'
		BEGIN
			IF	OBJECT_ID('TicketVoiding_RequestDetailTicket_Single') IS NOT NULL
			BEGIN;
				SELECT	@rowcount = 0;

				BEGIN TRANSACTION;

				DELETE	tbl WITH (ROWLOCK)
				FROM		dbo.TicketVoiding_RequestDetailTicket_Single AS tbl WITH (ROWLOCK)
				INNER JOIN	dbo.strSplit (@transIds, ',') AS s
						ON	tbl.id = CONVERT(INT, s.val);

				SELECT	@rowcount = @@ROWCOUNT;

				COMMIT TRANSACTION;
			END
			RETURN
		END
		
		IF	@deletedTarget = 'TicketVoiding_RequestDetailTicket_SubParlay'
		BEGIN
			IF	OBJECT_ID('TicketVoiding_RequestDetailTicket_SubParlay') IS NOT NULL
			BEGIN;
				SELECT	@rowcount = 0;

				BEGIN TRANSACTION;

				DELETE	tbl WITH (ROWLOCK)
				FROM		dbo.TicketVoiding_RequestDetailTicket_SubParlay AS tbl WITH (ROWLOCK)
				INNER JOIN	dbo.strSplit (@transIds, ',') AS s
						ON	tbl.id = CONVERT(INT, s.val);

				SELECT	@rowcount = @@ROWCOUNT;

				COMMIT TRANSACTION;
			END
			RETURN
		END
		/*-----------------*/
	END
	ELSE-- Below is UN-ACCEPTED CASE
	BEGIN
		IF @Command = 'Except_DBTRANS' AND @@ServerName = 'DBTRANS'
			PRINT 'DBTRANS Exception'
		ELSE
		BEGIN
			PRINT 'Invalid input parameters'
			RETURN
		END
	END
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/