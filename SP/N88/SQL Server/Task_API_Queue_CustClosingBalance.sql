/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
USE bodb_N88
GO
ALTER PROCEDURE [dbo].[Task_API_Queue_CustClosingBalance]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20210524@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of CustClosingBalance table

	Revisions:
		- 20210524@Percy: Initialize SP [RedmineID: #155334]
		- 20211018@Percy: Keep API's data within 7 days [RedmineID: #163336]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'CustClosingBalance')
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

	CREATE TABLE #tmpCustClosingBalance
	(
		Time				DATETIME
		,CustId				INT
		,SiteId				INT
		,Balance			DECIMAL(20, 4)
		,CreateTime			DATETIME
		,DataType			TINYINT -- 0: update, 1: insert
		,PRIMARY KEY (Time, CustId, SiteId)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'CustClosingBalance')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'CustClosingBalance'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'CustClosingBalance'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpCustClosingBalance

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpCustClosingBalance
				(
					Time
					,CustId
					,SiteId
					,Balance
					,CreateTime
				)
				SELECT
					NULLIF(t.c.value('@time', 'DATETIME'), '')
					,t.c.value('@custid', 'INT')
					,t.c.value('@siteid', 'INT')
					,t.c.value('@balance', 'DECIMAL')
					,NULLIF(t.c.value('@createtime', 'DATETIME'), '')
				FROM @XmlData.nodes('root/row') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN b.Time IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpCustClosingBalance t
					LEFT JOIN dbo.CustClosingBalance b WITH (NOLOCK) ON t.Time = b.Time AND t.CustId = b.CustId AND t.SiteId = b.SiteId
				WHERE b.Time IS NULL
					OR ISNULL(t.Balance, 0) <> ISNULL(b.Balance, 0)
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpCustClosingBalance WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.Balance = t.Balance
						FROM dbo.CustClosingBalance b
							INNER JOIN #tmpCustClosingBalance t ON t.Time = b.Time AND t.CustId = b.CustId AND t.SiteId = b.SiteId
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpCustClosingBalance WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.CustClosingBalance
						(
							Time
							,CustId
							,SiteId
							,Balance
							,CreateTime
						)
						SELECT
							Time
							,CustId
							,SiteId
							,Balance
							,CreateTime
						FROM #tmpCustClosingBalance
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
	WHERE DataSource = 'CustClosingBalance'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(DAY, -7, GETDATE())

	DROP TABLE #tmpCustClosingBalance
END
GO