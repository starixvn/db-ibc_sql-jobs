USE [bodb_PlaytechCS]
GO
/****** Object:  StoredProcedure [dbo].[Task_AGCasino_ImportDataToDB_Queue]    Script Date: 2/14/2017 4:08:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_AGCasino_ImportDataToDB_Queue    Script Date: 1/16/2017 18:13:39 ******/
ALTER PROCEDURE [dbo].[Task_AGCasino_ImportDataToDB_Queue]
	@QueueIDInput BIGINT = 0
AS 
/*
Created: 20161227@Francis
Task : [Task_AGCasino_ImportDataToDB]
Description: Pulling GD bet tickets from API
DB: DBPTCS.bodb_PlaytechCS

Original:

Revisions:
	- 20161229@Francis: Improve the way to retrieve XmlData [RedmineID: #68972]
	- 20170214@Francis: Keep about 5000 finished rows in Queue
Param explanation:

*/
BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput != 0
		IF (SELECT ProductID FROM dbo.Product3rd_ImportQueue WITH (NOLOCK) WHERE QueueID = @QueueIDInput) != 10
			BEGIN
				RAISERROR('Input QueueID is not compitable with the product, pls check again!',0,1)
				RETURN
			END
	
	DECLARE @OldVersionKey BIGINT, @NewVersionKey BIGINT, @LicenseeName VARCHAR(50), @Winlostdate DATE
	DECLARE @QueueID BIGINT = NULL, @XmlData XML, @LogDesc VARCHAR(2000) = NULL
	
	CREATE TABLE #TmpData (
		BillNo		BIGINT,
		IBCCustID	INT,
		BetTime		DATETIME,
		GameType	VARCHAR(10),
		BetAmount	MONEY,
		NetAmount	MONEY,
		PlayType	SMALLINT,
		LoginIP		VARCHAR(20),
		Currency	TINYINT,
	)

	BEGIN TRY
	WHILE EXISTS (SELECT TOP 1 1 FROM dbo.Product3rd_ImportQueue WITH (NOLOCK) WHERE (FinishedTime IS NULL AND ProductID = 10) OR @QueueIDInput != 0)
		BEGIN
			--Get QueueID, XmlData
			IF @QueueIDInput != 0
				SELECT @QueueID = QueueID, @XmlData = XmlData, @LicenseeName = LicenseeName
				FROM dbo.Product3rd_ImportQueue WITH (NOLOCK)
				WHERE QueueID = @QueueIDInput
			ELSE
				SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData, @LicenseeName = LicenseeName
				FROM dbo.Product3rd_ImportQueue WITH (NOLOCK)
				WHERE FinishedTime IS NULL AND ProductID = 10
				ORDER BY QueueID ASC
			--
			
			--Parse XmlData
			SELECT @NewVersionKey = x.v.value('(NEWVERSIONKEY/text())[1]', 'BIGINT')
			FROM @XmlData.nodes('/TransList') AS x(v)
			
			TRUNCATE TABLE #TmpData
			
			INSERT INTO #TmpData(BillNo, IBCCustID, BetTime, GameType, BetAmount, NetAmount, PlayType, LoginIP, Currency)
				SELECT 
					x.v.value('(BILLNO/text())[1]', 'BIGINT') AS BillNo,
					x.v.value('(IBCCUSTID/text())[1]', 'INT') AS IBCCustID,
					CONVERT(VARCHAR(10), x.v.value('(BETTIME/text())[1]', 'DATETIME'), 120) AS BetTime,	
					x.v.value('(GAMETYPE/text())[1]', 'VARCHAR(10)') AS GameType,	
					x.v.value('(BETAMOUNT/text())[1]', 'MONEY') AS BetAmount,	
					x.v.value('(NETAMOUNT/text())[1]', 'MONEY') AS NetAmount,	
					x.v.value('(PLAYTYPE/text())[1]', 'SMALLINT') AS PlayType,
					x.v.value('(LOGINIP/text())[1]', 'VARCHAR(20)') AS LoginIP,	
					x.v.value('(CURRENCY/text())[1]', 'TINYINT') AS Currency
				FROM @XmlData.nodes('/TransList/TRANSACTION') x(v)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))
			--
			
			--Get info for Log
			SELECT @OldVersionKey = SettingValue
			FROM dbo.LicIntegrationSetting WITH (NOLOCK)
			WHERE LicenseeName LIKE @LicenseeName
			  AND SettingName LIKE 'GoldDeluxe_VersionKey'
			
			SELECT @Winlostdate = MIN(BetTime)
			FROM #TmpData
			
			SET @LogDesc = NULL
			
			SELECT @LogDesc = COALESCE(@LogDesc + '; ', '') + CONVERT(VARCHAR(10),CAST(BetTime AS DATE)) + ' (No. of tickets: ' + CONVERT(VARCHAR(20),COUNT(BillNo)) + ')'
			FROM #TmpData
			GROUP BY BetTime
			
			SELECT @LogDesc = @LogDesc + '; OldVersionKey: ' + CONVERT (VARCHAR(20),@OldVersionKey) + '; NewVersionKey: ' + CONVERT (VARCHAR(20),@NewVersionKey)
			--
			
			--Import data to DB
			MERGE dbo.bettrans_AGCasino AS dest
			USING (SELECT d.BillNo, 
					d.IBCCustID, 
					d.BetTime,
					d.GameType, -- GameType
					d.betAmount, -- Stake
					d.betAmount, -- Actual_Stake
					d.betAmount + d.NetAmount, -- Winlost 
					CASE 
						WHEN d.NetAmount > 0 THEN 'WON'
						WHEN d.NetAmount < 0 THEN 'LOSE'
						ELSE 'DRAW'
					END, -- Status
					CASE 
						WHEN d.NetAmount > 0 THEN '112'
						WHEN d.NetAmount < 0 THEN '113'
						ELSE '111'
					END, -- StatusID
					d.PlayType, -- PlayType
					d.BetTime, -- Winlostdate
					c.username, -- Username
					d.LoginIP, -- IP
					c.recommend, c.mrecommend, c.srecommend, c.currency,
					CASE WHEN GameType LIKE 'CBAC' THEN 1 ELSE 0 END -- IsVIPGame
					FROM #TmpData d
						INNER JOIN bodb02.dbo.Customer c WITH(NOLOCK) ON c.custid = d.IBCCustID)
			AS src (BillNo, IBCCustID, Transdate, GameType, Stake, Actual_Stake, Winlost, [Status], StatusID, 
					PlayType, Winlostdate, Username, LoginIP, recommend, mrecommend, srecommend, currency, IsVIPGame)
				ON (dest.TicketID = src.BillNo)
			WHEN MATCHED THEN
				UPDATE SET dest.CustID = src.IBCCustID
						,dest.Transdate = src.Transdate
						,dest.GameType = src.GameType
						,dest.Stake = src.Stake
						,dest.Actual_Stake = src.Actual_Stake
						,dest.Winlost = src.Winlost
						,dest.[Status] = src.[Status]
						,dest.StatusID = src.StatusID
						,dest.PlayType = src.PlayType
						,dest.Winlostdate = src.Winlostdate
						,dest.Username = src.Username
						,dest.IP = src.LoginIP
						,dest.recommend = src.recommend
						,dest.mrecommend = src.mrecommend
						,dest.srecommend = src.srecommend
						,dest.currency = src.currency
						,dest.IsVIPGame = src.IsVIPGame
			WHEN NOT MATCHED THEN
				INSERT (TicketID, CustID, Transdate, GameType, Stake, Actual_Stake, Winlost, 
						[Status], StatusID, PlayType, Winlostdate,  Username, IP, 
						recommend, mrecommend, srecommend, Currency, IsVIPGame)
				VALUES (src.BillNo, src.IBCCustID, src.Transdate, src.GameType, src.Stake, src.Actual_Stake, src.Winlost, 
						src.[Status], src.StatusID, src.PlayType, src.Winlostdate, src.Username, src.LoginIP, 
						src.recommend, src.mrecommend, src.srecommend, src.currency, src.IsVIPGame);
			--		
		
			--Update VersionKey
			IF (@@ROWCOUNT != 0)
			BEGIN
				UPDATE dbo.LicIntegrationSetting WITH (ROWLOCK, UPDLOCK)
					SET SettingValue = @NewVersionKey
					WHERE LicenseeName LIKE @LicenseeName
						AND SettingName LIKE 'AGCasino_VersionKey'
			END
			--
			
			--Delete old data that has been finished
			IF (@QueueID >= 2000 AND @QueueID % 1000 = 0)
				DELETE 
				FROM dbo.Product3rd_ImportQueue
				WHERE QueueID IN (
					SELECT TOP (@QueueID - 5000) QueueID
					FROM dbo.Product3rd_ImportQueue WITH (NOLOCK)
					WHERE FinishedTime IS NOT NULL 
						--AND ProductID = 10
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