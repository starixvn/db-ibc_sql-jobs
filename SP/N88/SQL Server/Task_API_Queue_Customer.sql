/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_API_Queue_Customer]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20200520@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of Customer table

	Revisions:
		- 20200520@Percy: Initialize SP [RedmineID: #133254]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'Customer')
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

	CREATE TABLE #tmpCustomer
	(
		CustId			INT NOT NULL
		,SiteId			INT NOT NULL
		,UserName		VARCHAR(30)
		,CurrencyId		INT
		,UserLang		VARCHAR(4)
		,ActStatus		TINYINT
		,AgentId		INT
		,AllAgentId		NVARCHAR(MAX)
		,UserLevel		TINYINT
		,RegTime		DATETIME
		,IsTest			TINYINT
		,Status			TINYINT
		,DataType		TINYINT -- 0: update, 1: insert
		,PRIMARY KEY (CustId)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'Customer')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'Customer'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'Customer'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpCustomer

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpCustomer
				(
					CustId
					,SiteId
					,UserName
					,CurrencyId
					,UserLang
					,ActStatus
					,AgentId
					,AllAgentId
					,UserLevel
					,RegTime
					,IsTest
					,Status
				)
				SELECT
					t.c.value('@custid', 'INT')
					,t.c.value('@siteid', 'INT')
					,t.c.value('@username', 'VARCHAR(30)')
					,t.c.value('@currencyid', 'INT')
					,t.c.value('@userlang', 'VARCHAR(4)')
					,t.c.value('@actstatus', 'TINYINT')
					,t.c.value('@agentid', 'INT')
					,t.c.value('@allagentid', 'NVARCHAR(MAX)')
					,t.c.value('@userlevel', 'TINYINT')
					,t.c.value('@regtime', 'DATETIME')
					,t.c.value('@istest', 'BIT')
					,t.c.value('@status', 'TINYINT')
				FROM @XmlData.nodes('root/row') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN b.CustId IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpCustomer t
					LEFT JOIN dbo.Customer b WITH (NOLOCK) ON t.CustId = b.CustId
				WHERE b.CustId IS NULL
					OR ISNULL(t.SiteId, 0) <> ISNULL(b.SiteId, 0)
					OR ISNULL(t.UserName, '') <> ISNULL(b.UserName, '')
					OR ISNULL(t.CurrencyId, 0) <> ISNULL(b.CurrencyId, 0)
					OR ISNULL(t.UserLang, '') <> ISNULL(b.UserLang, '')
					OR ISNULL(t.ActStatus, 0) <> ISNULL(b.ActStatus, 0)
					OR ISNULL(t.AgentId, 0) <> ISNULL(b.AgentId, 0)
					OR ISNULL(t.AllAgentId, '') <> ISNULL(b.AllAgentId, '')
					OR ISNULL(t.UserLevel, 0) <> ISNULL(b.UserLevel, 0)
					OR ISNULL(t.RegTime, '') <> ISNULL(b.RegTime, '')
					OR ISNULL(t.IsTest, 0) <> ISNULL(b.IsTest, 0)
					OR ISNULL(t.Status, 0) <> ISNULL(b.Status, 0)
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpCustomer WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.SiteId = t.SiteId
							,b.UserName = t.UserName
							,b.CurrencyId = t.CurrencyId
							,b.UserLang = t.UserLang
							,b.ActStatus = t.ActStatus
							,b.AgentId = t.AgentId
							,b.AllAgentId = t.AllAgentId
							,b.UserLevel = t.UserLevel
							,b.RegTime = t.RegTime
							,b.IsTest = t.IsTest
							,b.Status = t.Status
						FROM dbo.Customer b
							INNER JOIN #tmpCustomer t ON b.CustId = t.CustId
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpCustomer WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.Customer
						(
							CustId
							,SiteId
							,UserName
							,CurrencyId
							,UserLang
							,ActStatus
							,AgentId
							,AllAgentId
							,UserLevel
							,RegTime
							,IsTest
							,Status
						)
						SELECT
							CustId
							,SiteId
							,UserName
							,CurrencyId
							,UserLang
							,ActStatus
							,AgentId
							,AllAgentId
							,UserLevel
							,RegTime
							,IsTest
							,Status
						FROM #tmpCustomer
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
	WHERE DataSource = 'Customer'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(MONTH, -1, GETDATE())

	DROP TABLE #tmpCustomer
END
GO