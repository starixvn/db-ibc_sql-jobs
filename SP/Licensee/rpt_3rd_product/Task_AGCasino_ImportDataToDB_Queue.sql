/*<info serverAlias="DBPTCS-bodb_PlaytechCS,DBBAL-bodb_PlaytechCS" executers="" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_AGCasino_ImportDataToDB_Queue]
	@QueueIDInput	BIGINT = 0,
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20161227@Francis
	Task : [Task_AGCasino_ImportDataToDB]
	Description: Pulling GD bet tickets from API
	DB: DBPTCS.bodb_PlaytechCS,DBBAL-bodb_PlaytechCS

	Revisions:
		- 20161229@Francis: Improve the way to retrieve XmlData [RedmineID: #68972]
		- 20170214@Francis: Keep about 5000 finished rows in Queue
		- 20171218@Percy: Add ErrCode, ErrMsg replace RAISERROR [RedmineID: #88325]
		- 20211004@Sol: LAP - Support IPv6 - [RedmineID: #162342]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
		- 20211011@Danny: Import data based on settle status [RedmineID: #162947]

	Param explanation:
	
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput != 0
		IF (SELECT ProductID FROM dbo.Product3rd_ImportQueue WITH (NOLOCK) WHERE QueueID = @QueueIDInput) != 10
		BEGIN
			SELECT	@ErrCode = 100,
					@ErrMsg = N'Input QueueID is not compitable with the product, please check again!'
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
		LoginIP		VARCHAR(45),
		Currency	TINYINT,
		Flag		SMALLINT
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
			
			INSERT INTO #TmpData(BillNo, IBCCustID, BetTime, GameType, BetAmount, NetAmount, PlayType, LoginIP, Currency, Flag)
				SELECT 
					x.v.value('(BILLNO/text())[1]', 'BIGINT') AS BillNo,
					x.v.value('(IBCCUSTID/text())[1]', 'INT') AS IBCCustID,
					CONVERT(VARCHAR(10), x.v.value('(BETTIME/text())[1]', 'DATETIME'), 120) AS BetTime,	
					x.v.value('(GAMETYPE/text())[1]', 'VARCHAR(10)') AS GameType,	
					x.v.value('(BETAMOUNT/text())[1]', 'MONEY') AS BetAmount,	
					x.v.value('(NETAMOUNT/text())[1]', 'MONEY') AS NetAmount,	
					x.v.value('(PLAYTYPE/text())[1]', 'SMALLINT') AS PlayType,
					x.v.value('(LOGINIP/text())[1]', 'VARCHAR(45)') AS LoginIP,	
					x.v.value('(CURRENCY/text())[1]', 'TINYINT') AS Currency,
					x.v.value('(FLAG/text())[1]', 'SMALLINT') AS Flag
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

			/* Flag description
				1 - settled
				0 - not yet settled
				-1 - reset testing balance
				-2 - bet placed had been modified
				-8 - cancelled designated bet placed
				-9 - cancelled bet placed
			*/
			DELETE	dbo.bettrans_AGCasino 
			WHERE  TicketID IN (	SELECT BillNo
									FROM 	#TmpData 
									WHERE Flag IN (-1, -8, -9)
								)
		
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
					SELECT QueueID
					FROM dbo.Product3rd_ImportQueue WITH (NOLOCK)
					WHERE FinishedTime IS NOT NULL 
						AND isSummarized = 1
						AND QueueID < (@QueueID - 5000))
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
		SELECT	@ErrCode = 101,
				@ErrMsg = ERROR_MESSAGE()

		SELECT  @LogDesc = 'MsgError: ' + @ErrMsg
	
		UPDATE dbo.Product3rd_ImportQueue WITH (UPDLOCK, ROWLOCK)
		SET FinishedTime = NULL, LogDesc = @LogDesc
		WHERE QueueID = ISNULL(@QueueID,0)
	
		DROP TABLE #TmpData

		SELECT @ErrMsg = 'QueueID = ' + CONVERT(VARCHAR(20), @QueueID) + ', ProductID = 10, MsgError = ' + @ErrMsg
	
		RETURN
	END CATCH
END
GO