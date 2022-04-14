/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
USE bodb_N88
GO
ALTER PROCEDURE [dbo].[Task_API_Queue_ReferralMLog]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20220412@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of ReferralMLog table

	Revisions:
		- 20220412@Percy: Initialize SP [RedmineID: #171245]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'ReferralMLog')
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
	
	CREATE TABLE #tmpReferralMLog
	(
		Id				INT
		,CustId			INT
		,CurrencyId		INT
		,Username		VARCHAR(50)
		,SiteId			INT
		,RefferalAmount	DECIMAL(20, 4)
		,Memo			VARCHAR(200)
		,RelId			BIGINT
		,CreateTime		DATETIME
		,DataType		TINYINT -- 0: update, 1: insert
		,PRIMARY KEY (Id)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'ReferralMLog')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'ReferralMLog'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'ReferralMLog'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpReferralMLog

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpReferralMLog
				(
					Id
					,CustId
					,CurrencyId
					,Username
					,SiteId
					,RefferalAmount
					,Memo
					,RelId
					,CreateTime
				)
				SELECT
					t.c.value('@id', 'INT')
					,t.c.value('@custid', 'INT')
					,t.c.value('@currencyid', 'INT')
					,t.c.value('@username', 'VARCHAR(50)')
					,t.c.value('@siteid', 'INT')
					,t.c.value('@refferalamount', 'DECIMAL(20, 4)')
					,t.c.value('@memo', 'VARCHAR(200)')
					,t.c.value('@relid', 'BIGINT')
					,NULLIF(t.c.value('@createtime', 'DATETIME'), '')
				FROM @XmlData.nodes('root/row') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN b.Id IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpReferralMLog t
					LEFT JOIN dbo.ReferralMLog b WITH (NOLOCK) ON t.Id = b.Id
				WHERE b.Id IS NULL
					OR ISNULL(t.CustId, 0) <> ISNULL(b.CustId, 0)
					OR ISNULL(t.CurrencyId, 0) <> ISNULL(b.CurrencyId, 0)
					OR ISNULL(t.UserName, '') <> ISNULL(b.UserName, '')
					OR ISNULL(t.SiteId, 0) <> ISNULL(b.SiteId, 0)
					OR ISNULL(t.RefferalAmount, 0) <> ISNULL(b.RefferalAmount, 0)
					OR ISNULL(t.Memo, '') <> ISNULL(b.Memo, '')
					OR ISNULL(t.RelId, 0) <> ISNULL(b.RelId, 0)
					OR ISNULL(t.CreateTime, '') <> ISNULL(b.CreateTime, '')
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpReferralMLog WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.CustId = t.CustId
							,b.CurrencyId = t.CurrencyId
							,b.UserName = t.UserName
							,b.SiteId = t.SiteId
							,b.RefferalAmount = t.RefferalAmount
							,b.Memo = t.Memo
							,b.RelId = t.RelId
							,b.CreateTime = t.CreateTime
						FROM dbo.ReferralMLog b
							INNER JOIN #tmpReferralMLog t ON b.Id = t.Id
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpReferralMLog WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.ReferralMLog
						(
							Id
							,CustId
							,CurrencyId
							,Username
							,SiteId
							,RefferalAmount
							,Memo
							,RelId
							,CreateTime
						)
						SELECT
							Id
							,CustId
							,CurrencyId
							,Username
							,SiteId
							,RefferalAmount
							,Memo
							,RelId
							,CreateTime
						FROM #tmpReferralMLog
						WHERE DataType = 1
					END
				END

				INSERT INTO @WinlostDate (WinlostDate)
				SELECT b.WinlostDate
				FROM (SELECT DISTINCT CONVERT(DATE, CreateTime) AS WinlostDate FROM #tmpReferralMLog WHERE DataType IN (0, 1)) b
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
	SELECT 'ReferralMLog', WinlostDate FROM @WinlostDate

	-- Remove old data
	DELETE dbo.API_Queue WITH (ROWLOCK, UPDLOCK)
	WHERE DataSource = 'ReferralMLog'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(DAY, -7, GETDATE())

	DROP TABLE #tmpReferralMLog
END
GO