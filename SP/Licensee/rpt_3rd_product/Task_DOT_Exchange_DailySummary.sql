/*<info serverAlias="DBLIC-bodb_3rdproduct,DBBAL-bodb_3rdproduct" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DOT_Exchange_DailySummary]
	@winlostdate	DATETIME	
	,@IsManual		BIT = 0
	,@GenForDataWarehouse INT = 0 
AS
/*   
	Created: 20171220@Harper
	Task: Summary Exchange data and insert into rptDepWinlost_ThirdParty
	DB: DBLIC-bodb_3rdproduct, DBBAL-bodb_3rdproduct
	
	Revisions:	
		- 20171220@Harper: Create new SP [RedmineID: #86640]
		- 20180528@Sophia: Gen data into new table rptDepWinlost_ThirdParty_Performance for Nap report performance [redmine: #93582]
		- 20181212@Bruce: New Games Sicbo & Bidme - Add bettype [#102624]
		- 20190625@Percy: Temporary adding DBLIC on OAS_ChargeInfo and related functions [RedmineID: #103658]
		- 20190724@Percy: Remove DBLIC on OAS_ChargeInfo and related functions [RedmineID: #103658]
		- 20190911@Kean: LAP Analytics Tool - Add new param to generate data for DataWarehouse [RedmineID: #117689]
		- 20200818@Percy: Change EventType's data type from smallint to int [RedmineID: #138524]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
		- 20230619@Malcolm: Get Event and Event Type [Redmine: #189536]
		- 20230710@Malcolm: Sum data for @GenForDataWarehouse = 1 [Redmine: #189536]
		- 20231106@Malcolm: Add Market Name [Redmine: #195271]
		- 20240301@Sophia: Exchange product - Get PT from new table on NAP system [RedmineID: #201169]

	Param's Explanation:
		- @winlostdate: The date need to summary
		- @IsManual: task run manual or auto

	EXEC Task_DOT_Exchange_DailySummary @winlostdate = '2017-12-11'
*/  
SET NOCOUNT ON

