/*<info serverAlias="DBAGE-bodb_AGE" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_CDC_bettrans_compact_checkNotify]
AS
/*
	Created by: 20231201@Bobby
	Task: 153357 - Alpha - CDC bettrans_compact - check SUMDATA Notify
	DB: DBAGE.bodb_AGE
	Revisions:
		- 20231201@Bobby:  Implement bettrans_compact Redmine: [#153357]
		- 20240321@Bobby:  checkSum remove extraWinloss vs extraComm Redmine: [#200041]
		- 20240401@Bobby:  Fix bug checkNotify & Correct Redmine: [#202655]
		- 20240506@Bobby:  Enhance code to avoid deadlock Redmine: [#204799]
		- 20240522@Bobby: Enhance checkSum process [RedmineID: #205378]
*/
BEGIN

	SET NOCOUNT ON;

	DECLARE @checkDate SMALLDATETIME, @toDay SMALLDATETIME, @lastJobRun DATETIME;
	DECLARE @moveBetsDay SMALLDATETIME, @notifyTime DATETIME

	EXEC bodb02.dbo.NAP_Admin_GetMovebetDate @MovebetDate = @moveBetsDay OUTPUT
	SELECT @checkDate	= DATEADD(DAY, 1, @moveBetsDay)
		,@toDay			= CAST(GETDATE() AS DATE);

	SELECT TOP(1) @lastJobRun = JSON_VALUE(VValue, '$.lastRun')
	FROM bodb_AGE.dbo.SystemSettings WITH(NOLOCK)
	WHERE VName='Age_cdc_bettrans_compact'
	;

	DROP TABLE IF EXISTS #tmpNotify;
	SELECT custid, winlostdate, checkSumKey, checkSumData, COUNT(1) AS diffCount, MIN(createdTime) AS FromTime, MAX(createdTime) AS ToTime
	INTO #tmpNotify
	FROM dbo.bettrans_compact_checkSum WITH(NOLOCK)
	WHERE winlostdate BETWEEN @checkDate AND @toDay AND notifyStatus = 0
		AND DATEDIFF(SECOND, @lastJobRun, GETDATE()) < 60 -- 1 minute. Check the Job is running OR NOT.
	GROUP BY custid, winlostdate, checkSumKey, checkSumData
	HAVING COUNT(1) >= 2 -- exist diff value through 1 hour

	--TODO: Send notification IF any
	IF EXISTS(SELECT TOP 1 1 FROM #tmpNotify)
	BEGIN
		
		SELECT @notifyTime = GETDATE();

		-- Mark @notifyTime
		UPDATE ck
		SET createdTime = @notifyTime
		FROM dbo.bettrans_compact_checkSum ck WITH(ROWLOCK, UPDLOCK)
		INNER JOIN #tmpNotify tmp ON tmp.custid = ck.custid
			AND tmp.winlostdate = ck.winlostdate
			AND tmp.checkSumKey = ck.checkSumKey
		WHERE ck.notifyStatus = 0;

		--TODO: correct data --> notifyStatus = 2 IF corrected
		EXEC [dbo].[Task_CDC_bettrans_compact_CorrectData] @notifyTime = @notifyTime

		--SEND mail IF any rows
		IF EXISTS (
			SELECT 1 FROM dbo.bettrans_compact_checkSum ck WITH(NOLOCK)
			INNER JOIN #tmpNotify tmp ON tmp.custid = ck.custid
				AND tmp.winlostdate = ck.winlostdate
				AND tmp.checkSumKey = ck.checkSumKey
			WHERE ck.notifyStatus = 0
				AND ck.createdTime = @notifyTime
		)
		BEGIN

			-- Mark notifyStatus
			UPDATE ck
			SET ck.notifyStatus = 1
			FROM dbo.bettrans_compact_checkSum ck WITH(ROWLOCK, UPDLOCK)
			INNER JOIN #tmpNotify tmp ON tmp.custid = ck.custid
				AND tmp.winlostdate = ck.winlostdate
				AND tmp.checkSumKey = ck.checkSumKey
			WHERE ck.notifyStatus = 0
				AND ck.createdTime = @notifyTime;

			DECLARE @subject VARCHAR(1000), @notify VARCHAR(4000), @recipients VARCHAR(1000);
			SELECT @subject = CONCAT(@@SERVERNAME, '_', db_name(), '_bettrans_compact CHECK SUM diff data found')
				, @recipients = 'dbaadmin@starixsoft.com';

			WITH CTE_Notify AS (
				SELECT ck.winlostdate, MIN(tmp.FromTime) AS FromTime, MAX(tmp.ToTime) AS ToTime
				FROM #tmpNotify tmp
				INNER JOIN dbo.bettrans_compact_checkSum ck WITH(NOLOCK) ON tmp.custid = ck.custid
					AND tmp.winlostdate = ck.winlostdate
					AND tmp.checkSumKey = ck.checkSumKey
				WHERE ck.notifyStatus = 1
					AND ck.createdTime = @notifyTime
				GROUP BY ck.winlostdate
			) 
			SELECT @notify = STRING_AGG(notify, ',')
			FROM (
				SELECT '[SELECT * FROM dbo.bettrans_compact_checkSum WITH(NOLOCK)
				WHERE winlostdate=''' + FORMAT(winlostdate, 'yyyy-MM-dd') + '''
					AND createdTime >= ''' + FORMAT(@notifyTime, 'yyy-MM-dd HH:mm:00')  + '''
					AND notifyStatus=1]'
				FROM CTE_Notify
			) AS t (notify)

			--SELECT @notify
			RAISERROR (@notify, 0, 1) WITH NOWAIT;

			EXEC msdb.dbo.sp_send_dbmail @recipients = @recipients
			, @body						= @notify
			, @sensitivity				= 'Personal'
			, @importance				= 'Normal'
			, @copy_recipients			= ''
			, @blind_copy_recipients	= ''
			, @subject					= @subject
			, @profile_name				= default
		END

	END

	--DELETE old rows
	DECLARE @checkTimeToDelete DATETIME = DATEADD(DAY, -1, GETDATE())
	DELETE ck
	FROM dbo.bettrans_compact_checkSum ck WITH(ROWLOCK)
	WHERE ck.createdTime < @checkTimeToDelete;


	--DELETE old rows bettrans_compact
	DECLARE @loopCount INT, @rTotal INT, @delCount INT, @delRows INT, @fromCount INT;
	DROP TABLE IF EXISTS #tmpCust;
	CREATE TABLE #tmpCust (rIdx INT IDENTITY(1, 1) PRIMARY KEY, custid INT, winlostdate SMALLDATETIME, rCount INT);

	INSERT INTO #tmpCust(custid, winlostdate, rCount)
	SELECT custid, winlostdate, COUNT(1) AS rCount
	FROM dbo.bettrans_compact del WITH(NOLOCK)
	WHERE del.winlostdate < @moveBetsDay
	GROUP BY custid, winlostdate;
	SET @rTotal = @@ROWCOUNT;

	SELECT @loopCount = 100, @delCount = 3000;
	
	SET DEADLOCK_PRIORITY LOW;
	WHILE(@loopCount <= @rTotal)
	BEGIN
		SET @fromCount = (@loopCount - 100)+1;

		DELETE TOP(@delCount) del
		FROM dbo.bettrans_compact del 
		INNER JOIN #tmpCust tmp ON tmp.custid = del.custid AND tmp.winlostdate = del.winlostdate
		WHERE tmp.rIdx BETWEEN @fromCount AND @loopCount;
		SET @delRows = @@ROWCOUNT;

		IF @delRows = 0 AND @loopCount >= @rTotal
			BREAK;

		--print concat('--> runnning ->> @loopCount: ', @loopCount, ' / ', @rTotal)
		SET @loopCount += IIF(@delRows = 0, 100, 0)
		SET @loopCount = IIF(@loopCount > @rTotal, @rTotal, @loopCount)
	END
END
GO