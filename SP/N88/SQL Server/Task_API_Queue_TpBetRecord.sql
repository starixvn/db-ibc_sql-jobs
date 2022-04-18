/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
USE bodb_N88
GO

ALTER PROCEDURE [dbo].[Task_API_Queue_TpBetRecord]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20200520@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of TpBetRecord table

	Revisions:
		- 20200520@Percy: Initialize SP [RedmineID: #133254]
		- 20200818@Percy: Add column ValidBet [RedmineID: #137395]
		- 20201105@Percy: Remove duplicate data from API [RedmineID: #144888]
		- 20210125@Percy: Add column BonusId [RedmineID: #149268]
		- 20210301@Percy: Add column Revenue [RedmineID: #150398]
		- 20210715@Percy: Add columns ProgressiveBet, ProgressiveWin [RedmineID: #158438]
		- 20211018@Percy: Keep API's data within 7 days [RedmineID: #163336]
		- 20220120@Percy: Keep raw data within 1 year [RedmineID: #167823]
		- 20220222@Percy: Add TpBetRecord_bk table [RedmineID: #167823]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'TpBetRecord')
		BEGIN
			SELECT	@ErrCode = 100,
					@ErrMsg = 'Input QueueID is not compitable with table, please check again!'
			RETURN
		END
	END

	DECLARE @ArchiveDate DATETIME = dbo.N88_f_GetSystemSettings('ArchiveData_Date')

	DECLARE @QueueID	BIGINT = NULL
			,@XmlData	XML
			,@LogDesc	VARCHAR(2000) = NULL
			,@numOftry	TINYINT

	CREATE TABLE #tmpTpBetRecord
	(
		TpId			INT
		,TransId		VARCHAR(50)
		,GameType		INT
		,CustId			VARCHAR(45)
		,UserName		VARCHAR(30)
		,CurrencyId		INT
		,SiteId			INT
		,TpUserName		VARCHAR(50)
		,TransTime		DATETIME
		,SettledTime	DATETIME
		,Stake			DECIMAL(20,4)
		,ValidBet		DECIMAL(20,4)
		,WinlostAmount	DECIMAL(20,4)
		,Revenue		DECIMAL(20,4)
		,ProgressiveBet	DECIMAL(20,4)
		,ProgressiveWin	DECIMAL(20,4)
		,SettlementType	TINYINT
		,TicketStatus	TINYINT
		,OriginalState	VARCHAR(10)
		,TicketKey		BIGINT
		,CreateTime		DATETIME
		,BonusId		INT
		,IsBk			BIT
		,DataType		TINYINT DEFAULT ((1)) -- 0: update, 1: insert
		--,PRIMARY KEY (TpId, TransId, GameType)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'TpBetRecord')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'TpBetRecord'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'TpBetRecord'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpTpBetRecord

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpTpBetRecord
				(
					TpId
					,TransId
					,GameType
					,CustId
					,UserName
					,CurrencyId
					,SiteId
					,TpUserName
					,TransTime
					,SettledTime
					,Stake
					,ValidBet
					,WinlostAmount
					,Revenue
					,ProgressiveBet
					,ProgressiveWin
					,SettlementType
					,TicketStatus
					,OriginalState
					,TicketKey
					,CreateTime
					,BonusId
					,IsBk
				)
				SELECT
					TpId
					,TransId
					,GameType
					,CustId
					,UserName
					,CurrencyId
					,SiteId
					,TpUserName
					,TransTime
					,SettledTime
					,Stake
					,ValidBet
					,WinlostAmount
					,Revenue
					,ProgressiveBet
					,ProgressiveWin
					,SettlementType
					,TicketStatus
					,OriginalState
					,TicketKey
					,CreateTime
					,BonusId
					,CASE WHEN CONVERT(DATE, SettledTime) >= @ArchiveDate THEN 0 ELSE 1 END
				FROM (
					SELECT
						t.c.value('@tpid', 'INT') AS TpId
						,t.c.value('@transid', 'VARCHAR(50)') AS TransId
						,t.c.value('@gametype', 'INT') AS GameType
						,t.c.value('@custid', 'VARCHAR(45)') AS CustId
						,t.c.value('@username', 'VARCHAR(30)') AS UserName
						,t.c.value('@currencyid', 'INT') AS CurrencyId
						,t.c.value('@siteid', 'INT') AS SiteId
						,t.c.value('@tpusername', 'VARCHAR(50)') AS TpUserName
						,t.c.value('@transtime', 'DATETIME') AS TransTime
						,t.c.value('@settledtime', 'DATETIME') AS SettledTime
						,t.c.value('@stake', 'DECIMAL(20,4)') AS Stake
						,CAST(NULLIF(t.c.value('@validbet', 'varchar(30)'), '') AS DECIMAL(20,4)) AS ValidBet
						,t.c.value('@winlostamount', 'DECIMAL(20,4)') AS WinlostAmount
						,CAST(NULLIF(t.c.value('@revenue', 'varchar(30)'), '') AS DECIMAL(20,4)) AS Revenue
						,CAST(NULLIF(t.c.value('@progressivebet', 'varchar(30)'), '') AS DECIMAL(20,4)) AS ProgressiveBet
						,CAST(NULLIF(t.c.value('@progressivewin', 'varchar(30)'), '') AS DECIMAL(20,4)) AS ProgressiveWin
						,t.c.value('@settlementtype', 'TINYINT') AS SettlementType
						,t.c.value('@ticketstatus', 'TINYINT') AS TicketStatus
						,t.c.value('@originalstate', 'VARCHAR(10)') AS OriginalState
						,t.c.value('@ticketkey', 'BIGINT') AS TicketKey
						,t.c.value('@createtime', 'DATETIME') AS CreateTime
						,t.c.value('@bonusid', 'INT') AS BonusId
					FROM @XmlData.nodes('transaction/trans') t(c)
				) r
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Remove duplicate data
				DELETE t
				FROM (
					SELECT TpId, TransId, GameType
						,ROW_NUMBER() OVER(PARTITION BY TpId, TransId, GameType ORDER BY SettledTime DESC) AS RN
					FROM #tmpTpBetRecord
				) t
				WHERE RN > 1

				-- Update data for TpBetRecord
				IF EXISTS (SELECT 1 FROM #tmpTpBetRecord WHERE IsBk = 0)
				BEGIN
					UPDATE t
					SET t.DataType = 0 -- update
					FROM #tmpTpBetRecord t
						INNER JOIN dbo.TpBetRecord b WITH (NOLOCK) ON t.TpId = b.TpId AND t.TransId = b.TransId AND t.GameType = b.GameType
					WHERE t.IsBk = 0
					
					IF @@ROWCOUNT <> 0
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.CustId			= t.CustId
							,b.UserName			= t.UserName
							,b.CurrencyId		= t.CurrencyId
							,b.SiteId			= t.SiteId
							,b.TpUserName		= t.TpUserName
							,b.TransTime		= t.TransTime
							,b.SettledTime		= t.SettledTime
							,b.Stake			= t.Stake
							,b.ValidBet			= t.ValidBet
							,b.WinlostAmount	= t.WinlostAmount
							,b.Revenue			= t.Revenue
							,b.ProgressiveBet	= t.ProgressiveBet
							,b.ProgressiveWin	= t.ProgressiveWin
							,b.SettlementType	= t.SettlementType
							,b.TicketStatus		= t.TicketStatus
							,b.OriginalState	= t.OriginalState
							,b.TicketKey		= t.TicketKey
							,b.CreateTime		= t.CreateTime
							,b.BonusId			= t.BonusId
							,b.WinlostDate		= CONVERT(DATE, t.SettledTime)
						FROM dbo.TpBetRecord b
							INNER JOIN #tmpTpBetRecord t ON t.TpId = b.TpId AND t.TransId = b.TransId AND t.GameType = b.GameType
						WHERE
							t.IsBk = 0 AND t.DataType = 0
							AND
							(
								ISNULL(b.CustId, 0)				<> ISNULL(t.CustId, 0)
								OR ISNULL(b.UserName, '')		<> ISNULL(t.UserName, '')
								OR ISNULL(b.CurrencyId, 0)		<> ISNULL(t.CurrencyId, 0)
								OR ISNULL(b.SiteId, 0)			<> ISNULL(t.SiteId, 0)
								OR ISNULL(b.TpUserName, '')		<> ISNULL(t.TpUserName, '')
								OR ISNULL(b.TransTime, '')		<> ISNULL(t.TransTime, '')
								OR ISNULL(b.SettledTime, '')	<> ISNULL(t.SettledTime, '')
								OR ISNULL(b.Stake, 0)			<> ISNULL(t.Stake, 0)
								OR ISNULL(b.ValidBet, 0)		<> ISNULL(t.ValidBet, 0)
								OR ISNULL(b.WinlostAmount, 0)	<> ISNULL(t.WinlostAmount, 0)
								OR ISNULL(b.Revenue, 0)			<> ISNULL(t.Revenue, 0)
								OR ISNULL(b.ProgressiveBet, 0)	<> ISNULL(t.ProgressiveBet, 0)
								OR ISNULL(b.ProgressiveWin, 0)	<> ISNULL(t.ProgressiveWin, 0)
								OR ISNULL(b.SettlementType, 0)	<> ISNULL(t.SettlementType, 0)
								OR ISNULL(b.TicketStatus, 0)	<> ISNULL(t.TicketStatus, 0)
								OR ISNULL(b.OriginalState, '')	<> ISNULL(t.OriginalState, '')
								OR ISNULL(b.TicketKey, 0)		<> ISNULL(t.TicketKey, 0)
								OR ISNULL(b.CreateTime, '')		<> ISNULL(t.CreateTime, '')
								OR ISNULL(b.BonusId, 0)			<> ISNULL(t.BonusId, 0)
							)
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpTpBetRecord WHERE IsBk = 0 AND DataType = 1)
					BEGIN
						INSERT INTO dbo.TpBetRecord
						(
							TpId
							,TransId
							,GameType
							,CustId
							,UserName
							,CurrencyId
							,SiteId
							,TpUserName
							,TransTime
							,SettledTime
							,Stake
							,ValidBet
							,WinlostAmount
							,Revenue
							,ProgressiveBet
							,ProgressiveWin
							,SettlementType
							,TicketStatus
							,OriginalState
							,TicketKey
							,CreateTime
							,BonusId
							,WinlostDate
						)
						SELECT
							TpId
							,TransId
							,GameType
							,CustId
							,UserName
							,CurrencyId
							,SiteId
							,TpUserName
							,TransTime
							,SettledTime
							,Stake
							,ValidBet
							,WinlostAmount
							,Revenue
							,ProgressiveBet
							,ProgressiveWin
							,SettlementType
							,TicketStatus
							,OriginalState
							,TicketKey
							,CreateTime
							,BonusId
							,CONVERT(DATE, SettledTime)
						FROM #tmpTpBetRecord
						WHERE IsBk = 0 AND DataType = 1
					END
				END

				-- Update data for TpBetRecord_bk
				IF EXISTS (SELECT 1 FROM #tmpTpBetRecord WHERE IsBk = 1)
				BEGIN
					UPDATE t
					SET t.DataType = 0 -- update
					FROM #tmpTpBetRecord t
						INNER JOIN bodb_N88_Archive.dbo.TpBetRecord_bk b WITH (NOLOCK) ON t.TpId = b.TpId AND t.TransId = b.TransId AND t.GameType = b.GameType
					WHERE t.IsBk = 1
					
					IF @@ROWCOUNT <> 0
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.CustId			= t.CustId
							,b.UserName			= t.UserName
							,b.CurrencyId		= t.CurrencyId
							,b.SiteId			= t.SiteId
							,b.TpUserName		= t.TpUserName
							,b.TransTime		= t.TransTime
							,b.SettledTime		= t.SettledTime
							,b.Stake			= t.Stake
							,b.ValidBet			= t.ValidBet
							,b.WinlostAmount	= t.WinlostAmount
							,b.Revenue			= t.Revenue
							,b.ProgressiveBet	= t.ProgressiveBet
							,b.ProgressiveWin	= t.ProgressiveWin
							,b.SettlementType	= t.SettlementType
							,b.TicketStatus		= t.TicketStatus
							,b.OriginalState	= t.OriginalState
							,b.TicketKey		= t.TicketKey
							,b.CreateTime		= t.CreateTime
							,b.BonusId			= t.BonusId
							,b.WinlostDate		= CONVERT(DATE, t.SettledTime)
						FROM bodb_N88_Archive.dbo.TpBetRecord_bk b
							INNER JOIN #tmpTpBetRecord t ON t.TpId = b.TpId AND t.TransId = b.TransId AND t.GameType = b.GameType
						WHERE
							t.IsBk = 1 AND t.DataType = 0
							AND
							(
								ISNULL(b.CustId, 0)				<> ISNULL(t.CustId, 0)
								OR ISNULL(b.UserName, '')		<> ISNULL(t.UserName, '')
								OR ISNULL(b.CurrencyId, 0)		<> ISNULL(t.CurrencyId, 0)
								OR ISNULL(b.SiteId, 0)			<> ISNULL(t.SiteId, 0)
								OR ISNULL(b.TpUserName, '')		<> ISNULL(t.TpUserName, '')
								OR ISNULL(b.TransTime, '')		<> ISNULL(t.TransTime, '')
								OR ISNULL(b.SettledTime, '')	<> ISNULL(t.SettledTime, '')
								OR ISNULL(b.Stake, 0)			<> ISNULL(t.Stake, 0)
								OR ISNULL(b.ValidBet, 0)		<> ISNULL(t.ValidBet, 0)
								OR ISNULL(b.WinlostAmount, 0)	<> ISNULL(t.WinlostAmount, 0)
								OR ISNULL(b.Revenue, 0)			<> ISNULL(t.Revenue, 0)
								OR ISNULL(b.ProgressiveBet, 0)	<> ISNULL(t.ProgressiveBet, 0)
								OR ISNULL(b.ProgressiveWin, 0)	<> ISNULL(t.ProgressiveWin, 0)
								OR ISNULL(b.SettlementType, 0)	<> ISNULL(t.SettlementType, 0)
								OR ISNULL(b.TicketStatus, 0)	<> ISNULL(t.TicketStatus, 0)
								OR ISNULL(b.OriginalState, '')	<> ISNULL(t.OriginalState, '')
								OR ISNULL(b.TicketKey, 0)		<> ISNULL(t.TicketKey, 0)
								OR ISNULL(b.CreateTime, '')		<> ISNULL(t.CreateTime, '')
								OR ISNULL(b.BonusId, 0)			<> ISNULL(t.BonusId, 0)
							)
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpTpBetRecord WHERE IsBk = 1 AND DataType = 1)
					BEGIN
						INSERT INTO bodb_N88_Archive.dbo.TpBetRecord_bk
						(
							TpId
							,TransId
							,GameType
							,CustId
							,UserName
							,CurrencyId
							,SiteId
							,TpUserName
							,TransTime
							,SettledTime
							,Stake
							,ValidBet
							,WinlostAmount
							,Revenue
							,ProgressiveBet
							,ProgressiveWin
							,SettlementType
							,TicketStatus
							,OriginalState
							,TicketKey
							,CreateTime
							,BonusId
							,WinlostDate
						)
						SELECT
							TpId
							,TransId
							,GameType
							,CustId
							,UserName
							,CurrencyId
							,SiteId
							,TpUserName
							,TransTime
							,SettledTime
							,Stake
							,ValidBet
							,WinlostAmount
							,Revenue
							,ProgressiveBet
							,ProgressiveWin
							,SettlementType
							,TicketStatus
							,OriginalState
							,TicketKey
							,CreateTime
							,BonusId
							,CONVERT(DATE, SettledTime)
						FROM #tmpTpBetRecord
						WHERE IsBk = 1 AND DataType = 1
					END
				END

				-- if parse xml and insert/update data successfully --> break out of while
				BREAK
			END TRY
			BEGIN CATCH
				SELECT @numOftry = @numOftry + 1

				IF @numOftry = 3
				BEGIN
					SELECT @ErrCode = 101, @ErrMsg = ERROR_MESSAGE()
					BREAK
				END
			END CATCH
		END

		-- Update Queue
		IF @ErrCode = 0
		BEGIN
			UPDATE dbo.API_Queue WITH (ROWLOCK)
			SET FinishedTime = CASE WHEN FinishedTime IS NULL THEN CURRENT_TIMESTAMP ELSE FinishedTime END
				,IsFinished = 1
				,LogDesc = 'Msg="Successfull"'
			WHERE QueueID = @QueueID
		END
		ELSE
		BEGIN
			UPDATE dbo.API_Queue WITH (ROWLOCK)
			SET LogDesc = 'Msg="' + @ErrMsg + '"'
			WHERE QueueID = @QueueID

			SELECT @ErrMsg = 'QueueID = ' + CONVERT(VARCHAR(20), @QueueID) + ', MsgError = ' + @ErrMsg
		END

		-- Manually input QueueId --> break out of while
		IF @QueueIDInput <> 0
			BREAK

		-- Stop if parse failure
		IF @ErrCode <> 0
			RETURN
	END

	-- Remove old data
	DELETE dbo.API_Queue WITH (ROWLOCK, UPDLOCK)
	WHERE DataSource = 'TpBetRecord'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(DAY, -7, GETDATE())
		
	DROP TABLE #tmpTpBetRecord
END
GO