BEGIN TRY
	
	DECLARE @ProductId INT, @i SMALLINT = 1, @WLDate DATE

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
		
	-- #Region: Get minimum date that can be regen data
	DECLARE @Day TINYINT, @MinDate DATE, @Today DATE 
	SELECT @Today = GETDATE()
	SELECT @Day = DAY(@Today)
	IF @Day <= 5 --- 1st -> 5th of the month
	BEGIN 
		SELECT @MinDate = DATEADD(mm, DATEDIFF(mm, 0, GETDATE()) - 1, 0)  -- FirstOfPreviousMonth 
	END
	ELSE
	BEGIN 
		SELECT @MinDate =  DATEADD(mm, DATEDIFF(mm, 0, GETDATE()), 0) -- FirstOfCurrentMonth
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

	-- #Region: Get charge rate to caculate WinLostA
	DECLARE @fdate DATE, @tDate DATE
	SELECT @fdate = MIN(Winlostdate) FROM @WLDateList
	SELECT @tDate = MAX(Winlostdate) FROM @WLDateList
	
	CREATE TABLE #LicenseeExchangePT (LicenseeName VARCHAR(50), CurrencyId INT, PT MONEY, FromDate DATE, ToDate DATE)
		
	CREATE TABLE #TicketData (	Custid			INT,	
								SiteID			INT,
								LicenseeName	VARCHAR(50),							
								CurrencyID		INT,
								ExVirtualRate	FLOAT,
								UserID			VARCHAR(20),
								EventID			INT,
								EventName		NVARCHAR(500),
								MarketID		VARCHAR(50),							
								Turnover		MONEY,							
								Winlost			MONEY,	
								WinLostA		MONEY,
								DrawTO			MONEY,	
								DrawBetCount	INT,						
								BetCount		INT,
								ValidBetAmount	MONEY,
								CommissionP		MONEY,
								CommissionA		MONEY,
								EventTypeName   NVARCHAR(50), 
								EventType 		INT,
								MarketName	    VARCHAR(500)
							)
							
	CREATE TABLE #DetailData (	
								UserID			VARCHAR(20),
								EventID			INT,
								MarketID		VARCHAR(50),
								DrawTO			MONEY,	
								DrawBetCount	INT,						
								BetCount		INT,
								Lay				MONEY,
								Back			MONEY,
								EventTypeName   NVARCHAR(50),
								EventType 		INT,
								MarketName	    VARCHAR(500)
							)
	
	CREATE TABLE #TicketDataForDataWarehouse (
								[Winlostdate] DATE
								,[Custid] INT
								,[Currency] INT
								,[ProductId] INT
								,[Turnover] MONEY
								,[Winlost] MONEY
								,[WinLostA] MONEY
								,[DrawTO] MONEY
								,[DrawBetCount] INT
								,[BetCount] INT
								,[CommissionP] MONEY
								,[CommissionA] MONEY
								,[ValidBetAmount] MONEY	
								,[Bettype] SMALLINT
								,EventId INT
								,EventName NVARCHAR(500)
								,EVentType INT
								,EventTypeName NVARCHAR(50)
								,MarketName	VARCHAR(500)
							)	

	WHILE EXISTS (SELECT TOP 1 1 FROM @WLDateList WHERE ID = @i)
	BEGIN
		SELECT @WLDate = winlostdate
		FROM @WLDateList
		WHERE ID = @i		
		
		TRUNCATE TABLE #LicenseeExchangePT 
		
		INSERT INTO #LicenseeExchangePT (LicenseeName, CurrencyId, PT)	 
		SELECT 	c.site as LicenseeName, c.Currency as CurrencyId, s.PT
		FROM 	bodb02.dbo.Dep_ChargeInfoSetting s WITH (NOLOCK) 
			INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) 
				ON c.CustId = s.CustId 
		WHERE s.Sporttype = 221 AND @WLDate BETWEEN s.FromDate AND s.ToDate
	
		IF @WLDate >= @MinDate OR @IsManual = 1
		BEGIN 
			TRUNCATE TABLE #TicketData
			
			INSERT INTO #TicketData (custid, SiteID, LicenseeName, CurrencyID, ExVirtualRate, UserID, EventID, EventName, MarketID
									, Turnover, Winlost, CommissionP, CommissionA)
			SELECT b.CustID, ISNULL(site.SiteID,-1) as SiteId, c.site as LicenseeName, b.Currency, b.ExVirtualRate, b.userId, b.eventID, b.eventName, b.marketID
				, SUM(ISNULL(b.stakeTotal,0) * 1/b.ExVirtualRate), SUM(ISNULL(b.marketTotal,0) * 1/b.ExVirtualRate)
				, SUM(ISNULL(b.commission,0) * 1/b.ExVirtualRate), SUM(ISNULL(b.agentCommission,0) * 1/b.ExVirtualRate)				
			FROM dbo.Sum_winloss_Exchange b WITH (NOLOCK)
				LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.Custid = b.CustID AND c.roleid = 1
				LEFT JOIN bodb02.dbo.Site ibcsite WITH (NOLOCK) ON c.site=ibcsite.site
				LEFT JOIN bodb_licensee.dbo.view_site_list [site] WITH (NOLOCK) ON ibcsite.siteid=site.IbcSiteID
			WHERE CONVERT(DATE, b.settledDate) = @WLDate
			GROUP BY b.CustID, ISNULL(site.SiteID,-1), b.currency, b.ExVirtualRate, b.userId, b.eventID, b.eventName, b.marketID

			INSERT INTO #DetailData( UserID ,EventID ,MarketID ,BetCount  ,DrawBetCount ,DrawTO ,Lay ,Back, eventType, EventTypeName, MarketName)			
			SELECT d.userId, d.eventID, d.marketID
				, COUNT(*) AS Betcount
				, SUM(CASE WHEN d.profitLoss = 0 THEN 1 ELSE 0 END) AS DrawBetCount
				, SUM(CASE WHEN d.profitLoss = 0 THEN (d.matchStake * 1/b.ExVirtualRate) ELSE 0 END) AS DrawTO
				, SUM(CASE WHEN d.matchType = 'Lay' THEN (d.matchStake * 1/b.ExVirtualRate) ELSE 0 END) AS Lay
				, SUM(CASE WHEN d.matchType = 'Back' THEN (d.matchStake * 1/b.ExVirtualRate) ELSE 0 END) AS Back
				, d.eventType, d.EventTypeName, MAX(d.MarketName) AS MarketName
			FROM dbo.Bettrans_Exchange d WITH (NOLOCK)
				INNER JOIN #TicketData b ON d.userId = b.userId AND d.eventID = b.eventID AND d.marketID = b.marketID
			WHERE d.betstatus = 'Settled'				
			GROUP BY d.userId, d.eventID, d.marketID, d.eventType, d.EventTypeName
			
			UPDATE b
			SET b.BetCount = ISNULL(d.BetCount, 0),
				b.DrawBetCount = ISNULL(d.DrawBetCount, 0),
				b.DrawTO = ISNULL(d.DrawTO, 0),
				b.ValidBetAmount = ABS(ISNULL(d.Lay, 0) - ISNULL(d.Back, 0)),
				b.eventType = ISNULL(d.eventType,-1),
				b.EventTypeName = ISNULL(d.EventTypeName, 'Invalid'),
				b.MarketName = ISNULL(d.MarketName, '')
			FROM #TicketData b
				LEFT JOIN #DetailData d ON d.userId = b.userId AND d.eventID = b.eventID AND d.marketID = b.marketID
				
			UPDATE b
			SET b.WinLostA = - (ISNULL(Winlost, 0)) * (r.PT)
			FROM #TicketData b
				INNER JOIN #LicenseeExchangePT r 
					ON b.LicenseeName = r.LicenseeName AND b.CurrencyId = r.CurrencyId 
			
			--- Delete unused data because of bettrans_exchange does not has data , but Sum_winloss_Exchange still has data with 0 ( case void or refund) 
			DELETE #TicketData 
			WHERE ISNULL(Turnover,0) = 0 AND ISNULL(Winlost,0) = 0 AND ISNULL(WinLostA,0) = 0 AND ISNULL(CommissionP,0) = 0 AND ISNULL(CommissionA,0) = 0 
				  AND ISNULL(BetCount,0) = 0 AND ISNULL(DrawBetCount,0) = 0 AND ISNULL(DrawTO,0) = 0 AND ISNULL(ValidBetAmount,0) = 0		  
				  AND ISNULL(eventType,-1) = -1 AND ISNULL(EventTypeName, 'Invalid') = 'Invalid'
			
			-- Check flag when insert to sum table	  
			IF @GenForDataWarehouse = 0
			BEGIN
				-- Insert data to rptDepWinlost_ThirdParty
				DELETE FROM bodb_LicenseeReport.dbo.rptDepWinlost_ThirdParty WITH (ROWLOCK) 
				WHERE Winlostdate = @WLDate AND ProductId = @ProductId

				INSERT INTO bodb_LicenseeReport.dbo.rptDepWinlost_ThirdParty (winlostdate, custid, currency, ProductId,
															 turnover, Winlost, WinLostA, drawTO, drawBetCount, BetCount, 
															 CommissionP, CommissionA, ValidBetAmount, bettype)
				SELECT @WLDate, custid, CurrencyID, @ProductId
						, SUM(ISNULL(turnover, 0)), SUM(ISNULL(Winlost, 0)), SUM(ISNULL(WinLostA, 0))
						, SUM(ISNULL(DrawTO, 0)), SUM(ISNULL(DrawBetCount, 0)), SUM(ISNULL(BetCount, 0))
						, SUM(ISNULL(CommissionP, 0)), SUM(ISNULL(CommissionA, 0)), SUM(ISNULL(ValidBetAmount, 0))		
						, -1-- bettype
				FROM #TicketData					
				GROUP BY Custid, CurrencyID
			
			
				-- Insert data to rptDepWinlost_ThirdParty_Performance
				DELETE FROM bodb_LicenseeReport.dbo.rptDepWinlost_ThirdParty_Performance WITH (ROWLOCK) 
				WHERE Winlostdate = @WLDate AND ProductId = @ProductId

				INSERT INTO bodb_LicenseeReport.dbo.rptDepWinlost_ThirdParty_Performance (winlostdate, custid, SiteID, currency, ProductId,
															 turnover, Winlost, WinLostA, drawTO, drawBetCount, BetCount, 
															 CommissionP, CommissionA, ValidBetAmount, SportType)
				SELECT @WLDate, custid, SiteID, CurrencyID, @ProductId
						, SUM(ISNULL(turnover, 0)), SUM(ISNULL(Winlost, 0)), SUM(ISNULL(WinLostA, 0))
						, SUM(ISNULL(DrawTO, 0)), SUM(ISNULL(DrawBetCount, 0)), SUM(ISNULL(BetCount, 0))
						, SUM(ISNULL(CommissionP, 0)), SUM(ISNULL(CommissionA, 0)), SUM(ISNULL(ValidBetAmount, 0))		
						, ISNULL(EventType,-1)
				FROM #TicketData					
				GROUP BY Custid, SiteID, CurrencyID, EventType

				--- Update info for summarize
				UPDATE h
				SET SumToThirdPartyDate = GETDATE()				
				FROM dbo.Product3rd_SummarizedDateHistory h
				WHERE h.WinlostDate = @WLDate
					AND EXISTS (	
									SELECT 1 
									FROM @ResettledDateList d 
									WHERE h.ID = d.ID
								)
						
				---- Update Sports_ThirdParty
								
				INSERT INTO bodb_LicenseeReport.dbo.Sports_ThirdParty (SportType, SportName, ProductId)
				SELECT DISTINCT EventType, EventTypeName, @ProductId as ProductId
				FROM #TicketData T
				WHERE NOT EXISTS (SELECT SportType FROM bodb_LicenseeReport.dbo.Sports_ThirdParty s WITH (NOLOCK) WHERE s.ProductID = 31 AND s.SportType = T.EventType)
			
				UPDATE s
				SET s.SportName = t.EventTypeName
				FROM bodb_LicenseeReport.dbo.Sports_ThirdParty s 
					INNER JOIN #TicketData t ON s.SportType = T.EventType 
				WHERE s.ProductID = @ProductId
					AND s.SportName <> t.EventTypeName
			END
			ELSE
			BEGIN
				INSERT INTO #TicketDataForDataWarehouse ([Winlostdate],[Custid],[Currency],[ProductId],[Turnover],[Winlost],[WinLostA],[DrawTO]
																,[DrawBetCount],[BetCount],[CommissionP],[CommissionA],[ValidBetAmount],[Bettype],[EventID],[EventName],[EventType],[EventTypeName],[MarketName])
				SELECT @WLDate [Winlostdate], custid [Custid], CurrencyID [Currency], @ProductId [ProductId]
					, SUM(ISNULL(turnover, 0)) [Turnover], SUM(ISNULL(Winlost, 0)) [Winlost], SUM(ISNULL(WinLostA, 0)) [WinLostA]
					, SUM(ISNULL(DrawTO, 0)) [DrawTO], SUM(ISNULL(DrawBetCount, 0)) [DrawBetCount], SUM(ISNULL(BetCount, 0)) [BetCount]
					, SUM(ISNULL(CommissionP, 0)) [CommissionP], SUM(ISNULL(CommissionA, 0)) [CommissionA], SUM(ISNULL(ValidBetAmount, 0)) [ValidBetAmount]	
					, -1 [Bettype]-- bettype
					, t.[EventID], t.EventName, t.[EventType], MAX(t.[EventTypeName]) EventTypeName, t.MarketName
				FROM #TicketData t
				GROUP BY t.Custid, t.CurrencyID, t.EventID, t.EventType, t.EventName, t.MarketName
			END 
		END 
				
		SELECT @i = @i + 1
	END

	-- Output Data For DataWarehouse	  
	IF @GenForDataWarehouse = 1
	BEGIN
		SELECT [Winlostdate],[Custid],[Currency],[ProductId],SUM([Turnover]) AS [Turnover], SUM([Winlost]) AS [Winlost], SUM([WinLostA]) AS [WinLostA], SUM([DrawTO]) AS [DrawTO]
			  ,SUM([DrawBetCount]) AS [DrawBetCount],SUM([BetCount]) AS [BetCount],SUM([CommissionP]) AS [CommissionP],SUM([CommissionA]) AS [CommissionA]
			  ,SUM([ValidBetAmount]) AS [ValidBetAmount],[Bettype]
		FROM #TicketDataForDataWarehouse
		GROUP BY [Winlostdate],[Custid],[Currency],[ProductId],[Bettype]
	END
	ELSE IF @GenForDataWarehouse = 2
	BEGIN
		SELECT [Winlostdate],[Custid],[Currency],[Turnover],[Winlost],[WinLostA],[DrawTO]
							,[DrawBetCount],[BetCount],[CommissionP],[CommissionA],[ValidBetAmount]
							,[EventID],[EventName],[EventType],[EventTypeName], [MarketName]
		FROM #TicketDataForDataWarehouse
		WHERE Winlostdate = @winlostdate

	END
	
	DROP TABLE #TicketDataForDataWarehouse
	DROP TABLE #TicketData
	DROP TABLE #DetailData 
END TRY

BEGIN CATCH
	-- This SPs called from another SP in rptDepwinlost Summary process, failure of this SP should not affect to that process
	PRINT 'Error occured in Exchange summary data process: ERR_CODE: '+ CAST(ERROR_NUMBER() AS VARCHAR(20)) + ', ERR_MSG: ' + ERROR_MESSAGE()
	RETURN
END CATCH
GO