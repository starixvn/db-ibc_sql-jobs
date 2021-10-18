/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
USE bodb_N88
GO
ALTER PROCEDURE [dbo].[Task_API_Queue_PromotionSpecific]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20210112@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of PromotionSpecific table

	Revisions:
		- 20210112@Percy: Initialize SP [RedmineID: #146759]
		- 20211018@Percy: Keep API's data within 7 days [RedmineID: #163336]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'PromotionSpecific')
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

	CREATE TABLE #tmpPromotionSpecific
	(
		BonusCode		VARCHAR(50)
		,CurrencyId		TINYINT
		,SiteId			INT
		,Usage			INT
		,BeenUsed		INT
		,RollOver		INT
		,Bonus			DECIMAL(18, 2)
		,BonusType		TINYINT
		,RequiredAmount	DECIMAL(18, 2)
		,LockedType		VARCHAR(45)
		,MaxBonus		DECIMAL(18, 2)
		,Status			TINYINT
		,Details		NVARCHAR(MAX)
		,CreateTime		DATETIME
		,UpdateTime		DATETIME
		,LastClaimTime	DATETIME
		,MinPayout		DECIMAL(18, 2)
		,SettleTime		DATETIME
		,AffId			INT
		,VN_AffId		INT
		,VN_AffIds		NVARCHAR(MAX)
		,VN_AffCodes	NVARCHAR(MAX)
		,DataType		TINYINT -- 0: update, 1: insert
		,PRIMARY KEY (BonusCode, CurrencyId, SiteId)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'PromotionSpecific')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'PromotionSpecific'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'PromotionSpecific'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpPromotionSpecific

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpPromotionSpecific
				(
					BonusCode
					,CurrencyId
					,SiteId
					,Usage
					,BeenUsed
					,RollOver
					,Bonus
					,BonusType
					,RequiredAmount
					,LockedType
					,MaxBonus
					,Status
					,Details
					,CreateTime
					,UpdateTime
					,LastClaimTime
					,MinPayout
					,SettleTime
					,AffId
					,VN_AffId
					,VN_AffIds
					,VN_AffCodes
				)
				SELECT
					t.c.value('@bonuscode', 'VARCHAR(50)')
					,t.c.value('@currencyid', 'TINYINT')
					,t.c.value('@siteid', 'INT')
					,t.c.value('@usage', 'INT')
					,t.c.value('@beenused', 'INT')
					,t.c.value('@rollover', 'INT')
					,t.c.value('@bonus', 'DECIMAL(18, 2)')
					,t.c.value('@bonustype', 'TINYINT')
					,t.c.value('@requiredamount', 'DECIMAL(18, 2)')
					,t.c.value('@lockedtype', 'VARCHAR(45)')
					,t.c.value('@maxbonus', 'DECIMAL(18, 2)')
					,t.c.value('@status', 'TINYINT')
					,t.c.value('@details', 'NVARCHAR(MAX)')
					,NULLIF(t.c.value('@createtime', 'DATETIME'), '')
					,NULLIF(t.c.value('@updatetime', 'DATETIME'), '')
					,NULLIF(t.c.value('@lastclaimtime', 'DATETIME'), '')
					,t.c.value('@minpayout', 'DECIMAL(18, 2)')
					,NULLIF(t.c.value('@settletime', 'DATETIME'), '')
					,t.c.value('@affid', 'INT')
					,t.c.value('@vn_affid', 'INT')
					,t.c.value('@vn_affids', 'NVARCHAR(MAX)')
					,t.c.value('@vn_affcodes', 'NVARCHAR(MAX)')
				FROM @XmlData.nodes('root/row') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN b.BonusCode IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpPromotionSpecific t
					LEFT JOIN dbo.PromotionSpecific b WITH (NOLOCK)
						ON		t.BonusCode		= t.BonusCode
							AND t.CurrencyId	= b.CurrencyId
							AND t.SiteId		= b.SiteId
				WHERE b.BonusCode IS NULL
					OR ISNULL(t.Usage, 0) <> ISNULL(b.Usage, 0)
					OR ISNULL(t.BeenUsed, 0) <> ISNULL(b.BeenUsed, 0)
					OR ISNULL(t.RollOver, 0) <> ISNULL(b.RollOver, 0)
					OR ISNULL(t.Bonus, 0) <> ISNULL(b.Bonus, 0)
					OR ISNULL(t.BonusType, 0) <> ISNULL(b.BonusType, 0)
					OR ISNULL(t.RequiredAmount, 0) <> ISNULL(b.RequiredAmount, 0)
					OR ISNULL(t.LockedType, '') <> ISNULL(b.LockedType, '')
					OR ISNULL(t.MaxBonus, 0) <> ISNULL(b.MaxBonus, 0)
					OR ISNULL(t.Status, 0) <> ISNULL(b.Status, 0)
					OR ISNULL(t.Details, '') <> ISNULL(b.Details, '')
					OR ISNULL(t.CreateTime, '') <> ISNULL(b.CreateTime, '')
					OR ISNULL(t.UpdateTime, '') <> ISNULL(b.UpdateTime, '')
					OR ISNULL(t.LastClaimTime, '') <> ISNULL(b.LastClaimTime, '')
					OR ISNULL(t.MinPayout, 0) <> ISNULL(b.MinPayout, 0)
					OR ISNULL(t.SettleTime, '') <> ISNULL(b.SettleTime, '')
					OR ISNULL(t.AffId, 0) <> ISNULL(b.AffId, 0)
					OR ISNULL(t.VN_AffId, 0) <> ISNULL(b.VN_AffId, 0)
					OR ISNULL(t.VN_AffIds, '') <> ISNULL(b.VN_AffIds, '')
					OR ISNULL(t.VN_AffCodes, '') <> ISNULL(b.VN_AffCodes, '')
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpPromotionSpecific WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.Usage = t.Usage
							,b.BeenUsed = t.BeenUsed
							,b.RollOver = t.RollOver
							,b.Bonus = t.Bonus
							,b.BonusType = t.BonusType
							,b.RequiredAmount = t.RequiredAmount
							,b.LockedType = t.LockedType
							,b.MaxBonus = t.MaxBonus
							,b.Status = t.Status
							,b.Details = t.Details
							,b.CreateTime = t.CreateTime
							,b.UpdateTime = t.UpdateTime
							,b.LastClaimTime = t.LastClaimTime
							,b.MinPayout = t.MinPayout
							,b.SettleTime = t.SettleTime
							,b.AffId = t.AffId
							,b.VN_AffId = t.VN_AffId
							,b.VN_AffIds = t.VN_AffIds
							,b.VN_AffCodes = t.VN_AffCodes
						FROM dbo.PromotionSpecific b
							INNER JOIN #tmpPromotionSpecific t
								ON		t.BonusCode		= t.BonusCode
									AND t.CurrencyId	= b.CurrencyId
									AND t.SiteId		= b.SiteId
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpPromotionSpecific WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.PromotionSpecific
						(
							BonusCode
							,CurrencyId
							,SiteId
							,Usage
							,BeenUsed
							,RollOver
							,Bonus
							,BonusType
							,RequiredAmount
							,LockedType
							,MaxBonus
							,Status
							,Details
							,CreateTime
							,UpdateTime
							,LastClaimTime
							,MinPayout
							,SettleTime
							,AffId
							,VN_AffId
							,VN_AffIds
							,VN_AffCodes
						)
						SELECT
							BonusCode
							,CurrencyId
							,SiteId
							,Usage
							,BeenUsed
							,RollOver
							,Bonus
							,BonusType
							,RequiredAmount
							,LockedType
							,MaxBonus
							,Status
							,Details
							,CreateTime
							,UpdateTime
							,LastClaimTime
							,MinPayout
							,SettleTime
							,AffId
							,VN_AffId
							,VN_AffIds
							,VN_AffCodes
						FROM #tmpPromotionSpecific
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
	WHERE DataSource = 'PromotionSpecific'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(DAY, -7, GETDATE())

	DROP TABLE #tmpPromotionSpecific
END
GO