/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_API_Queue_ReferralLog]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20230301@Malcolm
	DB: DBN88-bodb_N88
	Task: Insert data of ReferralLog table

	Revisions:
		- 20230301@Malcolm: Initialize SP [RedmineID: #183930]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'ReferralLog')
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
	
	CREATE TABLE #tmpReferralLog
	(
		SQ					INT
		,CustId				INT
		,CurrencyId			TINYINT
		,UserName			VARCHAR(30)
		,SiteId				INT
		,ReferralFreeCredit	DECIMAL (18, 4)
		,AgentId			INT
		,ReferralAmount		DECIMAL (18, 4)
		,Memo				VARCHAR(200)
		,RelId				BIGINT
		,CreateTime			DATETIME
		,RewardStatus		TINYINT
		,DataType			TINYINT -- 0: update, 1: insert
		,PRIMARY KEY (SQ)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'ReferralLog')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'ReferralLog'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'ReferralLog'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpReferralLog

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpReferralLog
				(
					SQ
					,CustId				
					,CurrencyId			
					,UserName			
					,SiteId				
					,ReferralFreeCredit	
					,AgentId			
					,ReferralAmount		
					,Memo				
					,RelId				
					,CreateTime
					,RewardStatus
				)
				SELECT
					t.c.value('@sq', 'INT')
					,t.c.value('@custid', 'INT')
					,t.c.value('@currencyid', 'TINYINT')
					,t.c.value('@username', 'VARCHAR(30)')
					,t.c.value('@siteid', 'INT')
					,t.c.value('@referralfreecredit', 'DECIMAL(18, 4)')
					,t.c.value('@agentid', 'INT')
					,t.c.value('@referralamount', 'DECIMAL(18, 4)')
					,t.c.value('@memo', 'VARCHAR(200)')
					,t.c.value('@relid', 'BIGINT')
					,t.c.value('@createtime', 'DATETIME')
					,t.c.value('@rewardstatus', 'TINYINT')
				FROM @XmlData.nodes('root/row') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN b.SQ IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpReferralLog t
					LEFT JOIN dbo.ReferralLog b WITH (NOLOCK) ON t.SQ = b.SQ
				WHERE b.SQ IS NULL
					OR ISNULL(t.CustId, 0) <> ISNULL(b.CustId, 0)
					OR ISNULL(t.CurrencyId, 0) <> ISNULL(b.CurrencyId, 0)
					OR ISNULL(t.UserName, '') <> ISNULL(b.UserName, '')
					OR ISNULL(t.SiteId, 0) <> ISNULL(b.SiteId, 0)
					OR ISNULL(t.ReferralFreeCredit, 0) <> ISNULL(b.ReferralFreeCredit, 0)
					OR ISNULL(t.AgentId, 0) <> ISNULL(b.AgentId, 0)
					OR ISNULL(t.ReferralAmount, 0) <> ISNULL(b.ReferralAmount, 0)
					OR ISNULL(t.Memo, '') <> ISNULL(b.Memo, '')
					OR ISNULL(t.RelId, 0) <> ISNULL(b.RelId, 0)
					OR ISNULL(t.CreateTime, '') <> ISNULL(b.CreateTime, '')
					OR ISNULL(t.RewardStatus, 0) <> ISNULL(b.RewardStatus, 0)
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpReferralLog WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET 
							b.CustId				= t.CustId
							,b.CurrencyId			= t.CurrencyId
							,b.UserName				= t.UserName
							,b.SiteId				= t.SiteId
							,b.ReferralFreeCredit	= t.ReferralFreeCredit
							,b.AgentId				= t.AgentId
							,b.ReferralAmount		= t.ReferralAmount
							,b.Memo					= t.Memo
							,b.RelId				= t.RelId
							,b.CreateTime			= t.CreateTime
							,b.RewardStatus			= t.RewardStatus
						FROM dbo.ReferralLog b
							INNER JOIN #tmpReferralLog t ON b.SQ = t.SQ
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpReferralLog WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.ReferralLog
						(
							SQ
							,CustId				
							,CurrencyId			
							,UserName			
							,SiteId				
							,ReferralFreeCredit	
							,AgentId			
							,ReferralAmount		
							,Memo				
							,RelId				
							,CreateTime
							,RewardStatus
						)
						SELECT
							SQ
							,CustId				
							,CurrencyId			
							,UserName			
							,SiteId				
							,ReferralFreeCredit	
							,AgentId			
							,ReferralAmount		
							,Memo				
							,RelId				
							,CreateTime
							,RewardStatus
						FROM #tmpReferralLog
						WHERE DataType = 1
					END
				END

				INSERT INTO @WinlostDate (WinlostDate)
				SELECT b.WinlostDate
				FROM (SELECT DISTINCT CONVERT(DATE, CreateTime) AS WinlostDate FROM #tmpReferralLog WHERE DataType IN (0, 1)) b
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
	SELECT 'ReferralLog', WinlostDate FROM @WinlostDate

	-- Remove old data
	DELETE dbo.API_Queue WITH (ROWLOCK, UPDLOCK)
	WHERE DataSource = 'ReferralLog'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(DAY, -7, GETDATE())

	DROP TABLE #tmpReferralLog
END
GO