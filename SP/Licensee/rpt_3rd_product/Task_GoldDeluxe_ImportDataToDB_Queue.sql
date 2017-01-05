USE [bodb_PlaytechCS]
GO
/****** Object:  StoredProcedure [dbo].[Task_GoldDeluxe_ImportDataToDB_Queue]    Script Date: 01/05/2017 00:03:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_GoldDeluxe_ImportDataToDB_Queue]
	@QueueIDInput BIGINT = 0
AS 
/*
Created: 20161227@Francis
Task : [Task_GoldDeluxe_ImportDataToDB]
Description: Pulling GD bet tickets from API
DB: DBPTCS.bodb_PlaytechCS

Original:

Revisions:
	- 20161229@Francis: Improve the way to retrieve XmlData [RedmineID: #68972]

Param explanation:

*/
BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput != 0
		IF (SELECT ProductID FROM dbo.Product3rd_ImportQueue WITH (NOLOCK) WHERE QueueID = @QueueIDInput) != 11
			BEGIN
				RAISERROR('Input QueueID is not compitable with the product, pls check again!',0,1)
				RETURN
			END

	DECLARE @OldVersionKey BIGINT, @NewVersionKey BIGINT, @LicenseeName VARCHAR(50), @Winlostdate DATE
	DECLARE @QueueID BIGINT = NULL, @XmlData XML, @LogDesc VARCHAR(2000) = NULL

	CREATE TABLE #TmpData (
		BetID            VARCHAR(50),
		IBCCustid        INT,
		playerName        VARCHAR(50),
		BetTime            DATETIME,
		BalanceTime        DATE,
		GameType        TINYINT,
		ProductID        VARCHAR(20),
		BetType            VARCHAR(20),
		BetAmount        MONEY,
		WinLoss            MONEY,
		StartBalance    MONEY,
		EndBalance        MONEY,
		JackpotWin        MONEY,
		RNGID            INT,
		BetResult        VARCHAR(20),
		Currency        TINYINT,
	)
	BEGIN TRY
	WHILE EXISTS (SELECT TOP 1 1 FROM dbo.Product3rd_ImportQueue WITH (NOLOCK) WHERE (FinishedTime IS NULL AND ProductID = 11) OR @QueueIDInput != 0)	
		BEGIN
			--Get QueueID, XmlData
			IF @QueueIDInput != 0
				SELECT @QueueID = QueueID, @XmlData = XmlData, @LicenseeName = LicenseeName
				FROM dbo.Product3rd_ImportQueue WITH (NOLOCK)
				WHERE QueueID = @QueueIDInput
			ELSE
				SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData, @LicenseeName = LicenseeName
				FROM dbo.Product3rd_ImportQueue WITH (NOLOCK)
				WHERE FinishedTime IS NULL AND ProductID = 11
				ORDER BY QueueID ASC
			--
			
			--Parse XmlData
			SELECT @NewVersionKey = x.v.value('(NEWVERSIONKEY/text())[1]', 'BIGINT')
			FROM @XmlData.nodes('/TransList') AS x(v)
				
			TRUNCATE TABLE #TmpData
			
			INSERT INTO #TmpData(BetID, IBCCustID, playerName, BetTime, BalanceTime, GameType, ProductID, BetType, BetAmount
								, WinLoss, StartBalance, EndBalance, JackpotWin, RNGID, BetResult, Currency)
				SELECT 
					x.v.value('(BETID/text())[1]','VARCHAR(50)') AS BetID,
					x.v.value('(IBCCUSTID/text())[1]', 'INT') AS IBCCustID,
					x.v.value('(PLAYERNAME/text())[1]', 'VARCHAR(50)') AS playerName,    
					x.v.value('(BETTIME/text())[1]', 'DATETIME') AS BetTime,    
					CONVERT(VARCHAR(10),x.v.value('(BALANCETIME/text())[1]', 'DATETIME'), 120) AS BalanceTime,    
					x.v.value('(GAMETYPE/text())[1]', 'TINYINT') AS GameType,    
					x.v.value('(PRODUCTID/text())[1]', 'VARCHAR(20)') AS ProductID,
					x.v.value('(BETTYPE/text())[1]', 'VARCHAR(20)') AS BetType,    
					x.v.value('(BETAMOUNT/text())[1]', 'MONEY') AS BetAmount,
					x.v.value('(WINLOSS/text())[1]', 'MONEY') AS WinLoss,
					x.v.value('(STARTBALANCE/text())[1]', 'MONEY') AS StartBalance,
					x.v.value('(ENDBALANCE/text())[1]', 'MONEY') AS EndBalance,
					x.v.value('(JACKPOTWIN/text())[1]', 'MONEY') AS JackpotWin,
					x.v.value('(RNGID/text())[1]', 'INT') AS RNGID,
					x.v.value('(BETRESULT/text())[1]', 'VARCHAR(20)') AS BetResult,
					x.v.value('(CURRENCY/text())[1]', 'TINYINT') AS Currency    
				FROM @XmlData.nodes('/TransList/TRANSACTION') AS x(v)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))
			--
			
			--Get info for Log
			SELECT @OldVersionKey = SettingValue
			FROM dbo.LicIntegrationSetting WITH (NOLOCK)
			WHERE LicenseeName LIKE @LicenseeName
			  AND SettingName LIKE 'GoldDeluxe_VersionKey'
			
			SELECT @Winlostdate = MIN(BalanceTime)
			FROM #TmpData
			
			SET @LogDesc = NULL
			
			SELECT @LogDesc = COALESCE(@LogDesc + '; ', '') + CONVERT(VARCHAR(10),BalanceTime) + ' (No. of tickets: ' + CONVERT(VARCHAR(20),COUNT(BetID)) + ')'
			FROM #TmpData
			GROUP BY BalanceTime
			
			SELECT @LogDesc = @LogDesc + '; OldVersionKey: ' + CONVERT (VARCHAR(20),@OldVersionKey) + '; NewVersionKey: ' + CONVERT (VARCHAR(20),@NewVersionKey)
			--
			
			-- Import data to DB
			MERGE dbo.bettrans_GoldDeluxe AS dest
			USING ( SELECT d.BetID, 
				d.IBCCUSTID, 
				d.playerName,
				d.BetTime,                
				d.GameType, -- GameType
				d.ProductID,
				d.BetType,
				d.betAmount, -- Stake            
				d.WinLoss,-- Winlost 
				d.StartBalance,
				d.EndBalance,
				d.JackpotWin,
				d.RNGID,            
				CASE 
					WHEN d.BetResult ='Win' THEN 'WON'
					WHEN d.BetResult ='Loss' THEN 'LOSE'
					WHEN d.BetResult ='Tie' THEN 'DRAW'
					WHEN d.BetResult ='Cancel' THEN 'REJECT'
					WHEN d.BetResult ='Voided' THEN 'VOID'                    
				END, -- Status
				CASE 
					WHEN d.BetResult ='Win' THEN 112
					WHEN d.BetResult ='Loss' THEN 113
					WHEN d.BetResult ='Tie' THEN 111
					WHEN d.BetResult ='Cancel' THEN 101
					WHEN d.BetResult ='Voided' THEN 102
				END, -- StatusID
	            d.BalanceTime, -- Winlostdate
				c.recommend, c.mrecommend, c.srecommend, c.currency            
			FROM #TmpData d
				INNER JOIN bodb02.dbo.Customer c WITH(NOLOCK) ON c.custid = d.IBCCustID)
			AS src (BetID, IBCCustID, playerName,BetTime, GameType, ProductID, BetType, betAmount, WinLoss, StartBalance, 
					EndBalance, JackpotWin, RNGID, Status,StatusId,WinlostDate, recommend, mrecommend, srecommend, currency)
				ON (dest.TicketID = src.BetID)
			WHEN MATCHED THEN
			UPDATE SET dest.CustID = src.IBCCustID
				,dest.Transdate = src.BetTime                    
				,dest.Stake = src.BetAmount                    
				,dest.Winlost = src.WinLoss
				,dest.[Status] = src.[Status]
				,dest.StatusID = src.StatusID
				,dest.userName2 = src.playerName
				,dest.Winlostdate = src.Winlostdate                    
				,dest.GameType = src.GameType
				,dest.ProductID = src.ProductID
				,dest.BetType = src.BetType
				,dest.StartBalance = src.StartBalance
				,dest.EndBalance = src.EndBalance
				,dest.JackpotWin = src.JackpotWin
				,dest.RNGID = src.RNGID
				,dest.recommend = src.recommend
				,dest.mrecommend = src.mrecommend
				,dest.srecommend = src.srecommend
				,dest.currency = src.currency    
			WHEN NOT MATCHED BY TARGET THEN
			INSERT (TicketID, CustID, UserName2,Transdate, GameType, ProductID, BetType, Stake, WinLost, StartBalance, 
				EndBalance, JackpotWin, RNGID, Status,StatusId,WinlostDate, recommend, mrecommend, srecommend, currency)
			VALUES (SRC.BetID, SRC.IBCCustID, SRC.playerName,SRC.BetTime, SRC.GameType, SRC.ProductID, SRC.BetType, SRC.betAmount, 
				SRC.WinLoss, SRC.StartBalance, SRC.EndBalance, SRC.JackpotWin, SRC.RNGID, SRC.Status,SRC.StatusId,SRC.WinlostDate, 
				SRC.recommend, SRC.mrecommend, SRC.srecommend, SRC.currency);		
					
			--Update VersionKey
			IF (@@ROWCOUNT != 0)
			BEGIN
				UPDATE dbo.LicIntegrationSetting WITH (ROWLOCK, UPDLOCK)
				SET SettingValue = @NewVersionKey
				WHERE LicenseeName LIKE @LicenseeName
					AND SettingName LIKE 'GoldDeluxe_VersionKey'
			END	
			ELSE 
			--
						
			--Delete old data that has been finished
			IF (@QueueID >= 2000 AND @QueueID % 1000 = 0)
				DELETE 
				FROM dbo.Product3rd_ImportQueue
				WHERE QueueID IN (
					SELECT TOP (1000) QueueID
					FROM dbo.Product3rd_ImportQueue WITH (NOLOCK)
					WHERE FinishedTime IS NOT NULL 
						--AND ProductID = 11
						AND QueueID < @QueueID
					ORDER BY QueueID ASC)
			--	
			--Update QueueID set FinishedTime and additional Log Info
			UPDATE dbo.Product3rd_ImportQueue WITH (UPDLOCK, ROWLOCK)
			SET FinishedTime = CASE WHEN FinishedTime IS NULL THEN CURRENT_TIMESTAMP
									ELSE FinishedTime
							   END
				, WinlostDate = @Winlostdate
				, LogDesc = @LogDesc
			WHERE QueueID = @QueueID
			--	
			
			IF @QueueIDInput != 0
			BREAK
		END    
		
	DROP TABLE #TmpData	
	END TRY
	BEGIN CATCH --Write ErrLog
	SELECT @LogDesc = 'MsgError: ' + ERROR_MESSAGE()
	
	UPDATE dbo.Product3rd_ImportQueue WITH (UPDLOCK, ROWLOCK)
	SET FinishedTime = NULL
		, LogDesc = @LogDesc
	WHERE QueueID = ISNULL(@QueueID,0)
	
	
	PRINT (ERROR_MESSAGE())
	DROP TABLE #TmpData
	END CATCH
END
