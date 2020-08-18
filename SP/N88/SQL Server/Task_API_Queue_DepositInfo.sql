/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_API_Queue_DepositInfo]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20200716@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of DepositInfo table

	Revisions:
		- 20200716@Percy: Initialize SP [RedmineID: #137395]
		- 20200818@Percy: Add new columns: Flag, Operator, UpdateTime [RedmineID: #137395]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'DepositInfo')
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

	CREATE TABLE #tmpDepositInfo
	(
		DepositId		INT
		,TransId		VARCHAR(30)
		,DepositType	TINYINT
		,CustId			INT
		,UserName		VARCHAR(30)
		,CurrencyId		TINYINT
		,SiteId			INT
		,DepositInfo	NVARCHAR(MAX)
		,Amount			DECIMAL(18,4)
		,ActualDeposit	DECIMAL(18,4)
		,CreateTime		DATETIME
		,TPCreateTime	DATETIME
		,CallbackTime	DATETIME
		,FirstDeposit	BIT
		,ThirdId		VARCHAR(100)
		,RefId			VARCHAR(100)
		,DepositTime	DATETIME
		,Memo			VARCHAR(100)
		,PostScript		VARCHAR(45)
		,Comment		VARCHAR(500)
		,Status			TINYINT
		,Flag			INT
		,Operator		VARCHAR(30)
		,UpdateTime		DATETIME
		,DataType		TINYINT -- 0: update, 1: insert
		,PRIMARY KEY (DepositId)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'DepositInfo')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'DepositInfo'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'DepositInfo'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpDepositInfo

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpDepositInfo
				(
					DepositId
					,TransId
					,DepositType
					,CustId
					,UserName
					,CurrencyId
					,SiteId
					,DepositInfo
					,Amount
					,ActualDeposit
					,CreateTime
					,TPCreateTime
					,CallbackTime
					,FirstDeposit
					,ThirdId
					,RefId
					,DepositTime
					,Memo
					,PostScript
					,Comment
					,Status
					,Flag
					,Operator
					,UpdateTime
				)
				SELECT
					t.c.value('@depositid', 'INT')
					,t.c.value('@transid', 'VARCHAR(30)')
					,t.c.value('@deposittype', 'TINYINT')
					,t.c.value('@custid', 'INT')
					,t.c.value('@username', 'VARCHAR(30)')
					,t.c.value('@currencyid', 'TINYINT')
					,t.c.value('@siteid', 'INT')
					,t.c.value('@depositinfo', 'NVARCHAR(MAX)')
					,t.c.value('@amount', 'DECIMAL(18, 4)')
					,t.c.value('@actualdeposit', 'DECIMAL(18, 4)')
					,NULLIF(t.c.value('@createtime', 'DATETIME'), '')
					,NULLIF(t.c.value('@tpcreatetime', 'DATETIME'), '')
					,NULLIF(t.c.value('@callbacktime', 'DATETIME'), '')
					,t.c.value('@firstdeposit', 'BIT')
					,t.c.value('@thirdid', 'VARCHAR(100)')
					,t.c.value('@refid', 'VARCHAR(100)')
					,NULLIF(t.c.value('@deposittime', 'DATETIME'), '')
					,t.c.value('@memo', 'VARCHAR(100)')
					,t.c.value('@postscript', 'VARCHAR(45)')
					,t.c.value('@comment', 'VARCHAR(500)')
					,t.c.value('@status', 'TINYINT')
					,t.c.value('@flag', 'int')
					,t.c.value('@operator', 'VARCHAR(30)')
					,NULLIF(t.c.value('@updatetime', 'DATETIME'), '')
				FROM @XmlData.nodes('root/row') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN b.DepositId IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpDepositInfo t
					LEFT JOIN dbo.DepositInfo b WITH (NOLOCK) ON t.DepositId = b.DepositId
				WHERE b.DepositId IS NULL
					OR ISNULL(t.TransId, '') <> ISNULL(b.TransId, '')
					OR ISNULL(t.DepositType, 0) <> ISNULL(b.DepositType, 0)
					OR ISNULL(t.CustId, 0) <> ISNULL(b.CustId, 0)
					OR ISNULL(t.UserName, '') <> ISNULL(b.UserName, '')
					OR ISNULL(t.CurrencyId, 0) <> ISNULL(b.CurrencyId, 0)
					OR ISNULL(t.SiteId, 0) <> ISNULL(b.SiteId, 0)
					OR ISNULL(t.DepositInfo, '') <> ISNULL(b.DepositInfo, '')
					OR ISNULL(t.Amount, 0) <> ISNULL(b.Amount, 0)
					OR ISNULL(t.ActualDeposit, 0) <> ISNULL(b.ActualDeposit, 0)
					OR ISNULL(t.CreateTime, '') <> ISNULL(b.CreateTime, '')
					OR ISNULL(t.TPCreateTime, '') <> ISNULL(b.TPCreateTime, '')
					OR ISNULL(t.CallbackTime, '') <> ISNULL(b.CallbackTime, '')
					OR ISNULL(t.FirstDeposit, '') <> ISNULL(b.FirstDeposit, '')
					OR ISNULL(t.ThirdId, '') <> ISNULL(b.ThirdId, '')
					OR ISNULL(t.RefId, '') <> ISNULL(b.RefId, '')
					OR ISNULL(t.DepositTime, '') <> ISNULL(b.DepositTime, '')
					OR ISNULL(t.Memo, '') <> ISNULL(b.Memo, '')
					OR ISNULL(t.PostScript, '') <> ISNULL(b.PostScript, '')
					OR ISNULL(t.Comment, '') <> ISNULL(b.Comment, '')
					OR ISNULL(t.Status, 0) <> ISNULL(b.Status, 0)
					OR ISNULL(t.Flag, 0) <> ISNULL(b.Flag, 0)
					OR ISNULL(t.Operator, '') <> ISNULL(b.Operator, '')
					OR ISNULL(t.UpdateTime, '') <> ISNULL(b.UpdateTime, '')
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpDepositInfo WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.DepositId = t.DepositId
							,b.TransId = t.TransId
							,b.DepositType = t.DepositType
							,b.CustId = t.CustId
							,b.UserName = t.UserName
							,b.CurrencyId = t.CurrencyId
							,b.SiteId = t.SiteId
							,b.DepositInfo = t.DepositInfo
							,b.Amount = t.Amount
							,b.ActualDeposit = t.ActualDeposit
							,b.CreateTime = t.CreateTime
							,b.TPCreateTime = t.TPCreateTime
							,b.CallbackTime = t.CallbackTime
							,b.FirstDeposit = t.FirstDeposit
							,b.ThirdId = t.ThirdId
							,b.RefId = t.RefId
							,b.DepositTime = t.DepositTime
							,b.Memo = t.Memo
							,b.PostScript = t.PostScript
							,b.Comment = t.Comment
							,b.Status = t.Status
							,b.Flag = t.Flag
							,b.Operator = t.Operator
							,b.UpdateTime = t.UpdateTime
						FROM dbo.DepositInfo b
							INNER JOIN #tmpDepositInfo t ON b.DepositId = t.DepositId
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpDepositInfo WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.DepositInfo
						(
							DepositId
							,TransId
							,DepositType
							,CustId
							,UserName
							,CurrencyId
							,SiteId
							,DepositInfo
							,Amount
							,ActualDeposit
							,CreateTime
							,TPCreateTime
							,CallbackTime
							,FirstDeposit
							,ThirdId
							,RefId
							,DepositTime
							,Memo
							,PostScript
							,Comment
							,Status
							,Flag
							,Operator
							,UpdateTime
						)
						SELECT
							DepositId
							,TransId
							,DepositType
							,CustId
							,UserName
							,CurrencyId
							,SiteId
							,DepositInfo
							,Amount
							,ActualDeposit
							,CreateTime
							,TPCreateTime
							,CallbackTime
							,FirstDeposit
							,ThirdId
							,RefId
							,DepositTime
							,Memo
							,PostScript
							,Comment
							,Status
							,Flag
							,Operator
							,UpdateTime
						FROM #tmpDepositInfo
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
	WHERE DataSource = 'DepositInfo'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(MONTH, -1, GETDATE())

	DROP TABLE #tmpDepositInfo
END
GO