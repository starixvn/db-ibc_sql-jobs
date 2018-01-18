USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_Check_Data_Consistency_Job]    Script Date: 9/28/2017 11:57:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_Check_Data_Consistency_Job] @Recipients VARCHAR(1024)
	, @Copy_recipients VARCHAR(1024) = ''
	, @Mode VARCHAR(20) = ''
	, @IsDebug BIT = 0
AS
/*
	Created: 20160622@Patrick
	Task: Check data consistency
	DB: DBTP/bodb02
	Revision:
		- 20171011@Patrick: Move code check setting for FW
		
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @ErrMessage VARCHAR(MAX), @ErrorTmp VARCHAR(512), @CurrentDate DATETIME, @Retry INT, @HasError BIT
	DECLARE @ErrorsTmp TABLE (ProductId INT, ProductName VARCHAR(100), FromDate SMALLDATETIME, ToDate SMALLDATETIME, ErrMessage VARCHAR(512))

	SELECT @ErrMessage = '', @ErrorTmp = '', @CurrentDate = GETDATE(), @Retry = 0, @HasError = 0
	
	--step #1: check winlostdate concistency by match
	SET @ErrorTmp = ''
	IF DATEPART(HOUR, GETDATE()) % 2 = 0 OR @Mode = 'UAT'
	BEGIN
		EXEC dbo.Task_CheckWinlostdate_Consistency @ErrMessage = @ErrorTmp OUTPUT
		IF ISNULL(@ErrorTmp, '') <> ''
		BEGIN
			SET @HasError = 1
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
			SET @HasError = 1
		END
		--only this kind need to send email when completed
		INSERT INTO @ErrorsTmp(ProductId, ProductName, FromDate, ToDate, ErrMessage)
		VALUES(0, 'All', CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE), CASE WHEN ISNULL(@ErrorTmp, '') <> '' THEN @ErrorTmp ELSE 'Successful' END)
	END

	DECLARE @HasError1 BIT
	DECLARE @Fromdate SMALLDATETIME, @Todate SMALLDATETIME, @Today DATETIME, @CheckDate DATETIME
	SET @Today = GETDATE()
			
	IF CAST(@Today AS DATE) <> CAST(DATEADD(HOUR, -1, @Today) AS DATE)
		SELECT @Todate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE)) --yesterday
	ELSE
		SELECT @Todate = CAST(GETDATE() AS DATE) --today

	SET @Fromdate = (SELECT MAX(eventdate) FROM bodb02.dbo.match14 WITH(NOLOCK))--DATEADD(DAY, -2, @Todate) --three days ago
	IF @Fromdate IS NULL
		SET @Fromdate = DATEADD(DAY, -2, @Todate) --three days ago

	SELECT @CheckDate = @Fromdate, @Retry = 1

	WHILE @CheckDate <= @Todate
	BEGIN
		
		--For Microgaming RNG Casino
		OneMore_205:
		SET @ErrorTmp = ''
		EXEC dbo.Task_RNG_DataConsistency_Check @FromDate = @CheckDate
			, @ToDate = @CheckDate
			, @ProductId = 205

			, @ErrMessage = @ErrorTmp OUTPUT
		
		IF ISNULL(@ErrorTmp, '') <> ''
		BEGIN
			IF @Retry < 3
			BEGIN
				WAITFOR DELAY '00:02:00:000' --retry after 2 minutes
				SET @Retry = @Retry + 1
				GOTO OneMore_205
			END

			SET @HasError1 = 1
			INSERT INTO @ErrorsTmp(ProductId, ProductName, FromDate, ToDate, ErrMessage)
			VALUES(205, 'Microgaming RNG Casino', @CheckDate, @CheckDate, @ErrorTmp)	
		END
				
		--For Macau Games
		OneMore_212:
		SELECT @ErrorTmp = '', @Retry = 1
		EXEC dbo.Task_RNG_DataConsistency_Check @FromDate = @CheckDate
			, @ToDate = @CheckDate
			, @ProductId = 212

			, @ErrMessage = @ErrorTmp OUTPUT
	
		IF ISNULL(@ErrorTmp, '') <> ''
		BEGIN
			IF @Retry < 3
			BEGIN
				WAITFOR DELAY '00:02:00:000' --retry after 2 minutes
				SET @Retry = @Retry + 1
				GOTO OneMore_212
			END

			SET @HasError1 = 1
			INSERT INTO @ErrorsTmp(ProductId, ProductName, FromDate, ToDate, ErrMessage)
			VALUES(212, 'Macau Games', @CheckDate, @CheckDate, @ErrorTmp)	
		END

		--Fishing World
		OneMore_219:
		SELECT @ErrorTmp = '', @Retry = 1
		EXEC dbo.Task_RNG_DataConsistency_Check @FromDate = @CheckDate
			, @ToDate = @CheckDate
			, @ProductId = 219

			, @ErrMessage = @ErrorTmp OUTPUT
	
		IF ISNULL(@ErrorTmp, '') <> ''
		BEGIN
			IF @Retry < 3
			BEGIN
				WAITFOR DELAY '00:02:00:000' --retry after 2 minutes
				SET @Retry = @Retry + 1
				GOTO OneMore_219
			END

			SET @HasError1 = 1
			INSERT INTO @ErrorsTmp(ProductId, ProductName, FromDate, ToDate, ErrMessage)
			VALUES(219, 'Fishing World', @CheckDate, @CheckDate, @ErrorTmp)	
		END

		--RNG - RNG Game
		OneMore_208:
		SELECT @ErrorTmp = '', @Retry = 1
		EXEC dbo.Task_RNG_DataConsistency_Check @FromDate = @CheckDate
			, @ToDate = @CheckDate
			, @ProductId = 208

			, @ErrMessage = @ErrorTmp OUTPUT
	
		IF ISNULL(@ErrorTmp, '') <> ''
		BEGIN
			IF @Retry < 3
			BEGIN
				WAITFOR DELAY '00:02:00:000' --retry after 2 minutes
				SET @Retry = @Retry + 1
				GOTO OneMore_208
			END

			SET @HasError1 = 1
			INSERT INTO @ErrorsTmp(ProductId, ProductName, FromDate, ToDate, ErrMessage)
			VALUES(208, 'RNG - RNG Game', @CheckDate, @CheckDate, @ErrorTmp)	
		END

		--RNG - Mini Games
		OneMore_209:
		SELECT @ErrorTmp = '', @Retry = 1
		SET @ErrorTmp = ''
		EXEC dbo.Task_RNG_DataConsistency_Check @FromDate = @CheckDate
			, @ToDate = @CheckDate
			, @ProductId = 209

			, @ErrMessage = @ErrorTmp OUTPUT
	
		IF ISNULL(@ErrorTmp, '') <> ''
		BEGIN
			IF @Retry < 3
			BEGIN
				WAITFOR DELAY '00:02:00:000' --retry after 2 minutes
				SET @Retry = @Retry + 1
				GOTO OneMore_209
			END

			SET @HasError1 = 1
			INSERT INTO @ErrorsTmp(ProductId, ProductName, FromDate, ToDate, ErrMessage)
			VALUES(209, 'RNG - Mini Games', @CheckDate, @CheckDate, @ErrorTmp)	
		END

		--RNG - Mobile
		OneMore_210:
		SELECT @ErrorTmp = '', @Retry = 1
		SET @ErrorTmp = ''
		EXEC dbo.Task_RNG_DataConsistency_Check @FromDate = @CheckDate
			, @ToDate = @CheckDate
			, @ProductId = 210

			, @ErrMessage = @ErrorTmp OUTPUT
	
		IF ISNULL(@ErrorTmp, '') <> ''
		BEGIN
			IF @Retry < 3
			BEGIN
				WAITFOR DELAY '00:02:00:000' --retry after 2 minutes
				SET @Retry = @Retry + 1
				GOTO OneMore_210
			END

			SET @HasError1 = 1
			INSERT INTO @ErrorsTmp(ProductId, ProductName, FromDate, ToDate, ErrMessage)
			VALUES(210, 'RNG - Mobile', @Fromdate, @Todate, @ErrorTmp)	
		END

		--For Microgaming Live Casino
		OneMore_MGCLC:
		SELECT @ErrorTmp = '', @Retry = 1
		EXEC dbo.Task_MicroGamingLC_DataConsistency_Check @FDate = @CheckDate
			, @TDate = @CheckDate
			, @ErrMessage =  @ErrorTmp OUTPUT

		IF ISNULL(@ErrorTmp, '') <> ''
		BEGIN
			IF @Retry < 3
			BEGIN
				WAITFOR DELAY '00:02:00:000' --retry after 2 minutes
				SET @Retry = @Retry + 1
				GOTO OneMore_MGCLC
			END

			SET @HasError1 = 1
			INSERT INTO @ErrorsTmp(ProductId, ProductName, FromDate, ToDate, ErrMessage)
			VALUES(203, 'Microgaming Live Casino', @CheckDate, @CheckDate, @ErrorTmp)
		END
			
		--For Allbet
		OneMore_211:
		SELECT @ErrorTmp = '', @Retry = 1
		EXEC dbo.Task_LC_DataConsistency_Check @FromDate = @CheckDate
			, @ToDate = @CheckDate
			, @ProductId = 211

			, @ErrMessage = @ErrorTmp OUTPUT
	
		IF ISNULL(@ErrorTmp, '') <> ''
		BEGIN
			IF @Retry < 3 -- for case replication delay
			BEGIN
				WAITFOR DELAY '00:02:00:000' --retry after 2 minutes
				SET @Retry = @Retry + 1
				GOTO OneMore_211
			END

			SET @HasError1 = 1
			INSERT INTO @ErrorsTmp(ProductId, ProductName, FromDate, ToDate, ErrMessage)
			VALUES(211, 'Allbet', @CheckDate, @CheckDate, @ErrorTmp)
		END
		
		PRINT @CheckDate
		SET @CheckDate =  DATEADD(DAY, 1, @CheckDate)

		SET @HasError1 = 0
	END
	
	--check case have a ticket before lauching date
	--SET @ErrorTmp = ''
	--DECLARE @SettingDate DATETIME, @LaunchedDate DATETIME
	--SELECT @SettingDate = '2017-03-23', @LaunchedDate = '2017-03-30'
	--EXEC dbo.DBA_CheckingTicketAfterInitializingSetting	@SettingDate = @SettingDate	
	--	, @LaunchedDate = @LaunchedDate
	--	, @ProductID = 24 --Products.ProductId
	--	, @ListSite = '611111,722222,766666,789y,7aa666,XYZbet,Best-odds'
	--	, @ListCurrency = ''
	--	, @ErrorMsg = @ErrorTmp OUTPUT

	--IF ISNULL(@ErrorTmp, '') <> ''
	--BEGIN
	--	SET @HasError1 = 1
	--	INSERT INTO @ErrorsTmp(ProductId, ProductName, FromDate, ToDate, ErrMessage)
	--	VALUES(219, 'Fishing World', @SettingDate, @LaunchedDate, @ErrorTmp)
	--END
	
	IF @HasError <> @HasError1 AND @HasError1 = 1
	BEGIN
		SET @HasError = @HasError1
	END

	--add more check data at here...
		
	--if any error then send mail
	IF EXISTS (SELECT TOP 1 1 FROM @ErrorsTmp)
	BEGIN
		DECLARE @job_name VARCHAR(125), @subject VARCHAR(125)
		SET @job_name = 'bodb02: Check consistency of data'
		SELECT @subject = 'SQL Server Job System: ''' + @job_name + ''' completed on \\' + @@servername
		SELECT @ErrMessage = N'<H3>Status of check the ticket consistency'-- from ['+ CAST(@FromDate AS VARCHAR) +'] to ['+ CAST(@ToDate AS VARCHAR) +']</H3>'
							 + N'<table border="1">'
							 + N'<tr><th>Product Name</th><th>From Date</th><th>To Date</th><th>Message</th></tr>'
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
		IF @IsDebug = 0
		BEGIN
			EXEC msdb.dbo.sp_send_dbmail @recipients = @Recipients
				, @subject = @subject
				, @body = @ErrMessage
				, @body_format = 'HTML'
				, @copy_recipients = @Copy_recipients

			IF @HasError = 1
			BEGIN
				RAISERROR (@ErrMessage, 16, 1)
			END
		END
		ELSE
		BEGIN
			PRINT @ErrMessage
		END
	END
END

GO


