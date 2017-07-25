 /*<info serverAlias="DBTXN-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[ExecRep_02]
	@tmp1 sql_variant = NULL,
	@tmp2 sql_variant = NULL,
	@tmp3 sql_variant = NULL,
	@winlostdate datetime = NULL,
	@Command varchar(20) = NULL
AS

SET NOCOUNT ON
/*
	Created by:[]
	Date:
	Task: call from Joe : ClearData14 working routine
	DB: DBTXN.BODB02
	Revisions:		
		- 20151012@Sophia: Add delete BettransLC14 and BettransRNG14
    	- 20160526@Victor: Add delete TransLog14 
		- 20170725@Sophia: Change Datatype of TransID [Redmine: #73545]
 */
-- =======================
-- Parameter check\control
-- =======================

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
	-- =================
	-- BEGIN DELETE DATA
	-- =================
	PRINT 'DELETE DATA'

	-- if specific command come, do it and quit
	IF CONVERT(varchar(50), @tmp1) = 'Delete bettrans14 by custid range'
	BEGIN
		DELETE B14
		FROM dbo.bettrans14 B14 WITH (ROWLOCK)
		WHERE
			winlostdate = @winlostdate
			AND custid BETWEEN CAST(@tmp2 AS int) AND CAST(@tmp3 AS int)

		RETURN
	END

	Declare @rc int, @rn int, @rn2 int

	/*CREATE TABLE #c (rn int PRIMARY KEY IDENTITY(1,1), custid int)
	INSERT INTO #c (custid)
	SELECT distinct custid
	FROM dbo.bettrans14 with (rowlock)
	WHERE winlostdate = @winlostdate

	SET @rn  = 1
	SET @rn2 = 20000
	SET @rc  = 1
	WHILE @rc > 0
	BEGIN
		BEGIN TRANSACTION
			DELETE B
			FROM dbo.bettrans14 B
				INNER JOIN #c C ON B.winlostdate = @winlostdate AND B.custid = C.custid
			WHERE
				C.rn BETWEEN @rn AND @rn2
				--AND winlostdate = @winlostdate

			SET @rc = @@ROWCOUNT
		COMMIT TRANSACTION

		SET @rn  = @rn  + 20000
		SET @rn2 = @rn2 + 20000
	END
	DROP TABLE #c
	*/
	DELETE TOP (2500) B14
	FROM dbo.bettrans14 B14 WITH (ROWLOCK, INDEX=IX_bettrans14)
	WHERE winlostdate = @winlostdate
	
	IF @@ROWCOUNT > 0 RETURN
	PRINT 'Continue'

	
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
			FROM dbo.bettransm14 B
				INNER JOIN #btm T ON B.transid = T.transid
			WHERE
				T.rn BETWEEN @rn AND @rn2

			SET @rc = @@ROWCOUNT
		COMMIT TRANSACTION

		SET @rn  = @rn  + 2500
		SET @rn2 = @rn2 + 2500
	END
	DROP TABLE #btm

	SET @rc = 1
	WHILE @RC > 0
	BEGIN
		BEGIN TRANSACTION
		DELETE TOP (2500)
		FROM sum_winloss with (ROWLOCK)
		WHERE winlostdate <= @winlostdate

		SET @rc = @@ROWCOUNT
		COMMIT TRANSACTION
	END

	SET @rc = 1
	WHILE @RC > 0
	BEGIN
		BEGIN TRANSACTION
		DELETE TOP (2500)
		FROM bettransG14 with (ROWLOCK)
		WHERE winlostdate = @winlostdate

		SET @rc = @@ROWCOUNT
		COMMIT TRANSACTION
	END

	SET @rc = 1
	WHILE @RC > 0
	BEGIN
		BEGIN TRANSACTION
		DELETE TOP (2500)
		FROM TransLog14  with (ROWLOCK)
		WHERE winlostdate = @winlostdate

		SET @rc = @@ROWCOUNT
		COMMIT TRANSACTION
	END
	
	SET @rc = 1
	WHILE @RC > 0
	BEGIN
		BEGIN TRANSACTION
		DELETE TOP (2500)
		FROM bettransLC14 WITH (ROWLOCK)
		WHERE winlostdate = @winlostdate

		SET @rc = @@ROWCOUNT
		COMMIT TRANSACTION
	END

	
	SET @rc = 1
	WHILE @RC > 0
	BEGIN
		BEGIN TRANSACTION
		DELETE TOP (2500)
		FROM bettransRNG14 WITH (ROWLOCK)
		WHERE winlostdate = @winlostdate

		SET @rc = @@ROWCOUNT
		COMMIT TRANSACTION
	END

	IF EXISTS (select * from dbo.sysobjects where name = 'bettranssum') 
	BEGIN
		DELETE FROM bettranssum WHERE winlostdate = @winlostdate
	END
	-- =====
	--  END
	-- =====
END

ELSE
-- Below is UN-ACCEPTED CASE
BEGIN
	IF @Command = 'Except_DBTRANS' AND @@ServerName = 'DBTRANS'
		PRINT 'DBTRANS Exception'	
	ELSE
	BEGIN
		PRINT 'Invalid input parameters'
		RETURN
	END
END

GO

