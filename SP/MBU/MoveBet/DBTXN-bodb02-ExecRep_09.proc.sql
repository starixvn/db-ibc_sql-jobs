SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
ALTER PROCEDURE dbo.ExecRep_09
	@recommend int,
	@winlostdate smalldatetime,
	@parlay tinyint = 0,
	@tableName varchar(125) = '',
	@refnos varchar(max) = '',
	@rowDeleted int = 0 OUTPUT,
	@firstRound bit = 0,
	@matchId int = 0
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
		- 20180329@Percy: Enhance MBBU process [RedmineID: #92391]
		- 20181222@Billy:   Remove Queue processing on DBTP - [Redmine: #000000]
		- 20190131@Patrick: Delete bettransm batch by batch at replicated servers to reduce lock escalation [RedmineID: #108581]
		- 20190319@Patrick: DB06 migration [RedmineID: #110208]
		- 20190701@Percy: Update directly flag of MBBU process [RedmineID: #115877]
		- 20190828@Billy:	Add table [bettransInfo] - [Redmine: #119219]
		- 20191030@Billy:	Remove table [BetLucky3Result] - [Redmine: #122987]
		- 20191126@Patrick: Ignore remove data on DB054/DB055 - [Redmine: #124104]
		- 20200916@Brice:	Change serverName DB06 to DB06C2\DB06 [Redmine: #140355]
		- 20210126@Patrick: Migrate DB Server DB054 to cluster [Redmine: #149273]
		- 202010316@Patrick: Revise Movebet flow to support transfer 247 Redmine: [#149927]

 */
BEGIN
	--SET NOCOUNT ON
	
	-- 20181222@Billy: Comment code due to replication issue from DBTP to DBMNL
/*
	IF @@SERVERNAME = 'DBTP' AND @parlay = 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.ExecRep_Queue WHERE command = 'ExecRep_09' AND datevalue = @winlostdate)
			INSERT INTO dbo.ExecRep_Queue (command, datevalue, qPriority) VALUES ('ExecRep_09',@winlostdate, 2)
		
		RETURN
	END
*/

	-- 20190828@Billy: Temp variable table for deleting [bettransInfo]
	DECLARE	@__tmpTransId AS TABLE (
				id		BIGINT		PRIMARY KEY CLUSTERED
			);

	IF @tableName = 'SystemSettings'
	BEGIN
		IF EXISTS (
			SELECT TOP 1 1 
			FROM dbo.sysobjects WHERE name = 'SystemSettings'
		)
		BEGIN
			/*
			@parlay:
				3: MB on
				4: MB off
				5: BU on
				6: BU off
			*/
			DECLARE @VName VARCHAR(50)
			SELECT  @VName = CASE WHEN @parlay IN (3,4) THEN 'isMovingBet_Local' WHEN @parlay IN (5,6) THEN 'isArchivingBet_Local' END

			DECLARE @updatedFlag TABLE (VValue VARCHAR(200))

			--//@parlay = 3,5: turn on flag --> input start time, @parlay = 4,6: turn off flag --> input end time
			IF @parlay IN (3,5)
			BEGIN
				UPDATE dbo.SystemSettings WITH (ROWLOCK)
				SET VValue = CONVERT(VARCHAR(200), CONVERT(SMALLINT, VValue) + 1)
				OUTPUT DELETED.VValue INTO @updatedFlag (VValue)
				WHERE VName = @VName

				IF EXISTS (SELECT 1 FROM @updatedFlag WHERE VValue = '0')
				BEGIN
					UPDATE dbo.SystemSettings WITH (ROWLOCK)
					SET VValue = CONVERT(VARCHAR(200), GETDATE(), 121)
					WHERE VName = 'StartMoving_Local'
				END
			END
			ELSE IF @parlay IN (4,6)
			BEGIN
				UPDATE dbo.SystemSettings WITH (ROWLOCK)
				SET VValue = CONVERT(VARCHAR(200), CONVERT(SMALLINT, VValue) - 1)
				OUTPUT INSERTED.VValue INTO @updatedFlag (VValue)
				WHERE VName = @VName

				IF EXISTS (SELECT 1 FROM @updatedFlag WHERE VValue = '0')
				BEGIN
					UPDATE dbo.SystemSettings WITH (ROWLOCK)
					SET VValue = CONVERT(VARCHAR(200), GETDATE(), 121)
					WHERE VName = 'EndMoving_Local'
				END
			END
			ELSE IF @parlay = 7 -- start copying data to [14] and switch movebet day
			BEGIN
				--==check if does not exist then insert
				IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.SystemSettings WHERE VName = 'Movebet_DoneCopy_Local')
				BEGIN
					INSERT INTO dbo.SystemSettings(VName, VValue)
					VALUES('Movebet_DoneCopy_Local', '0')
				END

				UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
				SET VValue = '1'
				WHERE VName = 'Movebet_DoneCopy_Local'

				IF @@SERVERNAME IN ('DB06C2\DB06', 'DB061', 'DB055', 'DB054C2\DB054', 'DB052', 'DB053')
				BEGIN
					EXEC DBTXN.bodb02.dbo.Task_UpdSystemSetting @VName = 'Movebet_ReadyUpdMBDate', @VValue = '1'
				END
				
			END
			ELSE IF @parlay = 8 -- end copying data to [14]
			BEGIN
				UPDATE dbo.SystemSettings WITH (ROWLOCK)
				SET VValue = '0'
				WHERE VName = 'Movebet_DoneCopy_Local'

				IF @@SERVERNAME IN ('DB06C2\DB06', 'DB061', 'DB055', 'DB054C2\DB054', 'DB052', 'DB053')
				BEGIN
					EXEC DBTRANS.bodb02.dbo.Task_UpdSystemSetting @VName = 'Movebet_ReadyUpdMBDate', @VValue = '-1'
				END
				
			END
			ELSE IF @parlay = 9 --prepare movebet day
			BEGIN
				--==check if does not exist then insert
				IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.SystemSettings WHERE VName = 'BeingMovebetDate')
				BEGIN
					--first time
					INSERT INTO dbo.SystemSettings(VName, VValue)
					VALUES('BeingMovebetDate', CONVERT(VARCHAR(10), @winlostdate, 121))
				END

				--==being move bet
				UPDATE dbo.SystemSettings WITH (ROWLOCK)
				SET VValue = CONVERT(VARCHAR(10), @winlostdate, 121)
				WHERE VName = 'BeingMovebetDate'
				
			END
			ELSE IF @parlay = 10 --update new movebet day
			BEGIN
				
				--==update @winlostdate to new movebet day
				UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
				SET VValue = CONVERT(VARCHAR(10), @winlostdate, 121)
				WHERE VName = 'MovebetDate'
				
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

	IF @@SERVERNAME LIKE 'DB04%' OR @@SERVERNAME IN ('DB054', 'DB054C2\DB054', 'DB055')
	BEGIN
		PRINT 'nothing'
	END
	ELSE
	BEGIN
		SET @rowDeleted = 0

		--//for bettrans
		IF @tableName = 'bettrans'
		BEGIN
			WHILE 1 = 1
			BEGIN
				DELETE	@__tmpTransId;

				DELETE TOP (2000)
				FROM dbo.bettrans WITH (ROWLOCK)
				OUTPUT deleted.transid
				INTO @__tmpTransId (id)
				WHERE custid = @custid
					AND	winlostdate = @winlostdate
					AND	bettype < 19999;

				SET @RowDeleted = @@ROWCOUNT;

				-- 20190828@Billy: Add [bettransInfo] table
				DELETE	tbl
				FROM @__tmpTransId AS tmp
				INNER JOIN dbo.BettransInfo AS tbl WITH (ROWLOCK)
						ON	tmp.id = tbl.transid;

				IF @rowDeleted < 2000
					BREAK;
			END
			RETURN
		END
		
		--//for translog
		IF @tableName = 'translog'
		BEGIN
			DELETE TOP (2000) FROM dbo.translog WITH(ROWLOCK)
			WHERE recommend = @recommend AND winlostdate = @winlostdate

			SET @RowDeleted = @@ROWCOUNT

			RETURN
		END

		--//for bettransLC
		IF @tableName = 'bettransLC'
		BEGIN
			DELETE TOP (2000) FROM dbo.bettransLC WITH(ROWLOCK)
			WHERE recommend = @recommend AND winlostdate = @winlostdate  

			SET @RowDeleted = @@ROWCOUNT

			RETURN
		END

		--//for bettransRNG
		IF @tableName = 'bettransRNG'
		BEGIN
			DELETE TOP (2000) FROM dbo.bettransRNG WITH(ROWLOCK)
			WHERE recommend = @recommend AND winlostdate = @winlostdate 

			SET @RowDeleted = @@ROWCOUNT

			RETURN
		END
	END

	IF @parlay = 1
	BEGIN
		IF @tableName = 'bettransM' AND @matchId > 0
		BEGIN
			WHILE 1 = 1
			BEGIN
				DELETE TOP(2000) FROM bettransm WITH(ROWLOCK)
				WHERE matchid = @matchId

				IF @@ROWCOUNT < 2000
					BREAK
			END
		END
		ELSE IF @tableName = 'bettransM' AND @matchId = -1 -- last round
		BEGIN
			DELETE FROM bettransm WITH(ROWLOCK)
			WHERE winlostdate = @winlostdate
		END
	END

	IF @parlay = 2
	BEGIN
		DELETE FROM bettransG WITH(ROWLOCK) WHERE winlostdate = @winlostdate
	END
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/