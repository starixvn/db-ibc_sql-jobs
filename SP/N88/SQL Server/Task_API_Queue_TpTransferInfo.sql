/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
USE bodb_N88
GO
ALTER PROCEDURE [dbo].[Task_API_Queue_TpTransferInfo]
	@QueueIDInput	BIGINT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20200520@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of TpTransferInfo table

	Revisions:
		- 20200716@Percy: Initialize SP [RedmineID: #137395]
		- 20211018@Percy: Keep API's data within 7 days [RedmineID: #163336]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = 'TpTransferInfo')
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

	CREATE TABLE #tmpTpTransferInfo
	(
		TransferId	INT
		,TransId	VARCHAR(30)
		,TpId		INT
		,CustId		INT
		,UserName	VARCHAR(30)
		,SiteId		INT
		,Direction	TINYINT
		,Amount		DECIMAL(18, 2)
		,Memo		VARCHAR(100)
		,Status		TINYINT
		,CreateTime	DATETIME
		,ThirdId	VARCHAR(50)
		,DataType	TINYINT -- 0: update, 1: insert
		,PRIMARY KEY (TransferId)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = 'TpTransferInfo')
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = 'TpTransferInfo'
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = 'TpTransferInfo'
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpTpTransferInfo

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpTpTransferInfo
				(
					TransferId
					,TransId
					,TpId
					,CustId
					,UserName
					,SiteId
					,Direction
					,Amount
					,Memo
					,Status
					,CreateTime
					,ThirdId
				)
				SELECT
					t.c.value('@transferid', 'INT')
					,t.c.value('@transid', 'VARCHAR(30)')
					,t.c.value('@tpid', 'INT')
					,t.c.value('@custid', 'INT')
					,t.c.value('@username', 'VARCHAR(30)')
					,t.c.value('@siteid', 'INT')
					,t.c.value('@direction', 'TINYINT')
					,t.c.value('@amount', 'DECIMAL(18, 2)')
					,t.c.value('@memo', 'VARCHAR(100)')
					,t.c.value('@status', 'TINYINT')
					,NULLIF(t.c.value('@createtime', 'DATETIME'), '')
					,t.c.value('@thirdid', 'VARCHAR(50)')
				FROM @XmlData.nodes('root/row') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN b.TransferId IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpTpTransferInfo t
					LEFT JOIN dbo.TpTransferInfo b WITH (NOLOCK) ON t.TransferId = b.TransferId
				WHERE b.TransferId IS NULL
					OR ISNULL(t.TransId, 0) <> ISNULL(b.TransId, 0)
					OR ISNULL(t.TpId, '') <> ISNULL(b.TpId, '')
					OR ISNULL(t.CustId, 0) <> ISNULL(b.CustId, 0)
					OR ISNULL(t.UserName, '') <> ISNULL(b.UserName, '')
					OR ISNULL(t.SiteId, 0) <> ISNULL(b.SiteId, 0)
					OR ISNULL(t.Direction, 0) <> ISNULL(b.Direction, 0)
					OR ISNULL(t.Amount, 0) <> ISNULL(b.Amount, 0)
					OR ISNULL(t.Memo, '') <> ISNULL(b.Memo, '')
					OR ISNULL(t.Status, 0) <> ISNULL(b.Status, 0)
					OR ISNULL(t.CreateTime, '') <> ISNULL(b.CreateTime, '')
					OR ISNULL(t.ThirdId, '') <> ISNULL(b.ThirdId, '')
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpTpTransferInfo WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.TransId = t.TransId
							,b.TpId = t.TpId
							,b.CustId = t.CustId
							,b.UserName = t.UserName
							,b.SiteId = t.SiteId
							,b.Direction = t.Direction
							,b.Amount = t.Amount
							,b.Memo = t.Memo
							,b.Status = t.Status
							,b.CreateTime = t.CreateTime
							,b.ThirdId = t.ThirdId
						FROM dbo.TpTransferInfo b
							INNER JOIN #tmpTpTransferInfo t ON b.TransferId = t.TransferId
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpTpTransferInfo WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.TpTransferInfo
						(
							TransferId
							,TransId
							,TpId
							,CustId
							,UserName
							,SiteId
							,Direction
							,Amount
							,Memo
							,Status
							,CreateTime
							,ThirdId
						)
						SELECT
							TransferId
							,TransId
							,TpId
							,CustId
							,UserName
							,SiteId
							,Direction
							,Amount
							,Memo
							,Status
							,CreateTime
							,ThirdId
						FROM #tmpTpTransferInfo
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
	WHERE DataSource = 'TpTransferInfo'
		AND IsFinished = 1
		AND FinishedTime < DATEADD(DAY, -7, GETDATE())

	DROP TABLE #tmpTpTransferInfo
END
GO