USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[ExecRep_02]    Script Date: 01/26/2015 04:53:19 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ExecRep_02]
	@tmp1 sql_variant = NULL,
	@tmp2 sql_variant = NULL,
	@tmp3 sql_variant = NULL,
	@winlostdate datetime = NULL,
	@Command varchar(20) = NULL
AS
SET NOCOUNT ON
-- call from Joe : ClearData14 working routine

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
	DELETE TOP (250000)
	FROM dbo.bettrans14
	WHERE winlostdate = @winlostdate
	
	IF @@ROWCOUNT > 0 RETURN
	PRINT 'Continue'

	CREATE TABLE #btm (rn int PRIMARY KEY IDENTITY(1,1), transid int)

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
	SET @rn2 = 50000
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

		SET @rn  = @rn  + 50000
		SET @rn2 = @rn2 + 50000
	END
	DROP TABLE #btm

	SET @rc = 1
	WHILE @RC > 0
	BEGIN
		BEGIN TRANSACTION
		DELETE TOP (5000)
		FROM sum_winloss with (ROWLOCK)
		WHERE winlostdate <= @winlostdate

		SET @rc = @@ROWCOUNT
		COMMIT TRANSACTION
	END

	SET @rc = 1
	WHILE @RC > 0
	BEGIN
		BEGIN TRANSACTION
		DELETE TOP (5000)
		FROM bettransG14 with (ROWLOCK)
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

SET NOCOUNT OFF

GO

GRANT VIEW DEFINITION ON [dbo].[ExecRep_02] TO [vnteam] AS [dbo]
GO


