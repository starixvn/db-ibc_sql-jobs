USE [LASDB]
GO

/****** Object:  StoredProcedure [dbo].[ExecRep_02_Las]    Script Date: 01/27/2015 00:23:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.ExecRep_02_Las    Script Date: 3/21/2014 4:25:44 PM ******/
CREATE PROCEDURE [dbo].[ExecRep_02_Las]
	@winlostdate date = NULL,
	@Command varchar(20) = 'ALL_DB'
AS
/*
	Created by: Victor
	Date: 20140315
	Task: Clear data bettrans14, bettransm14, Sum_WinLoss_Cust, Sum_WinLoss_Agent
	DB: DBLAS.LASDB
	Orginal SP: Suncity.ExecRep_02_Las
	Revisions:
		
*/

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

--IF -- below is ACCEPTED case
--(
--	(@Command = 'ALL_DB') -- delete on all server
--	--OR
--	--(@Command = 'Except_DBTRANS' AND @@ServerName <> 'DBTRANS') 
--)
BEGIN
	-- =================
	-- BEGIN DELETE DATA
	-- =================
	PRINT 'DELETE DATA'

	Declare @rc int, @rn int, @rn2 int

	DELETE FROM dbo.bettrans14
	WHERE winlostdate = @winlostdate

	PRINT 'Done deleting bettrans14'

	DELETE FROM dbo.bettrans14_Agent
	WHERE winlostdate = @winlostdate
	
	PRINT 'Done deleting bettrans14_Agent'


	CREATE TABLE #btm (rn int PRIMARY KEY IDENTITY(1,1), transid int)


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
		FROM Sum_WinLoss_Cust with (ROWLOCK)
		WHERE winlostdate <= @winlostdate

		SET @rc = @@ROWCOUNT
		COMMIT TRANSACTION
	END

	SET @rc = 1
	WHILE @RC > 0
	BEGIN
		BEGIN TRANSACTION
		DELETE TOP (5000)
		FROM Sum_WinLoss_Agent with (ROWLOCK)
		WHERE winlostdate <= @winlostdate

		SET @rc = @@ROWCOUNT
		COMMIT TRANSACTION
	END

	IF EXISTS (select * from dbo.sysobjects where name = 'Bettrans_Sum') 
	BEGIN
		DELETE FROM Bettrans_Sum WHERE winlostdate = @winlostdate
	END

	IF EXISTS (select * from dbo.sysobjects where name = 'Bettrans_Agent_Sum') 
	BEGIN
		DELETE FROM Bettrans_Agent_Sum WHERE winlostdate = @winlostdate
	END
	-- =====
	--  END
	-- =====

	PRINT 'DONE DELETE DATA'
END

--ELSE
---- Below is UN-ACCEPTED CASE
--BEGIN
--	--IF @Command = 'Except_DBTRANS' AND @@ServerName = 'DBTRANS'
--	--	PRINT 'DBTRANS Exception'	
--	--ELSE
--	BEGIN
--		PRINT 'Invalid input parameters'
--		RETURN
--	END
--END

SET NOCOUNT OFF
GO


