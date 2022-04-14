/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
USE bodb_N88
GO
ALTER PROCEDURE [dbo].[Task_API_Queue_BonusInfo]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20200818@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of BonusInfo table

	Revisions:
		- 20200818@Percy: Initialize SP [RedmineID: #137395]
		- 20211018@Percy: Keep API's data within 7 days [RedmineID: #163336]
		- 20220412@Percy: Import SUM data [RedmineID: #171245]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'BonusInfo')
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

	CREATE TABLE #tmpBonusInfo
	(
		BonusId			INT
		,TransId		VARCHAR(30)
		,PromotionType	TINYINT
		,BonusCode		VARCHAR(50)
		,CustId			INT
		,UserName		VARCHAR(30)
		,CurrencyId		TINYINT
		,SiteId			INT
		,LockedAmount	DECIMAL(18,2)
		,BonusAmount	DECIMAL(18,2)
		,ExpiryTime		DATETIME
		,BonusInfo		NVARCHAR(MAX)
		,Memo			VARCHAR(100)
		,CreateTime		DATETIME
		,Status			TINYINT
		,DataType		TINYINT -- 0: update, 1: insert
		,PRIMARY KEY (BonusId)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'BonusInfo')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'BonusInfo'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'BonusInfo'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpBonusInfo

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpBonusInfo
				(
					BonusId
					,TransId
					,PromotionType
					,BonusCode
					,CustId
					,UserName
					,CurrencyId
					,SiteId
					,LockedAmount
					,BonusAmount
					,ExpiryTime
					,BonusInfo
					,Memo
					,CreateTime
					,Status
				)
				SELECT
					t.c.value('@bonusid', 'INT')
					,t.c.value('@transid', 'VARCHAR(30)')
					,t.c.value('@promotiontype', 'TINYINT')
					,t.c.value('@bonuscode', 'VARCHAR(50)')
					,t.c.value('@custid', 'INT')
					,t.c.value('@username', 'VARCHAR(30)')
					,t.c.value('@currencyid', 'TINYINT')
					,t.c.value('@siteid', 'INT')
					,t.c.value('@lockedamount', 'DECIMAL(18, 2)')
					,t.c.value('@bonusamount', 'DECIMAL(18, 2)')
					,NULLIF(t.c.value('@expirytime', 'DATETIME'), '')
					,t.c.value('@bonusinfo', 'NVARCHAR(MAX)')
					,t.c.value('@memo', 'VARCHAR(100)')
					,NULLIF(t.c.value('@createtime', 'DATETIME'), '')
					,t.c.value('@status', 'TINYINT')
				FROM @XmlData.nodes('root/row') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN b.BonusId IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpBonusInfo t
					LEFT JOIN dbo.BonusInfo b WITH (NOLOCK) ON t.BonusId = b.BonusId
				WHERE b.BonusId IS NULL
					OR ISNULL(t.TransId, 0) <> ISNULL(b.TransId,0)
					OR ISNULL(t.PromotionType, 0) <> ISNULL(b.PromotionType, 0)
					OR ISNULL(t.BonusCode, '') <> ISNULL(b.BonusCode, '')
					OR ISNULL(t.CustId, 0) <> ISNULL(b.CustId, 0)
					OR ISNULL(t.UserName, 0) <> ISNULL(b.UserName, 0)
					OR ISNULL(t.CurrencyId, 0) <> ISNULL(b.CurrencyId, 0)
					OR ISNULL(t.SiteId, 0) <> ISNULL(b.SiteId, 0)
					OR ISNULL(t.LockedAmount, 0) <> ISNULL(b.LockedAmount, 0)
					OR ISNULL(t.BonusAmount, 0) <> ISNULL(b.BonusAmount,0)
					OR ISNULL(t.ExpiryTime, 0) <> ISNULL(b.ExpiryTime,0)
					OR ISNULL(t.BonusInfo, '') <> ISNULL(b.BonusInfo,'')
					OR ISNULL(t.Memo, 0) <> ISNULL(b.Memo,0)
					OR ISNULL(t.CreateTime, 0) <> ISNULL(b.CreateTime,0)
					OR ISNULL(t.Status, 0) <> ISNULL(b.Status,0)
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpBonusInfo WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.TransId = t.TransId
							,b.PromotionType = t.PromotionType
							,b.BonusCode = t.BonusCode
							,b.CustId = t.CustId
							,b.UserName = t.UserName
							,b.CurrencyId = t.CurrencyId
							,b.SiteId = t.SiteId
							,b.LockedAmount = t.LockedAmount
							,b.BonusAmount = t.BonusAmount
							,b.ExpiryTime = t.ExpiryTime
							,b.BonusInfo = t.BonusInfo
							,b.Memo = t.Memo
							,b.CreateTime = t.CreateTime
							,b.Status = t.Status
						FROM dbo.BonusInfo b
							INNER JOIN #tmpBonusInfo t ON b.BonusId = t.BonusId
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpBonusInfo WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.BonusInfo
						(
							BonusId
							,TransId
							,PromotionType
							,BonusCode
							,CustId
							,UserName
							,CurrencyId
							,SiteId
							,LockedAmount
							,BonusAmount
							,ExpiryTime
							,BonusInfo
							,Memo
							,CreateTime
							,Status
						)
						SELECT
							BonusId
							,TransId
							,PromotionType
							,BonusCode
							,CustId
							,UserName
							,CurrencyId
							,SiteId
							,LockedAmount
							,BonusAmount
							,ExpiryTime
							,BonusInfo
							,Memo
							,CreateTime
							,Status
						FROM #tmpBonusInfo
						WHERE DataType = 1
					END
				END

				INSERT INTO @WinlostDate (WinlostDate)
				SELECT b.WinlostDate
				FROM (SELECT DISTINCT CONVERT(DATE, CreateTime) AS WinlostDate FROM #tmpBonusInfo WHERE DataType IN (0, 1)) b
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
	SELECT 'BonusInfo', WinlostDate FROM @WinlostDate

	-- Remove old data
	DELETE dbo.API_Queue WITH (ROWLOCK, UPDLOCK)
	WHERE DataSource = 'BonusInfo'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(DAY, -7, GETDATE())

	DROP TABLE #tmpBonusInfo
END
GO