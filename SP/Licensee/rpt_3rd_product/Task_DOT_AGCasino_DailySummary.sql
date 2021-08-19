/*<info serverAlias="DBACC-bodb02,DBBAL-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_DOT_AGCasino_DailySummary]
	@winlostdate DATETIME
	,@IsManual BIT = 0
	,@GenForDataWarehouse BIT = 0 
AS
/*   
	Created: 20140911@Victor
	Task: Summary AG Casino data and insert into rptDepWinlost_AGCasino
	DB: DBACC/bodb02

	Revisions:
		- 20141017@Victor: remove RAISEERROR statement to avoid affection to rptDepWinlost Summary job
		- 20141121@Don: Adjustment to serve to change KeenOcean's currency RMB to HK$
		- 20151005@Don: Add filter by status
		- 20170116@Francis: Automatically sum data to sum table from raw table when sum range is out of job's range [RedmineID: #68972]
		- 20170407@Sophia:: Add rule auto regen data : [Redmine: #72914]
								1st -> 5th : Can Edit data of Previous month  and current Month
								6th -> end of the month : Edit data of current month only
		- 20190911@Kean: LAP Analytics Tool - Add new param to generate data for DataWarehouse [RedmineID: #117689]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
	Param's Explanation:
		- @winlostdate: The date need to summary
		- @IsManual: task run manual or auto
		- @GenForDataWarehouse: Flag to generate for DataWarehouse
*/  
SET NOCOUNT ON
BEGIN TRY

	--Used as metadata for SSIS in DataWarahouse
	IF 1 = 2
	BEGIN
		SELECT CAST(NULL AS DATE) [Winlostdate]
			,CAST(NULL AS INT) [Custid]
			,CAST(NULL AS INT) [Sporttype]
			,CAST(NULL AS INT) [Currency]
			,CAST(NULL AS MONEY) [Turnover]
			,CAST(NULL AS MONEY) [DrawTO]
			,CAST(NULL AS MONEY) [Winlost]
			,CAST(NULL AS MONEY) [Playercomm]
			,CAST(NULL AS INT) [BetCount]
			,CAST(NULL AS INT) [DrawBetCount]
			,CAST(NULL AS BIT) [IsVIPGame]
	END

	DECLARE @BackupDay DATE
	SELECT @BackupDay = ISNULL(MIN(Winlostdate),'') FROM DBPTCS.bodb_PlaytechCS.dbo.bettrans_AGCasino
	
	DECLARE @WLDateTab AS TABLE (ID SMALLINT IDENTITY (1,1), winlostdate DATE)
	DECLARE @i SMALLINT = 1, @SqlStr VARCHAR (1000) = ''
	
	DECLARE @Day TINYINT, @MinDate DATE 
	SELECT @Day = DAY(GETDATE())
	IF @Day <= 5 --- 1st -> 5th of the month
	BEGIN 
		SELECT @MinDate = DATEADD(mm, DATEDIFF(mm, 0, GETDATE()) - 1, 0)  ----- FirstOfPreviousMonth 
	END
	ELSE
	BEGIN 
		SELECT @MinDate =  DATEADD(mm, DATEDIFF(mm, 0, GETDATE()), 0) --- FirstOfCurrentMonth
	END
		
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
	CREATE TABLE #TicketDataForDataWarehouse (	
								[Winlostdate] DATE
								,[Custid] INT
								,[Sporttype] INT
								,[Currency] INT
								,[Turnover] MONEY
								,[DrawTO] MONEY
								,[Winlost] MONEY
								,[Playercomm] MONEY
								,[BetCount] INT
								,[DrawBetCount] INT
								,[IsVIPGame] BIT)

	WHILE EXISTS (SELECT TOP 1 1 FROM @WLDateTab WHERE ID = @i)
	BEGIN
		
		SELECT @winlostdate = winlostdate
		FROM @WLDateTab
		WHERE ID = @i
	
		IF @winlostdate >= @MinDate OR @IsManual = 1
		BEGIN 
		
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
			IF @@SERVERNAME <> 'DBBAL' 
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
			
			-- Check flag when insert to sum table	  
			IF @GenForDataWarehouse = 0
			BEGIN
				--Insert data to rptDepWinlost_AGCasino
				DELETE FROM bodb_report.dbo.rptDepWinlost_AGCasino WITH (ROWLOCK) WHERE Winlostdate = @winlostdate

				INSERT INTO bodb_report.dbo.rptDepWinlost_AGCasino (winlostdate, custid, sporttype, currency, turnover, drawTO, 
																	winlost, playercomm, BetCount, drawBetCount, IsVIPGame)
				SELECT @winlostdate, custid, sporttype, currency, turnover, drawTO, 
					winlost, playercomm, BetCount, drawBetCount, IsVIPGame
				FROM #TicketData					
		
				SET @SqlStr = 'UPDATE bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (UPDLOCK, ROWLOCK)
				SET isSummarized = 1
				WHERE Winlostdate = ''' + CONVERT(VARCHAR(20),@winlostdate,112) + ''' AND isSummarized = 0
					AND ProductID = 10;'
				
				EXEC(@SqlStr) AT [DBPTCS]
			END
			ELSE
			BEGIN
				INSERT INTO #TicketDataForDataWarehouse([Winlostdate],[Custid],[Sporttype],[Currency],[Turnover],[DrawTO],[Winlost],[Playercomm]
														,[BetCount],[DrawBetCount],[IsVIPGame])
				SELECT @winlostdate [Winlostdate], custid [Custid], sporttype [Sporttype], currency [Currency], turnover [Turnover], drawTO [DrawTO], 
					winlost [Winlost], playercomm [Playercomm], BetCount [BetCount], drawBetCount [DrawBetCount], IsVIPGame [IsVIPGame]
				FROM #TicketData
			END
			
		END
		SELECT @i = @i + 1	
	END

		-- Output Data For DataWarehouse	  
	IF @GenForDataWarehouse = 1
	BEGIN
		SELECT [Winlostdate],[Custid],[Sporttype],[Currency],[Turnover],[DrawTO],[Winlost],[Playercomm]
														,[BetCount],[DrawBetCount],[IsVIPGame]
		FROM #TicketDataForDataWarehouse
	END

	DROP TABLE #TicketDataForDataWarehouse
	DROP TABLE #TicketData
END TRY
BEGIN CATCH
	-- This SPs called from another SP in rptDepwinlost Summary process, failure of this SP should not affect to that process
	--RAISERROR(15000,1,1,'Error occured in summarizing AG Casino data.')
	PRINT 'Error occured in AGCasino summary data process: ERR_CODE: '+ CAST(ERROR_NUMBER() AS VARCHAR(20)) + ', ERR_MSG: ' + ERROR_MESSAGE()
	RETURN
END CATCH
GO
GRANT EXECUTE ON [dbo].[Task_DOT_AGCasino_DailySummary] TO [dwrs2] AS [dbo]