/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_API_Queue_Promotion]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20210112@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of Promotion table

	Revisions:
		- 20210112@Percy: Initialize SP [RedmineID: #146759]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'Promotion')
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

	CREATE TABLE #tmpPromotion
	(
		BonusCode		VARCHAR(50)
		,SiteId			INT
		,Description	VARCHAR(300)
		,PromotionType	TINYINT
		,CategoryId		TINYINT
		,TpId			INT
		,PeriodFrom		BIGINT
		,PeriodTo		BIGINT
		,StartDate		DATETIME
		,EndDate		DATETIME
		,ExpiryDays		TINYINT
		,Sort			SMALLINT
		,CreateTime		DATETIME
		,Status			TINYINT
		,LastUpdateTime	DATETIME
		,LastUpdateUser	VARCHAR(50)
		,WalletType		TINYINT
		,RedeemHours	TINYINT
		,PeriodType		TINYINT
		,PeriodDay		TINYINT
		,SpecialCode	VARCHAR(20)
		,IsSpecial		BIT
		,DataType		TINYINT -- 0: update, 1: insert
		,PRIMARY KEY (BonusCode, SiteId)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'Promotion')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'Promotion'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'Promotion'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpPromotion

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpPromotion
				(
					BonusCode
					,SiteId
					,Description
					,PromotionType
					,CategoryId
					,TpId
					,PeriodFrom
					,PeriodTo
					,StartDate
					,EndDate
					,ExpiryDays
					,Sort
					,CreateTime
					,Status
					,LastUpdateTime
					,LastUpdateUser
					,WalletType
					,RedeemHours
					,PeriodType
					,PeriodDay
					,SpecialCode
					,IsSpecial
				)
				SELECT
					t.c.value('@bonuscode', 'VARCHAR(50)')
					,t.c.value('@siteid', 'INT')
					,t.c.value('@description', 'VARCHAR(300)')
					,t.c.value('@promotiontype', 'TINYINT')
					,t.c.value('@categoryid', 'TINYINT')
					,t.c.value('@tpid', 'INT')
					,t.c.value('@periodfrom', 'BIGINT')
					,t.c.value('@periodto', 'BIGINT')
					,NULLIF(t.c.value('@startdate', 'DATETIME'), '')
					,NULLIF(t.c.value('@enddate', 'DATETIME'), '')
					,t.c.value('@expirydays', 'TINYINT')
					,t.c.value('@sort', 'SMALLINT')
					,NULLIF(t.c.value('@createtime', 'DATETIME'), '')
					,t.c.value('@status', 'TINYINT')
					,NULLIF(t.c.value('@lastupdatetime', 'DATETIME'), '')
					,t.c.value('@lastupdateuser', 'VARCHAR(50)')
					,t.c.value('@wallettype', 'TINYINT')
					,t.c.value('@redeemhours', 'TINYINT')
					,t.c.value('@periodtype', 'TINYINT')
					,t.c.value('@periodday', 'TINYINT')
					,t.c.value('@specialcode', 'VARCHAR(20)')
					,t.c.value('@isspecial', 'BIT')
				FROM @XmlData.nodes('root/row') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN b.BonusCode IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpPromotion t
					LEFT JOIN dbo.Promotion b WITH (NOLOCK) ON t.BonusCode = b.BonusCode AND t.SiteId = b.SiteId
				WHERE b.BonusCode IS NULL
					OR ISNULL(t.Description, '') <> ISNULL(b.Description, '')
					OR ISNULL(t.PromotionType, 0) <> ISNULL(b.PromotionType, 0)
					OR ISNULL(t.CategoryId, 0) <> ISNULL(b.CategoryId, 0)
					OR ISNULL(t.TpId, 0) <> ISNULL(b.TpId, 0)
					OR ISNULL(t.PeriodFrom, 0) <> ISNULL(b.PeriodFrom, 0)
					OR ISNULL(t.PeriodTo, 0) <> ISNULL(b.PeriodTo, 0)
					OR ISNULL(t.StartDate, '') <> ISNULL(b.StartDate, '')
					OR ISNULL(t.EndDate, '') <> ISNULL(b.EndDate, '')
					OR ISNULL(t.ExpiryDays, 0) <> ISNULL(b.ExpiryDays, 0)
					OR ISNULL(t.Sort, 0) <> ISNULL(b.Sort, 0)
					OR ISNULL(t.CreateTime, '') <> ISNULL(b.CreateTime, '')
					OR ISNULL(t.Status, 0) <> ISNULL(b.Status, 0)
					OR ISNULL(t.LastUpdateTime, '') <> ISNULL(b.LastUpdateTime, '')
					OR ISNULL(t.LastUpdateUser, '') <> ISNULL(b.LastUpdateUser, '')
					OR ISNULL(t.WalletType, 0) <> ISNULL(b.WalletType, 0)
					OR ISNULL(t.RedeemHours, 0) <> ISNULL(b.RedeemHours, 0)
					OR ISNULL(t.PeriodType, 0) <> ISNULL(b.PeriodType, 0)
					OR ISNULL(t.PeriodDay, 0) <> ISNULL(b.PeriodDay, 0)
					OR ISNULL(t.SpecialCode, '') <> ISNULL(b.SpecialCode, '')
					OR ISNULL(t.IsSpecial, 0) <> ISNULL(b.IsSpecial, 0)
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpPromotion WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.Description = t.Description
							,b.PromotionType = t.PromotionType
							,b.CategoryId = t.CategoryId
							,b.TpId = t.TpId
							,b.PeriodFrom = t.PeriodFrom
							,b.PeriodTo = t.PeriodTo
							,b.StartDate = t.StartDate
							,b.EndDate = t.EndDate
							,b.ExpiryDays = t.ExpiryDays
							,b.Sort = t.Sort
							,b.CreateTime = t.CreateTime
							,b.Status = t.Status
							,b.LastUpdateTime = t.LastUpdateTime
							,b.LastUpdateUser = t.LastUpdateUser
							,b.WalletType = t.WalletType
							,b.RedeemHours = t.RedeemHours
							,b.PeriodType = t.PeriodType
							,b.PeriodDay = t.PeriodDay
							,b.SpecialCode = t.SpecialCode
							,b.IsSpecial = t.IsSpecial
						FROM dbo.Promotion b
							INNER JOIN #tmpPromotion t ON t.BonusCode = b.BonusCode AND t.SiteId = b.SiteId
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpPromotion WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.Promotion
						(
							BonusCode
							,SiteId
							,Description
							,PromotionType
							,CategoryId
							,TpId
							,PeriodFrom
							,PeriodTo
							,StartDate
							,EndDate
							,ExpiryDays
							,Sort
							,CreateTime
							,Status
							,LastUpdateTime
							,LastUpdateUser
							,WalletType
							,RedeemHours
							,PeriodType
							,PeriodDay
							,SpecialCode
							,IsSpecial
						)
						SELECT
							BonusCode
							,SiteId
							,Description
							,PromotionType
							,CategoryId
							,TpId
							,PeriodFrom
							,PeriodTo
							,StartDate
							,EndDate
							,ExpiryDays
							,Sort
							,CreateTime
							,Status
							,LastUpdateTime
							,LastUpdateUser
							,WalletType
							,RedeemHours
							,PeriodType
							,PeriodDay
							,SpecialCode
							,IsSpecial
						FROM #tmpPromotion
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
	WHERE DataSource = 'Promotion'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(MONTH, -1, GETDATE())

	DROP TABLE #tmpPromotion
END
GO