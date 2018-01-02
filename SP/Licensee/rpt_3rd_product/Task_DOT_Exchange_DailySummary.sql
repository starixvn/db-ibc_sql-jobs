/*<info serverAlias="DBLIC-bodb_3rdproduct," executers="" viewers="vnteam" isFunction="0" isNested=”0”></info>*/

ALTER PROCEDURE [dbo].[Task_DOT_Exchange_DailySummary]
	@winlostdate DATETIME	
	,@IsManual BIT = 0 
AS
/*   
	Created: 20171220@Harper
	Task: Summary Exchange data and insert into rptDepWinlost_ThirdParty
	DB: DBLIC/bodb_3rdproduct
	Original:
	Revisions:	
		- 20171220@Harper: Create new SP [RedmineID: #86640]
	
	Param's Explanation:
		- @winlostdate: The date need to summary
		- @IsManual: task run manual or auto

	EXEC Task_DOT_Exchange_DailySummary @winlostdate = '2017-12-11'
*/  
SET NOCOUNT ON

BEGIN TRY	
	DECLARE @ProductId INT

	SELECT @ProductId = ProductId 
	FROM bodb_Licensee.dbo.Product3rd WITH(NOLOCK) 
	WHERE ProductName = 'Exchange'

	IF(@ProductId IS NULL)
	BEGIN
		PRINT 'Error occured in Exchange summary data process does not exist product'
		RETURN
	END
	
	DECLARE @WLDateList AS TABLE (ID SMALLINT IDENTITY (1,1), Winlostdate DATE)
	DECLARE @ResettledDateList AS TABLE (ID BIGINT, WinlostDate DATE)
	DECLARE @i SMALLINT = 1
	
	-- #Region: Get minimum date that can be regen data
	DECLARE @Day TINYINT, @MinDate DATE, @Today DATE 
	SELECT @Today = GETDATE()
	SELECT @Day = DAY(@Today)
	IF @Day <= 5 --- 1st -> 5th of the month
	BEGIN 
		SELECT @MinDate = DATEADD(mm, DATEDIFF(mm, 0, GETDATE()) - 1, 0)  ----- FirstOfPreviousMonth 
	END
	ELSE
	BEGIN 
		SELECT @MinDate =  DATEADD(mm, DATEDIFF(mm, 0, GETDATE()), 0) --- FirstOfCurrentMonth
	END
	-- #EndRegion: Get minimum date that can be regen data

	-- #Region: Get date range to summarize data
	INSERT INTO @ResettledDateList ( ID, WinlostDate )
	SELECT h.ID, h.WinlostDate
	FROM dbo.Product3rd_SummarizedDateHistory h WITH (NOLOCK)
	WHERE h.ProductID = @ProductId AND h.SumToThirdPartyDate IS NULL

	INSERT INTO @WLDateList
	SELECT DISTINCT (t.winlostdate)
	FROM (
			SELECT CAST(@winlostdate AS DATE) AS Winlostdate
			UNION ALL
			SELECT DISTINCT WinlostDate AS Winlostdate
			FROM @ResettledDateList
		 )t	
	-- #EndRegion: Get date range to summarize data
	
	CREATE TABLE #TicketData (	Custid			INT,								
								CurrencyID		INT,
								ExVirtualRate	FLOAT,
								UserID			VARCHAR(20),
								EventID			INT,
								MarketID		VARCHAR(50),							
								Turnover		MONEY,							
								Winlost			MONEY,	
								DrawTO			MONEY,	
								DrawBetCount	INT,						
								BetCount		INT,
								ValidBetAmount	MONEY,
								CommissionP		MONEY,
								CommissionA		MONEY
							)
							
	CREATE TABLE #DetailData (	
								UserID			VARCHAR(20),
								EventID			INT,
								MarketID		VARCHAR(50),
								DrawTO			MONEY,	
								DrawBetCount	INT,						
								BetCount		INT,
								Lay				MONEY,
								Back			MONEY
							)	
	
	WHILE EXISTS (SELECT TOP 1 1 FROM @WLDateList WHERE ID = @i)
	BEGIN
		SELECT @winlostdate = winlostdate
		FROM @WLDateList
		WHERE ID = @i
	
		IF @winlostdate >= @MinDate OR @IsManual = 1
		BEGIN 
			TRUNCATE TABLE #TicketData
			
			INSERT INTO #TicketData (custid, CurrencyID, ExVirtualRate, UserID, EventID, MarketID
									, Turnover, Winlost, CommissionP, CommissionA )
			SELECT b.CustID, b.Currency, b.ExVirtualRate, b.userId, b.eventID, b.marketID
				, SUM(b.stakeTotal * 1/b.ExVirtualRate), SUM(b.marketTotal * 1/b.ExVirtualRate)
				, SUM(b.commission * 1/b.ExVirtualRate), SUM(b.agentCommission * 1/b.ExVirtualRate)
			FROM dbo.Sum_winloss_Exchange b WITH (NOLOCK)
			WHERE CONVERT(DATE, b.settledDate) = @winlostdate
			GROUP BY b.CustID, b.currency, b.ExVirtualRate, b.userId, b.eventID, b.marketID

			INSERT INTO #DetailData( UserID ,EventID ,MarketID ,BetCount  ,DrawBetCount ,DrawTO ,Lay ,Back )			
			SELECT d.userId, d.eventID, d.marketID
				, COUNT(*) AS Betcount
				, SUM(CASE WHEN d.profitLoss = 0 THEN 1 ELSE 0 END) AS DrawBetCount
				, SUM(CASE WHEN d.profitLoss = 0 THEN (d.matchStake * 1/b.ExVirtualRate) ELSE 0 END) AS DrawTO
				, SUM(CASE WHEN d.matchType = 'Lay' THEN (d.matchStake * 1/b.ExVirtualRate) ELSE 0 END) AS Lay
				, SUM(CASE WHEN d.matchType = 'Back' THEN (d.matchStake * 1/b.ExVirtualRate) ELSE 0 END) AS Back
			FROM dbo.Bettrans_Exchange d WITH (NOLOCK)
				INNER JOIN #TicketData b ON d.userId = b.userId AND d.eventID = b.eventID AND d.marketID = b.marketID
			WHERE d.betstatus = 'Settled'				
			GROUP BY d.userId, d.eventID, d.marketID

			UPDATE b
			SET b.BetCount = ISNULL(d.BetCount, 0),
				b.DrawBetCount = ISNULL(d.DrawBetCount, 0),
				b.DrawTO = ISNULL(d.DrawTO, 0),
				b.ValidBetAmount = ABS(ISNULL(d.Lay, 0) - ISNULL(d.Back, 0))
			FROM #TicketData b
				INNER JOIN #DetailData d ON d.userId = b.userId AND d.eventID = b.eventID AND d.marketID = b.marketID

			-- Insert data to rptDepWinlost_ThirdParty
			DELETE FROM bodb_LicenseeReport.dbo.rptDepWinlost_ThirdParty WITH (ROWLOCK) 
			WHERE Winlostdate = @winlostdate AND ProductId = @ProductId

			INSERT INTO bodb_LicenseeReport.dbo.rptDepWinlost_ThirdParty (winlostdate, custid, currency, ProductId,
														 turnover, Winlost, drawTO, drawBetCount, BetCount, 
														 CommissionP, CommissionA, ValidBetAmount)
			SELECT @winlostdate, custid, CurrencyID, @ProductId
					, SUM(turnover), SUM(Winlost), SUM(DrawTO), SUM(DrawBetCount), SUM(BetCount)
					, SUM(CommissionP), SUM(CommissionA), SUM(ValidBetAmount)				
			FROM #TicketData					
			GROUP BY Custid, CurrencyID

			--- Update info for summarize
			UPDATE h
			SET SumToThirdPartyDate = GETDATE()				
			FROM dbo.Product3rd_SummarizedDateHistory h
			WHERE h.WinlostDate = @winlostdate
				AND EXISTS (SELECT 1 
							FROM @ResettledDateList d 
							WHERE h.ID = d.ID
							)
		END 
				
		SELECT @i = @i + 1
	END
	
	DROP TABLE #TicketData
END TRY

BEGIN CATCH
	-- This SPs called from another SP in rptDepwinlost Summary process, failure of this SP should not affect to that process
	PRINT 'Error occured in Exchange summary data process: ERR_CODE: '+ CAST(ERROR_NUMBER() AS VARCHAR(20)) + ', ERR_MSG: ' + ERROR_MESSAGE()
	RETURN
END CATCH