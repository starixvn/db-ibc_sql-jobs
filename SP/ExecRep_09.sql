/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[ExecRep_09]
	@recommend int,
	@winlostdate smalldatetime,
	@parlay tinyint = 0,
	@tableName varchar(125) = ''
AS
-- *** IMPORTANT ***
-- IF code altered, must to go check related SP of ExecRep_Queue @ DBTP
-- *****************
/*
	Created by:[]
	Date: f
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
		- 20171017@Lukas: rewrite deleting betparlayDetail part for improving performance on replicated DB (avoid many loop inside transaction)
		- 20171102@Patrick: Update code for:
			+ Delete data bettrans/translog/bettransRnG/bettransLC/bettransG batch by batch
			+ Add more signal to replicated servers when MB/BU starting or done
			+ Set current datetime value to checktime field when insert ticket 19999
			+ When processing a line then insert itself and upline's to [List]
 */
BEGIN
	--SET NOCOUNT ON 
	IF @@SERVERNAME = 'DBTP' AND @parlay = 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.ExecRep_Queue WHERE command = 'ExecRep_09' AND datevalue = @winlostdate)
			INSERT INTO dbo.ExecRep_Queue (command, datevalue, qPriority) VALUES ('ExecRep_09',@winlostdate, 2)
		
		RETURN
	END

	IF @tableName = 'SystemSettings'
	BEGIN
		IF EXISTS (
			SELECT TOP 1 1 
			FROM dbo.sysobjects WHERE name = 'SystemSettings'
		)
		BEGIN
			--//@parlay = 3 will turn on isMovingBet_Local flag, @parlay = 4 will turn off isMovingBet_Local flag
			IF @parlay IN (3,4) --used for turn on flag for MB case
			BEGIN
				UPDATE dbo.SystemSettings WITH(ROWLOCK, UPDLOCK) 
				SET VValue = CASE WHEN @parlay = 3 THEN 1 ELSE 0 END
				WHERE VName = 'isMovingBet_Local'
			END
			--//@parlay = 5 well turn on isArchivingBet_Local flag, @parlay = 6 will turn off isArchivingBet_Local flag
			ELSE IF @parlay IN (5,6)
			BEGIN
				UPDATE dbo.SystemSettings WITH(ROWLOCK, UPDLOCK) 
				SET VValue = CASE WHEN @parlay = 5 THEN 1 ELSE 0 END
				WHERE VName = 'isArchivingBet_Local'
			END
		END
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
			END

			DROP TABLE #CurrRefNoList
			DROP TABLE #RefNoList
		
		END
		ELSE IF EXISTS (SELECT TOP 1 1 FROM dbo.sysobjects WHERE name = @tableName)
			AND @tableName = 'betParlayDetail'
		BEGIN

			DECLARE @refnoTable TABLE(refno BIGINT PRIMARY KEY CLUSTERED)
			DECLARE @xmlData XML
			SET @xmlData = CONVERT(XML, REPLACE('<root><r t="' + @refnos + '"/></root>', '^', '"/><r t="'))

			INSERT INTO @refnoTable (refno)
			SELECT T.C.value('./@t', 'BIGINT') AS transid
			FROM @xmlData.nodes('//r') AS T(C)
			OPTION (OPTIMIZE FOR (@xmlData = NULL))

			WHILE 1 = 1 
			BEGIN
				DELETE TOP(5000) dt
				FROM @refnoTable r
					INNER LOOP JOIN betParlayDetail dt ON r.refno = dt.refno
				WHERE winlostdate <= DATEADD(DAY, - 14, @winlostdate)

				IF @@ROWCOUNT = 0 
					BREAK
			END
		END
		RETURN
	END

	IF @@SERVERNAME LIKE 'DB04%'
	BEGIN
		PRINT 'nothing'
	END
	ELSE
	BEGIN
		SET @rowDeleted = 0

		--//for bettrans
		IF @tableName = 'bettrans'
		BEGIN
			IF @@SERVERNAME IN ('DBTRANS', 'DB06', 'DBLICAPI', 'DBLicApi02')
			BEGIN
				DELETE TOP (2000) FROM bettrans WITH(ROWLOCK)
				WHERE recommend = @recommend AND winlostdate = @winlostdate AND bettype < 19999

				SET @RowDeleted = @@ROWCOUNT
			END
			ELSE IF @firstRound = 1 --for all replicated servers, will delete by recommend
			BEGIN
				DELETE FROM bettrans WITH(ROWLOCK)
				WHERE recommend = @recommend AND winlostdate = @winlostdate AND bettype < 19999

				SET @RowDeleted = @@ROWCOUNT
			END

			RETURN
		END
		
		--//for translog
		IF @tableName = 'translog'
		BEGIN
			IF @@SERVERNAME IN ('DBTRANS', 'DB06', 'DBLICAPI', 'DBLicApi02')
			BEGIN
				DELETE TOP (2000) FROM translog WITH(ROWLOCK)
				WHERE recommend = @recommend AND winlostdate = @winlostdate

				SET @RowDeleted = @@ROWCOUNT
			END
			ELSE IF @firstRound = 1 --for all replicated servers, will delete by recommend
			BEGIN
				DELETE FROM translog WITH(ROWLOCK)
				WHERE recommend = @recommend AND winlostdate = @winlostdate

				SET @RowDeleted = @@ROWCOUNT
			END

			RETURN
		END

		--//for bettransLC
		IF @tableName = 'bettransLC'
		BEGIN
			IF @@SERVERNAME IN ('DBTRANS', 'DB06', 'DBLICAPI', 'DBLicApi02')
			BEGIN	
				DELETE TOP (2000) FROM bettransLC WITH(ROWLOCK)
				WHERE recommend = @recommend AND winlostdate = @winlostdate  

				SET @RowDeleted = @@ROWCOUNT
			END
			ELSE IF @firstRound = 1 --for all replicated servers, will delete by recommend
			BEGIN
				DELETE FROM bettransLC WITH(ROWLOCK)
				WHERE recommend = @recommend AND winlostdate = @winlostdate  

				SET @RowDeleted = @@ROWCOUNT
			END

			RETURN
		END

		--//for bettransRNG
		IF @tableName = 'bettransRNG'
		BEGIN
			IF @@SERVERNAME IN ('DBTRANS', 'DB06', 'DBLICAPI', 'DBLicApi02')
			BEGIN
				DELETE TOP (2000) FROM bettransRNG WITH(ROWLOCK)
				WHERE recommend = @recommend AND winlostdate = @winlostdate 

				SET @RowDeleted = @@ROWCOUNT
			END
			ELSE IF @firstRound = 1 --for all replicated servers, will delete by recommend
			BEGIN
				DELETE FROM bettransRNG WITH(ROWLOCK)
				WHERE recommend = @recommend AND winlostdate = @winlostdate 

				SET @RowDeleted = @@ROWCOUNT
			END

			RETURN
		END
	END

	IF @parlay = 1
	BEGIN
		Declare @rc int, @rn int, @rn2 int
		Declare @matchid int
		CREATE TABLE #m (rn int PRIMARY KEY IDENTITY(1,1), matchid int)

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
	
		DELETE FROM bettransm WITH(ROWLOCK) WHERE matchid = @matchid

		DELETE FROM #m WHERE rn = @rn
		SET @rn = @rn + 1
		GOTO NextMatchIDm
	
		NoMoreMatchIDm:
		DELETE FROM bettransm WITH(ROWLOCK, UPDLOCK) WHERE winlostdate = @winlostdate
	
		DROP TABLE #m
	END

	IF @parlay = 2
	BEGIN	
		
		DELETE FROM bettransG WITH(ROWLOCK) WHERE winlostdate = @winlostdate

		IF EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'BetLucky3Result')
		BEGIN
			DELETE FROM dbo.BetLucky3Result WITH(ROWLOCK) WHERE WinlostDate = @winlostdate
		END
	END
END