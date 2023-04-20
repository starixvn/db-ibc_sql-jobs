/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
USE bodb_N88
GO
ALTER PROCEDURE [dbo].[Task_API_Queue_WithdrawalInfo]
	@QueueIDInput	BIGINT = 0
	,@IsRePull		BIT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20200818@Percy
	DB: DBN88-bodb_N88
	Task: Insert data of WithdrawalInfo table

	Revisions:
		- 20200818@Percy: Initialize SP [RedmineID: #137395]
		- 20211018@Percy: Keep API's data within 7 days [RedmineID: #163336]
		- 20230418@Evan: Enhance DB job which sync [RedmineID: #183319]

	Param's Explanation:
		@QueueIDInput: manually import
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @DataSource VARCHAR(200) = 'WithdrawalInfo';

	IF @IsRePull = 1
	BEGIN
		SET @DataSource = 'CorrectWithdrawalInfo'
	END

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND DataSource = @DataSource)
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

	CREATE TABLE #tmpWithdrawalInfo
	(
		WithdrawalId	INT
		,TransId		VARCHAR(30)
		,WithdrawalType	TINYINT
		,CustId			INT
		,UserName		VARCHAR(30)
		,CurrencyId		TINYINT
		,SiteId			INT
		,WithdrawalInfo	NVARCHAR(MAX)
		,Amount			DECIMAL(18,4)
		,RefId			VARCHAR(100)
		,ChargeFee		DECIMAL(18,2)
		,CreateTime		DATETIME
		,Memo			VARCHAR(200)
		,Comment		VARCHAR(500)
		,Status			TINYINT
		,Flag			INT
		,Operator		VARCHAR(30)
		,UpdateTime		DATETIME
		,DataType		TINYINT -- 0: update, 1: insert
		,PRIMARY KEY (WithdrawalId)
	)

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT 1 FROM dbo.API_Queue WITH (NOLOCK) WHERE IsFinished = 0 AND DataSource = @DataSource)
	)
	BEGIN
		-- Get XML Data
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND DataSource = @DataSource
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM dbo.API_Queue WITH (NOLOCK)
			WHERE IsFinished = 0 AND DataSource = @DataSource
			ORDER BY QueueID ASC

		-- Parse XML Data, if failed --> try 3 times
		SET @numOftry = 0
		WHILE (1 = 1)
		BEGIN
			-- Reset temp data
			TRUNCATE TABLE #tmpWithdrawalInfo

			BEGIN TRY
				-- Parse XML Data
				INSERT INTO #tmpWithdrawalInfo
				(
					WithdrawalId
					,TransId
					,WithdrawalType
					,CustId
					,UserName
					,CurrencyId
					,SiteId
					,WithdrawalInfo
					,Amount
					,RefId
					,ChargeFee
					,CreateTime
					,Memo
					,Comment
					,Status
					,Flag
					,Operator
					,UpdateTime
				)
				SELECT
					t.c.value('@withdrawalid', 'INT')
					,t.c.value('@transid', 'VARCHAR(30)')
					,t.c.value('@withdrawaltype', 'TINYINT')
					,t.c.value('@custid', 'INT')
					,t.c.value('@username', 'VARCHAR(35)')
					,t.c.value('@currencyid', 'TINYINT')
					,t.c.value('@siteid', 'INT')
					,t.c.value('@withdrawalinfo', 'NVARCHAR(MAX)')
					,t.c.value('@amount', 'DECIMAL(18,2)')
					,t.c.value('@refid', 'VARCHAR(100)')
					,t.c.value('@chargefee', 'DECIMAL(18,2)')
					,NULLIF(t.c.value('@createtime', 'DATETIME'), '')
					,t.c.value('@memo', 'VARCHAR(200)')
					,t.c.value('@comment', 'VARCHAR(500)')
					,t.c.value('@status', 'TINYINT')
					,t.c.value('@flag', 'INT')
					,t.c.value('@operator', 'VARCHAR(30)')
					,NULLIF(t.c.value('@updatetime', 'DATETIME'), '')
				FROM @XmlData.nodes('root/row') t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				-- Update DataType
				UPDATE t
				SET t.DataType = CASE
									WHEN b.WithdrawalId IS NULL THEN 1 -- insert
									ELSE 0 END -- update
				FROM #tmpWithdrawalInfo t
					LEFT JOIN dbo.WithdrawalInfo b WITH (NOLOCK) ON t.WithdrawalId = b.WithdrawalId
				WHERE b.WithdrawalId IS NULL
					OR ISNULL(t.WithdrawalId, 0) <> ISNULL(b.WithdrawalId, 0)
					OR ISNULL(t.TransId, '') <> ISNULL(b.TransId, '')
					OR ISNULL(t.WithdrawalType, 0) <> ISNULL(b.WithdrawalType, 0)
					OR ISNULL(t.CustId, 0) <> ISNULL(b.CustId, 0)
					OR ISNULL(t.UserName, '') <> ISNULL(b.UserName, '')
					OR ISNULL(t.CurrencyId, 0) <> ISNULL(b.CurrencyId, 0)
					OR ISNULL(t.SiteId, 0) <> ISNULL(b.SiteId, 0)
					OR ISNULL(t.WithdrawalInfo, '') <> ISNULL(b.WithdrawalInfo, '')
					OR ISNULL(t.Amount, 0) <> ISNULL(b.Amount, 0)
					OR ISNULL(t.RefId, '') <> ISNULL(b.RefId, '')
					OR ISNULL(t.ChargeFee, 0) <> ISNULL(b.ChargeFee, 0)
					OR ISNULL(t.CreateTime, '') <> ISNULL(b.CreateTime, '')
					OR ISNULL(t.Memo, '') <> ISNULL(b.Memo, '')
					OR ISNULL(t.Comment, '') <> ISNULL(b.Comment, '')
					OR ISNULL(t.Status, 0) <> ISNULL(b.Status, 0)
					OR ISNULL(t.Flag, 0) <> ISNULL(b.Flag, 0)
					OR ISNULL(t.Operator, '') <> ISNULL(b.Operator, '')
					OR ISNULL(t.UpdateTime, '') <> ISNULL(b.UpdateTime, '')
				
				IF @@ROWCOUNT <> 0
				BEGIN
					-- update
					IF EXISTS (SELECT 1 FROM #tmpWithdrawalInfo WHERE DataType = 0)
					BEGIN
						UPDATE b WITH (ROWLOCK)
						SET b.TransId = t.TransId
							,b.WithdrawalType = t.WithdrawalType
							,b.CustId = t.CustId
							,b.UserName = t.UserName
							,b.CurrencyId = t.CurrencyId
							,b.SiteId = t.SiteId
							,b.WithdrawalInfo = t.WithdrawalInfo
							,b.Amount = t.Amount
							,b.RefId = t.RefId
							,b.ChargeFee = t.ChargeFee
							,b.CreateTime = t.CreateTime
							,b.Memo = t.Memo
							,b.Comment = t.Comment
							,b.Status = t.Status
							,b.Flag = t.Flag
							,b.Operator = t.Operator
							,b.UpdateTime = t.UpdateTime
						FROM dbo.WithdrawalInfo b
							INNER JOIN #tmpWithdrawalInfo t ON b.WithdrawalId = t.WithdrawalId
						WHERE t.DataType = 0
					END

					-- insert
					IF EXISTS (SELECT 1 FROM #tmpWithdrawalInfo WHERE DataType = 1)
					BEGIN
						INSERT INTO dbo.WithdrawalInfo
						(
							WithdrawalId
							,TransId
							,WithdrawalType
							,CustId
							,UserName
							,CurrencyId
							,SiteId
							,WithdrawalInfo
							,Amount
							,RefId
							,ChargeFee
							,CreateTime
							,Memo
							,Comment
							,Status
							,Flag
							,Operator
							,UpdateTime
						)
						SELECT
							WithdrawalId
							,TransId
							,WithdrawalType
							,CustId
							,UserName
							,CurrencyId
							,SiteId
							,WithdrawalInfo
							,Amount
							,RefId
							,ChargeFee
							,CreateTime
							,Memo
							,Comment
							,Status
							,Flag
							,Operator
							,UpdateTime
						FROM #tmpWithdrawalInfo
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

	IF @IsRePull = 0
	BEGIN
		-- Remove old data
		DELETE dbo.API_Queue WITH (ROWLOCK, UPDLOCK)
		WHERE DataSource = @DataSource
			AND IsFinished = 1
			AND FinishedTime < DATEADD(DAY, -7, GETDATE())
	END

	DROP TABLE #tmpWithdrawalInfo
END
GO