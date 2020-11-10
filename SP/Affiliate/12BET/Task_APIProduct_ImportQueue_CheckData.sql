/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_APIProduct_ImportQueue_CheckData]
	@ProductId		INT,
	@QueueIdInput	INT = 0, -- manually import
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Import Data Job - Parse xml data from Queue by Product to check Data

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102322]
		- 20181201@Percy: Integrate new products: 12Crystal - GPI, 12Quartz - iSoftbet, 12Diamond - OPUS [RedmineID: #104892]
		- 20190128@Percy: Betsoft - Change way to get winlostdate [RedmineID: #107979]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @QueueId BIGINT, @XmlData XML, @WinlostDate SMALLDATETIME, @ListQueueId VARCHAR(MAX) = ''

	CREATE TABLE #Ebet (Username NVARCHAR(50), BetHistoryId NVARCHAR(100), Bet MONEY, Payout MONEY, PayoutTime DATETIME)
	CREATE TABLE #Betsoft (Username NVARCHAR(50), GameSessionId BIGINT, GameId INT, PlatForm VARCHAR(50), BetId INT, Amount MONEY, Win MONEY, BetTime DATETIME, StartDate DATETIME, EndDate DATETIME)
	CREATE TABLE #Crystal (operationCode BIGINT, userId VARCHAR(50), changeTime DATETIME, changeType VARCHAR(20), gameName VARCHAR(200), fround SMALLINT, bet MONEY, ret MONEY, changes MONEY, endBalance MONEY, operator VARCHAR(50), jcon MONEY, jwin MONEY, platform TINYINT, gametype SMALLINT, ver VARCHAR(20))
	CREATE TABLE #iSoftbet (PLAYERID VARCHAR(50), CURRENCY VARCHAR(5), SESSIONID VARCHAR(100), GAMEID VARCHAR(10), ROUNDID VARCHAR(100), TRANSACTIONID VARCHAR(100), TYPE VARCHAR(50), TIME DATETIME, AMOUNT MONEY)
	CREATE TABLE #OPUS (transaction_id BIGINT, transaction_date_time DATETIME, member_code VARCHAR(30), member_type VARCHAR(10), currency VARCHAR(5), balance_start MONEY, balance_end MONEY, bet MONEY, win MONEY, game_code VARCHAR(5), game_detail VARCHAR(300), bet_status VARCHAR(10), player_hand NVARCHAR(4000), game_result VARCHAR(500), game_category VARCHAR(10), vendor VARCHAR(20), DrawNumber INT, m88_studio VARCHAR(5), stamp_date DATETIME, bet_record_id VARCHAR(10))

	-- Manually import
	IF @QueueIdInput <> 0
		SELECT @QueueId = QueueId, @XmlData = XmlData
		FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
		WHERE ProductId = @ProductId AND JobType = 1 AND QueueId = @QueueIdInput
	ELSE
		SELECT TOP 1 @QueueId = QueueId, @XmlData = XmlData
		FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
		WHERE ProductId = @ProductId AND JobType = 1 AND FinishedTime IS NULL
		ORDER BY QueueId

	DECLARE @IsErr BIT = 1
	
	WHILE @XmlData IS NOT NULL
	BEGIN
		-- clean up tmp table
		TRUNCATE TABLE #Ebet
		TRUNCATE TABLE #Betsoft
		TRUNCATE TABLE #Crystal
		TRUNCATE TABLE #iSoftbet
		TRUNCATE TABLE #OPUS

		-- Ebet
		IF @ProductId = 10
		BEGIN
			BEGIN TRY
				INSERT INTO #Ebet (Username, BetHistoryId, Bet, Payout, PayoutTime)
				SELECT	t.c.value('@USERNAME', 'NVARCHAR(50)')	AS Username,
						t.c.value('@ID', 'NVARCHAR(100)')		AS BetHistoryId,
						t.c.value('@BET', 'MONEY')				AS Bet,
						t.c.value('@PAYOUT', 'MONEY')			AS Payout,
						t.c.value('@PAYOUTTIME', 'DATETIME')	AS PayoutTime
				FROM @XmlData.nodes('ROOT/RESPONSE/BETHISTORYLIST/BETHISTORY') AS t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				IF EXISTS (
					SELECT 1
					FROM (
						SELECT m.IBCCustId, e.Username, e.BetHistoryId, e.Bet, e.Payout, e.PayoutTime
						FROM #Ebet e
							INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + e.Username = m.Username
					) AS e
						LEFT JOIN dbo.bettrans_Ebet be WITH (NOLOCK) ON e.BetHistoryId = be.BetHistoryId
					WHERE be.BetHistoryId IS NULL
						OR e.Username	<> be.Username
						OR e.Bet		<> be.Bet
						OR e.Payout		<> be.Payout
						OR e.PayoutTime	<> be.PayoutTime
				)
				BEGIN
					SELECT @ListQueueId = @ListQueueId + ',' + CONVERT(VARCHAR(20), @QueueId)

					DELETE be WITH (ROWLOCK, UPDLOCK)
					FROM dbo.bettrans_Ebet be
					WHERE EXISTS (SELECT 1 FROM #Ebet e WHERE be.BetHistoryId = e.BetHistoryId)

					INSERT INTO dbo.bettrans_Ebet (IBCCustId, Username, BetHistoryId, Bet, Payout, PayoutTime, WinlostDate)
					SELECT m.IBCCustId, e.Username, e.BetHistoryId, e.Bet, e.Payout, e.PayoutTime, CONVERT(DATE, e.PayoutTime) AS WinlostDate
					FROM #Ebet e
						INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + e.Username = m.Username
				END

				SELECT @WinlostDate = MIN(CONVERT(DATE, PayoutTime)) FROM #Ebet

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH
		END
		-- Betsoft
		ELSE IF @ProductId = 11
		BEGIN
			DECLARE @StartDate DATETIME, @EndDate DATETIME

			BEGIN TRY
				SELECT	@StartDate = REPLACE(t.c.value('(STARTDATE/text())[1]', 'VARCHAR(50)'), '_', ' '),
						@EndDate = REPLACE(t.c.value('(ENDDATE/text())[1]', 'VARCHAR(50)'), '_', ' ')
				FROM @XmlData.nodes('BSGSYSTEM/REQUEST') AS t(c)

				-- Convert from GMT+0 to GMT-4
				SELECT @StartDate = DATEADD(HOUR, -4, @StartDate), @EndDate = DATEADD(HOUR, -4, @EndDate)

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

				IF EXISTS (
					SELECT 1
					FROM (
						SELECT m.IBCCustId, b.Username, b.GameSessionId, b.GameId, b.PlatForm, b.BetId, b.Amount, b.Win, b.BetTime, b.StartDate, b.EndDate
						FROM #Betsoft b
							INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + b.Username = m.Username
					) AS b
						LEFT JOIN dbo.bettrans_Betsoft bb WITH (NOLOCK) ON b.IBCCustId = bb.IBCCustId AND b.GameSessionId = bb.GameSessionId AND b.GameId = bb.GameId AND b.BetId = bb.BetId
					WHERE bb.Username IS NULL
						OR b.PlatForm	<> bb.PlatForm
						OR b.Amount		<> bb.Amount
						OR b.Win		<> bb.Win
						OR b.BetTime	<> bb.BetTime
						OR b.StartDate	<> bb.StartDate
						OR b.StartDate	<> bb.EndDate
				)
				BEGIN
					SELECT @ListQueueId = @ListQueueId + ',' + CONVERT(VARCHAR(20), @QueueId)
				
					DELETE bb WITH (ROWLOCK, UPDLOCK)
					FROM dbo.bettrans_Betsoft bb
					WHERE EXISTS (SELECT 1 FROM #Betsoft b WHERE bb.Username = b.Username AND bb.GameSessionId = b.GameSessionId AND bb.GameId = b.GameId)
				
					INSERT INTO dbo.bettrans_Betsoft (IBCCustId, Username, GameSessionId, GameId, PlatForm, BetId, Amount, Win, BetTime, StartDate, EndDate, WinlostDate)
					SELECT m.IBCCustId, b.Username, b.GameSessionId, b.GameId, b.PlatForm, b.BetId, b.Amount, b.Win, b.BetTime, b.StartDate, b.EndDate, @WinlostDate
					FROM #Betsoft b
						INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + b.Username = m.Username
				END

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH
		END
		-- Crystal
		ELSE IF @ProductId = 12
		BEGIN
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

				IF EXISTS (
					SELECT 1
					FROM (
						SELECT c.operationCode, c.userId, c.changeTime, c.changeType, c.gameName, c.fround, c.bet, c.ret, c.changes, c.endBalance, c.operator, c.jcon, c.jwin, c.platform, c.gametype, c.ver, m.IBCCustId, CONVERT(DATE, c.changeTime) AS WinlostDate
						FROM #Crystal c
							INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + c.userId = m.Username
					) AS c
						LEFT JOIN dbo.bettrans_Crystal bc WITH (NOLOCK) ON bc.operationCode = c.operationCode
					WHERE bc.operationCode IS NULL
						OR c.userId		<> bc.userId
						OR c.changeTime	<> bc.changeTime
						OR c.changeType	<> bc.changeType
						OR c.gameName	<> bc.gameName
						OR c.fround		<> bc.fround
						OR c.bet		<> bc.bet
						OR c.ret		<> bc.ret
						OR c.changes	<> bc.changes
						OR c.endBalance	<> bc.endBalance
						OR c.operator	<> bc.operator
						OR c.jcon		<> bc.jcon
						OR c.jwin		<> bc.jwin
						OR c.platform	<> bc.platform
						OR c.gametype	<> bc.gametype
						OR c.ver		<> bc.ver
				)
				BEGIN
					SELECT @ListQueueId = @ListQueueId + ',' + CONVERT(VARCHAR(20), @QueueId)

					DELETE bc WITH (ROWLOCK, UPDLOCK)
					FROM dbo.bettrans_Crystal bc
					WHERE EXISTS (SELECT 1 FROM #Crystal c WHERE bc.operationCode = c.operationCode)
				
					INSERT INTO dbo.bettrans_Crystal (operationCode, userId, changeTime, changeType, gameName, fround, bet, ret, changes, endBalance, operator, jcon, jwin, platform, gametype, ver, IBCCustId, WinlostDate)
					SELECT c.operationCode, c.userId, c.changeTime, c.changeType, c.gameName, c.fround, c.bet, c.ret, c.changes, c.endBalance, c.operator, c.jcon, c.jwin, c.platform, c.gametype, c.ver, m.IBCCustId, CONVERT(DATE, c.changeTime) AS WinlostDate
					FROM #Crystal c
						INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + c.userId = m.Username
				END

				SELECT @WinlostDate = MIN(CONVERT(DATE, changeTime)) FROM #Crystal

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH
		END
		-- iSoftbet
		ELSE IF @ProductId = 13
		BEGIN
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

				IF EXISTS (
					SELECT 1
					FROM (
						SELECT i.PLAYERID, i.CURRENCY, i.SESSIONID, i.GAMEID, i.ROUNDID, i.TRANSACTIONID, i.TYPE, i.TIME, i.AMOUNT, m.IBCCustId, CONVERT(DATE, i.TIME) AS WinlostDate
						FROM #iSoftbet i
							INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + i.PLAYERID = m.Username
					) AS i
						LEFT JOIN dbo.bettrans_iSoftbet bi WITH (NOLOCK) ON bi.TRANSACTIONID = i.TRANSACTIONID
					WHERE bi.TRANSACTIONID IS NULL
						OR i.PLAYERID	<> bi.PLAYERID
						OR i.CURRENCY	<> bi.CURRENCY
						OR i.SESSIONID	<> bi.SESSIONID
						OR i.GAMEID		<> bi.GAMEID
						OR i.ROUNDID	<> bi.ROUNDID
						OR i.TYPE		<> bi.TYPE
						OR i.TIME		<> bi.TIME
						OR i.AMOUNT		<> bi.AMOUNT
				)
				BEGIN
					SELECT @ListQueueId = @ListQueueId + ',' + CONVERT(VARCHAR(20), @QueueId)
				
					DELETE bi WITH (ROWLOCK, UPDLOCK)
					FROM dbo.bettrans_iSoftbet bi
					WHERE EXISTS (SELECT 1 FROM #iSoftbet i WHERE bi.TRANSACTIONID = i.TRANSACTIONID)
				
					INSERT INTO dbo.bettrans_iSoftbet (PLAYERID, CURRENCY, SESSIONID, GAMEID, ROUNDID, TRANSACTIONID, TYPE, TIME, AMOUNT, IBCCustId, WinlostDate)
					SELECT i.PLAYERID, i.CURRENCY, i.SESSIONID, i.GAMEID, i.ROUNDID, i.TRANSACTIONID, i.TYPE, i.TIME, i.AMOUNT, m.IBCCustId, CONVERT(DATE, i.TIME) AS WinlostDate
					FROM #iSoftbet i
						INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + i.PLAYERID = m.Username
				END

				SELECT @WinlostDate = MIN(CONVERT(DATE, TIME)) FROM #iSoftbet

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH
		END
		-- OPUS
		ELSE IF @ProductId = 14
		BEGIN
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

				IF EXISTS (
					SELECT 1
					FROM (
						SELECT o.transaction_id, o.transaction_date_time, o.member_code, o.member_type, o.currency, o.balance_start, o.balance_end, o.bet, o.win, o.game_code, o.game_detail, o.bet_status, o.player_hand, o.game_result, o.game_category, o.vendor, o.DrawNumber, o.m88_studio, o.stamp_date, o.bet_record_id, m.IBCCustId, CONVERT(DATE, o.transaction_date_time) AS WinlostDate
						FROM #OPUS o
							INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + RIGHT(o.member_code, LEN(o.member_code) - 3) = m.Username
					) AS o
						LEFT JOIN dbo.bettrans_OPUS bo WITH (NOLOCK) ON bo.transaction_id = o.transaction_id
					WHERE bo.transaction_id IS NULL
						OR o.transaction_date_time	<> bo.transaction_date_time
						OR o.member_code			<> bo.member_code
						OR o.member_type			<> bo.member_type
						OR o.currency				<> bo.currency
						OR o.balance_start			<> bo.balance_start
						OR o.balance_end			<> bo.balance_end
						OR o.bet					<> bo.bet
						OR o.win					<> bo.win
						OR o.game_code				<> bo.game_code
						OR o.game_detail			<> bo.game_detail
						OR o.bet_status				<> bo.bet_status
						OR o.player_hand			<> bo.player_hand
						OR o.game_result			<> bo.game_result
						OR o.game_category			<> bo.game_category
						OR o.vendor					<> bo.vendor
						OR o.DrawNumber				<> bo.DrawNumber
						OR o.m88_studio				<> bo.m88_studio
						OR o.stamp_date				<> bo.stamp_date
						OR o.bet_record_id			<> bo.bet_record_id
				)
				BEGIN
					SELECT @ListQueueId = @ListQueueId + ',' + CONVERT(VARCHAR(20), @QueueId)

					DELETE bo WITH (ROWLOCK, UPDLOCK)
					FROM dbo.bettrans_OPUS bo
					WHERE EXISTS (SELECT 1 FROM #OPUS o WHERE bo.transaction_id = o.transaction_id)
				
					INSERT INTO dbo.bettrans_OPUS (transaction_id, transaction_date_time, member_code, member_type, currency, balance_start, balance_end, bet, win, game_code, game_detail, bet_status, player_hand, game_result, game_category, vendor, DrawNumber, m88_studio, stamp_date, bet_record_id, IBCCustId, WinlostDate)
					SELECT o.transaction_id, o.transaction_date_time, o.member_code, o.member_type, o.currency, o.balance_start, o.balance_end, o.bet, o.win, o.game_code, o.game_detail, o.bet_status, o.player_hand, o.game_result, o.game_category, o.vendor, o.DrawNumber, o.m88_studio, o.stamp_date, o.bet_record_id, m.IBCCustId, CONVERT(DATE, o.transaction_date_time) AS WinlostDate
					FROM #OPUS o
						INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + RIGHT(o.member_code, LEN(o.member_code) - 3) = m.Username
				END

				SELECT @WinlostDate = MIN(CONVERT(DATE, transaction_date_time)) FROM #OPUS

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH
		END

		IF @IsErr = 1
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = CONVERT (NVARCHAR(100), @QueueId)
			RETURN
		END
		ELSE
		BEGIN
			UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
			SET FinishedTime = GETDATE(), WinlostDate = @WinlostDate, LogDesc = 'Successfully'
			WHERE QueueId = @QueueId

			SELECT @QueueId = NULL, @XmlData = NULL

			SELECT TOP 1 @QueueId = QueueId, @XmlData = XmlData
			FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
			WHERE ProductId = @ProductId AND JobType = 1 AND FinishedTime IS NULL
			ORDER BY QueueId
		END
	END

	IF ISNULL(@ListQueueId, '') <> ''
	BEGIN
		SELECT @ErrCode = 500, @ErrMsg = @ListQueueId
	END

	DROP TABLE #Ebet
	DROP TABLE #Betsoft
END
GO