USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[ExecRep_09]    Script Date: 10/12/2015 02:45:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ExecRep_09]
	@recommend int,
	@winlostdate smalldatetime,
	@parlay tinyint = 0
AS
SET NOCOUNT ON
/*
	Created by:[]
	Date:
	Task: 
	DB: DBTXN.BODB02
	Revisions:
		- 20100207@Thien: manipulate the flag isMovingBet on DB06.bodb02.dbo.SystemSettings for Parlay settlement
		- 20140305@Vivi: add delete translog
		- 20151012@Sophia: Add delete BettransLC and BettransRNG 
    
 */

IF @parlay = 29
BEGIN

	if exists (select * from dbo.sysobjects where name = 'betParlayResult')
	BEGIN
		Declare @refNos TABLE (refno bigint PRIMARY KEY)
		INSERT INTO @refNos
		SELECT refno
		FROM dbo.bettrans14 with (nolock)
		WHERE winlostdate <= @winlostdate AND bettype = 29
	
		DELETE FROM dbo.betParlayResult WITH(ROWLOCK, UPDLOCK)
		WHERE
			--winlostdate <= @winlostdate
			RefNo IN (SELECT RefNo FROM @refNos)
		
		DELETE FROM dbo.betParlayDetail WITH(ROWLOCK, UPDLOCK)
		WHERE
			winlostdate <= DATEADD(day, -14, @winlostdate)
			--RefNo IN (SELECT RefNo FROM @refNos)
	END
	
	RETURN

END


Declare @rc int, @rn int, @rn2 int
Declare @matchid int
CREATE TABLE #m (rn int PRIMARY KEY IDENTITY(1,1), matchid int)

IF @@SERVERNAME LIKE 'DB04%'
BEGIN
/*	INSERT INTO #m (matchid)
	SELECT distinct matchid
	FROM dbo.bettrans with (nolock)
	WHERE winlostdate = @winlostdate AND bettype < 19999
	SET @rn2 = @@ROWCOUNT
	
	IF @rn2 = 0 GOTO NothingToDelete

	DELETE FROM bettrans WHERE winlostdate = @winlostdate AND matchid = 0 AND bettype < 19999
	DELETE FROM bettrans WHERE winlostdate = @winlostdate AND matchid IN (9,29)
*/	
	SET @rn  = 1
	
/*	NextMatchID:
	SELECT @matchid = matchid FROM #m WHERE rn = @rn
	IF @@ROWCOUNT = 0 GOTO NoMoreMatchID
	
	DELETE FROM bettrans WHERE matchid = @matchid AND winlostdate = @winlostdate
	DELETE FROM #m WHERE rn = @rn
	SET @rn = @rn + 1
	GOTO NextMatchID

	NoMoreMatchID:
	DELETE FROM bettrans WHERE winlostdate = @winlostdate AND bettype < 19999
	
	NothingToDelete:
*/
END
ELSE
BEGIN
	DELETE FROM bettrans WITH(ROWLOCK, UPDLOCK)
	WHERE recommend = @recommend AND winlostdate = @winlostdate AND bettype < 19999

	DELETE FROM translog WITH(ROWLOCK, UPDLOCK)
	WHERE recommend = @recommend AND winlostdate = @winlostdate
		
	DELETE FROM bettransLC WITH(ROWLOCK, UPDLOCK)
	WHERE recommend = @recommend AND winlostdate = @winlostdate  

	DELETE FROM bettransRNG WITH(ROWLOCK, UPDLOCK)
	WHERE recommend = @recommend AND winlostdate = @winlostdate 

END
IF @parlay = 1
BEGIN
	--IF @@SERVERNAME = N'DB04' RETURN -- not delete bettransm on DB04
	
	--IF @@SERVERNAME IN ( N'DB04', N'DB042' )
	--	DELETE FROM bettransm
	--	WHERE matchid IN (SELECT matchid FROM match WHERE eventdate = @winlostdate)
	--ELSE

	INSERT INTO #m (matchid)
	SELECT DISTINCT m.matchid
	FROM dbo.bettransm b with (nolock)
		INNER JOIN dbo.match m with (nolock) ON b.matchid = m.matchid
	WHERE winlostdate = @winlostdate
	SET @rn2 = @@ROWCOUNT
	
	SET @rn = 1

	NextMatchIDm:
	SELECT @matchid = matchid FROM #m WHERE rn = @rn
	IF @@ROWCOUNT = 0 GOTO NoMoreMatchIDm
	
	DELETE FROM bettransm WITH(ROWLOCK, UPDLOCK) WHERE matchid = @matchid --AND winlostdate = @winlostdate
	DELETE FROM #m WHERE rn = @rn
	SET @rn = @rn + 1
	GOTO NextMatchIDm
	
	NoMoreMatchIDm:
	DELETE FROM bettransm WITH(ROWLOCK, UPDLOCK) WHERE winlostdate = @winlostdate
	
END


IF @parlay = 2
BEGIN
	--IF @@SERVERNAME = N'DB04' RETURN -- not delete bettransG on DB04
	
	--IF @@SERVERNAME IN ( N'DB04', N'DB042' )
	--	DELETE FROM bettransG
	--	WHERE matchid IN (SELECT matchid FROM match WHERE eventdate = @winlostdate)
	--ELSE

	DELETE FROM bettransG WITH(ROWLOCK, UPDLOCK) WHERE winlostdate = @winlostdate
	

	--set FALSE for the flag isMovingBet on DB06.bodb02.dbo.SystemSettings
	--to allow the Mix Parlay calculation again
	IF @@SERVERNAME = 'DB06'
	BEGIN
		if exists (select * from dbo.sysobjects where name = 'SystemSettings')
		BEGIN
			UPDATE SystemSettings WITH(ROWLOCK, UPDLOCK) set VValue = 0 where VName = 'isMovingBet'
		END
	END	
END


DROP TABLE #m


GO
GRANT VIEW DEFINITION ON [dbo].[ExecRep_09] TO [vnteam] AS [dbo]