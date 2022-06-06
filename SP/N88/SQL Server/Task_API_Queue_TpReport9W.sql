/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
USE bodb_N88
GO
ALTER PROCEDURE [dbo].[Task_API_Queue_TpReport9W]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20220518@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of TpReport9W table

	Revisions:
		- 20220518@Percy: Initialize SP [RedmineID: #172917]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'TpReport9W')
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

	CREATE TABLE #tmpTpReport9W
	(
		SQ					BIGINT NOT NULL
		,userId				VARCHAR(20)
		,agentId			VARCHAR(50)
		,eventId			VARCHAR(20)
		,marketId			VARCHAR(20)
		,settledDate		DATETIME 
		,resettledDate		DATETIME
		,profitLoss			DECIMAL(20,4)
		,marketTotal		DECIMAL(20,4)
		,commission			DECIMAL(20,4)
		,agentCommission	DECIMAL(20,4)
		,stakeTotal			DECIMAL(20,4)
		,CreateTime			DATETIME
		,UpdateTime			DATETIME
		,CustId				INT
		,CurrencyId			INT
		,SiteId				INT
		,DataType			TINYINT -- 0: update, 1: insert
		,PRIMARY KEY (SQ)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'TpReport9W')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'TpReport9W'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'TpReport9W'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpTpReport9W

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpTpReport9W
				(
					SQ
					,userId
					,agentId
					,eventId
					,marketId
					,settledDate
					,resettledDate
					,profitLoss
					,marketTotal
					,commission
					,agentCommission
					,stakeTotal
					,CreateTime
					,UpdateTime
					,CustId
				)
				SELECT
					t.c.value('@sq', 'BIGINT')
					,t.c.value('@userid', 'VARCHAR(20)')
					,t.c.value('@agentid', 'VARCHAR(50)')
					,t.c.value('@eventid', 'VARCHAR(20)')
					,t.c.value('@marketid', 'VARCHAR(20)')
					,t.c.value('@settleddate', 'DATETIME')
					,NULLIF(t.c.value('@resettleddate', 'DATETIME'), '')
					,t.c.value('@profitloss', 'DECIMAL(20, 4)')
					,t.c.value('@markettotal', 'DECIMAL(20, 4)')
					,t.c.value('@commission', 'DECIMAL(20, 4)')
					,t.c.value('@agentcommission', 'DECIMAL(20, 4)')
					,t.c.value('@staketotal', 'DECIMAL(20, 4)')
					,NULLIF(t.c.value('@createtime', 'DATETIME'), '')
					,NULLIF(t.c.value('@updatetime', 'DATETIME'), '')
					,t.c.value('@custid', 'INT')
				FROM @XmlData.nodes('root/row') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update CustInfo
				UPDATE t
				SET t.CurrencyId = c.CurrencyId, t.SiteId = c.SiteId
				FROM #tmpTpReport9W t
					INNER JOIN dbo.Customer c WITH (NOLOCK) ON t.CustId = c.CustId

				DELETE #tmpTpReport9W WHERE CurrencyId IS NULL

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN b.SQ IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpTpReport9W t
					LEFT JOIN dbo.TpReport9W b WITH (NOLOCK) ON t.SQ = b.SQ
				WHERE b.SQ IS NULL
					OR ISNULL(t.userId, '') <> ISNULL(b.userId, '')
					OR ISNULL(t.agentId, '') <> ISNULL(b.agentId, '')
					OR ISNULL(t.eventId, '') <> ISNULL(b.eventId, '')
					OR ISNULL(t.marketId, '') <> ISNULL(b.marketId, '')
					OR ISNULL(t.settledDate, '') <> ISNULL(b.settledDate, '')
					OR ISNULL(t.resettledDate, '') <> ISNULL(b.resettledDate, '')
					OR ISNULL(t.profitLoss, 0) <> ISNULL(b.profitLoss, 0)
					OR ISNULL(t.marketTotal, 0) <> ISNULL(b.marketTotal, 0)
					OR ISNULL(t.commission, 0) <> ISNULL(b.commission, 0)
					OR ISNULL(t.agentCommission, 0) <> ISNULL(b.agentCommission, 0)
					OR ISNULL(t.stakeTotal, 0) <> ISNULL(b.stakeTotal, 0)
					OR ISNULL(t.CreateTime, '') <> ISNULL(b.CreateTime, '')
					OR ISNULL(t.UpdateTime, '') <> ISNULL(b.UpdateTime, '')
					OR ISNULL(t.CustId, 0) <> ISNULL(b.CustId, 0)
					OR ISNULL(t.CurrencyId, 0) <> ISNULL(b.CurrencyId, 0)
					OR ISNULL(t.SiteId, 0) <> ISNULL(b.SiteId, 0)
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpTpReport9W WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.userId = t.userId
							,b.agentId = t.agentId
							,b.eventId = t.eventId
							,b.marketId = t.marketId
							,b.settledDate = t.settledDate
							,b.resettledDate = t.resettledDate
							,b.profitLoss = t.profitLoss
							,b.marketTotal = t.marketTotal
							,b.commission = t.commission
							,b.agentCommission = t.agentCommission
							,b.stakeTotal = t.stakeTotal
							,b.CreateTime = t.CreateTime
							,b.UpdateTime = t.UpdateTime
							,b.CustId = t.CustId
							,b.CurrencyId = t.CurrencyId
							,b.SiteId = t.SiteId
						FROM dbo.TpReport9W b
							INNER JOIN #tmpTpReport9W t ON b.SQ = t.SQ
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpTpReport9W WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.TpReport9W
						(
							SQ
							,userId
							,agentId
							,eventId
							,marketId
							,settledDate
							,resettledDate
							,profitLoss
							,marketTotal
							,commission
							,agentCommission
							,stakeTotal
							,CreateTime
							,UpdateTime
							,CustId
							,CurrencyId
							,SiteId
						)
						SELECT
							SQ
							,userId
							,agentId
							,eventId
							,marketId
							,settledDate
							,resettledDate
							,profitLoss
							,marketTotal
							,commission
							,agentCommission
							,stakeTotal
							,CreateTime
							,UpdateTime
							,CustId
							,CurrencyId
							,SiteId
						FROM #tmpTpReport9W
						WHERE DataType = 1
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
	WHERE DataSource = 'TpReport9W'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(DAY, -7, GETDATE())

	DROP TABLE #tmpTpReport9W
END
GO