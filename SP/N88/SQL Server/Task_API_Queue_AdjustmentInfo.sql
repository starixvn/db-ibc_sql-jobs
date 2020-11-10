/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_API_Queue_AdjustmentInfo]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20201021@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of AdjustmentInfo table

	Revisions:
		- 20201021@Percy: Initialize SP [RedmineID: #143879]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'AdjustmentInfo')
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

	CREATE TABLE #tmpAdjustmentInfo
	(
		AdjustId		INT
		,TransId		VARCHAR(30)
		,AdjustType		TINYINT
		,CustId			INT
		,UserName		VARCHAR(30)
		,CurrencyId		TINYINT
		,SiteId			INT
		,AdjustIdInfo	NVARCHAR(MAX)
		,Amount			DECIMAL(18, 4)
		,CreateTime		DATETIME
		,FirstDeposit	BIT
		,RefId			VARCHAR(100)
		,Memo			VARCHAR(500)
		,Comment		VARCHAR(500)
		,Status			TINYINT
		,DataType		TINYINT -- 0: update, 1: insert
		,PRIMARY KEY (AdjustId)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'AdjustmentInfo')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'AdjustmentInfo'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'AdjustmentInfo'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpAdjustmentInfo

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpAdjustmentInfo
				(
					AdjustId
					,TransId
					,AdjustType
					,CustId
					,UserName
					,CurrencyId
					,SiteId
					,AdjustIdInfo
					,Amount
					,CreateTime
					,FirstDeposit
					,RefId
					,Memo
					,Comment
					,Status
				)
				SELECT
					t.c.value('@adjustid', 'INT')
					,t.c.value('@transid', 'VARCHAR(30)')
					,t.c.value('@adjusttype', 'TINYINT')
					,t.c.value('@custid', 'INT')
					,t.c.value('@username', 'VARCHAR(30)')
					,t.c.value('@currencyid', 'TINYINT')
					,t.c.value('@siteid', 'INT')
					,t.c.value('@adjustidinfo', 'NVARCHAR(MAX)')
					,t.c.value('@amount', 'DECIMAL(18, 4)')
					,NULLIF(t.c.value('@createtime', 'DATETIME'), '')
					,t.c.value('@firstdeposit', 'BIT')
					,t.c.value('@refid', 'VARCHAR(100)')
					,t.c.value('@memo', 'VARCHAR(500)')
					,t.c.value('@comment', 'VARCHAR(500)')
					,t.c.value('@status', 'TINYINT')
				FROM @XmlData.nodes('root/row') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN b.AdjustId IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpAdjustmentInfo t
					LEFT JOIN dbo.AdjustmentInfo b WITH (NOLOCK) ON t.AdjustId = b.AdjustId
				WHERE b.AdjustId IS NULL
					OR ISNULL(t.TransId, '') <> ISNULL(b.TransId, '')
					OR ISNULL(t.AdjustType, 0) <> ISNULL(b.AdjustType, 0)
					OR ISNULL(t.CustId, 0) <> ISNULL(b.CustId, 0)
					OR ISNULL(t.UserName, '') <> ISNULL(b.UserName, '')
					OR ISNULL(t.CurrencyId, 0) <> ISNULL(b.CurrencyId, 0)
					OR ISNULL(t.SiteId, 0) <> ISNULL(b.SiteId, 0)
					OR ISNULL(t.AdjustIdInfo, '') <> ISNULL(b.AdjustIdInfo,'')
					OR ISNULL(t.Amount, 0) <> ISNULL(b.Amount, 0)
					OR ISNULL(t.CreateTime, '') <> ISNULL(b.CreateTime, '')
					OR ISNULL(t.FirstDeposit, 0) <> ISNULL(b.FirstDeposit, 0)
					OR ISNULL(t.RefId, '') <> ISNULL(b.RefId, '')
					OR ISNULL(t.Memo, '') <> ISNULL(b.Memo, '')
					OR ISNULL(t.Comment, '') <> ISNULL(b.Comment, '')
					OR ISNULL(t.Status, 0) <> ISNULL(b.Status, 0)
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpAdjustmentInfo WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.TransId = t.TransId
							,b.AdjustType = t.AdjustType
							,b.CustId = t.CustId
							,b.UserName = t.UserName
							,b.CurrencyId = t.CurrencyId
							,b.SiteId = t.SiteId
							,b.AdjustIdInfo = t.AdjustIdInfo
							,b.Amount = t.Amount
							,b.CreateTime = t.CreateTime
							,b.FirstDeposit = t.FirstDeposit
							,b.RefId = t.RefId
							,b.Memo = t.Memo
							,b.Comment = t.Comment
							,b.Status = t.Status
						FROM dbo.AdjustmentInfo b
							INNER JOIN #tmpAdjustmentInfo t ON b.AdjustId = t.AdjustId
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpAdjustmentInfo WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.AdjustmentInfo
						(
							AdjustId
							,TransId
							,AdjustType
							,CustId
							,UserName
							,CurrencyId
							,SiteId
							,AdjustIdInfo
							,Amount
							,CreateTime
							,FirstDeposit
							,RefId
							,Memo
							,Comment
							,Status
						)
						SELECT
							AdjustId
							,TransId
							,AdjustType
							,CustId
							,UserName
							,CurrencyId
							,SiteId
							,AdjustIdInfo
							,Amount
							,CreateTime
							,FirstDeposit
							,RefId
							,Memo
							,Comment
							,Status
						FROM #tmpAdjustmentInfo
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
	WHERE DataSource = 'AdjustmentInfo'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(MONTH, -1, GETDATE())

	DROP TABLE #tmpAdjustmentInfo
END
GO