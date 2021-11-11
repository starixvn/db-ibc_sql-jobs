/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
USE bodb_N88
GO
ALTER PROCEDURE [dbo].[Task_API_Queue_EventDraw]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20211028@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of EventDraw table

	Revisions:
		- 20211028@Percy: Initialize SP [RedmineID: #161048]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'EventDraw')
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

	CREATE TABLE #tmpEventDraw
	(
		EventId		INT
		,EventName	VARCHAR(100)
		,SiteId		INT
		,EventType	TINYINT
		,StartTime	DATETIME
		,EndTime	DATETIME
		,TimeZone	VARCHAR(10)
		,ResetDate	DATE
		,CreateTime	DATETIME
		,UpdateTime	DATETIME
		,DataType	TINYINT -- 0: update, 1: insert
		,PRIMARY KEY (EventId)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'EventDraw')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'EventDraw'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'EventDraw'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpEventDraw

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpEventDraw
				(
					EventId
					,EventName
					,SiteId
					,EventType
					,StartTime
					,EndTime
					,TimeZone
					,ResetDate
					,CreateTime
					,UpdateTime
				)
				SELECT
					t.c.value('@eventid', 'INT')
					,t.c.value('@eventname', 'VARCHAR(100)')
					,t.c.value('@siteid', 'INT')
					,t.c.value('@eventtype', 'TINYINT')
					,NULLIF(t.c.value('@starttime', 'DATETIME'), '')
					,NULLIF(t.c.value('@endtime', 'DATETIME'), '')
					,t.c.value('@timezone', 'VARCHAR(100)')
					,NULLIF(t.c.value('@resetdate', 'DATE'), '')
					,NULLIF(t.c.value('@createtime', 'DATETIME'), '')
					,NULLIF(t.c.value('@updatetime', 'DATETIME'), '')
				FROM @XmlData.nodes('root/row') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN b.EventId IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpEventDraw t
					LEFT JOIN dbo.EventDraw b WITH (NOLOCK) ON t.EventId = b.EventId
				WHERE b.EventId IS NULL
					OR ISNULL(t.EventName, '') <> ISNULL(b.EventName, '')
					OR ISNULL(t.SiteId, 0) <> ISNULL(b.SiteId, 0)
					OR ISNULL(t.EventType, 0) <> ISNULL(b.EventType, 0)
					OR ISNULL(t.StartTime, '') <> ISNULL(b.StartTime, '')
					OR ISNULL(t.EndTime, '') <> ISNULL(b.EndTime, '')
					OR ISNULL(t.TimeZone, '') <> ISNULL(b.TimeZone, '')
					OR ISNULL(t.ResetDate, '') <> ISNULL(b.ResetDate, '')
					OR ISNULL(t.CreateTime, '') <> ISNULL(b.CreateTime, '')
					OR ISNULL(t.UpdateTime, '') <> ISNULL(b.UpdateTime, '')

				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpEventDraw WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.EventName = t.EventName
							,b.SiteId = t.SiteId
							,b.EventType = t.EventType
							,b.StartTime = t.StartTime
							,b.EndTime = t.EndTime
							,b.TimeZone = t.TimeZone
							,b.ResetDate = t.ResetDate
							,b.CreateTime = t.CreateTime
							,b.UpdateTime = t.UpdateTime
						FROM dbo.EventDraw b
							INNER JOIN #tmpEventDraw t ON b.EventId = t.EventId
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpEventDraw WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.EventDraw
						(
							EventId
							,EventName
							,SiteId
							,EventType
							,StartTime
							,EndTime
							,TimeZone
							,ResetDate
							,CreateTime
							,UpdateTime
						)
						SELECT
							EventId
							,EventName
							,SiteId
							,EventType
							,StartTime
							,EndTime
							,TimeZone
							,ResetDate
							,CreateTime
							,UpdateTime
						FROM #tmpEventDraw
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
	WHERE DataSource = 'EventDraw'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(DAY, -7, GETDATE())

	DROP TABLE #tmpEventDraw
END
GO