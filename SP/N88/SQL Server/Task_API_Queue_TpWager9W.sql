/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
USE bodb_N88
GO
ALTER PROCEDURE [dbo].[Task_API_Queue_TpWager9W]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20220518@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of TpWager9W table

	Revisions:
		- 20220518@Percy: Initialize SP [RedmineID: #172917]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'TpWager9W')
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

	CREATE TABLE #tmpTpWager9W
	(
		betId				VARCHAR(50) NOT NULL
		,userId				VARCHAR(20)
		,agentId			VARCHAR(50)
		,eventId			VARCHAR(10)
		,marketId			VARCHAR(50)
		,matchSettledDate	DATETIME
		,settledDate		DATETIME
		,betStatus			VARCHAR(20)
		,matchStake			DECIMAL(20,4)
		,profitLoss			DECIMAL(20,4)
		,CreateTime			DATETIME
		,UpdateTime			DATETIME
		,DataType			TINYINT -- 0: update, 1: insert
		,PRIMARY KEY (betId)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'TpWager9W')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'TpWager9W'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'TpWager9W'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpTpWager9W

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpTpWager9W
				(
					betId
					,userId
					,agentId
					,eventId
					,marketId
					,matchSettledDate
					,settledDate
					,betStatus
					,matchStake
					,profitLoss
					,CreateTime
					,UpdateTime
				)
				SELECT
					t.c.value('@betid', 'VARCHAR(50)')
					,t.c.value('@userid', 'VARCHAR(20)')
					,t.c.value('@agentid', 'VARCHAR(50)')
					,t.c.value('@eventid', 'VARCHAR(20)')
					,t.c.value('@marketid', 'VARCHAR(20)')
					,NULLIF(t.c.value('@matchsettleddate', 'DATETIME'), '')
					,NULLIF(t.c.value('@matchsettleddate', 'DATETIME'), '') -- settledDate
					,t.c.value('@betstatus', 'VARCHAR(20)')
					,t.c.value('@matchstake', 'DECIMAL(20, 4)')
					,t.c.value('@profitloss', 'DECIMAL(20, 4)')
					,t.c.value('@createtime', 'DATETIME')
					,t.c.value('@updatetime', 'DATETIME')
				FROM @XmlData.nodes('root/row') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update settledTime
				UPDATE t
				SET t.settledDate = s.settledDate
				FROM #tmpTpWager9W t
					INNER JOIN dbo.TpReport9W s WITH (NOLOCK) ON t.userId = s.userId AND t.eventId = s.eventId AND t.marketId = s.marketId

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN b.betId IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpTpWager9W t
					LEFT JOIN dbo.TpWager9W b WITH (NOLOCK) ON t.betId = b.betId
				WHERE b.betId IS NULL
					OR ISNULL(t.userId, '') <> ISNULL(b.userId, '')
					OR ISNULL(t.agentId, '') <> ISNULL(b.agentId, '')
					OR ISNULL(t.eventId, '') <> ISNULL(b.eventId, '')
					OR ISNULL(t.marketId, '') <> ISNULL(b.marketId, '')
					OR ISNULL(t.matchSettledDate, '') <> ISNULL(b.matchSettledDate, '')
					OR ISNULL(t.settledDate, '') <> ISNULL(b.settledDate, '')
					OR ISNULL(t.betStatus, '') <> ISNULL(b.betStatus, '')
					OR ISNULL(t.matchStake, 0) <> ISNULL(b.matchStake, 0)
					OR ISNULL(t.profitLoss, 0) <> ISNULL(b.profitLoss, 0)
					OR ISNULL(t.CreateTime, '') <> ISNULL(b.CreateTime, '')
					OR ISNULL(t.UpdateTime, '') <> ISNULL(b.UpdateTime, '')
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpTpWager9W WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.userId = t.userId
							,b.agentId = t.agentId
							,b.eventId = t.eventId
							,b.marketId = t.marketId
							,b.matchSettledDate = t.matchSettledDate
							,b.settledDate = t.settledDate
							,b.betStatus = t.betStatus
							,b.matchStake = t.matchStake
							,b.profitLoss = t.profitLoss
							,b.CreateTime = t.CreateTime
							,b.UpdateTime = t.UpdateTime
						FROM dbo.TpWager9W b
							INNER JOIN #tmpTpWager9W t ON b.betId = t.betId
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpTpWager9W WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.TpWager9W
						(
							betId
							,userId
							,agentId
							,eventId
							,marketId
							,matchSettledDate
							,settledDate
							,betStatus
							,matchStake
							,profitLoss
							,CreateTime
							,UpdateTime
						)
						SELECT
							betId
							,userId
							,agentId
							,eventId
							,marketId
							,matchSettledDate
							,settledDate
							,betStatus
							,matchStake
							,profitLoss
							,CreateTime
							,UpdateTime
						FROM #tmpTpWager9W
						WHERE DataType = 1
					END

					-- Update settledTime on TpBetRecord/TpBetRecord_bk
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.SettledTime = DATEADD(HOUR, -8, t.settledDate), b.WinlostDate = CONVERT(DATE, DATEADD(HOUR, -8, t.settledDate))
						FROM dbo.TpBetRecord b
							INNER JOIN #tmpTpWager9W t ON b.TransId = t.betId
						WHERE b.TpId = 31 AND b.GameType = 51
							AND b.SettledTime <> DATEADD(HOUR, -8, t.settledDate)
							
						UPDATE b WITH (ROWLOCK)
						SET b.SettledTime = DATEADD(HOUR, -8, t.settledDate), b.WinlostDate = CONVERT(DATE, DATEADD(HOUR, -8, t.settledDate))
						FROM bodb_N88_Archive.dbo.TpBetRecord_bk b
							INNER JOIN #tmpTpWager9W t ON b.TransId = t.betId
						WHERE b.TpId = 31 AND b.GameType = 51
							AND b.SettledTime <> DATEADD(HOUR, -8, t.settledDate)
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
	WHERE DataSource = 'TpWager9W'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(DAY, -7, GETDATE())

	DROP TABLE #tmpTpWager9W
END
GO