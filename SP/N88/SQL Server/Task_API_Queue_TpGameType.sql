/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
USE bodb_N88
GO
ALTER PROCEDURE [dbo].[Task_API_Queue_TpGameType]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20200520@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of TpGameType table

	Revisions:
		- 20200520@Percy: Initialize SP [RedmineID: #133254]
		- 20211018@Percy: Keep API's data within 7 days [RedmineID: #163336]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'TpGameType')
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

	CREATE TABLE #tmpTpGameType
	(
		Type			INT
		,TypeName		VARCHAR(45)
		,DataType		TINYINT -- 0: update, 1: insert, 2: delete
		,PRIMARY KEY (Type)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'TpGameType')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'TpGameType'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'TpGameType'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpTpGameType

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpTpGameType
				(
					Type
					,TypeName
				)
				SELECT
					t.c.value('@type', 'INT')
					,t.c.value('@typename', 'VARCHAR(45)')
				FROM @XmlData.nodes('root/row') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN t.Type IS NULL THEN 2 -- delete
									WHEN b.Type IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpTpGameType t
					FULL OUTER JOIN dbo.TpGameType b WITH (NOLOCK) ON t.Type = b.Type
				WHERE t.Type IS NULL
					OR b.Type IS NULL
					OR ISNULL(t.TypeName, '') <> ISNULL(b.TypeName, '')
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpTpGameType WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.TypeName = t.TypeName
						FROM dbo.TpGameType b
							INNER JOIN #tmpTpGameType t ON b.Type = t.Type
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpTpGameType WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.TpGameType
						(
							Type
							,TypeName
						)
						SELECT
							Type
							,TypeName
						FROM #tmpTpGameType
						WHERE DataType = 1
					END

					-- delete
					IF EXISTS (SELECT 1 FROM #tmpTpGameType WHERE DataType = 2)
					BEGIN
						DELETE b WITH (ROWLOCK, UPDLOCK)
						FROM dbo.TpGameType b
							INNER JOIN #tmpTpGameType t ON b.Type = t.Type
						WHERE t.DataType = 2
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
	WHERE DataSource = 'TpGameType'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(DAY, -7, GETDATE())

	DROP TABLE #tmpTpGameType
END
GO