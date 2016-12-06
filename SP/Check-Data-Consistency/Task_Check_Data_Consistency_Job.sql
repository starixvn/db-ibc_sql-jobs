USE [bodb02]
GO
ALTER PROCEDURE [dbo].[Task_Check_Data_Consistency_Job] @Recipients VARCHAR(1024)
	, @Copy_recipients VARCHAR(1024) = ''
	, @Mode VARCHAR(20) = ''
AS
/*
	Created: 20160622@Patrick
	Task: Check data consistency
	DB: DBTP/bodb02
	Revision:
		
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @ErrMessage VARCHAR(MAX), @ErrorTmp VARCHAR(512), @CurrentDate DATETIME, @Retry INT
	DECLARE @ErrorsTmp TABLE (ProductId INT, ProductName VARCHAR(100), FromDate SMALLDATETIME, ToDate SMALLDATETIME, ErrMessage VARCHAR(512))

	SELECT @ErrMessage = '', @ErrorTmp = '', @CurrentDate = GETDATE(), @Retry = 0
	
	--step #1: check winlostdate concistency by match
	SET @ErrorTmp = ''
	IF DATEPART(HOUR, GETDATE()) % 2 = 0 OR @Mode = 'UAT'
	BEGIN
		EXEC dbo.Task_CheckWinlostdate_Consistency @ErrMessage = @ErrorTmp OUTPUT
		IF ISNULL(@ErrorTmp, '') <> ''
		BEGIN
			INSERT INTO @ErrorsTmp(ProductId, ProductName, FromDate, ToDate, ErrMessage)
			VALUES(0, 'All', CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE), @ErrorTmp)
		END
	END
	
	--step #2: verify settled ticket
	SET @ErrorTmp = ''
	IF DATEPART(HOUR, @CurrentDate) = 7 OR DATEPART(HOUR, GETDATE()) = 7 OR @Mode = 'UAT' --run at 7AM
	BEGIN
		EXEC dbo.Task_DailysettledTicket_Verify @mode = 1, @ErrMessage = @ErrorTmp OUTPUT
		IF ISNULL(@ErrorTmp, '') <> ''
		BEGIN
			INSERT INTO @ErrorsTmp(ProductId, ProductName, FromDate, ToDate, ErrMessage)
			VALUES(0, 'All', CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE), @ErrorTmp)
		END
	END

	WHILE @Retry < 3
	BEGIN
		--step #3: check data consistency between bettrans and bettransRnG
		IF DATEPART(HOUR, GETDATE()) = 2 OR DATEPART(HOUR, @CurrentDate) = 2 OR @Mode = 'UAT' --run at 2AM
		BEGIN
	
			DECLARE @Fromdate SMALLDATETIME, @Todate SMALLDATETIME
			SELECT @Todate = DATEADD(DD, -1, CAST(GETDATE() AS DATE)) --yesterday
			SELECT @Fromdate = DATEADD(DAY, -2, @Todate) --three days ago
	
			--For Microgaming RNG Casino
			SET @ErrorTmp = ''
			EXEC dbo.Task_MicroGamingRNG_DataConsistency_Check @FDate = @FromDate
				, @TDate = @ToDate
				, @ErrMessage = @ErrorTmp OUTPUT
		
			IF ISNULL(@ErrorTmp, '') <> ''
			BEGIN
				INSERT INTO @ErrorsTmp(ProductId, ProductName, FromDate, ToDate, ErrMessage)
				VALUES(205, 'Microgaming RNG Casino', @Fromdate, @Todate, @ErrorTmp)
			END
	
			--For Macau Games
			SET @ErrorTmp = ''
			EXEC dbo.Task_RNG_DataConsistency_Check @FromDate = @FromDate
				, @ToDate = @ToDate
				, @ProductId = 212

				, @ErrMessage = @ErrorTmp OUTPUT
	
			IF ISNULL(@ErrorTmp, '') <> ''
			BEGIN
				INSERT INTO @ErrorsTmp(ProductId, ProductName, FromDate, ToDate, ErrMessage)
				VALUES(212, 'Macau Games', @Fromdate, @Todate, @ErrorTmp)
			END

			--For Microgaming Live Casino
			SET @ErrorTmp = ''
			EXEC dbo.Task_MicroGamingLC_DataConsistency_Check @FDate = @Fromdate
				, @TDate = @Todate
				, @ErrMessage =  @ErrorTmp OUTPUT

			IF ISNULL(@ErrorTmp, '') <> ''
			BEGIN
				INSERT INTO @ErrorsTmp(ProductId, ProductName, FromDate, ToDate, ErrMessage)
				VALUES(203, 'Microgaming Live Casino', @Fromdate, @Todate, @ErrorTmp)
			END
		END

		IF NOT EXISTS (SELECT TOP 1 1 FROM @ErrorsTmp) OR @Retry = 2
			BREAK

		SET @Retry = @Retry + 1
		WAITFOR DELAY '00:02:00:000' --retry after 2 minutes

		DELETE FROM @ErrorsTmp WHERE ProductId <> 0
	END

	--add more check data at here...

	--if any error then send mail
	IF EXISTS (SELECT TOP 1 1 FROM @ErrorsTmp)
	BEGIN
		
		DECLARE @job_name VARCHAR(125), @subject VARCHAR(125)
		SET @job_name = 'bodb02: Check consistency of data'
		SELECT @subject = 'SQL Server Job System: ''' + @job_name + ''' completed on \\' + @@servername

		SELECT @ErrMessage = N'<H3>Failed to check consistency of tickets'-- from ['+ CAST(@FromDate AS VARCHAR) +'] to ['+ CAST(@ToDate AS VARCHAR) +']</H3>'
							 + N'<table border="1">'
							 + N'<tr><th>Product Name</th><th>From Date</th><th>To Date</th><th>Error Message</th></tr>'
							 + CAST(( SELECT --td = ProductId, '',
											 td = ProductName, '',
											 td = CONVERT(VARCHAR(20), FromDate, 110), '',
											 td = CONVERT(VARCHAR(20), ToDate, 110), '',
											 td = ErrMessage, ''
									FROM @ErrorsTmp
									FOR XML PATH('tr'), TYPE 
								) AS NVARCHAR(MAX) ) + N'</table>'

		--IF @Mode = 'UAT'--for testing purpose
		--BEGIN
		--	SELECT @Recipients = 'patrick.pham@starixsoft.com', @Copy_recipients = CASE WHEN ISNULL(@Copy_recipients, '') <> '' THEN 'francis.le@starixsoft.com' 
		--																			ELSE @Copy_recipients END
		--END

		EXEC msdb.dbo.sp_send_dbmail @recipients = @Recipients
			, @subject = @subject
			, @body = @ErrMessage
			, @body_format = 'HTML'
			, @copy_recipients = @Copy_recipients

		RAISERROR (@ErrMessage, 16, 1)
	END
END