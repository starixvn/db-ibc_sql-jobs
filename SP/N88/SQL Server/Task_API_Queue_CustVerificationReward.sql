/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
USE bodb_N88
GO
ALTER PROCEDURE [dbo].[Task_API_Queue_CustVerificationReward]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20220325@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of CustVerificationReward table

	Revisions:
		- 20220325@Percy: Initialize SP [RedmineID: #170390]
		- 20220412@Percy: Import SUM data [RedmineID: #171245]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'CustVerificationReward')
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
	
	CREATE TABLE #tmpCustVerificationReward
	(
		CustId				INT
		,SiteId				INT
		,CurrencyId			INT
		,PhoneReward		DECIMAL(20, 4)
		,PhoneRewardTime	DATETIME
		,EmailReward		DECIMAL(20, 4)
		,EmailRewardTime	DATETIME
		,DataType			TINYINT -- 0: update, 1: insert
		,PRIMARY KEY (CustId)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'CustVerificationReward')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'CustVerificationReward'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'CustVerificationReward'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpCustVerificationReward

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpCustVerificationReward
				(
					CustId
					,SiteId
					,CurrencyId
					,PhoneReward
					,PhoneRewardTime
					,EmailReward
					,EmailRewardTime
				)
				SELECT
					t.CustId
					,t.SiteId
					,c.CurrencyId
					,t.PhoneReward
					,t.PhoneRewardTime
					,t.EmailReward
					,t.EmailRewardTime
				FROM (
					SELECT
						t.c.value('@custid', 'INT') AS CustId
						,t.c.value('@siteid', 'INT') AS SiteId
						,NULLIF(t.c.value('@phonereward', 'VARCHAR(25)'), '') AS PhoneReward
						,NULLIF(t.c.value('@phonerewardtime', 'DATETIME'), '') AS PhoneRewardTime
						,NULLIF(t.c.value('@emailreward', 'VARCHAR(25)'), '') AS EmailReward
						,NULLIF(t.c.value('@emailrewardtime', 'DATETIME'), '') AS EmailRewardTime
					FROM @XmlData.nodes('root/row') t(c)
				) t
					INNER JOIN dbo.Customer c WITH (NOLOCK) ON t.CustId = c.CustId
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN b.CustId IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpCustVerificationReward t
					LEFT JOIN dbo.CustVerificationReward b WITH (NOLOCK) ON t.CustId = b.CustId
				WHERE b.CustId IS NULL
					OR ISNULL(t.SiteId, 0) <> ISNULL(b.SiteId, 0)
					OR ISNULL(t.CurrencyId, 0) <> ISNULL(b.CurrencyId, 0)
					OR ISNULL(t.PhoneReward, 0) <> ISNULL(b.PhoneReward, 0)
					OR ISNULL(t.PhoneRewardTime, '') <> ISNULL(b.PhoneRewardTime, '')
					OR ISNULL(t.EmailReward, 0) <> ISNULL(b.EmailReward, 0)
					OR ISNULL(t.EmailRewardTime, '') <> ISNULL(b.EmailRewardTime, '')
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpCustVerificationReward WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.SiteId = t.SiteId
							,b.CurrencyId = t.CurrencyId
							,b.PhoneReward = t.PhoneReward
							,b.PhoneRewardTime = t.PhoneRewardTime
							,b.EmailReward = t.EmailReward
							,b.EmailRewardTime = t.EmailRewardTime
						FROM dbo.CustVerificationReward b
							INNER JOIN #tmpCustVerificationReward t ON b.CustId = t.CustId
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpCustVerificationReward WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.CustVerificationReward
						(
							CustId
							,SiteId
							,CurrencyId
							,PhoneReward
							,PhoneRewardTime
							,EmailReward
							,EmailRewardTime
						)
						SELECT
							CustId
							,SiteId
							,CurrencyId
							,PhoneReward
							,PhoneRewardTime
							,EmailReward
							,EmailRewardTime
						FROM #tmpCustVerificationReward
						WHERE DataType = 1
					END

					-- update CustVerificationRewardDetail table
					;WITH CTE_Tager AS (
						SELECT c.CustId, c.SiteId, c.CurrencyId, c.RewardType, c.RewardAmount, c.RewardTime
						FROM #tmpCustVerificationReward t
							INNER JOIN dbo.CustVerificationRewardDetail c WITH (ROWLOCK) ON t.CustId = c.CustId
					), CTE_Source AS (
						SELECT t.CustId, t.SiteId, t.CurrencyId, c.RewardType, c.RewardAmount, c.RewardTime
						FROM #tmpCustVerificationReward t
							CROSS APPLY (
								SELECT CONVERT(TINYINT, 1) AS RewardType, t.PhoneReward AS RewardAmount, t.PhoneRewardTime AS RewardTime WHERE t.PhoneReward IS NOT NULL AND t.PhoneRewardTime IS NOT NULL
								UNION ALL SELECT 2, t.EmailReward, t.EmailRewardTime WHERE t.EmailReward IS NOT NULL AND t.EmailRewardTime IS NOT NULL
							) c
						WHERE t.DataType IS NOT NULL
					)
					MERGE CTE_Tager AS t
					USING CTE_Source AS s ON t.CustId = s.CustId AND t.RewardType = s.RewardType
					WHEN MATCHED THEN UPDATE
						SET t.SiteId = s.SiteId, t.CurrencyId = s.CurrencyId, t.RewardAmount = s.RewardAmount, t.RewardTime = s.RewardTime
					WHEN NOT MATCHED BY TARGET THEN INSERT
						(CustId, SiteId, CurrencyId, RewardType, RewardAmount, RewardTime)
						VALUES (s.CustId, s.SiteId, s.CurrencyId, s.RewardType, s.RewardAmount, s.RewardTime)
					WHEN NOT MATCHED BY SOURCE THEN DELETE;
				END

				INSERT INTO @WinlostDate (WinlostDate)
				SELECT b.WinlostDate
				FROM (
					SELECT DISTINCT CONVERT(DATE, c.RewardTime) AS WinlostDate
					FROM #tmpCustVerificationReward t
						CROSS APPLY (
							SELECT t.EmailRewardTime AS RewardTime WHERE t.EmailRewardTime IS NOT NULL
							UNION ALL SELECT t.PhoneRewardTime WHERE t.PhoneRewardTime IS NOT NULL
						) c
					WHERE t.DataType IN (0, 1)
				) b
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
	SELECT 'CustVerificationReward', WinlostDate FROM @WinlostDate

	-- Remove old data
	DELETE dbo.API_Queue WITH (ROWLOCK, UPDLOCK)
	WHERE DataSource = 'CustVerificationReward'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(DAY, -7, GETDATE())

	DROP TABLE #tmpCustVerificationReward
END
GO