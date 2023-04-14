/*<info serverAlias="DBTP-bodb02" executers="" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Check_Data_Consistency_Job] 
	  @Recipients VARCHAR(1024)
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
		- 20180516@Paul: Add code for PP [Redmine:#95284]
		- 20180518@Kathy: Add code for Bullfighting [Redmine:#95199]
		- 20201022@Patrick: Change email to starixvn [Redmine: #143607]
		- 20220221@July: Add code for Spadegaming [Redmine: #168750]
		- 20230425@July: Remove unnecessary rules [Redmine: #186736]

*/
BEGIN
	SET NOCOUNT ON
	DECLARE @ErrMessage VARCHAR(MAX), @ErrorTmp VARCHAR(512), @CurrentDate DATETIME, @HasError BIT
	DECLARE @ErrorsTmp TABLE (ProductId INT, ProductName VARCHAR(100), FromDate SMALLDATETIME, ToDate SMALLDATETIME, ErrMessage VARCHAR(512))

	SELECT @ErrMessage = '', @ErrorTmp = '', @CurrentDate = GETDATE(), @HasError = 0
	
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

	--if any error then send mail
	IF EXISTS (SELECT TOP 1 1 FROM @ErrorsTmp)
	BEGIN
		DECLARE @job_name VARCHAR(125), @subject VARCHAR(125)
		SET @job_name = 'bodb02: Check consistency of data'
		SELECT @subject = 'SQL Server Job System: ''' + @job_name + ''' completed on \\' + @@servername
		SELECT @ErrMessage = N'<H3>Status of check the ticket consistency'
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


