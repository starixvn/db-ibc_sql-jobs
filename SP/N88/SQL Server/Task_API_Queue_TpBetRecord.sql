/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
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
		,Stake			DECIMAL(18,2)
		,ValidBet		DECIMAL(18,2)
		,WinlostAmount	DECIMAL(18,2)
		,SettlementType	TINYINT
		,TicketStatus	TINYINT
		,OriginalState	VARCHAR(10)
		,TicketKey		BIGINT
		,CreateTime		DATETIME
		,BonusId		INT
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
					,SettlementType
					,TicketStatus
					,OriginalState
					,TicketKey
					,CreateTime
					,BonusId
				)
				SELECT
					t.c.value('@tpid', 'INT')
					,t.c.value('@transid', 'VARCHAR(50)')
					,t.c.value('@gametype', 'INT')
					,t.c.value('@custid', 'VARCHAR(45)')
					,t.c.value('@username', 'VARCHAR(30)')
					,t.c.value('@currencyid', 'INT')
					,t.c.value('@siteid', 'INT')
					,t.c.value('@tpusername', 'VARCHAR(50)')
					,t.c.value('@transtime', 'DATETIME')
					,t.c.value('@settledtime', 'DATETIME')
					,t.c.value('@stake', 'DECIMAL(18,2)')
					,CAST(NULLIF(t.c.value('@validbet', 'varchar(30)'), '') AS DECIMAL(18,2))
					,t.c.value('@winlostamount', 'DECIMAL(18,2)')
					,t.c.value('@settlementtype', 'TINYINT')
					,t.c.value('@ticketstatus', 'TINYINT')
					,t.c.value('@originalstate', 'VARCHAR(10)')
					,t.c.value('@ticketkey', 'BIGINT')
					,t.c.value('@createtime', 'DATETIME')
					,t.c.value('@bonusid', 'INT')
				FROM @XmlData.nodes('transaction/trans') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Remove duplicate data
				DELETE t
				FROM (
					SELECT TpId, TransId, GameType
						,ROW_NUMBER() OVER(PARTITION BY TpId, TransId, GameType ORDER BY SettledTime DESC) AS RN
					FROM #tmpTpBetRecord
				) t
				WHERE RN > 1

				-- Update DataType for update
				UPDATE t
				SET t.DataType = 0 -- update
				FROM #tmpTpBetRecord t
					INNER JOIN dbo.TpBetRecord b WITH (NOLOCK) ON t.TpId = b.TpId AND t.TransId = b.TransId AND t.GameType = b.GameType
				
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
						t.DataType = 0
						AND
						(
							ISNULL(b.CustId, '')			<> ISNULL(t.CustId, '')
							OR ISNULL(b.UserName, '')		<> ISNULL(t.UserName, '')
							OR ISNULL(b.CurrencyId, 0)		<> ISNULL(t.CurrencyId, 0)
							OR ISNULL(b.SiteId, 0)			<> ISNULL(t.SiteId, 0)
							OR ISNULL(b.TpUserName, '')		<> ISNULL(t.TpUserName, '')
							OR ISNULL(b.TransTime, '')		<> ISNULL(t.TransTime, '')
							OR ISNULL(b.SettledTime, '')	<> ISNULL(t.SettledTime, '')
							OR ISNULL(b.Stake, 0)			<> ISNULL(t.Stake, 0)
							OR ISNULL(b.ValidBet, 0)		<> ISNULL(t.ValidBet, 0)
							OR ISNULL(b.WinlostAmount, 0)	<> ISNULL(t.WinlostAmount, 0)
							OR ISNULL(b.SettlementType, 0)	<> ISNULL(t.SettlementType, 0)
							OR ISNULL(b.TicketStatus, 0)	<> ISNULL(t.TicketStatus, 0)
							OR ISNULL(b.OriginalState, '')	<> ISNULL(t.OriginalState, '')
							OR ISNULL(b.TicketKey, 0)		<> ISNULL(t.TicketKey, 0)
							OR ISNULL(b.CreateTime, '')		<> ISNULL(t.CreateTime, '')
							OR ISNULL(b.BonusId, 0)			<> ISNULL(t.BonusId, 0)
						)
				END

				-- insert
				IF EXISTS (SELECT 1 FROM #tmpTpBetRecord WHERE DataType = 1)
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
						,SettlementType
						,TicketStatus
						,OriginalState
						,TicketKey
						,CreateTime
						,BonusId
						,CONVERT(DATE, SettledTime)
					FROM #tmpTpBetRecord
					WHERE DataType = 1
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
		AND FinishedTime < DATEADD(MONTH, -1, GETDATE())

	DROP TABLE #tmpTpBetRecord
END
GO