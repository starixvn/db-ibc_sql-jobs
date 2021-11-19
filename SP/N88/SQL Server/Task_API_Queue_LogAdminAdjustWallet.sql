/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
USE bodb_N88
GO
ALTER PROCEDURE [dbo].[Task_API_Queue_LogAdminAdjustWallet]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20211118@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of LogAdminAdjustWallet table

	Revisions:
		- 20211118@Percy: Initialize SP [RedmineID: #161048]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'LogAdminAdjustWallet')
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

	CREATE TABLE #tmpLogAdminAdjustWallet
	(
		TransferId	INT
		,TransId	VARCHAR(30)
		,ThirdId	VARCHAR(50)
		,TpId		INT
		,CustId		INT
		,UserName	VARCHAR(30)
		,SiteId		INT
		,CurrencyId	INT
		,Direction	TINYINT
		,Amount		DECIMAL(20,4)
		,Memo		VARCHAR(200)
		,Status		TINYINT
		,CreateTime DATETIME
		,Operator	VARCHAR(30)
		,Remarks	VARCHAR(100)
		,DataType	TINYINT -- 0: update, 1: insert
		,PRIMARY KEY (TransferId)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'LogAdminAdjustWallet')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'LogAdminAdjustWallet'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'LogAdminAdjustWallet'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpLogAdminAdjustWallet

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpLogAdminAdjustWallet
				(
					TransferId
					,TransId
					,ThirdId
					,TpId
					,CustId
					,UserName
					,SiteId
					,CurrencyId
					,Direction
					,Amount
					,Memo
					,Status
					,CreateTime
					,Operator
					,Remarks
				)
				SELECT
					t.TransferId
					,t.TransId
					,t.ThirdId
					,t.TpId
					,t.CustId
					,t.UserName
					,t.SiteId
					,c.CurrencyId
					,t.Direction
					,t.Amount
					,t.Memo
					,t.Status
					,t.CreateTime
					,t.Operator
					,t.Remarks
				FROM (
					SELECT
						t.c.value('@transferid', 'INT') AS TransferId
						,t.c.value('@transid', 'VARCHAR(30)') AS TransId
						,t.c.value('@thirdid', 'VARCHAR(50)') AS ThirdId
						,t.c.value('@tpid', 'INT') AS TpId
						,t.c.value('@custid', 'INT') AS CustId
						,t.c.value('@username', 'VARCHAR(30)') AS UserName
						,t.c.value('@siteid', 'INT') AS SiteId
						,t.c.value('@direction', 'TINYINT') AS Direction
						,t.c.value('@amount', 'DECIMAL(20,4)') AS Amount
						,t.c.value('@memo', 'VARCHAR(200)') AS Memo
						,t.c.value('@status', 'TINYINT') AS Status
						,NULLIF(t.c.value('@createtime', 'DATETIME'), '') AS CreateTime
						,t.c.value('@operator', 'VARCHAR(30)') AS Operator
						,t.c.value('@remarks', 'VARCHAR(100)') AS Remarks
					FROM @XmlData.nodes('root/row') t(c)
				) t
					INNER JOIN dbo.Customer c WITH (NOLOCK) ON t.CustId = c.CustId
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN b.TransferId IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpLogAdminAdjustWallet t
					LEFT JOIN dbo.LogAdminAdjustWallet b WITH (NOLOCK) ON t.TransferId = b.TransferId
				WHERE b.TransferId IS NULL
					OR ISNULL(t.TransId, '') <> ISNULL(b.TransId, '')
					OR ISNULL(t.ThirdId, '') <> ISNULL(b.ThirdId, '')
					OR ISNULL(t.TpId, 0) <> ISNULL(b.TpId, 0)
					OR ISNULL(t.CustId, 0) <> ISNULL(b.CustId, 0)
					OR ISNULL(t.UserName, '') <> ISNULL(b.UserName, '')
					OR ISNULL(t.SiteId, 0) <> ISNULL(b.SiteId, 0)
					OR ISNULL(t.CurrencyId, 0) <> ISNULL(b.CurrencyId, 0)
					OR ISNULL(t.Direction, 0) <> ISNULL(b.Direction, 0)
					OR ISNULL(t.Amount, 0) <> ISNULL(b.Amount, 0)
					OR ISNULL(t.Memo, '') <> ISNULL(b.Memo, '')
					OR ISNULL(t.Status, 0) <> ISNULL(b.Status, 0)
					OR ISNULL(t.CreateTime, '') <> ISNULL(b.CreateTime, '')
					OR ISNULL(t.Operator, '') <> ISNULL(b.Operator, '')
					OR ISNULL(t.Remarks, '') <> ISNULL(b.Remarks, '')
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpLogAdminAdjustWallet WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.TransId = t.TransId
							,b.ThirdId = t.ThirdId
							,b.TpId = t.TpId
							,b.CustId = t.CustId
							,b.UserName = t.UserName
							,b.SiteId = t.SiteId
							,b.CurrencyId = t.CurrencyId
							,b.Direction = t.Direction
							,b.Amount = t.Amount
							,b.Memo = t.Memo
							,b.Status = t.Status
							,b.CreateTime = t.CreateTime
							,b.Operator = t.Operator
							,b.Remarks = t.Remarks
						FROM dbo.LogAdminAdjustWallet b
							INNER JOIN #tmpLogAdminAdjustWallet t ON b.TransferId = t.TransferId
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpLogAdminAdjustWallet WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.LogAdminAdjustWallet
						(
							TransferId
							,TransId
							,ThirdId
							,TpId
							,CustId
							,UserName
							,SiteId
							,CurrencyId
							,Direction
							,Amount
							,Memo
							,Status
							,CreateTime
							,Operator
							,Remarks
						)
						SELECT
							TransferId
							,TransId
							,ThirdId
							,TpId
							,CustId
							,UserName
							,SiteId
							,CurrencyId
							,Direction
							,Amount
							,Memo
							,Status
							,CreateTime
							,Operator
							,Remarks
						FROM #tmpLogAdminAdjustWallet
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
	WHERE DataSource = 'LogAdminAdjustWallet'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(DAY, -7, GETDATE())

	DROP TABLE #tmpLogAdminAdjustWallet
END
GO