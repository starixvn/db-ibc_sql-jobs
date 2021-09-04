/*<info serverAlias="DBPTCS-bodb_PlaytechCS,DBBAL-bodb_PlaytechCS" executers="" isFunction="0" isNested="1"></info>*/
USE [bodb_PlaytechCS]
GO

ALTER PROCEDURE [dbo].[Task_GoldDeluxe_ImportDataToDB_Queue]
	@QueueIDInput	BIGINT = 0,
	@JobType		TINYINT = 0,
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20161227@Francis
	DB: DBPTCS-bodb_PlaytechCS, DBBAL-bodb_PlaytechCS
	Task: Gold Deluxe - Import raw data from API - Process queue

	Revisions:
		- 20161229@Francis: Improve the way to retrieve XmlData [RedmineID: #68972]
		- 20170214@Francis: Keep about 5000 finished rows in Queue
		- 20171218@Percy: Add ErrCode, ErrMsg replace RAISERROR [RedmineID: #88325]
		- 20181003@Percy: Using colum JobType to apply Tip [RedmineID: #70177]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]

	Param explanation:
		. JobType:
			0: bettrans_GoldDeluxe
			1: GoldDeluxe_Tip
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
		IF EXISTS (SELECT 1 FROM dbo.Product3rd_ImportQueue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND (ProductId <> 11 OR ISNULL(JobType, 0) = @JobType))
		BEGIN
			SELECT	@ErrCode = 100,
					@ErrMsg = N'Input QueueID is not compitable with the product, please check again!'
			RETURN
		END

	DECLARE @QueueID BIGINT, @XmlData XML, @LicenseeName VARCHAR(50), @Winlostdate DATE, @LogDesc VARCHAR(2000)
	DECLARE @OldVersionKey BIGINT, @NewVersionKey BIGINT

	CREATE TABLE #bettrans_GoldDeluxe
	(
		BetID			VARCHAR(50),
		IBCCustId		INT,
		playerName		VARCHAR(50),
		BetTime			DATETIME,
		BalanceTime		DATE,
		GameType		TINYINT,
		ProductID		VARCHAR(20),
		BetType			VARCHAR(20),
		BetAmount		MONEY,
		WinLoss			MONEY,
		StartBalance	MONEY,
		EndBalance      MONEY,
		JackpotWin      MONEY,
		RNGID           INT,
		BetResult       VARCHAR(20),
		Currency		TINYINT,
	)

	CREATE TABLE #GoldDeluxe_Tip
	(
		TipId			VARCHAR(50),
		IBCCustId		INT,
		Deposit_CustId	INT,
		PlayerName		VARCHAR(50),
		TipTime			DATETIME,
		Amount			DECIMAL(18,3),
		Currency		SMALLINT,
		AnchorId		INT
	)

	WHILE (@QueueIDInput <> 0 OR EXISTS (SELECT 1 FROM dbo.Product3rd_ImportQueue WITH (NOLOCK) WHERE FinishedTime IS NULL AND ProductID = 11 AND ISNULL(JobType, 0) = @JobType))
	BEGIN
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData, @LicenseeName = LicenseeName
			FROM dbo.Product3rd_ImportQueue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData, @LicenseeName = LicenseeName
			FROM dbo.Product3rd_ImportQueue WITH (NOLOCK)
			WHERE FinishedTime IS NULL AND ProductID = 11 AND ISNULL(JobType, 0) = @JobType
			ORDER BY QueueID ASC
		
		-- Parse XmlData
		BEGIN TRY
			-- Reset data
			TRUNCATE TABLE #bettrans_GoldDeluxe
			TRUNCATE TABLE #GoldDeluxe_Tip
			
			SET @LogDesc = NULL

			IF @JobType = 0
			BEGIN
				-- Get new version key
				SELECT @NewVersionKey = x.v.value('(NEWVERSIONKEY/text())[1]', 'BIGINT')
				FROM @XmlData.nodes('/TransList') AS x(v)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Get old version key
				SELECT @OldVersionKey = SettingValue
				FROM dbo.LicIntegrationSetting WITH (NOLOCK)
				WHERE LicenseeName = @LicenseeName AND SettingName = 'GoldDeluxe_VersionKey'
				
				-- Get data from xml
				INSERT INTO #bettrans_GoldDeluxe
				(
					BetID, IBCCustID, playerName, BetTime, BalanceTime, GameType, ProductID, BetType, BetAmount,
					WinLoss, StartBalance, EndBalance, JackpotWin, RNGID, BetResult, Currency
				)
				SELECT 
					x.v.value('(BETID/text())[1]','VARCHAR(50)')		AS BetID,
					x.v.value('(IBCCUSTID/text())[1]', 'INT')			AS IBCCustID,
					x.v.value('(PLAYERNAME/text())[1]', 'VARCHAR(50)')	AS playerName,    
					x.v.value('(BETTIME/text())[1]', 'DATETIME')		AS BetTime,    
					CONVERT(VARCHAR(10), x.v.value('(BALANCETIME/text())[1]', 'DATETIME'), 120) AS BalanceTime,    
					x.v.value('(GAMETYPE/text())[1]', 'TINYINT')		AS GameType,    
					x.v.value('(PRODUCTID/text())[1]', 'VARCHAR(20)')	AS ProductID,
					x.v.value('(BETTYPE/text())[1]', 'VARCHAR(20)')		AS BetType,    
					x.v.value('(BETAMOUNT/text())[1]', 'MONEY')			AS BetAmount,
					x.v.value('(WINLOSS/text())[1]', 'MONEY')			AS WinLoss,
					x.v.value('(STARTBALANCE/text())[1]', 'MONEY')		AS StartBalance,
					x.v.value('(ENDBALANCE/text())[1]', 'MONEY')		AS EndBalance,
					x.v.value('(JACKPOTWIN/text())[1]', 'MONEY')		AS JackpotWin,
					x.v.value('(RNGID/text())[1]', 'INT')				AS RNGID,
					x.v.value('(BETRESULT/text())[1]', 'VARCHAR(20)')	AS BetResult,
					x.v.value('(CURRENCY/text())[1]', 'TINYINT')		AS Currency    
				FROM @XmlData.nodes('/TransList/TRANSACTION') AS x(v)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Process data
				MERGE dbo.bettrans_GoldDeluxe AS dest
				USING
				(
					SELECT
						d.BetID, 
						d.IBCCustID, 
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
							WHEN d.BetResult ='Win'		THEN 'WON'
							WHEN d.BetResult ='Loss'	THEN 'LOSE'
							WHEN d.BetResult ='Tie'		THEN 'DRAW'
							WHEN d.BetResult ='Cancel'	THEN 'REJECT'
							WHEN d.BetResult ='Voided'	THEN 'VOID'                    
						END, -- Status
						CASE 
							WHEN d.BetResult ='Win'		THEN 112
							WHEN d.BetResult ='Loss'	THEN 113
							WHEN d.BetResult ='Tie'		THEN 111
							WHEN d.BetResult ='Cancel'	THEN 101
							WHEN d.BetResult ='Voided'	THEN 102
						END, -- StatusID
						d.BalanceTime, -- Winlostdate
						c.recommend, c.mrecommend, c.srecommend, c.currency
					FROM #bettrans_GoldDeluxe d
						INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.custid = d.IBCCustID
					) AS src
						(
							BetID, IBCCustID, playerName, BetTime, GameType, ProductID, BetType, betAmount, WinLoss, StartBalance, 
							EndBalance, JackpotWin, RNGID, Status, StatusId, WinlostDate, recommend, mrecommend, srecommend, currency
						) ON (dest.TicketID = src.BetID)
				WHEN MATCHED THEN UPDATE
				SET dest.CustID			= src.IBCCustID,
					dest.Transdate		= src.BetTime,                  
					dest.Stake			= src.BetAmount,                 
					dest.Winlost		= src.WinLoss,
					dest.[Status]		= src.[Status],
					dest.StatusID		= src.StatusID,
					dest.userName2		= src.playerName,
					dest.Winlostdate	= src.Winlostdate,                
					dest.GameType		= src.GameType,
					dest.ProductID		= src.ProductID,
					dest.BetType		= src.BetType,
					dest.StartBalance	= src.StartBalance,
					dest.EndBalance		= src.EndBalance,
					dest.JackpotWin		= src.JackpotWin,
					dest.RNGID			= src.RNGID,
					dest.recommend		= src.recommend,
					dest.mrecommend		= src.mrecommend,
					dest.srecommend		= src.srecommend,
					dest.currency		= src.currency
				WHEN NOT MATCHED BY TARGET THEN INSERT
					(
						TicketID, CustID, UserName2,Transdate, GameType, ProductID, BetType, Stake, WinLost, StartBalance, 
						EndBalance, JackpotWin, RNGID, Status,StatusId,WinlostDate, recommend, mrecommend, srecommend, currency
					)
					VALUES
					(
						src.BetID, src.IBCCustID, src.playerName, src.BetTime, src.GameType, src.ProductID, src.BetType, src.betAmount, 
						src.WinLoss, src.StartBalance, src.EndBalance, src.JackpotWin, src.RNGID, src.Status, src.StatusId, src.WinlostDate, 
						src.recommend, src.mrecommend, src.srecommend, src.currency
					);

				IF @@ROWCOUNT <> 0
				BEGIN
					UPDATE dbo.LicIntegrationSetting WITH (ROWLOCK, UPDLOCK)
					SET SettingValue = @NewVersionKey
					WHERE LicenseeName = @LicenseeName
						AND SettingName = 'GoldDeluxe_VersionKey'
				END	

				SELECT @WinlostDate = MIN(BalanceTime) FROM #bettrans_GoldDeluxe
			
				SELECT @LogDesc = COALESCE(@LogDesc + '; ', '') + CONVERT(VARCHAR(10),BalanceTime) + ' (No. of tickets: ' + CONVERT(VARCHAR(20), COUNT(BetID)) + ')'
				FROM #bettrans_GoldDeluxe
				GROUP BY BalanceTime
			
				SELECT @LogDesc = @LogDesc + '; OldVersionKey: ' + CONVERT (VARCHAR(20),@OldVersionKey) + '; NewVersionKey: ' + CONVERT (VARCHAR(20),@NewVersionKey)
			END
			ELSE IF @JobType = 1
			BEGIN
				INSERT INTO #GoldDeluxe_Tip
				(
					TipId, IBCCustId, Deposit_CustId, PlayerName, TipTime, Amount, Currency, AnchorId
				)
				SELECT 
					x.v.value('(TIPSID/text())[1]','VARCHAR(50)')		AS TipId,
					x.v.value('(IBCCUSTID/text())[1]', 'INT')			AS IBCCustId,
					x.v.value('(DEPOSIT_CUSTID/text())[1]', 'INT')		AS Deposit_CustId,
					x.v.value('(PLAYERNAME/text())[1]', 'VARCHAR(50)')	AS playerName,
					x.v.value('(TIPTIME/text())[1]', 'DATETIME')		AS TipTime,
					x.v.value('(AMOUNT/text())[1]', 'MONEY')			AS Amount,
					x.v.value('(CURRENCY/text())[1]', 'SMALLINT')		AS Currency,
					x.v.value('(ANCHORID/text())[1]', 'INT')			AS AnchorId 
				FROM @XmlData.nodes('/TransList/TRANSACTION') AS x(v)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				MERGE dbo.GoldDeluxe_Tip AS dest
				USING
				(
					SELECT
						d.TipId,
						d.IBCCustId,
						d.Deposit_CustId,
						d.playerName,
						d.TipTime,                
						d.Amount,
						c.currency,
						d.AnchorId,
						c.recommend,
						c.mrecommend,
						c.srecommend,
						CONVERT(DATE, d.TipTime) AS WinlostDate
					FROM #GoldDeluxe_Tip d
						INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.custid = d.IBCCustID
					) AS src
						(
							TipId,IBCCustId,Deposit_CustId,playerName,TipTime,Amount,currency,AnchorId,recommend,mrecommend,srecommend,WinlostDate
						) ON (dest.TipId = src.TipId)
				WHEN MATCHED THEN UPDATE
				SET dest.IBCCustId		= src.IBCCustId,
					dest.Deposit_CustId	= src.Deposit_CustId,                  
					dest.playerName		= src.playerName,                 
					dest.TipTime		= src.TipTime,
					dest.Amount			= src.Amount,
					dest.currency		= src.currency,
					dest.AnchorId		= src.AnchorId,
					dest.recommend		= src.recommend,
					dest.mrecommend		= src.mrecommend,
					dest.srecommend		= src.srecommend,
					dest.WinlostDate	= src.WinlostDate
				WHEN NOT MATCHED BY TARGET THEN INSERT
					(
						TipId,IBCCustId,Deposit_CustId,playerName,TipTime,Amount,currency,AnchorId,recommend,mrecommend,srecommend,WinlostDate
					)
					VALUES
					(
						TipId,IBCCustId,Deposit_CustId,playerName,TipTime,Amount,currency,AnchorId,recommend,mrecommend,srecommend,WinlostDate
					);

				SELECT @WinlostDate = MIN(CONVERT(DATE, TipTime)) FROM #GoldDeluxe_Tip

				SELECT @LogDesc = COALESCE(@LogDesc + '; ', '') + CONVERT(VARCHAR(10), CONVERT(DATE, TipTime)) + ' (No. of tickets: ' + CONVERT(VARCHAR(20), COUNT(TipId)) + ')'
				FROM #GoldDeluxe_Tip
				GROUP BY CONVERT(DATE, TipTime)
			END

			-- Delete old data that has been finished
			IF (@QueueID >= 2000 AND @QueueID % 1000 = 0)
				DELETE dbo.Product3rd_ImportQueue WITH (ROWLOCK, UPDLOCK)
				WHERE FinishedTime IS NOT NULL
					AND isSummarized = 1
					AND QueueID < (@QueueID - 5000)

			--Update QueueID set FinishedTime and additional Log Info
			UPDATE dbo.Product3rd_ImportQueue WITH (UPDLOCK, ROWLOCK)
			SET FinishedTime	= CASE WHEN FinishedTime IS NULL THEN CURRENT_TIMESTAMP ELSE FinishedTime END,
				WinlostDate		= @Winlostdate,
				LogDesc			= @LogDesc
			WHERE QueueID		= @QueueID
		END TRY
		BEGIN CATCH
			SELECT	@ErrCode = 101,
					@ErrMsg = ERROR_MESSAGE()

			SELECT  @LogDesc = 'MsgError: ' + @ErrMsg
	
			UPDATE dbo.Product3rd_ImportQueue WITH (UPDLOCK, ROWLOCK)
			SET FinishedTime = NULL, LogDesc = @LogDesc
			WHERE QueueID = @QueueID

			SELECT @ErrMsg = 'QueueID = ' + CONVERT(VARCHAR(20), @QueueID) + ', ProductID = 11, MsgError = ' + @ErrMsg

			RETURN
		END CATCH
		
		IF @QueueIDInput <> 0
			BREAK
	END

	DROP TABLE #bettrans_GoldDeluxe
	DROP TABLE #GoldDeluxe_Tip
END
GO