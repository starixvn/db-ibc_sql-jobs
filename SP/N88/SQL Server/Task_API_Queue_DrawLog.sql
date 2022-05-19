/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
USE bodb_N88
GO
ALTER PROCEDURE [dbo].[Task_API_Queue_DrawLog]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20211028@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of DrawLog table

	Revisions:
		- 20211028@Percy: Initialize SP [RedmineID: #161048]
		- 20220412@Percy: Import SUM data [RedmineID: #171245]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'DrawLog')
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

	DECLARE @WinlostDate TABLE (WinlostDate DATE PRIMARY KEY)
	
	CREATE TABLE #tmpDrawLog
	(
		Id				BIGINT
		,EventId		INT
		,PrizeId		INT
		,PrizeName		VARCHAR(100)
		,CustId			INT
		,SiteId			INT
		,CurrencyId		INT
		,Amount			DECIMAL(20, 4)
		,DrawEventDate	DATETIME
		,DrawTime		DATETIME
		,DataType		TINYINT -- 0: update, 1: insert
		,PRIMARY KEY (Id)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'DrawLog')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'DrawLog'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'DrawLog'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpDrawLog

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpDrawLog
				(
					Id
					,EventId
					,PrizeId
					,PrizeName
					,CustId
					,SiteId
					,CurrencyId
					,Amount
					,DrawEventDate
					,DrawTime
				)
				SELECT
					t.Id
					,t.EventId
					,t.PrizeId
					,t.PrizeName
					,t.CustId
					,c.SiteId
					,c.CurrencyId
					,t.Amount
					,t.DrawEventDate
					,t.DrawTime
				FROM (
					SELECT
						t.c.value('@id', 'BIGINT') AS Id
						,t.c.value('@eventid', 'INT') AS EventId
						,t.c.value('@prizeid', 'INT') AS PrizeId
						,t.c.value('@prizename', 'VARCHAR(100)') AS PrizeName
						,t.c.value('@custid', 'INT') AS CustId
						,t.c.value('@amount', 'DECIMAL(20, 4)') AS Amount
						,NULLIF(t.c.value('@draweventdate', 'DATETIME'), '') AS DrawEventDate
						,NULLIF(t.c.value('@drawtime', 'DATETIME'), '') AS DrawTime
					FROM @XmlData.nodes('root/row') t(c)
				) t
					INNER JOIN dbo.Customer c WITH (NOLOCK) ON t.CustId = c.CustId
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN b.Id IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpDrawLog t
					LEFT JOIN dbo.DrawLog b WITH (NOLOCK) ON t.Id = b.Id
				WHERE b.Id IS NULL
					OR ISNULL(t.EventId, 0) <> ISNULL(b.EventId, 0)
					OR ISNULL(t.PrizeId, 0) <> ISNULL(b.PrizeId, 0)
					OR ISNULL(t.PrizeName, '') <> ISNULL(b.PrizeName, '')
					OR ISNULL(t.CustId, 0) <> ISNULL(b.CustId, 0)
					OR ISNULL(t.SiteId, 0) <> ISNULL(b.SiteId, 0)
					OR ISNULL(t.CurrencyId, 0) <> ISNULL(b.CurrencyId, 0)
					OR ISNULL(t.Amount, 0) <> ISNULL(b.Amount, 0)
					OR ISNULL(t.DrawEventDate, '') <> ISNULL(b.DrawEventDate, '')
					OR ISNULL(t.DrawTime, '') <> ISNULL(b.DrawTime, '')
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpDrawLog WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.EventId = t.EventId
							,b.PrizeId = t.PrizeId
							,b.PrizeName = t.PrizeName
							,b.CustId = t.CustId
							,b.SiteId = t.SiteId
							,b.CurrencyId = t.CurrencyId
							,b.Amount = t.Amount
							,b.DrawEventDate = t.DrawEventDate
							,b.DrawTime = t.DrawTime
						FROM dbo.DrawLog b
							INNER JOIN #tmpDrawLog t ON b.Id = t.Id
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpDrawLog WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.DrawLog
						(
							Id
							,EventId
							,PrizeId
							,PrizeName
							,CustId
							,SiteId
							,CurrencyId
							,Amount
							,DrawEventDate
							,DrawTime
						)
						SELECT
							Id
							,EventId
							,PrizeId
							,PrizeName
							,CustId
							,SiteId
							,CurrencyId
							,Amount
							,DrawEventDate
							,DrawTime
						FROM #tmpDrawLog
						WHERE DataType = 1
					END
				END

				INSERT INTO @WinlostDate (WinlostDate)
				SELECT b.WinlostDate
				FROM (SELECT DISTINCT CONVERT(DATE, DrawTime) AS WinlostDate FROM #tmpDrawLog WHERE DataType IN (0, 1)) b
					LEFT JOIN @WinlostDate w ON b.WinlostDate = w.WinlostDate
				WHERE w.WinlostDate IS NULL

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

	-- For SUM data
	INSERT INTO dbo.BonusImportStatus (DataSource, WinlostDate)
	SELECT 'DrawLog', WinlostDate FROM @WinlostDate

	-- Remove old data
	DELETE dbo.API_Queue WITH (ROWLOCK, UPDLOCK)
	WHERE DataSource = 'DrawLog'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(DAY, -7, GETDATE())

	DROP TABLE #tmpDrawLog
END
GO