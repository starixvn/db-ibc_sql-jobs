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

		IF	@deletedTarget = 'bettransm14' --- delete bettransm14
		BEGIN
			CREATE TABLE #btm (rn int PRIMARY KEY IDENTITY(1,1), transid BIGINT)
			IF @@SERVERNAME LIKE 'DB04%' OR @@SERVERNAME IN ('DB054', 'DB055')
			BEGIN

				CREATE TABLE #m (matchid int PRIMARY KEY)
				INSERT INTO #m
				SELECT DISTINCT matchid FROM bettransm14

				DELETE FROM #m WHERE matchid in (SELECT matchid FROM dbo.match)
				DELETE FROM #m WHERE matchid in (SELECT matchid FROM dbo.match14)

				INSERT INTO #btm (transid)
				SELECT transid
				FROM bettransm14 B with (ROWLOCK)
				INNER JOIN #m M ON B.matchid = M.matchid

			END
			ELSE
			BEGIN
				INSERT INTO #btm (transid)
				SELECT transid
				FROM bettransm14 with (ROWLOCK)
				WHERE winlostdate = @winlostdate
			END


			SET @rn  = 1
			SET @rn2 = 2500
			SET @rc  = 1
			WHILE @rc > 0
			BEGIN
				BEGIN TRANSACTION
					DELETE B
					FROM #btm T
						INNER LOOP JOIN dbo.bettransm14 B ON B.transid = T.transid
					WHERE
						T.rn BETWEEN @rn AND @rn2

					SET @rc = @@ROWCOUNT
				COMMIT TRANSACTION

				SET @rn  = @rn  + 2500
				SET @rn2 = @rn2 + 2500
			END
			DROP TABLE #btm
			RETURN
		END  --- end of deleting bettransm14

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

				BEGIN TRANSACTION;

				DELETE	tbl WITH (ROWLOCK)
				FROM		dbo.MarkedTransaction AS tbl WITH (ROWLOCK)
				INNER JOIN	dbo.strSplit (CONVERT(VARCHAR(4000), @tmp1), ',') AS s
						ON	tbl.TransId = CONVERT(BIGINT, s.val);

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