/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_API_Queue_ServerInfo]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20200520@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of ServerInfo table

	Revisions:
		- 20200520@Percy: Initialize SP [RedmineID: #133254]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'ServerInfo')
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

	CREATE TABLE #tmpServerInfo
	(
		SiteId			INT NOT NULL
		,SiteName		VARCHAR(50)
		,LicenseeName	VARCHAR(50)
		,LangList		NVARCHAR(MAX)
		,CurrencyList	NVARCHAR(MAX)
		,DefLang		VARCHAR(4)
		,DefCurrency	INT
		,DataType		TINYINT -- 0: update, 1: insert, 2: delete
		,PRIMARY KEY (SiteId)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'ServerInfo')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'ServerInfo'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'ServerInfo'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpServerInfo

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpServerInfo
				(
					SiteId
					,SiteName
					,LangList
					,CurrencyList
					,DefLang
					,DefCurrency
				)
				SELECT
					t.c.value('@siteid', 'INT')
					,t.c.value('@sitename', 'VARCHAR(50)')
					,t.c.value('@langlist', 'NVARCHAR(MAX)')
					,t.c.value('@currencylist', 'NVARCHAR(MAX)')
					,t.c.value('@deflang', 'VARCHAR(4)')
					,t.c.value('@defcurrency', 'INT')
				FROM @XmlData.nodes('root/row') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update Licensee Name
				UPDATE t
				SET t.LicenseeName = l.LicenseeName
				FROM #tmpServerInfo t
					INNER JOIN bodb_Licensee.dbo.Licensees l WITH (NOLOCK) ON t.SiteName = l.BrandName

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN t.SiteId IS NULL THEN 2 -- delete
									WHEN b.SiteId IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpServerInfo t
					FULL OUTER JOIN dbo.ServerInfo b WITH (NOLOCK) ON t.SiteId = b.SiteId
				WHERE t.SiteId IS NULL
					OR b.SiteId IS NULL
					OR ISNULL(t.SiteName, '') <> ISNULL(b.SiteName, '')
					OR ISNULL(t.LicenseeName, '') <> ISNULL(b.LicenseeName, '')
					OR ISNULL(t.LangList, '') <> ISNULL(b.LangList, '')
					OR ISNULL(t.CurrencyList, '') <> ISNULL(b.CurrencyList, '')
					OR ISNULL(t.DefLang, '') <> ISNULL(b.DefLang, '')
					OR ISNULL(t.DefCurrency, 0) <> ISNULL(b.DefCurrency, 0)
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpServerInfo WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.SiteName = t.SiteName
							,b.LicenseeName = t.LicenseeName
							,b.LangList = t.LangList
							,b.CurrencyList = t.CurrencyList
							,b.DefLang = t.DefLang
							,b.DefCurrency = t.DefCurrency
						FROM dbo.ServerInfo b
							INNER JOIN #tmpServerInfo t ON b.SiteId = t.SiteId
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpServerInfo WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.ServerInfo
						(
							SiteId
							,SiteName
							,LicenseeName
							,LangList
							,CurrencyList
							,DefLang
							,DefCurrency
						)
						SELECT
							SiteId
							,SiteName
							,LicenseeName
							,LangList
							,CurrencyList
							,DefLang
							,DefCurrency
						FROM #tmpServerInfo
						WHERE DataType = 1
					END

					-- delete
					IF EXISTS (SELECT 1 FROM #tmpServerInfo WHERE DataType = 2)
					BEGIN
						DELETE b WITH (ROWLOCK, UPDLOCK)
						FROM dbo.ServerInfo b
							INNER JOIN #tmpServerInfo t ON b.SiteId = t.SiteId
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
	WHERE DataSource = 'ServerInfo'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(MONTH, -1, GETDATE())

	DROP TABLE #tmpServerInfo
END
GO