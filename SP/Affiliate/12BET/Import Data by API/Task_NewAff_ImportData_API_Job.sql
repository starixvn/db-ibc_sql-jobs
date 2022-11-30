/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_NewAff_ImportData_API_Job]
AS

/*
	Created: 20221130@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Import Data Job - API Products

	Revisions:
		- 20221130@Malcolm: Initialize SP [RedmineID: #180311]

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
	DECLARE @Products TABLE (Id INT IDENTITY(1,1), ProductId INT, LaunchDate SMALLDATETIME)
	DECLARE @Id INT = 1, @ProductId INT = NULL

	BEGIN
		DECLARE @today SMALLDATETIME
		SELECT  @today = CONVERT(DATE, GETDATE())
	
		INSERT INTO @Products (ProductId)
		SELECT ProductId FROM dbo.APIProductMappingSettings WITH (NOLOCK)

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
					EXEC dbo.Task_NewAPIProduct_ImportQueue_Product @ProductId = @ProductId, @WinlostDate = @WinlostDate
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
		SELECT @Subject = 'SQL Server Job System: ''Import data from raw table (NewAPI)'' failed on ' + @@SERVERNAME

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