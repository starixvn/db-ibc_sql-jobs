 /*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
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
		- 20170914@Patrick: Integrate with Lucky3 [RedmineId: #83190]
		- 20171004@Lukas:	Add @deletedTarget for deleting data for one by one table
		- 20180725@Billy:	Change the way of deleting data (except [bettransm14]) - [Redmine: #98857]
*/
-- =======================
-- Parameter check\control
-- =======================
BEGIN 

	SET NOCOUNT ON

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
				DELETE B14
				FROM dbo.bettrans14 B14 WITH (ROWLOCK)
				WHERE winlostdate = @winlostdate
					AND custid BETWEEN CAST(@tmp2 AS int) AND CAST(@tmp3 AS int)

				RETURN
			END
 
			DELETE TOP (2500) B14
			FROM dbo.bettrans14 B14 WITH (ROWLOCK, INDEX=IX_bettrans14)
			WHERE winlostdate = @winlostdate
	
			SET @rowcount = @@ROWCOUNT
			RETURN
		END --- end of deleting bettrans14

		IF	@deletedTarget = 'bettransm14' --- delete bettransm14
		BEGIN
			CREATE TABLE #btm (rn int PRIMARY KEY IDENTITY(1,1), transid BIGINT)
			IF @@SERVERNAME LIKE 'DB04%'
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

		IF	@deletedTarget = 'others' --- for deleting all other small tables
		BEGIN
			IF EXISTS (
				SELECT TOP 1 1
				FROM dbo.sysobjects WHERE name = 'BetLucky3Result14'
			)
			BEGIN
				SET @rc = 1
				WHILE @rc > 0
				BEGIN
					BEGIN TRANSACTION
					DELETE TOP (2500)
					FROM dbo.BetLucky3Result14 WITH (ROWLOCK)
					WHERE winlostdate = @winlostdate

					SET @rc = @@ROWCOUNT
					COMMIT TRANSACTION
				END
			END
			IF EXISTS (select * from dbo.sysobjects where name = 'bettranssum')
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

