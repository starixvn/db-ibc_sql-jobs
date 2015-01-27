USE [LASDB]
GO

/****** Object:  StoredProcedure [dbo].[ExecRep_09_Las]    Script Date: 01/27/2015 00:23:29 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ExecRep_09_Las]
	@CustIDs		VARCHAR(MAX)	= ''
	,@IsAgent		BIT				= NULL
	,@Winlostdate	SMALLDATETIME
	,@parlay		TINYINT			= 0
AS
/*
Created		: 20140316@Don
Task		: Delete bettrans/bettrans_Agent/bettransm for whole day of @winlostdate
DB			: DBLAS.lasdb

Revisions:
		
*/
BEGIN

	SET NOCOUNT ON
 
	IF @parlay = 29
	BEGIN

		IF EXISTS (SELECT * FROM dbo.sysobjects WHERE name = 'betParlayResult')
		BEGIN
			DELETE FROM dbo.betParlayResult
			WHERE winlostdate <= @winlostdate

			DELETE FROM dbo.BetParlayResult_Agent
			WHERE winlostdate <= @winlostdate
		
			DELETE FROM dbo.betParlayDetail
			WHERE winlostdate <= DATEADD(day, -14, @winlostdate)
		END
	
		RETURN

	END

 
	IF @parlay = 1
	BEGIN
		DECLARE @rc INT, @rn INT, @rn2 INT
		DECLARE @matchid INT
		CREATE TABLE #m (rn INT PRIMARY KEY IDENTITY(1,1), matchid INT)

		INSERT INTO #m (matchid)
			SELECT DISTINCT m.matchid
			FROM dbo.bettransm b WITH(NOLOCK)
				INNER JOIN bodb02.dbo.match m WITH(NOLOCK) ON b.matchid = m.matchid
			WHERE winlostdate = @winlostdate
		SET @rn2 = @@ROWCOUNT
	
		SET @rn = 1

		NextMatchIDm:
			SELECT @matchid = matchid FROM #m WHERE rn = @rn
			IF @@ROWCOUNT = 0 
				GOTO NoMoreMatchIDm
	
			DELETE FROM dbo.bettransm WHERE matchid = @matchid
			DELETE FROM #m WHERE rn = @rn
			SET @rn = @rn + 1
			GOTO NextMatchIDm
	
		NoMoreMatchIDm:
			DELETE FROM dbo.bettransm WHERE winlostdate = @winlostdate
	
		DROP TABLE #m
	END
	ELSE
	BEGIN 
		IF @IsAgent = 0
			DELETE FROM dbo.bettrans WHERE CustId IN (SELECT val FROM bodb02.dbo.StrSplit_key(@CustIds,',')) AND winlostdate = @winlostdate AND bettype < 19999
		ELSE 
			DELETE FROM dbo.bettrans_Agent WHERE AgentId IN (SELECT val FROM bodb02.dbo.StrSplit_key(@CustIds,',')) AND winlostdate = @winlostdate AND bettype < 19999

	END
END




GO

GRANT VIEW DEFINITION ON [dbo].[ExecRep_09_Las] TO [vnteam] AS [dbo]
GO


