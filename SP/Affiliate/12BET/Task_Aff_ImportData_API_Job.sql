/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_ImportData_API_Job]
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Import Data Job - API Products

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102322]
		- 20181020@Percy: Add list of products in APIProduct_ImportQueue [RedmineID: #102]
		- 20190117@Percy: Using core table for 3rd Products [RedmineID: #106503]
		- 20190322@Percy: Missing break loop [RedmineID: #110638]
		- 20190808@Percy: Add Exchange [RedmineID: #106504]
		- 20201012@Malcolm :  Change email Starixsoft.com to starixvn.com [RedmineId : #143312]
		- 20220704@Sol : remove email account - [RedmineId: #175043]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MaxCommDate SMALLDATETIME
	SELECT  @MaxCommDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'AFF_CommissionDate'

	DECLARE @tblWinlostDate TABLE (WinlostDate SMALLDATETIME, MaxQueueId BIGINT)

	DECLARE @OldLastQueueId BIGINT, @NewLastQueueId BIGINT, @WinlostDate SMALLDATETIME,
			@LaunchDate SMALLDATETIME, @FromImportDate SMALLDATETIME

	DECLARE @ErrTable TABLE (ProductId INT, WinlostDate SMALLDATETIME, ErrMsg NVARCHAR(4000))

	DECLARE @3rdProducts TABLE (Id INT IDENTITY(1,1), ProductId INT, LaunchDate SMALLDATETIME)
	DECLARE @Products TABLE (Id INT IDENTITY(1,1), ProductId INT, LaunchDate SMALLDATETIME)
	DECLARE @Id INT = 1, @ProductId INT = NULL

	-- 3rd Products: Product3rd_ImportQueue
	BEGIN
		DECLARE @3rdProductId INT
		
		SELECT @Id = 1, @ProductId = NULL
		
		INSERT INTO @3rdProducts (ProductId)
		SELECT ProductId FROM dbo.APIProductSettings WITH (NOLOCK)
		WHERE SettingName = 'SourceTable' AND SettingValue = '3rdProducts'

		UPDATE p
		SET p.LaunchDate = CONVERT(SMALLDATETIME, aps.SettingValue)
		FROM @3rdProducts p
			INNER JOIN dbo.APIProductSettings aps WITH (NOLOCK) ON p.ProductId = aps.ProductId AND aps.SettingName = 'LaunchDate'

		SELECT @ProductId = ProductId, @LaunchDate = LaunchDate FROM @3rdProducts WHERE Id = @Id

		WHILE @ProductId IS NOT NULL
		BEGIN
			-- Reset data
			SELECT @OldLastQueueId = NULL, @NewLastQueueId = NULL, @WinlostDate = NULL, @LaunchDate = NULL, @FromImportDate = NULL, @3rdProductId = NULL
			
			DELETE @tblWinlostDate

			SELECT @3rdProductId = CONVERT(INT, SettingValue) FROM dbo.APIProductSettings WITH (NOLOCK)
			WHERE ProductId = @ProductId AND SettingName = '3rdProductId'

			SELECT @OldLastQueueId = CONVERT(BIGINT, SettingValue) FROM dbo.APIProductSettings WITH (NOLOCK)
			WHERE ProductId = @ProductId AND SettingName = 'LastQueueId'

			SELECT @LaunchDate = CONVERT(SMALLDATETIME, SettingValue) FROM dbo.APIProductSettings WITH (NOLOCK)
			WHERE ProductId = @ProductId AND SettingName = 'LaunchDate'

			SELECT @FromImportDate = CASE WHEN @LaunchDate > @MaxCommDate THEN @LaunchDate ELSE DATEADD(DAY, 1, @MaxCommDate) END

			IF @3rdProductId = 31 -- Exchange
			BEGIN
				;WITH CTE_WinlostDate AS
				(
					SELECT @FromImportDate AS WinlostDate
					UNION ALL
					SELECT DATEADD(DAY, 1, WinlostDate)
					FROM CTE_WinlostDate
					WHERE WinlostDate < DATEADD(DAY, -1, GETDATE())
				)
				,CTE_QueueId AS
				(
					SELECT MAX(QueueId) AS QueueId FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (NOLOCK)
					WHERE ProductId = 31 AND FinishedTime IS NOT NULL
				)
				INSERT INTO @tblWinlostDate (WinlostDate, MaxQueueId)
				SELECT WinlostDate, QueueId
				FROM CTE_WinlostDate wld
					CROSS JOIN CTE_QueueId q
				OPTION (MAXRECURSION 0)
			END
			ELSE
			BEGIN
				INSERT INTO @tblWinlostDate (WinlostDate, MaxQueueId)
				SELECT WinlostDate, MAX(QueueId) FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (NOLOCK)
				WHERE ProductId = @3rdProductId AND QueueId > @OldLastQueueId AND WinlostDate >= @FromImportDate
				GROUP BY WinlostDate
			END

			SELECT @NewLastQueueId = MAX(MaxQueueId) FROM @tblWinlostDate
			SELECT @NewLastQueueId = ISNULL(@NewLastQueueId, @OldLastQueueId)

			SELECT TOP 1 @WinlostDate = WinlostDate FROM @tblWinlostDate ORDER BY WinlostDate

			WHILE @WinlostDate IS NOT NULL
			BEGIN
				BEGIN TRY
					EXEC dbo.Task_Aff_ImportData_3rdProduct @ProductId = @ProductId, @WinlostDate = @WinlostDate
				END TRY
				BEGIN CATCH
					INSERT INTO @ErrTable (ProductId, WinlostDate, ErrMsg)
					VALUES (@ProductId, @WinlostDate, ERROR_MESSAGE())
				END CATCH
			
				DELETE @tblWinlostDate WHERE WinlostDate = @WinlostDate
			
				SELECT @WinlostDate = NULL
				SELECT TOP 1 @WinlostDate = WinlostDate FROM @tblWinlostDate ORDER BY WinlostDate
			END

			UPDATE dbo.APIProductSettings WITH (ROWLOCK, UPDLOCK)
			SET SettingValue = CONVERT(VARCHAR(200), @NewLastQueueId)
			WHERE ProductId = @ProductId AND SettingName = 'LastQueueId'

			SELECT @Id = @Id + 1
			SELECT @ProductId = NULL, @LaunchDate = NULL
			SELECT @ProductId = ProductId, @LaunchDate = LaunchDate FROM @3rdProducts WHERE Id = @Id
		END
	END

	-- Products in APIProduct_ImportQueue
	BEGIN
		-- Reset data
		SELECT @OldLastQueueId = NULL, @NewLastQueueId = NULL, @WinlostDate = NULL, @LaunchDate = NULL, @FromImportDate = NULL
		SELECT @Id = 1, @ProductId = NULL

		DECLARE @today SMALLDATETIME
		SELECT  @today = CONVERT(DATE, GETDATE())
	
		INSERT INTO @Products (ProductId)
		SELECT ProductId FROM dbo.APIProductSettings WITH (NOLOCK)
		WHERE SettingName = 'SourceTable' AND SettingValue = 'APIProduct_ImportQueue'

		UPDATE p
		SET p.LaunchDate = CONVERT(SMALLDATETIME, aps.SettingValue)
		FROM @Products p
			INNER JOIN dbo.APIProductSettings aps WITH (NOLOCK) ON p.ProductId = aps.ProductId AND aps.SettingName = 'LaunchDate'
		
		SELECT @ProductId = ProductId, @LaunchDate = LaunchDate FROM @Products WHERE Id = @Id

		WHILE @ProductId IS NOT NULL
		BEGIN
			SELECT @WinlostDate = DATEADD(DAY, 1, @MaxCommDate)

			IF @WinlostDate < @LaunchDate
				SELECT @WinlostDate = @LaunchDate

			WHILE @WinlostDate <= @today
			BEGIN
				BEGIN TRY
					EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = @ProductId, @WinlostDate = @WinlostDate
				END TRY
				BEGIN CATCH
					INSERT INTO @ErrTable (ProductId, WinlostDate, ErrMsg)
					VALUES (@ProductId, @WinlostDate, ERROR_MESSAGE())
				END CATCH

				SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
			END
		
			SELECT @Id = @Id + 1
			SELECT @ProductId = NULL, @LaunchDate = NULL
			SELECT @ProductId = ProductId, @LaunchDate = LaunchDate FROM @Products WHERE Id = @Id
		END
	END

	-- Send mail if have error
	DECLARE @Subject VARCHAR(1000) = '', @Msg NVARCHAR(MAX) = ''

	IF EXISTS (SELECT 1 FROM @ErrTable)
	BEGIN
		SELECT @Subject = 'SQL Server Job System: ''Import data from raw table (API)'' failed on ' + @@SERVERNAME

		SELECT @Msg = '<H3>List of products have wrong data</H3>'
						+ '<table border="1"> '
						+ '<tr><th>No.</th><th>Product</th><th>WinlostDate</th></tr>'
						+ CAST((SELECT	td = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)), '',
										td = p.ProductName, '',
										td = CONVERT(VARCHAR(20), e.WinlostDate, 120), '',
										td = e.ErrMsg, ''
								FROM @ErrTable e
									INNER JOIN dbo.Products p WITH (NOLOCK) ON e.ProductId = p.ProductID
								FOR XML PATH('tr'), TYPE 
								) AS NVARCHAR(MAX)) + N'</table>'
			
		EXEC msdb.dbo.sp_send_dbmail
			@recipients		= 'sophia.nguyen@starixvn.com;pontus@starixvn.com',
			@subject		= @subject,
			@body			= @Msg,
			@body_format	= 'HTML'
	END
END
GO