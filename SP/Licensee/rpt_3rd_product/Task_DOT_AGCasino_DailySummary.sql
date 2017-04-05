/*<info serverAlias="DBTXN-bodb02,DBPRO-bodb02" executers="bodbAdminNet,bodbDownlineNet" viewers="vnteam" isFunction="0|1" isNested=”0|1”></info>*/
ALTER PROCEDURE [dbo].[Task_DOT_AGCasino_DailySummary]
	@winlostdate DATETIME
AS
/*   
Created: 20140911@Victor
Task: Summary AG Casino data and insert into rptDepWinlost_AGCasino
DB: DBACC/bodb02
Original:
Revisions:
	- 20141017@Victor: remove RAISEERROR statement to avoid affection to rptDepWinlost Summary job
	- 20141121@Don: Adjustment to serve to change KeenOcean's currency RMB to HK$
	- 20151005@Don: Add filter by status
	- 20170116@Francis: Automatically sum data to sum table from raw table when sum range is out of job's range [RedmineID: #68972]
Param's Explanation:
	- @winlostdate: The date need to summary
*/  
SET NOCOUNT ON
BEGIN TRY

	DECLARE @BackupDay DATE
	SELECT @BackupDay = ISNULL(MIN(Winlostdate),'') FROM DBPTCS.bodb_PlaytechCS.dbo.bettrans_AGCasino
	
	DECLARE @WLDateTab AS TABLE (ID SMALLINT IDENTITY (1,1), winlostdate DATE)
	DECLARE @i SMALLINT = 1, @SqlStr VARCHAR (1000) = ''
	
	INSERT INTO @WLDateTab
	SELECT DISTINCT (t.winlostdate)
	FROM
		(SELECT CAST(@winlostdate AS DATE) AS Winlostdate
		 UNION ALL
		 SELECT * FROM
		 OPENQUERY (DBPTCS, 'SELECT DISTINCT Winlostdate AS Winlostdate
		 FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (NOLOCK)
		 WHERE FinishedTime IS NOT NULL 
			   AND isSummarized = 0 
			   AND ProductID = 10')) t  
	
	CREATE TABLE #TicketData (	custid			INT,
								sporttype		SMALLINT,
								currency		INT,
								isVipGame		INT,
								turnover		MONEY,
								drawTO			MONEY,
								winlost			MONEY,
								playercomm		MONEY,
								betCount		INT,
								drawBetCount	INT)
	WHILE EXISTS (SELECT TOP 1 1 FROM @WLDateTab WHERE ID = @i)
	BEGIN
		
		SELECT @winlostdate = winlostdate
		FROM @WLDateTab
		WHERE ID = @i
	
		TRUNCATE TABLE #TicketData
		
		IF @winlostdate >= @BackupDay -- Get data in bettrans_AGCasino table
		BEGIN
			INSERT INTO #TicketData (custid, sporttype, currency, isVipGame, turnover, drawTO, winlost, playercomm, betCount, drawBetCount)
			SELECT b.CustID, 
				250 AS SportType,
				b.currency,
				isVIPGame,
				ISNULL(SUM(b.Stake),0) AS Turnover,
				ISNULL(SUM(CASE WHEN b.StatusID = 111 THEN b.Stake ELSE 0 END),0) AS DrawTO,
				ISNULL(SUM(b.Winlost - b.Actual_Stake),0) AS Winlost,
				0 AS PlayerComm,
				ISNULL(COUNT(*),0) AS Betcount,
				ISNULL(SUM(CASE WHEN b.StatusID = 111 THEN 1 ELSE 0 END),0) AS DrawBetCount
			FROM DBPTCS.bodb_PlaytechCS.dbo.bettrans_AGCasino b WITH (ROWLOCK)
			WHERE Winlostdate = @winlostdate
				AND StatusId IN (111, 112, 113)
			GROUP BY b.CustID, b.currency, isVIPGame
		END
		ELSE -- Get data in bettrans_AGCasino_bk table
		BEGIN
			INSERT INTO #TicketData (custid, sporttype, currency, isVipGame, turnover, drawTO, winlost, playercomm, BetCount, drawBetCount)
			SELECT b.CustID, 
				250 AS SportType,
				b.currency,
				isVIPGame,
				ISNULL(SUM(b.Stake),0) AS Turnover,
				ISNULL(SUM(CASE WHEN b.StatusID = 111 THEN b.Stake ELSE 0 END),0) AS DrawTO,
				ISNULL(SUM(b.Winlost - b.Actual_Stake),0) AS Winlost,
				0 AS PlayerComm,
				ISNULL(COUNT(*),0) AS Betcount,
				ISNULL(SUM(CASE WHEN b.StatusID = 111 THEN 1 ELSE 0 END),0) AS DrawBetCount
			FROM bodb_archive.dbo.bettrans_AGCasino_bk b WITH (ROWLOCK)
			WHERE Winlostdate = @winlostdate
				AND StatusId IN (111, 112, 113)
			GROUP BY b.CustID, b.currency, isVIPGame
		END
		
		--Insert data to rptDepWinlost_AGCasino
		DELETE FROM bodb_report.dbo.rptDepWinlost_AGCasino WHERE Winlostdate = @winlostdate

		INSERT INTO bodb_report.dbo.rptDepWinlost_AGCasino (winlostdate, custid, sporttype, currency, turnover, drawTO, 
															winlost, playercomm, BetCount, drawBetCount, IsVIPGame)
		SELECT @winlostdate, custid, sporttype, currency, turnover, drawTO, 
			winlost, playercomm, BetCount, drawBetCount, IsVIPGame
		FROM #TicketData
		
		SET @SqlStr = 'UPDATE bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (UPDLOCK, ROWLOCK)
		SET isSummarized = 1
		WHERE Winlostdate = ''' + CONVERT(VARCHAR(20),@winlostdate,112) + ''' AND isSummarized = 0
			AND ProductID = 10;'
			
		EXEC(@SqlStr) AT [DBPTCS];
		
		SELECT @i = @i + 1	
	END

	DROP TABLE #TicketData
END TRY
BEGIN CATCH
	-- This SPs called from another SP in rptDepwinlost Summary process, failure of this SP should not affect to that process
	--RAISERROR(15000,1,1,'Error occured in summarizing AG Casino data.')
	PRINT 'Error occured in AGCasino summary data process: ERR_CODE: '+ CAST(ERROR_NUMBER() AS VARCHAR(20)) + ', ERR_MSG: ' + ERROR_MESSAGE()
	RETURN
END CATCH