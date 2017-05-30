/*<info serverAlias="DBPTCS-bodb_PlaytechCS," executers="" viewers="vnteam" isFunction="0" isNested=”0”></info>*/
ALTER PROCEDURE [dbo].[Task_DOT_GoldDeluxe_DailySummary]
	@winlostdate DATETIME
	,@IsManual BIT = 0 
AS
/*   
Created: 20140313@Winnie
Task: Summary GoldDeluxe data and insert into rptDepWinlost_ThirdParty
DB: DBPTCS/bodb_PlaytechCS
Original:
Revisions:	
- 20170116@Francis: Automatically sum data to sum table from raw table when sum range is out of job's range [RedmineID: #68972]
- 20170407@Sophia:  Automatically sum data to Rpt_bettingByProduct [Redmine: #72914]
					Add rule auto regen data :
							1st -> 5th : Can Edit data of Previous month  and current Month
							6th -> end of the month : Edit data of current month only
Param's Explanation:
	- @winlostdate: The date need to summary
*/  
SET NOCOUNT ON
BEGIN TRY	
	DECLARE @ProductId INT
	SELECT @ProductId= ProductId FROM bodb_Licensee.dbo.Product3rd WITH(NOLOCK) WHERE ProductName='Gold Deluxe'
	IF(@ProductId IS NULL)
	BEGIN
	PRINT 'Error occured in Gold Deluxe summary data process does not exist product'
	RETURN
	END
	
	DECLARE @WLDateTab AS TABLE (ID SMALLINT IDENTITY (1,1), winlostdate DATE)
	DECLARE @i SMALLINT = 1
	
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
		 SELECT DISTINCT Winlostdate AS Winlostdate
		 FROM dbo.Product3rd_ImportQueue WITH (NOLOCK)
		 WHERE FinishedTime IS NOT NULL 
			   AND isSummarized = 0 --Winlostdate that has been finished to generate into raw data table bust has not been summarized to sum table
			   AND ProductID = @ProductId) t --GD
	
	CREATE TABLE #TicketData (	custid			INT,								
								currency		INT,							
								turnover		MONEY,							
								winlost			MONEY,	
								drawTO			MONEY,	
								drawBetCount	INT,						
								betCount		INT)
	
	
	WHILE EXISTS (SELECT TOP 1 1 FROM @WLDateTab WHERE ID = @i)
	BEGIN
		SELECT @winlostdate = winlostdate
		FROM @WLDateTab
		WHERE ID = @i
	
		IF @winlostdate >= @MinDate OR @IsManual = 1
		BEGIN 
			TRUNCATE TABLE #TicketData
			
			INSERT INTO #TicketData (custid, currency, turnover,winlost,drawTO,drawBetCount,betCount )
			SELECT b.CustID, 		
					b.currency,				
					ISNULL(SUM(b.Stake),0) AS Turnover,			
					ISNULL(SUM(b.Winlost - b.Stake),0) AS Winlost,	
					ISNULL(SUM(CASE WHEN b.StatusID = 111 THEN b.Stake ELSE 0 END),0) AS DrawTO,	
					ISNULL(SUM(CASE WHEN b.StatusID = 111 THEN 1 ELSE 0 END),0) AS DrawBetCount,	
				ISNULL(COUNT(b.TicketId),0) AS Betcount			

			FROM dbo.bettrans_GoldDeluxe b WITH (ROWLOCK)
			WHERE Winlostdate = @winlostdate AND StatusId IN (111,112,113)
			GROUP BY b.CustID, b.currency
		

			-- Insert data to rptDepWinlost_ThirdParty
			DELETE FROM bodb_LicenseeReport.dbo.rptDepWinlost_ThirdParty WITH (ROWLOCK) WHERE Winlostdate = @winlostdate and ProductId=@ProductId

			INSERT INTO bodb_LicenseeReport.dbo.rptDepWinlost_ThirdParty (winlostdate, custid, currency, turnover,
																winlost,drawTO,drawBetCount, BetCount,ProductId)
			SELECT @winlostdate, custid,  currency, turnover,
				winlost,drawTO,drawBetCount,  BetCount, @ProductId
			FROM #TicketData
					
			-- Insert data to rpt_BettingByProduct
			
			-- Insert data to rpt_BettingByProduct
			EXEC bodb_LicenseeReport.dbo.GEN_rptBettingByProduct @date = @WinlostDate, @date2 = @WinlostDate, @DataSource = 'SeparatedProduct' , @SeparatedProductID = 11
		
					
			---Update flag isSummarized to queue  
			UPDATE dbo.Product3rd_ImportQueue WITH (UPDLOCK, ROWLOCK)
			SET isSummarized = 1
			WHERE Winlostdate = @winlostdate AND isSummarized = 0
				AND ProductID = @ProductId
		END 
		
		SELECT @i = @i + 1
	END
	

	DROP TABLE #TicketData
END TRY
BEGIN CATCH
	-- This SPs called from another SP in rptDepwinlost Summary process, failure of this SP should not affect to that process
	--RAISERROR(15000,1,1,'Error occured in summarizing AG Casino data.')
	PRINT 'Error occured in Gold Deluxe summary data process: ERR_CODE: '+ CAST(ERROR_NUMBER() AS VARCHAR(20)) + ', ERR_MSG: ' + ERROR_MESSAGE()
	RETURN
END CATCH