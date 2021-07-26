/*<info serverAlias="DBAFF12BET-Affiliate_12BET" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_APIProduct_ImportQueue_Process]
	@ProductId		INT,
	@QueueIdInput	INT = 0, -- manually import
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Import Data Job - Parse xml data from Queue by Product

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102322]
		- 20181201@Percy: Integrate new products: 12Crystal - GPI, 12Quartz - iSoftbet, 12Diamond - OPUS [RedmineID: #104892]
		- 20190128@Percy: Betsoft - Change way to get winlostdate [RedmineID: #107979]
		- 20190328@Percy: Betsoft - Remove convert time zone [RedmineID: #110638]
		- 20190520@Percy: Ebet - Change way to get winlostdate: PayoutTime to CreateTime [RedmineID: #110638]
		- 20191130@Percy: Add Playtech Casino [RedmineID: #124784]
		- 20191206@Percy: Integrate new products: 12Topaz, LB Keno, GPI lottery, VR Lottery [RedmineID: #117197]
		- 20200707@Percy: Integrate new product: KY Gaming [RedmineID: #131437]
		- 20200827@Percy: Re-Integrate 12Topaz due to API's change [RedmineID: #139043]
		- 20201216@Percy: Integrate new product: BTi [RedmineID: #144456]
		- 20210615@Malcolm: Integrate new product: IM Esports [RedmineID: #157048]
		- 20210726@Malcolm: Change key from BetId to purchaseId [RedmineID: #159061]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @QueueId BIGINT, @XmlData XML, @WinlostDate SMALLDATETIME, @LastQueueId BIGINT

	DECLARE @Exchange TABLE (ExchangeDate SMALLDATETIME, ExchangeId INT, Currency NVARCHAR(50), ExRate FLOAT, AffExRate FLOAT)
	DECLARE @tmpWinlostDate TABLE (winlostdate SMALLDATETIME)

	-- Manually import
	IF @QueueIdInput <> 0
	BEGIN
		SELECT @QueueId = QueueId, @XmlData = XmlData
		FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
		WHERE ProductId = @ProductId AND JobType = 0 AND QueueId = @QueueIdInput
	END
	ELSE
	BEGIN
		SELECT @LastQueueId = CONVERT(BIGINT, SettingValue)
		FROM dbo.APIProductSettings WITH (NOLOCK)
		WHERE ProductId = @ProductId AND SettingName = 'LastQueueId'

		SELECT TOP 1 @QueueId = QueueId, @XmlData = XmlData
		FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
		WHERE ProductId = @ProductId AND QueueId >= @LastQueueId AND JobType = 0 AND FinishedTime IS NULL
		ORDER BY QueueId
	END

	DECLARE @IsErr BIT = 1
	
	WHILE @XmlData IS NOT NULL
	BEGIN
		-- PTCS
		IF @ProductId = 3
		BEGIN
			CREATE TABLE #PTCS (winlostdate SMALLDATETIME, UserName NVARCHAR(50), Turnover MONEY, Winlost MONEY, Deposit MONEY, Bonus MONEY, PShare MONEY, PWin MONEY, WinlostPShare MONEY)

			DELETE @Exchange
			DELETE @tmpWinlostDate

			CREATE TABLE #__tmp (winlostdate SMALLDATETIME, IBCCustID INT, Currency INT, Deposit MONEY, Bonus MONEY, Turnover MONEY, Winlost MONEY, ExRate FLOAT, AffExRate FLOAT, AffId INT)

			BEGIN TRY
				INSERT INTO #PTCS (winlostdate, UserName, Turnover, Winlost, Deposit, Bonus, PShare, PWin, WinlostPShare)
				SELECT	winlostdate
						,CASE WHEN UserName LIKE 'x[_]%' THEN RIGHT(UserName, LEN(UserName) - 2) ELSE UserName END -- remove x_username
						,Turnover / Div
						,(WinlostPShare - PShare) / Div AS Winlost
						,Deposit / Div
						,Bonus / Div
						,PShare / Div
						,PWin / Div
						,WinlostPShare / Div
				FROM (
					SELECT	t.c.value('@date', 'SMALLDATETIME') AS winlostdate,
							t.c.value('@username', 'VARCHAR(200)') AS UserName,
							t.c.value('@turnover', 'MONEY') AS Turnover,
							t.c.value('@deposit', 'MONEY') AS Deposit,
							t.c.value('@bonus', 'MONEY') AS Bonus,
							t.c.value('@progressiveshare', 'MONEY') AS PShare,
							t.c.value('@progressivewin', 'MONEY') AS PWin,
							t.c.value('@winlostaff', 'MONEY') AS WinlostPShare,
							CONVERT(MONEY, a.Div) AS Div
					FROM @XmlData.nodes('/root/trans') AS t(c)
						CROSS APPLY (SELECT CASE WHEN t.c.value('@username', 'VARCHAR(200)') LIKE 'x[_]%' THEN 1000.0 ELSE 1.0 END AS Div) a
				) AS t
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				INSERT INTO @tmpWinlostDate (winlostdate)
				SELECT DISTINCT winlostdate FROM #PTCS

				INSERT INTO @Exchange (ExchangeDate, ExchangeId, Currency, ExRate, AffExRate)
				SELECT ex1.winlostdate, ex.ExchangeId, ex.Currency, ex.ActualRate AS ExRate, ex.ActualRate2 AS AffExRate
				FROM dbo.Exchange ex WITH (NOLOCK)
					INNER JOIN
					(
						SELECT w.winlostdate, e.ExchangeId, MAX(e.UpdatedTime) AS UpdatedTime
						FROM dbo.Exchange e WITH (NOLOCK)
							INNER JOIN @tmpWinlostdate w ON e.UpdatedTime <= w.winlostdate
						GROUP BY w.winlostdate, e.ExchangeId
					) ex1 ON ex.ExchangeId = ex1.ExchangeId AND ex.UpdatedTime = ex1.UpdatedTime

				INSERT INTO #__tmp (winlostdate, IBCCustID, Currency, Deposit, Bonus, Turnover, Winlost, ExRate, AffExRate, AffId)
				SELECT d.winlostdate, d.IBCCustID, d.Currency, d.Deposit, d.Bonus, d.Turnover, -d.Winlost, ex.ExRate, ex.AffExRate, d.AffId
				FROM (
					SELECT t.winlostdate, mi.IBCCustID, mi.Currency, mi.AffId, SUM(Deposit) Deposit, SUM(Bonus) Bonus, SUM(Turnover) Turnover, SUM(Winlost) Winlost
					FROM #PTCS t
						INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON '12BET$' + t.Username = mi.Username
						INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON mi.AffId = ai.AffId AND winlostdate >= ai.CasinoJoinedDate
						LEFT JOIN dbo.MemberRemoval mr WITH (NOLOCK) ON mi.IBCCustID = mr.IBCCustID
					WHERE ai.CasinoJoinedDate IS NOT NULL
						AND mi.CreatedDate IS NOT NULL
						AND DATEDIFF(DAY, mi.CreatedDate, winlostdate) >= 0
						AND (
							mr.IBCCustID IS NULL
							OR DATEDIFF(MONTH, mr.RemovedDate, winlostdate) < 0
						)
					GROUP BY t.winlostdate, mi.IBCCustID, mi.Currency, mi.AffId
				) AS d
					INNER JOIN @Exchange ex ON d.Currency = ex.ExchangeID AND d.winlostdate = ex.ExchangeDate

				-- Check data
				;WITH CTE_rptMemberDaily AS
				(
					SELECT WinlostDate, IBCCustID, AffId, ProductId, Currency, AffExRate, ExRate, Bonus, Turnover, Winloss
					FROM dbo.rptMemberDaily WITH (NOLOCK)
					WHERE winlostdate IN (SELECT winlostdate FROM @tmpWinlostDate)
						AND ProductId IN (3, -3)
				)
				SELECT
					CASE	WHEN t.winlostdate IS NULL THEN -1 -- delete
							WHEN r.winlostdate IS NULL THEN 1 -- insert
							ELSE 0 END AS ModifiedType-- update
					,ISNULL(t.winlostdate, r.winlostdate) AS winlostdate
					,ISNULL(t.IBCCustId, r.IBCCustId) AS IBCCustId
					,ISNULL(t.ProductId, r.ProductId) AS ProductId
					,t.AffId, t.Currency, t.AffExRate, t.ExRate, t.Bonus, t.Turnover, t.Winloss
				INTO #__Data
				FROM (
					SELECT t1.WinlostDate, t1.IBCCustID, t1.AffId, t2.ProductId, t1.Currency, t1.AffExRate, t1.ExRate, t2.Bonus, t2.Turnover, t2.Winloss
					FROM #__tmp t1
						CROSS APPLY (
							SELECT 3 AS ProductId, 0 AS Bonus, Turnover, Winlost AS Winloss
							WHERE Turnover <> 0 OR Winlost <> 0
							UNION ALL
							SELECT -3 AS ProductId, Bonus, 0 AS Turnover, 0 AS Winloss
							WHERE Bonus <> 0
						) AS t2
				) AS t
					FULL OUTER JOIN CTE_rptMemberDaily r
						ON t.winlostdate = r.winlostdate AND t.IBCCustId = r.IBCCustId AND t.ProductId = r.ProductId

				SELECT @WinlostDate = MIN(WinlostDate) FROM #__Data

				-- Delete
				IF EXISTS (SELECT 1 FROM #__Data WHERE ModifiedType = -1)
				BEGIN
					DELETE r WITH (ROWLOCK, UPDLOCK)
					FROM dbo.rptMemberDaily r
						INNER JOIN #__Data d ON d.winlostdate = r.winlostdate AND d.IBCCustId = r.IBCCustId AND d.ProductId = r.ProductId
					WHERE d.ModifiedType = -1

					DELETE #__Data WHERE ModifiedType = -1
				END
				
				-- Insert
				IF EXISTS (SELECT 1 FROM #__Data WHERE ModifiedType = 1)
				BEGIN
					DELETE #__Data
					OUTPUT DELETED.WinlostDate,DELETED.AffId,DELETED.IBCCustId,DELETED.ProductId
							,0 Deposit,0 Withdrawal,DELETED.Bonus,0 Adjustment,DELETED.Turnover,DELETED.Winloss
							,DELETED.Currency,DELETED.ExRate,DELETED.AffExRate,0 AWinloss,0 AComm
					INTO dbo.rptMemberDaily(WinlostDate,AffId,IBCCustId,ProductId,Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,Currency,ExRate,AffExRate,AWinloss,AComm)
					WHERE ModifiedType = 1
				END

				-- Update
				IF EXISTS (SELECT 1 FROM #__Data WHERE ModifiedType = 0)
				BEGIN
					UPDATE r WITH (ROWLOCK)
					SET r.AffId = d.AffId
						,r.Deposit = 0
						,r.Withdrawal = 0
						,r.Bonus = d.Bonus
						,r.Adjustment = 0
						,r.Turnover = d.Turnover
						,r.Winloss = d.Winloss
						,r.Currency = d.Currency
						,r.ExRate = d.ExRate
						,r.AffExRate = d.AffExRate
						,r.AWinloss = 0
						,r.AComm = 0
					FROM dbo.rptMemberDaily r
						INNER JOIN #__Data d ON d.winlostdate = r.winlostdate AND d.IBCCustId = r.IBCCustId AND d.ProductId = r.ProductId
					WHERE d.ModifiedType = 0
						AND (
							r.AffId <> d.AffId
							OR r.Bonus <> d.Bonus
							OR r.Turnover <> d.Turnover
							OR r.Winloss <> d.Winloss
							OR r.Currency <> d.Currency
							OR r.ExRate <> d.ExRate
							OR r.AffExRate <> d.AffExRate
						)
				END

				DROP TABLE #__Data

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH

			DROP TABLE #__tmp
			DROP TABLE #PTCS
		END
		-- Ebet
		ELSE IF @ProductId = 10
		BEGIN
			CREATE TABLE #Ebet (Username NVARCHAR(50), BetHistoryId NVARCHAR(100), Bet MONEY, Payout MONEY, CreateTime DATETIME, PayoutTime DATETIME)

			BEGIN TRY
				INSERT INTO #Ebet (Username, BetHistoryId, Bet, Payout, CreateTime, PayoutTime)
				SELECT	t.c.value('@USERNAME', 'NVARCHAR(50)')	AS Username,
						t.c.value('@ID', 'NVARCHAR(100)')		AS BetHistoryId,
						t.c.value('@BET', 'MONEY')				AS Bet,
						t.c.value('@PAYOUT', 'MONEY')			AS Payout,
						t.c.value('@CREATETIME', 'DATETIME')	AS CreateTime,
						t.c.value('@PAYOUTTIME', 'DATETIME')	AS PayoutTime
				FROM @XmlData.nodes('ROOT/RESPONSE/BETHISTORYLIST/BETHISTORY') AS t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				DELETE be WITH (ROWLOCK, UPDLOCK)
				FROM dbo.bettrans_Ebet be
				WHERE EXISTS (SELECT 1 FROM #Ebet e WHERE be.BetHistoryId = e.BetHistoryId)

				INSERT INTO dbo.bettrans_Ebet (IBCCustId, Username, BetHistoryId, Bet, Payout, CreateTime, PayoutTime, WinlostDate)
				SELECT m.IBCCustId, e.Username, e.BetHistoryId, e.Bet, e.Payout, e.CreateTime, e.PayoutTime, CONVERT(DATE, e.CreateTime) AS WinlostDate
				FROM #Ebet e
					INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + e.Username = m.Username

				SELECT @WinlostDate = MIN(CONVERT(DATE, CreateTime)) FROM #Ebet

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH

			DROP TABLE #Ebet
		END
		-- Betsoft
		ELSE IF @ProductId = 11
		BEGIN
			CREATE TABLE #Betsoft (Username NVARCHAR(50), GameSessionId BIGINT, GameId INT, PlatForm VARCHAR(50), BetId INT, Amount MONEY, Win MONEY, BetTime DATETIME, StartDate DATETIME, EndDate DATETIME)

			DECLARE @StartDate DATETIME, @EndDate DATETIME
			
			BEGIN TRY
				SELECT	@StartDate = REPLACE(t.c.value('(STARTDATE/text())[1]', 'VARCHAR(50)'), '_', ' '),
						@EndDate = REPLACE(t.c.value('(ENDDATE/text())[1]', 'VARCHAR(50)'), '_', ' ')
				FROM @XmlData.nodes('BSGSYSTEM/REQUEST') AS t(c)

				IF DATEDIFF(DAY, @StartDate, DATEADD(SECOND, -1, @EndDate)) <> 0
				BEGIN
					SELECT @ErrCode = 100, @ErrMsg = CONVERT(NVARCHAR(100), @QueueId) + ': StartDate and EndDate are not in the same date!'
					RETURN
				END

				SELECT @WinlostDate = CONVERT(DATE, @StartDate)
				
				INSERT INTO #Betsoft (Username, GameSessionId, GameId, PlatForm, BetId, Amount, Win, BetTime, StartDate, EndDate)
				SELECT	t.c.value('(USERNAME/text())[1]', 'NVARCHAR(50)')	AS Username,
						t1.c.value('@id', 'BIGINT')							AS GameSessionId,
						t1.c.value('(GAMEID/text())[1]', 'INT')				AS GameId,
						t1.c.value('(PLATFORM/text())[1]', 'VARCHAR(50)')	AS PlatForm,
						t2.c.value('@id', 'INT')							AS BetId,
						t2.c.value('(AMOUNT/text())[1]', 'MONEY')			AS Amount,
						t2.c.value('(WIN/text())[1]', 'MONEY')				AS Win,
						t2.c.value('(BETTIME/text())[1]', 'DATETIME')		AS BetTime,
						@StartDate,
						@EndDate
				FROM @XmlData.nodes('BSGSYSTEM/RESPONSE/ACCOUNT') AS t(c)
					CROSS APPLY t.c.nodes('GAMESESSION') AS t1(c)
					CROSS APPLY t1.c.nodes('BET') AS t2(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				DELETE bb WITH (ROWLOCK, UPDLOCK)
				FROM dbo.bettrans_Betsoft bb
				WHERE EXISTS (SELECT 1 FROM #Betsoft b WHERE bb.Username = b.Username AND bb.GameSessionId = b.GameSessionId AND bb.GameId = b.GameId)
				
				INSERT INTO dbo.bettrans_Betsoft (IBCCustId, Username, GameSessionId, GameId, PlatForm, BetId, Amount, Win, BetTime, StartDate, EndDate, WinlostDate)
				SELECT m.IBCCustId, b.Username, b.GameSessionId, b.GameId, b.PlatForm, b.BetId, b.Amount, b.Win, b.BetTime, b.StartDate, b.EndDate, @WinlostDate
				FROM #Betsoft b
					INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + b.Username = m.Username

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH

			DROP TABLE #Betsoft
		END
		-- Crystal
		ELSE IF @ProductId = 12
		BEGIN
			CREATE TABLE #Crystal (operationCode BIGINT, userId VARCHAR(50), changeTime DATETIME, changeType VARCHAR(20), gameName VARCHAR(200), fround SMALLINT, bet MONEY, ret MONEY, changes MONEY, endBalance MONEY, operator VARCHAR(50), jcon MONEY, jwin MONEY, platform TINYINT, gametype SMALLINT, ver VARCHAR(20))

			BEGIN TRY
				INSERT INTO #Crystal (operationCode, userId, changeTime, changeType, gameName, fround, bet, ret, changes, endBalance, operator, jcon, jwin, platform, gametype, ver)
				SELECT	t.c.value('@operationCode', 'BIGINT')	AS operationCode,
						t.c.value('@userId', 'VARCHAR(50)')		AS userId,
						CONVERT(DATETIME, t.c.value('@changeTime', 'VARCHAR(50)'), 105)	AS changeTime,
						t.c.value('@changeType', 'VARCHAR(20)')	AS changeType,
						t.c.value('@gameName', 'VARCHAR(200)')	AS gameName,
						t.c.value('@fround', 'SMALLINT')		AS fround,
						t.c.value('@bet', 'MONEY')				AS bet,
						t.c.value('@ret', 'MONEY')				AS ret,
						t.c.value('@changes', 'MONEY')			AS changes,
						t.c.value('@endBalance', 'MONEY')		AS endBalance,
						t.c.value('@operator', 'VARCHAR(50)')	AS operator,
						t.c.value('@jcon', 'MONEY')				AS jcon,
						t.c.value('@jwin', 'MONEY')				AS jwin,
						t.c.value('@platform', 'TINYINT')		AS platform,
						t.c.value('@gametype', 'SMALLINT')		AS gametype,
						t.c.value('@ver', 'VARCHAR(20)')		AS ver
				FROM @XmlData.nodes('historyinfo/history') AS t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				DELETE bc WITH (ROWLOCK, UPDLOCK)
				FROM dbo.bettrans_Crystal bc
				WHERE EXISTS (SELECT 1 FROM #Crystal c WHERE bc.operationCode = c.operationCode)
				
				INSERT INTO dbo.bettrans_Crystal (operationCode, userId, changeTime, changeType, gameName, fround, bet, ret, changes, endBalance, operator, jcon, jwin, platform, gametype, ver, IBCCustId, WinlostDate)
				SELECT c.operationCode, c.userId, c.changeTime, c.changeType, c.gameName, c.fround, c.bet, c.ret, c.changes, c.endBalance, c.operator, c.jcon, c.jwin, c.platform, c.gametype, c.ver, m.IBCCustId, CONVERT(DATE, c.changeTime) AS WinlostDate
				FROM #Crystal c
					INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + c.userId = m.Username

				SELECT @WinlostDate = MIN(CONVERT(DATE, changeTime)) FROM #Crystal

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH

			DROP TABLE #Crystal
		END
		-- iSoftbet
		ELSE IF @ProductId = 13
		BEGIN
			CREATE TABLE #iSoftbet (PLAYERID VARCHAR(50), CURRENCY VARCHAR(5), SESSIONID VARCHAR(100), GAMEID VARCHAR(10), ROUNDID VARCHAR(100), TRANSACTIONID VARCHAR(100), TYPE VARCHAR(50), TIME DATETIME, AMOUNT MONEY)

			BEGIN TRY
				INSERT INTO #iSoftbet (PLAYERID, CURRENCY, SESSIONID, GAMEID, ROUNDID, TRANSACTIONID, TYPE, TIME, AMOUNT)
				SELECT	t.c.value('@PLAYERID', 'VARCHAR(50)')		AS PLAYERID,
						t.c.value('@CURRENCY', 'VARCHAR(5)')		AS CURRENCY,
						t.c.value('@SESSIONID', 'VARCHAR(100)')		AS SESSIONID,
						t.c.value('@GAMEID', 'VARCHAR(10)')			AS GAMEID,
						t.c.value('@ROUNDID', 'VARCHAR(100)')		AS ROUNDID,
						t.c.value('@TRANSACTIONID', 'VARCHAR(100)')	AS TRANSACTIONID,
						t.c.value('@TYPE', 'VARCHAR(50)')			AS TYPE,
						t.c.value('@TIME', 'DATETIME')				AS TIME,
						t.c.value('@AMOUNT', 'MONEY')				AS AMOUNT
				FROM @XmlData.nodes('ROOT/RESPONSE/BETHISTORYLIST/BETHISTORY') AS t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				DELETE bi WITH (ROWLOCK, UPDLOCK)
				FROM dbo.bettrans_iSoftbet bi
				WHERE EXISTS (SELECT 1 FROM #iSoftbet i WHERE bi.TRANSACTIONID = i.TRANSACTIONID)
				
				INSERT INTO dbo.bettrans_iSoftbet (PLAYERID, CURRENCY, SESSIONID, GAMEID, ROUNDID, TRANSACTIONID, TYPE, TIME, AMOUNT, IBCCustId, WinlostDate)
				SELECT i.PLAYERID, i.CURRENCY, i.SESSIONID, i.GAMEID, i.ROUNDID, i.TRANSACTIONID, i.TYPE, i.TIME, i.AMOUNT, m.IBCCustId, CONVERT(DATE, i.TIME) AS WinlostDate
				FROM #iSoftbet i
					INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + i.PLAYERID = m.Username

				SELECT @WinlostDate = MIN(CONVERT(DATE, TIME)) FROM #iSoftbet

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH

			DROP TABLE #iSoftbet
		END
		-- OPUS
		ELSE IF @ProductId = 14
		BEGIN
			CREATE TABLE #OPUS (transaction_id BIGINT, transaction_date_time DATETIME, member_code VARCHAR(30), member_type VARCHAR(10), currency VARCHAR(5), balance_start MONEY, balance_end MONEY, bet MONEY, win MONEY, game_code VARCHAR(5), game_detail VARCHAR(300), bet_status VARCHAR(10), player_hand NVARCHAR(4000), game_result VARCHAR(500), game_category VARCHAR(10), vendor VARCHAR(20), DrawNumber INT, m88_studio VARCHAR(5), stamp_date DATETIME, bet_record_id VARCHAR(10))

			BEGIN TRY
				INSERT INTO #OPUS (transaction_id, transaction_date_time, member_code, member_type, currency, balance_start, balance_end, bet, win, game_code, game_detail, bet_status, player_hand, game_result, game_category, vendor, DrawNumber, m88_studio, stamp_date, bet_record_id)
				SELECT	t.c.value('(transaction_id/text())[1]', 'BIGINT')			AS transaction_id,
						t.c.value('(transaction_date_time/text())[1]', 'DATETIME')	AS transaction_date_time,
						t.c.value('(member_code/text())[1]', 'VARCHAR(50)')			AS member_code,
						t.c.value('(member_type/text())[1]', 'VARCHAR(10)')			AS member_type,
						t.c.value('(currency/text())[1]', 'VARCHAR(5)')				AS currency,
						t.c.value('(balance_start/text())[1]', 'MONEY')				AS balance_start,
						t.c.value('(balance_end/text())[1]', 'MONEY')				AS balance_end,
						t.c.value('(bet/text())[1]', 'MONEY')						AS bet,
						t.c.value('(win/text())[1]', 'MONEY')						AS win,
						t.c.value('(game_code/text())[1]', 'VARCHAR(5)')			AS game_code,
						t.c.value('(game_detail/text())[1]', 'VARCHAR(300)')		AS game_detail,
						t.c.value('(bet_status/text())[1]', 'VARCHAR(10)')			AS bet_status,
						t.c.value('(player_hand/text())[1]', 'NVARCHAR(MAX)')		AS player_hand,
						t.c.value('(game_result/text())[1]', 'VARCHAR(500)')		AS game_result,
						t.c.value('(game_category/text())[1]', 'VARCHAR(10)')		AS game_category,
						t.c.value('(vendor/text())[1]', 'VARCHAR(20)')				AS vendor,
						t.c.value('(DrawNumber/text())[1]', 'INT')					AS DrawNumber,
						t.c.value('(m88_studio/text())[1]', 'VARCHAR(5)')			AS m88_studio,
						t.c.value('(stamp_date/text())[1]', 'DATETIME')				AS stamp_date,
						t.c.value('(bet_record_id/text())[1]', 'VARCHAR(10)')		AS bet_record_id
				FROM @XmlData.nodes('Transaction_Detail/bets/row') AS t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				DELETE bo WITH (ROWLOCK, UPDLOCK)
				FROM dbo.bettrans_OPUS bo
				WHERE EXISTS (SELECT 1 FROM #OPUS o WHERE bo.transaction_id = o.transaction_id)
				
				INSERT INTO dbo.bettrans_OPUS (transaction_id, transaction_date_time, member_code, member_type, currency, balance_start, balance_end, bet, win, game_code, game_detail, bet_status, player_hand, game_result, game_category, vendor, DrawNumber, m88_studio, stamp_date, bet_record_id, IBCCustId, WinlostDate)
				SELECT o.transaction_id, o.transaction_date_time, o.member_code, o.member_type, o.currency, o.balance_start, o.balance_end, o.bet, o.win, o.game_code, o.game_detail, o.bet_status, o.player_hand, o.game_result, o.game_category, o.vendor, o.DrawNumber, o.m88_studio, o.stamp_date, o.bet_record_id, m.IBCCustId, CONVERT(DATE, o.transaction_date_time) AS WinlostDate
				FROM #OPUS o
					INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + RIGHT(o.member_code, LEN(o.member_code) - 3) = m.Username

				SELECT @WinlostDate = MIN(CONVERT(DATE, transaction_date_time)) FROM #OPUS

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH

			DROP TABLE #OPUS
		END
		-- GPI Lottery
		ELSE IF @ProductId = 20
		BEGIN
			CREATE TABLE #GPILottery (memberId VARCHAR(50), memberType VARCHAR(10), betId BIGINT, betNo VARCHAR(50), drawId BIGINT, drawNo VARCHAR(50), areaName VARCHAR(50), isRNG BIT, betType VARCHAR(50), betContent VARCHAR(20), currency VARCHAR(10), betAmount MONEY, odds FLOAT, isWin BIT, winAmount MONEY, timeBet DATETIME, actionTime DATETIME, status VARCHAR(20), OS VARCHAR(10))

			BEGIN TRY
				INSERT INTO #GPILottery (memberId, memberType, betId, betNo, drawId, drawNo, areaName, isRNG, betType, betContent, currency, betAmount, odds, isWin, winAmount, timeBet, actionTime, status, OS)
				SELECT	t.c.value('(memberId/text())[1]', 'VARCHAR(50)')	AS memberId,
						t.c.value('(memberType/text())[1]', 'VARCHAR(10)')	AS memberType,
						t.c.value('(betId/text())[1]', 'BIGINT')			AS betId,
						t.c.value('(betNo/text())[1]', 'VARCHAR(50)')		AS betNo,
						t.c.value('(drawId/text())[1]', 'BIGINT')			AS drawId,
						t.c.value('(drawNo/text())[1]', 'VARCHAR(50)')		AS drawNo,
						t.c.value('(areaName/text())[1]', 'VARCHAR(50)')	AS areaName,
						t.c.value('(isRNG/text())[1]', 'BIT')				AS isRNG,
						t.c.value('(betType/text())[1]', 'VARCHAR(50)')		AS betType,
						t.c.value('(betContent/text())[1]', 'VARCHAR(20)')	AS betContent,
						t.c.value('(currency/text())[1]', 'VARCHAR(10)')	AS currency,
						t.c.value('(betAmount/text())[1]', 'MONEY')			AS betAmount,
						t.c.value('(odds/text())[1]', 'FLOAT')				AS odds,
						t.c.value('(isWin/text())[1]', 'BIT')				AS isWin,
						t.c.value('(winAmount/text())[1]', 'MONEY')			AS winAmount,
						t.c.value('(timeBet/text())[1]', 'DATETIME')		AS timeBet,
						t.c.value('(actionTime/text())[1]', 'DATETIME')		AS actionTime,
						t.c.value('(status/text())[1]', 'VARCHAR(20)')		AS status,
						t.c.value('(OS/text())[1]', 'VARCHAR(10)')			AS OS
				FROM @XmlData.nodes('root/transactions') AS t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				DELETE bg WITH (ROWLOCK, UPDLOCK)
				FROM dbo.bettrans_GPILottery bg
				WHERE EXISTS (SELECT 1 FROM #GPILottery g WHERE bg.betId = g.betId)
				
				INSERT INTO dbo.bettrans_GPILottery (memberId, memberType, betId, betNo, drawId, drawNo, areaName, isRNG, betType, betContent, currency, betAmount, odds, isWin, winAmount, timeBet, actionTime, status, OS, IBCCustId, WinlostDate)
				SELECT g.memberId, g.memberType, g.betId, g.betNo, g.drawId, g.drawNo, g.areaName, g.isRNG, g.betType, g.betContent, g.currency, g.betAmount, g.odds, g.isWin, g.winAmount, g.timeBet, g.actionTime, g.status, g.OS, m.IBCCustId, CONVERT(DATE, g.timeBet) AS WinlostDate
				FROM #GPILottery g
					INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + g.memberId = m.Username

				SELECT @WinlostDate = MIN(CONVERT(DATE, timeBet)) FROM #GPILottery

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH

			DROP TABLE #GPILottery
		END
		-- VR Lottery
		ELSE IF @ProductId = 21
		BEGIN
			CREATE TABLE #VRLottery (Provider VARCHAR(20), GameId VARCHAR(30), GameName VARCHAR(100), GameNo VARCHAR(20), GameNoId INT, PlayerId VARCHAR(50), ProviderPlayerId NVARCHAR(200), Currency VARCHAR(10), Tray SMALLINT, BetId VARCHAR(50), BetOn NVARCHAR(50), BetType NVARCHAR(100), BetDetails VARCHAR(100), Odds NVARCHAR(100), BetAmount MONEY, ValidBet MONEY, WinLoss MONEY, PlayerWinLoss MONEY, LossPrize MONEY, Tips MONEY, CommissionRate FLOAT, Commission MONEY, Status VARCHAR(20), Platform VARCHAR(20), BetDate DATETIME, ResultDate DATETIME, DateCreated DATETIME, LastUpdatedDate DATETIME)
			BEGIN TRY
				INSERT INTO #VRLottery (Provider, GameId, GameName, GameNo, GameNoId, PlayerId, ProviderPlayerId, Currency, Tray, BetId, BetOn, BetType, BetDetails, Odds, BetAmount, ValidBet, WinLoss, PlayerWinLoss, LossPrize, Tips, CommissionRate, Commission, Status, Platform, BetDate, ResultDate, DateCreated, LastUpdatedDate)
				SELECT	t.c.value('(Provider/text())[1]', 'VARCHAR(20)') AS Provider,
						t.c.value('(GameId/text())[1]', 'VARCHAR(30)') AS GameId,
						t.c.value('(GameName/text())[1]', 'VARCHAR(100)') AS GameName,
						t.c.value('(GameNo/text())[1]', 'VARCHAR(20)') AS GameNo,
						t.c.value('(GameNoId/text())[1]', 'INT') AS GameNoId,
						t.c.value('(PlayerId/text())[1]', 'VARCHAR(50)') AS PlayerId,
						t.c.value('(ProviderPlayerId/text())[1]', 'NVARCHAR(200)') AS ProviderPlayerId,
						t.c.value('(Currency/text())[1]', 'VARCHAR(10)') AS Currency,
						t.c.value('(Tray/text())[1]', 'SMALLINT') AS Tray,
						t.c.value('(BetId/text())[1]', 'VARCHAR(50)') AS BetId,
						t.c.value('(BetOn/text())[1]', 'NVARCHAR(50)') AS BetOn,
						t.c.value('(BetType/text())[1]', 'NVARCHAR(100)') AS BetType,
						t.c.value('(BetDetails/text())[1]', 'VARCHAR(100)') AS BetDetails,
						t.c.value('(Odds/text())[1]', 'NVARCHAR(100)') AS Odds,
						t.c.value('(BetAmount/text())[1]', 'MONEY') AS BetAmount,
						t.c.value('(ValidBet/text())[1]', 'MONEY') AS ValidBet,
						t.c.value('(WinLoss/text())[1]', 'MONEY') AS WinLoss,
						t.c.value('(PlayerWinLoss/text())[1]', 'MONEY') AS PlayerWinLoss,
						t.c.value('(LossPrize/text())[1]', 'MONEY') AS LossPrize,
						t.c.value('(Tips/text())[1]', 'MONEY') AS Tips,
						t.c.value('(CommissionRate/text())[1]', 'FLOAT') AS CommissionRate,
						t.c.value('(Commission/text())[1]', 'MONEY') AS Commission,
						t.c.value('(Status/text())[1]', 'VARCHAR(20)') AS Status,
						t.c.value('(Platform/text())[1]', 'VARCHAR(20)') AS Platform,
						t.c.value('(BetDate/text())[1]', 'DATETIME') AS BetDate,
						t.c.value('(ResultDate/text())[1]', 'DATETIME') AS ResultDate,
						t.c.value('(DateCreated/text())[1]', 'DATETIME') AS DateCreated,
						t.c.value('(LastUpdatedDate/text())[1]', 'DATETIME') AS LastUpdatedDate
				FROM @XmlData.nodes('root/Result') AS t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				DELETE bv WITH (ROWLOCK, UPDLOCK)
				FROM dbo.bettrans_VRLottery bv
				WHERE EXISTS (SELECT 1 FROM #VRLottery v WHERE bv.betId = v.betId)
				
				INSERT INTO dbo.bettrans_VRLottery (Provider, GameId, GameName, GameNo, GameNoId, PlayerId, ProviderPlayerId, Currency, Tray, BetId, BetOn, BetType, BetDetails, Odds, BetAmount, ValidBet, WinLoss, PlayerWinLoss, LossPrize, Tips, CommissionRate, Commission, Status, Platform, BetDate, ResultDate, DateCreated, LastUpdatedDate, IBCCustId, WinlostDate)
				SELECT Provider, v.GameId, v.GameName, v.GameNo, v.GameNoId, v.PlayerId, v.ProviderPlayerId, v.Currency, v.Tray, v.BetId, v.BetOn, v.BetType, v.BetDetails, v.Odds, v.BetAmount, v.ValidBet, v.WinLoss, v.PlayerWinLoss, v.LossPrize, v.Tips, v.CommissionRate, v.Commission, v.Status, v.Platform, v.BetDate, v.ResultDate, v.DateCreated, v.LastUpdatedDate, m.IBCCustId, CONVERT(DATE, DATEADD(HOUR, -6.5, v.ResultDate)) AS WinlostDate
				FROM #VRLottery v
					INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + v.PlayerId = m.Username

				SELECT @WinlostDate = MIN(CONVERT(DATE, DATEADD(HOUR, -6.5, ResultDate))) FROM #VRLottery

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH

			DROP TABLE #VRLottery
		END
		-- LB Keno
		ELSE IF @ProductId = 22
		BEGIN
			CREATE TABLE #LBKeno (member_id VARCHAR(50), member_type VARCHAR(10), session_token VARCHAR(200), bet_id BIGINT, bet_no VARCHAR(50), match_no VARCHAR(10), match_area VARCHAR(10), match_id INT, bet_type VARCHAR(10), bet_content NVARCHAR(50), bet_currency VARCHAR(5), bet_money MONEY, bet_odds FLOAT, bet_winning MONEY, bet_win VARCHAR(20), bet_status VARCHAR(20), bet_time DATETIME, trans_time DATETIME, bet_platform VARCHAR(20), bet_previous_id BIGINT)
			BEGIN TRY
				INSERT INTO #LBKeno (member_id, member_type, session_token, bet_id, bet_no, match_no, match_area, match_id, bet_type, bet_content, bet_currency, bet_money, bet_odds, bet_winning, bet_win, bet_status, bet_time, trans_time, bet_platform, bet_previous_id)
				SELECT	t.c.value('@member_id', 'VARCHAR(50)')		AS member_id,
						t.c.value('@member_type', 'VARCHAR(10)')	AS member_type,
						t.c.value('@session_token', 'VARCHAR(200)') AS session_token,
						t.c.value('@bet_id', 'BIGINT')				AS bet_id,
						t.c.value('@bet_no', 'VARCHAR(50)')			AS bet_no,
						t.c.value('@match_no', 'VARCHAR(10)')		AS match_no,
						t.c.value('@match_area', 'VARCHAR(10)')		AS match_area,
						t.c.value('@match_id', 'INT')				AS match_id,
						t.c.value('@bet_type', 'VARCHAR(10)')		AS bet_type,
						t.c.value('@bet_content', 'NVARCHAR(50)')	AS bet_content,
						t.c.value('@bet_currency', 'VARCHAR(5)')	AS bet_currency,
						t.c.value('@bet_money', 'MONEY')			AS bet_money,
						t.c.value('@bet_odds', 'FLOAT')				AS bet_odds,
						t.c.value('@bet_winning', 'MONEY')			AS bet_winning,
						t.c.value('@bet_win', 'VARCHAR(20)')		AS bet_win,
						t.c.value('@bet_status', 'VARCHAR(20)')		AS bet_status,
						t.c.value('@bet_time', 'DATETIME')			AS bet_time,
						t.c.value('@trans_time', 'DATETIME')		AS trans_time,
						t.c.value('@bet_platform', 'VARCHAR(20)')	AS bet_platform,
						t.c.value('@bet_previous_id', 'BIGINT')		AS bet_previous_id
				FROM @XmlData.nodes('game_transaction_detail/bet/item') AS t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				DELETE bl WITH (ROWLOCK, UPDLOCK)
				FROM dbo.bettrans_LBKeno bl
				WHERE EXISTS (SELECT 1 FROM #LBKeno l WHERE bl.bet_id = l.bet_id)
				
				INSERT INTO dbo.bettrans_LBKeno (member_id, member_type, session_token, bet_id, bet_no, match_no, match_area, match_id, bet_type, bet_content, bet_currency, bet_money, bet_odds, bet_winning, bet_win, bet_status, bet_time, trans_time, bet_platform, bet_previous_id, IBCCustId, WinlostDate)
				SELECT l.member_id, l.member_type, l.session_token, l.bet_id, l.bet_no, l.match_no, l.match_area, l.match_id, l.bet_type, l.bet_content, l.bet_currency, l.bet_money, l.bet_odds, l.bet_winning, l.bet_win, l.bet_status, l.bet_time, l.trans_time, l.bet_platform, l.bet_previous_id, m.IBCCustId, CONVERT(DATE, l.trans_time) AS WinlostDate
				FROM #LBKeno l
					INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + l.member_id = m.Username

				SELECT @WinlostDate = MIN(CONVERT(DATE, trans_time)) FROM #LBKeno

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH

			DROP TABLE #LBKeno
		END
		-- 12 Topaz
		ELSE IF @ProductId = 23
		BEGIN
			CREATE TABLE #Topaz (id	BIGINT, betcount INT, wager MONEY, payout MONEY, revenue MONEY, account_id BIGINT, account_ext_ref VARCHAR(50), currency_unit VARCHAR(5), transaction_time DATETIME, created DATETIME, category VARCHAR(50))

			BEGIN TRY
				INSERT INTO #Topaz (id, betcount, wager, payout, revenue, account_id, account_ext_ref, currency_unit, transaction_time, created, category)
				SELECT	t.c.value('(id/text())[1]', 'BIGINT')					AS id,
						t.c.value('(num_of_wager/text())[1]', 'INT')			AS betcount,
						t.c.value('(sum_of_wager/text())[1]', 'MONEY')			AS wager,
						t.c.value('(sum_of_payout/text())[1]', 'MONEY')			AS payout,
						t.c.value('(revenue/text())[1]', 'MONEY')				AS revenue,
						t.c.value('(account_id/text())[1]', 'BIGINT')			AS account_id,
						t.c.value('(account_ext_ref/text())[1]', 'VARCHAR(50)')	AS account_ext_ref,
						t.c.value('(currency_unit/text())[1]', 'VARCHAR(5)')	AS currency_unit,
						t.c.value('(transaction_time/text())[1]', 'DATETIME')	AS transaction_time,
						t.c.value('(created/text())[1]', 'DATETIME')			AS created,
						t.c.value('(category/text())[1]', 'VARCHAR(50)')		AS category
				FROM @XmlData.nodes('root/data') AS t(c)
				WHERE t.c.value('(category/text())[1]', 'VARCHAR(50)') = 'ENDROUND'
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				DELETE bt WITH (ROWLOCK, UPDLOCK)
				FROM dbo.bettrans_Topaz2 bt
				WHERE EXISTS (SELECT 1 FROM #Topaz t WHERE bt.id = t.id)
				
				INSERT INTO dbo.bettrans_Topaz2 (id, betcount, wager, payout, revenue, account_id, account_ext_ref, currency_unit, transaction_time, created, category, IBCCustId, WinlostDate)
				SELECT t.id, t.betcount, t.wager, t.payout, t.revenue, t.account_id, t.account_ext_ref, t.currency_unit, t.transaction_time, t.created, t.category, m.IBCCustId, CONVERT(DATE, t.transaction_time) AS WinlostDate
				FROM #Topaz t
					INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON t.account_ext_ref = m.Username

				SELECT @WinlostDate = MIN(CONVERT(DATE, transaction_time)) FROM #Topaz

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH

			DROP TABLE #Topaz
		END
		-- KY Gaming
		ELSE IF @ProductId = 24
		BEGIN
			CREATE TABLE #KYGaming (GameID NVARCHAR(50), Accounts NVARCHAR(50), ServerID INT, KindID INT, TableID INT, ChairID INT, UserCount INT, CardValue NVARCHAR(MAX), CellScore FLOAT, AllBet FLOAT, Profit FLOAT, Revenue FLOAT, GameStartTime DATETIME, GameEndTime DATETIME, ChannelID INT, LineCode NVARCHAR(50))

			BEGIN TRY
				INSERT INTO #KYGaming (GameID, Accounts, ServerID, KindID, TableID, ChairID, UserCount, CardValue, CellScore, AllBet, Profit, Revenue, GameStartTime, GameEndTime, ChannelID, LineCode)
				SELECT	t.c.value('(GameID/text())[1]', 'NVARCHAR(50)')		AS GameID,
						t.c.value('(Accounts/text())[1]', 'NVARCHAR(50)')	AS Accounts,
						t.c.value('(ServerID/text())[1]', 'INT')			AS ServerID,
						t.c.value('(KindID/text())[1]', 'INT')				AS KindID,
						t.c.value('(TableID/text())[1]', 'INT')				AS TableID,
						t.c.value('(ChairID/text())[1]', 'INT')				AS ChairID,
						t.c.value('(UserCount/text())[1]', 'INT')			AS UserCount,
						t.c.value('(CardValue/text())[1]', 'NVARCHAR(MAX)') AS CardValue,
						t.c.value('(CellScore/text())[1]', 'FLOAT')			AS CellScore,
						t.c.value('(AllBet/text())[1]', 'FLOAT')			AS AllBet,
						t.c.value('(Profit/text())[1]', 'FLOAT')			AS Profit,
						t.c.value('(Revenue/text())[1]', 'FLOAT')			AS Revenue,
						t.c.value('(GameStartTime/text())[1]', 'DATETIME')	AS GameStartTime,
						t.c.value('(GameEndTime/text())[1]', 'DATETIME')	AS GameEndTime,
						t.c.value('(ChannelID/text())[1]', 'INT')			AS ChannelID,
						t.c.value('(LineCode/text())[1]', 'NVARCHAR(50)')	AS LineCode
				FROM @XmlData.nodes('root/d/list') AS t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				DELETE bt WITH (ROWLOCK, UPDLOCK)
				FROM dbo.bettrans_KYGaming bt
				WHERE EXISTS (SELECT 1 FROM #KYGaming k WHERE bt.GameID = k.GameID)
				
				INSERT INTO dbo.bettrans_KYGaming (GameID, Accounts, ServerID, KindID, TableID, ChairID, UserCount, CardValue, CellScore, AllBet, Profit, Revenue, GameStartTime, GameEndTime, ChannelID, LineCode, IBCCustId, WinlostDate)
				SELECT GameID, Accounts, ServerID, KindID, TableID, ChairID, UserCount, CardValue, CellScore, AllBet, Profit, Revenue, GameStartTime, GameEndTime, ChannelID, LineCode, m.IBCCustId, CONVERT(DATE, k.GameEndTime) AS WinlostDate
				FROM #KYGaming k
					INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + REPLACE(k.Accounts, CONVERT(VARCHAR(30), ChannelID) + '_', '') = m.Username

				SELECT @WinlostDate = MIN(CONVERT(DATE, GameEndTime)) FROM #KYGaming

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH

			DROP TABLE #KYGaming
		END
		-- BTi
		ELSE IF @ProductId = 25
		BEGIN
			CREATE TABLE #BTi (PurchaseID BIGINT, BetID BIGINT, UserName VARCHAR(50), TotalStake MONEY, ValidStake MONEY, PL MONEY, BetStatus VARCHAR(30), BetSettledDate DATETIME)

			BEGIN TRY
				INSERT INTO #BTi (PurchaseID, BetID, UserName, TotalStake, ValidStake, PL, BetStatus, BetSettledDate)
				SELECT	t.c.value('(PurchaseID/text())[1]', 'BIGINT')		AS PurchaseID,
						t.c.value('(BetID/text())[1]', 'BIGINT')			AS BetID,
						t.c.value('(UserName/text())[1]', 'VARCHAR(50)')	AS UserName,
						t.c.value('(TotalStake/text())[1]', 'MONEY')		AS TotalStake,
						t.c.value('(ValidStake/text())[1]', 'MONEY')		AS ValidStake,
						t.c.value('(PL/text())[1]', 'MONEY')				AS PL,
						t.c.value('(BetStatus/text())[1]', 'VARCHAR(30)')	AS BetStatus,
						t.c.value('(BetSettledDate/text())[1]', 'DATETIME')	AS BetSettledDate
				FROM @XmlData.nodes('root/Bets') AS t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				SELECT @WinlostDate = MIN(CONVERT(DATE, BetSettledDate)) FROM #BTi

				IF @WinlostDate < '2021-07-01'
				BEGIN
					DELETE #BTi WHERE BetID IS NULL

					DELETE bt WITH (ROWLOCK, UPDLOCK)
					FROM dbo.bettrans_BTi bt
					WHERE EXISTS (SELECT 1 FROM #BTi k WHERE bt.BetID = k.BetID)

					INSERT INTO dbo.bettrans_BTi (BetID, UserName, TotalStake, ValidStake, PL, BetStatus, BetSettledDate, IBCCustId, WinlostDate)
					SELECT k.BetID, k.UserName, k.TotalStake, k.ValidStake, k.PL, k.BetStatus, k.BetSettledDate, m.IBCCustId, CONVERT(DATE, k.BetSettledDate) AS WinlostDate
					FROM #BTi k
						INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + k.UserName = m.Username
				END
				ELSE 
				BEGIN
					DELETE #BTi WHERE PurchaseID IS NULL

					DELETE bt WITH (ROWLOCK, UPDLOCK)
					FROM dbo.bettrans_BTi2 bt
					WHERE EXISTS (SELECT 1 FROM #BTi k WHERE bt.PurchaseId = k.PurchaseId)

					INSERT INTO dbo.bettrans_BTi2 (PurchaseId, UserName, TotalStake, ValidStake, PL, BetStatus, BetSettledDate, IBCCustId, WinlostDate)
					SELECT k.PurchaseId, k.UserName, k.TotalStake, k.ValidStake, k.PL, k.BetStatus, k.BetSettledDate, m.IBCCustId, CONVERT(DATE, k.BetSettledDate) AS WinlostDate
					FROM #BTi k
						INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + k.UserName = m.Username
				END		

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH

			DROP TABLE #BTi
		END

		-- IM Esports
		ELSE IF @ProductId = 31
		BEGIN
			CREATE TABLE #Sum_Winloss_IMEsports (PlayerId VARCHAR(50),Currency VARCHAR(10),BetCount INT, Turnover MONEY,ValidBet MONEY,WinLoss MONEY,IsHousePlayer SMALLINT,IBCCustId INT)

			DECLARE @FromDate SMALLDATETIME, @ToDate SMALLDATETIME

			SELECT @FromDate = t.c.value('(startDate/text())[1]', 'SMALLDATETIME'), @ToDate = t.c.value('(endDate/text())[1]', 'SMALLDATETIME')
			FROM  @XmlData.nodes('root') AS t(c)

			SELECT @WinlostDate = CONVERT(DATE, @FromDate)

			BEGIN TRY
				INSERT INTO #Sum_Winloss_IMEsports (PlayerId, Currency, BetCount, Turnover, ValidBet, WinLoss, IsHousePlayer, IBCCustId)
				SELECT	t.c.value('(PlayerId/text())[1]', 'VARCHAR(50)')	AS PlayerId,
						t.c.value('(Currency/text())[1]', 'VARCHAR(10)')	AS Currency,
						t.c.value('(BetCount/text())[1]', 'INT')			AS BetCount,
						t.c.value('(Turnover/text())[1]', 'MONEY')			AS Turnover,
						t.c.value('(ValidBet/text())[1]', 'MONEY')			AS ValidBet,					
						t.c.value('(WinLoss/text())[1]', 'MONEY')			AS WinLoss,
						t.c.value('(IsHousePlayer/text())[1]', 'SMALLINT')	AS IsHousePlayer,
						t.c.value('(IBCCustId/text())[1]', 'INT')			AS IBCCustId
				FROM @XmlData.nodes('root/Result/Details') AS t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				DELETE bt WITH (ROWLOCK, UPDLOCK)
				FROM dbo.Sum_Winloss_IMEsports bt	
				WHERE EXISTS (SELECT 1 FROM #Sum_Winloss_IMEsports t WHERE t.PlayerId = bt.PlayerId AND bt.WinlostDate = @WinlostDate)
				
				INSERT INTO dbo.Sum_Winloss_IMEsports (PlayerId, Currency, BetCount, Turnover, ValidBet, WinLoss, IsHousePlayer, FromDate, ToDate, IBCCustId, WinlostDate)
				SELECT k.PlayerId, k.Currency, k.BetCount, k.Turnover, k.ValidBet, k.WinLoss, k.IsHousePlayer, @FromDate, @ToDate, m.IBCCustId, @WinlostDate
				FROM #Sum_Winloss_IMEsports k
					INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + k.PlayerId = m.Username

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH

			DROP TABLE #Sum_Winloss_IMEsports
		END

		IF @IsErr = 1
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'Please help check data in APIProduct_ImportQueue table with QueueId = ' + CONVERT(NVARCHAR(100), @QueueId)
			RETURN
		END
		ELSE
		BEGIN
			UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
			SET FinishedTime = GETDATE(), WinlostDate = @WinlostDate, LogDesc = 'Successfully'
			WHERE QueueId = @QueueId

			SELECT @LastQueueId = @QueueId

			SELECT @QueueId = NULL, @XmlData = NULL

			IF @QueueIdInput = 0
				SELECT TOP 1 @QueueId = QueueId, @XmlData = XmlData
				FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
				WHERE ProductId = @ProductId AND QueueId >= @LastQueueId AND JobType = 0 AND FinishedTime IS NULL
				ORDER BY QueueId
		END
	END

	IF @IsErr = 0
	BEGIN
		UPDATE dbo.APIProductSettings WITH (ROWLOCK, UPDLOCK)
		SET SettingValue = CONVERT(VARCHAR(20), @LastQueueId)
		WHERE ProductId = @ProductId AND SettingName = 'LastQueueId'
	END
END
GO