/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_API_Queue_CustBonusRollover]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20210112@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of CustBonusRollover table

	Revisions:
		- 20210112@Percy: Initialize SP [RedmineID: #146759]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'CustBonusRollover')
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

	CREATE TABLE #tmpCustBonusRollover
	(
		BonusId				INT
		,PromoCategoryId	INT
		,TpId				INT
		,CustId				INT
		,SiteId				INT
		,Rollover			DECIMAL
		,Turnover			DECIMAL
		,Status				TINYINT
		,CreateTime			DATETIME
		,UpdateTime			DATETIME
		,DataType			TINYINT -- 0: update, 1: insert
		,PRIMARY KEY (BonusId)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'CustBonusRollover')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'CustBonusRollover'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'CustBonusRollover'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpCustBonusRollover

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpCustBonusRollover
				(
					BonusId
					,PromoCategoryId
					,TpId
					,CustId
					,SiteId
					,Rollover
					,Turnover
					,Status
					,CreateTime
					,UpdateTime
				)
				SELECT
					t.c.value('@bonusid', 'INT')
					,t.c.value('@promocategoryid', 'INT')
					,t.c.value('@tpid', 'INT')
					,t.c.value('@custid', 'INT')
					,t.c.value('@siteid', 'INT')
					,t.c.value('@rollover', 'DECIMAL')
					,t.c.value('@turnover', 'DECIMAL')
					,t.c.value('@status', 'TINYINT')
					,NULLIF(t.c.value('@createtime', 'DATETIME'), '')
					,NULLIF(t.c.value('@updatetime', 'DATETIME'), '')
				FROM @XmlData.nodes('root/row') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN b.BonusId IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpCustBonusRollover t
					LEFT JOIN dbo.CustBonusRollover b WITH (NOLOCK) ON t.BonusId = b.BonusId
				WHERE b.BonusId IS NULL
					OR ISNULL(t.BonusId, 0) <> ISNULL(b.BonusId, 0)
				OR ISNULL(t.PromoCategoryId, 0) <> ISNULL(b.PromoCategoryId, 0)
				OR ISNULL(t.TpId, 0) <> ISNULL(b.TpId, 0)
				OR ISNULL(t.CustId, 0) <> ISNULL(b.CustId, 0)
				OR ISNULL(t.SiteId, 0) <> ISNULL(b.SiteId, 0)
				OR ISNULL(t.Rollover, 0) <> ISNULL(b.Rollover, 0)
				OR ISNULL(t.Turnover, 0) <> ISNULL(b.Turnover, 0)
				OR ISNULL(t.Status, 0) <> ISNULL(b.Status, 0)
				OR ISNULL(t.CreateTime, '') <> ISNULL(b.CreateTime, '')
				OR ISNULL(t.UpdateTime, '') <> ISNULL(b.UpdateTime, '')
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpCustBonusRollover WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.PromoCategoryId = t.PromoCategoryId
							,b.TpId = t.TpId
							,b.CustId = t.CustId
							,b.SiteId = t.SiteId
							,b.Rollover = t.Rollover
							,b.Turnover = t.Turnover
							,b.Status = t.Status
							,b.CreateTime = t.CreateTime
							,b.UpdateTime = t.UpdateTime
						FROM dbo.CustBonusRollover b
							INNER JOIN #tmpCustBonusRollover t ON b.BonusId = t.BonusId
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpCustBonusRollover WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.CustBonusRollover
						(
							BonusId
							,PromoCategoryId
							,TpId
							,CustId
							,SiteId
							,Rollover
							,Turnover
							,Status
							,CreateTime
							,UpdateTime
						)
						SELECT
							BonusId
							,PromoCategoryId
							,TpId
							,CustId
							,SiteId
							,Rollover
							,Turnover
							,Status
							,CreateTime
							,UpdateTime
						FROM #tmpCustBonusRollover
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
	WHERE DataSource = 'CustBonusRollover'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(MONTH, -1, GETDATE())

	DROP TABLE #tmpCustBonusRollover
END
GO