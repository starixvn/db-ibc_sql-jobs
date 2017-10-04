/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[ExecRep_09] @recommend int,
	@winlostdate smalldatetime,
	@parlay tinyint = 0,
	@tableName varchar(125) = ''
AS
-- *** IMPORTANT ***
-- IF code altered, must to go check related SP of ExecRep_Queue @ DBTP
-- *****************

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
		- 20160121@Joe : move command to run in ExecRep_Queue @ DBTP (to solve Blocking problem which cause replication delay)
		- 20160816@Lukas: comment update isMovingBet section      
		- 20170222@Patrick: delete betparlaydetail & betparlayresult by batch
		- 20170914@Patrick: Integrate with Lucky3 [RedmineId: #83190] 
 
 */

IF @@SERVERNAME = 'DBTP' AND @parlay = 0
BEGIN
	IF NOT EXISTS (SELECT 1 FROM dbo.ExecRep_Queue WHERE command = 'ExecRep_09' AND datevalue = @winlostdate)
		INSERT INTO dbo.ExecRep_Queue (command, datevalue, qPriority) VALUES ('ExecRep_09',@winlostdate, 2)
		
	RETURN
END

IF @parlay = 29
BEGIN
	DECLARE @rx INT, @ry INT--, @debugMessage VARCHAR(200)

	IF EXISTS (SELECT TOP 1 1 FROM dbo.sysobjects WHERE name = @tableName)
		AND @tableName = 'betParlayResult'
	BEGIN
		
		CREATE TABLE #RefNoList (RefNo BIGINT, RowId INT IDENTITY(1,1) PRIMARY KEY)
		CREATE TABLE #CurrRefNoList (RefNo BIGINT)

		INSERT INTO #RefNoList(RefNo)
		SELECT RefNo
		FROM dbo.bettrans14 WITH (NOLOCK)
		WHERE winlostdate <= @winlostdate AND bettype = 29

		SET @rx = 1
		SET @ry = 3000

		WHILE 1 = 1
		BEGIN

			TRUNCATE TABLE #CurrRefNoList

			INSERT INTO #CurrRefNoList(RefNo)
			SELECT RefNo
			FROM #RefNoList t WHERE t.RowId BETWEEN @rx AND @ry

			IF @@ROWCOUNT <= 0
				BREAK

			RetryDelete_betParlayResult:
			BEGIN TRY
				DELETE TOP(3000) bpr
				FROM #CurrRefNoList t
					INNER JOIN dbo.betParlayResult bpr WITH(ROWLOCK) ON bpr.RefNo = t.refNo
				OPTION(FORCE ORDER)

				IF @@ROWCOUNT = 3000
					GOTO RetryDelete_betParlayResult

				SET @rx = @rx + 3000
				SET @ry = @ry + 3000

			END TRY
			BEGIN CATCH
				PRINT 'Error here!!!'
				GOTO RetryDelete_betParlayResult
			END CATCH

			--SET @debugMessage = 'betParlayResult -- ' + convert(varchar(50), getdate(), 121)
			--RAISERROR(@debugMessage, 0, 0) with nowait

		END

		DROP TABLE #CurrRefNoList
		DROP TABLE #RefNoList
		
	END
	ELSE IF EXISTS (SELECT TOP 1 1 FROM dbo.sysobjects WHERE name = @tableName)
		AND @tableName = 'betParlayDetail'
	BEGIN

		CREATE TABLE #IdList (rId BIGINT, RowId INT IDENTITY(1,1) PRIMARY KEY)
		CREATE TABLE #CurrIdList (rId BIGINT)

		INSERT INTO #IdList(rId)
		SELECT rID
		FROM dbo.BetParlayDetail WITH (NOLOCK)
		WHERE winlostdate <= DATEADD(DAY, - 14, @winlostdate)

		SET @rx = 1
		SET @ry = 3000

		WHILE 1 = 1
		BEGIN

			TRUNCATE TABLE #CurrIdList

			INSERT INTO #CurrIdList(rId)
			SELECT rId
			FROM #IdList t WHERE t.RowId BETWEEN @rx AND @ry

			IF @@ROWCOUNT <= 0
				BREAK

			RetryDelete_BetParlayDetail:
			BEGIN TRY
				DELETE bpd
				FROM #CurrIdList t
					INNER JOIN dbo.BetParlayDetail bpd WITH(ROWLOCK) ON bpd.rID = t.rId
				OPTION(FORCE ORDER)

				SET @rx = @rx + 3000
				SET @ry = @ry + 3000

			END TRY
			BEGIN CATCH
				PRINT 'Error here!!!'
				GOTO RetryDelete_BetParlayDetail
			END CATCH

			--SET @debugMessage = 'BetParlayDetail -- ' + convert(varchar(50), getdate(), 121)
			--RAISERROR(@debugMessage, 0, 0) with nowait

		END

		DROP TABLE #IdList
		DROP TABLE #CurrIdList

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

	IF EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'BetLucky3Result')
	BEGIN
		WHILE 1 = 1
		BEGIN
			DELETE TOP(2500) 
			FROM dbo.BetLucky3Result WITH(ROWLOCK)
			WHERE WinlostDate = @winlostdate

			IF @@ROWCOUNT = 0
				BREAK
		END
	END

	----set FALSE for the flag isMovingBet on DB06.bodb02.dbo.SystemSettings
	----to allow the Mix Parlay calculation again
	--IF @@SERVERNAME = 'DB06'
	--BEGIN
	--	if exists (select * from dbo.sysobjects where name = 'SystemSettings')
	--	BEGIN
	--		UPDATE SystemSettings WITH(ROWLOCK, UPDLOCK) set VValue = 0 where VName = 'isMovingBet'
	--	END
	--END	
END


DROP TABLE #m
GO
