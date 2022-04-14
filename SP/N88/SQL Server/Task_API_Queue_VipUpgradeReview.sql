/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
USE bodb_N88
GO
ALTER PROCEDURE [dbo].[Task_API_Queue_VipUpgradeReview]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20211028@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of VipUpgradeReview table

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
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'VipUpgradeReview')
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

	CREATE TABLE #tmpVipUpgradeReview
	(
		CustId				INT
		,CalculateMonth		DATE
		,UserName			VARCHAR(50)
		,SiteId				INT
		,CurrentVipLevel	TINYINT
		,UpgradeVipLevel	TINYINT
		,CurrencyId			INT
		,DepositAmount		DECIMAL(20, 4)
		,UpgradeAmount		DECIMAL(20, 4)
		,Status				TINYINT
		,CreateTime			DATETIME
		,SettleTime			DATETIME
		,LastUpdateTime		DATETIME
		,LastUpdateUser		VARCHAR(50)
		,DataType			TINYINT -- 0: update, 1: insert
		,PRIMARY KEY (CustId, CalculateMonth)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'VipUpgradeReview')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'VipUpgradeReview'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'VipUpgradeReview'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpVipUpgradeReview

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpVipUpgradeReview
				(
					CustId
					,CalculateMonth
					,UserName
					,SiteId
					,CurrentVipLevel
					,UpgradeVipLevel
					,CurrencyId
					,DepositAmount
					,UpgradeAmount
					,Status
					,CreateTime
					,SettleTime
					,LastUpdateTime
					,LastUpdateUser
				)
				SELECT
					t.c.value('@custid', 'INT')
					,t.c.value('@calculatemonth', 'VARCHAR(6)') + '01' -- convert to date
					,t.c.value('@username', 'VARCHAR(50)')
					,t.c.value('@siteid', 'INT')
					,t.c.value('@currentviplevel', 'TINYINT')
					,t.c.value('@upgradeviplevel', 'TINYINT')
					,t.c.value('@currencyid', 'INT')
					,t.c.value('@depositamount', 'DECIMAL(20, 4)')
					,t.c.value('@upgradeamount', 'DECIMAL(20, 4)')
					,t.c.value('@status', 'TINYINT')
					,NULLIF(t.c.value('@createtime', 'DATETIME'), '')
					,NULLIF(t.c.value('@settletime', 'DATETIME'), '')
					,NULLIF(t.c.value('@lastupdatetime', 'DATETIME'), '')
					,t.c.value('@lastupdateuser', 'VARCHAR(50)')
				FROM @XmlData.nodes('root/row') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN b.CustId IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpVipUpgradeReview t
					LEFT JOIN dbo.VipUpgradeReview b WITH (NOLOCK) ON t.CustId = b.CustId AND t.CalculateMonth = b.CalculateMonth
				WHERE b.CustId IS NULL
					OR ISNULL(t.UserName, '') <> ISNULL(b.UserName, '')
					OR ISNULL(t.SiteId, 0) <> ISNULL(b.SiteId, 0)
					OR ISNULL(t.CurrentVipLevel, 0) <> ISNULL(b.CurrentVipLevel, 0)
					OR ISNULL(t.UpgradeVipLevel, 0) <> ISNULL(b.UpgradeVipLevel, 0)
					OR ISNULL(t.CurrencyId, 0) <> ISNULL(b.CurrencyId, 0)
					OR ISNULL(t.DepositAmount, 0) <> ISNULL(b.DepositAmount, 0)
					OR ISNULL(t.UpgradeAmount, 0) <> ISNULL(b.UpgradeAmount, 0)
					OR ISNULL(t.Status, 0) <> ISNULL(b.Status, 0)
					OR ISNULL(t.CreateTime, '') <> ISNULL(b.CreateTime, '')
					OR ISNULL(t.SettleTime, '') <> ISNULL(b.SettleTime, '')
					OR ISNULL(t.LastUpdateTime, '') <> ISNULL(b.LastUpdateTime, '')
					OR ISNULL(t.LastUpdateUser, '') <> ISNULL(b.LastUpdateUser, '')
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpVipUpgradeReview WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.UserName = t.UserName
							,b.SiteId = t.SiteId
							,b.CurrentVipLevel = t.CurrentVipLevel
							,b.UpgradeVipLevel = t.UpgradeVipLevel
							,b.CurrencyId = t.CurrencyId
							,b.DepositAmount = t.DepositAmount
							,b.UpgradeAmount = t.UpgradeAmount
							,b.Status = t.Status
							,b.CreateTime = t.CreateTime
							,b.SettleTime = t.SettleTime
							,b.LastUpdateTime = t.LastUpdateTime
							,b.LastUpdateUser = t.LastUpdateUser
						FROM dbo.VipUpgradeReview b
							INNER JOIN #tmpVipUpgradeReview t ON b.CustId = t.CustId AND b.CalculateMonth = t.CalculateMonth
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpVipUpgradeReview WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.VipUpgradeReview
						(
							CustId
							,CalculateMonth
							,UserName
							,SiteId
							,CurrentVipLevel
							,UpgradeVipLevel
							,CurrencyId
							,DepositAmount
							,UpgradeAmount
							,Status
							,CreateTime
							,SettleTime
							,LastUpdateTime
							,LastUpdateUser
						)
						SELECT
							CustId
							,CalculateMonth
							,UserName
							,SiteId
							,CurrentVipLevel
							,UpgradeVipLevel
							,CurrencyId
							,DepositAmount
							,UpgradeAmount
							,Status
							,CreateTime
							,SettleTime
							,LastUpdateTime
							,LastUpdateUser
						FROM #tmpVipUpgradeReview
						WHERE DataType = 1
					END
				END

				INSERT INTO @WinlostDate (WinlostDate)
				SELECT b.WinlostDate
				FROM (SELECT DISTINCT CONVERT(DATE, SettleTime) AS WinlostDate FROM #tmpVipUpgradeReview WHERE DataType IN (0, 1)) b
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
	SELECT 'VipUpgradeReview', WinlostDate FROM @WinlostDate

	-- Remove old data
	DELETE dbo.API_Queue WITH (ROWLOCK, UPDLOCK)
	WHERE DataSource = 'VipUpgradeReview'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(DAY, -7, GETDATE())

	DROP TABLE #tmpVipUpgradeReview
END
GO