/*<info serverAlias="DBLIC-bodb_3rdProduct" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_Product3rd_ImportQueue_Novacash]
	@QueueIDInput	BIGINT = 0,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(500) = '' OUTPUT
AS

/*
	Created: 20200417@Percy
	DB: DBLIC.bodb_3rdProduct
	Task: Insert raw data of Novacash's products

	Revisions:
		- 20200417@Percy: Initialize SP [RedmineID: #129873]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND ProductID = 0)
		BEGIN
			SELECT	@ErrCode = 100,
					@ErrMsg = 'Input QueueID is not compitable with the product, please check again!'
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
		,WinlostAmount	DECIMAL(18,2)
		,SettlementType	TINYINT
		,TicketStatus	TINYINT
		,OriginalState	VARCHAR(10)
		,TicketKey		BIGINT
		,CreateTime		DATETIME
		,IBCCustId		INT
		,DataType		TINYINT DEFAULT ((1)) -- 0: update, 1: insert
		,PRIMARY KEY (TpId, TransId, GameType)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (NOLOCK) WHERE FinishedTime IS NULL AND ProductID = 0)
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND ProductID = 0
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (NOLOCK)
			WHERE FinishedTime IS NULL AND ProductID = 0
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
					,WinlostAmount
					,SettlementType
					,TicketStatus
					,OriginalState
					,TicketKey
					,CreateTime
				)
				SELECT
					t.c.value('@TpId', 'INT')
					,t.c.value('@TransId', 'VARCHAR(50)')
					,t.c.value('@GameType', 'INT')
					,t.c.value('@CustId', 'VARCHAR(45)')
					,t.c.value('@UserName', 'VARCHAR(30)')
					,t.c.value('@CurrencyId', 'INT')
					,t.c.value('@SiteId', 'INT')
					,t.c.value('@TpUserName', 'VARCHAR(50)')
					,t.c.value('@TransTime', 'DATETIME')
					,t.c.value('@SettledTime', 'DATETIME')
					,t.c.value('@Stake', 'DECIMAL(18,2)')
					,t.c.value('@WinlostAmount', 'DECIMAL(18,2)')
					,t.c.value('@SettlementType', 'TINYINT')
					,t.c.value('@TicketStatus', 'TINYINT')
					,t.c.value('@OriginalState', 'VARCHAR(10)')
					,t.c.value('@TicketKey', 'BIGINT')
					,t.c.value('@CreateTime', 'DATETIME')
				FROM @XmlData.nodes('transaction/trans') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update IBCCustId
				UPDATE t
				SET t.IBCCustId = c.custid
				FROM #tmpTpBetRecord t
					INNER JOIN dbo.ServerInfo s WITH (NOLOCK) ON s.SiteId = t.SiteId
					INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.username2 = s.LicenseeName + '$' + t.TpUserName

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
						,b.WinlostAmount	= t.WinlostAmount
						,b.SettlementType	= t.SettlementType
						,b.TicketStatus		= t.TicketStatus
						,b.OriginalState	= t.OriginalState
						,b.TicketKey		= t.TicketKey
						,b.CreateTime		= t.CreateTime
						,b.IBCCustId		= t.IBCCustId
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
							OR ISNULL(b.WinlostAmount, 0)	<> ISNULL(t.WinlostAmount, 0)
							OR ISNULL(b.SettlementType, 0)	<> ISNULL(t.SettlementType, 0)
							OR ISNULL(b.TicketStatus, 0)	<> ISNULL(t.TicketStatus, 0)
							OR ISNULL(b.OriginalState, '')	<> ISNULL(t.OriginalState, '')
							OR ISNULL(b.TicketKey, 0)		<> ISNULL(t.TicketKey, 0)
							OR ISNULL(b.CreateTime, '')		<> ISNULL(t.CreateTime, '')
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
						,WinlostAmount
						,SettlementType
						,TicketStatus
						,OriginalState
						,TicketKey
						,CreateTime
						,IBCCustId
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
						,WinlostAmount
						,SettlementType
						,TicketStatus
						,OriginalState
						,TicketKey
						,CreateTime
						,IBCCustId
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
			UPDATE bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (ROWLOCK)
			SET FinishedTime = CASE WHEN FinishedTime IS NULL THEN CURRENT_TIMESTAMP ELSE FinishedTime END,
				LogDesc = 'Msg="Successfull"'
			WHERE QueueID = @QueueID
		END
		ELSE
		BEGIN
			UPDATE bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (ROWLOCK)
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

	DROP TABLE #tmpTpBetRecord
END
GO