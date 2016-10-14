use [bodb_Report]
GO
ALTER PROCEDURE [dbo].[TASK_DepSumData_Job_CheckStatus]
AS
	/*
		Created By: Francis
		Created Date: 20161010
		Task: Check Status for Deposit Summary Data Job	
		DB: DBRPT.bodb_Report
		Revisions:
		Input Params:	
	*/
BEGIN

	SET NOCOUNT ON
	
	DECLARE @CurrentDate DATE,
			@CurrentHour TINYINT,
			@Count SMALLINT = 0,
			@Date DATE,
			@Subject VARCHAR(500) = '',
			@isValid BIT = 0,
			@ErrMsg VARCHAR(500) = '',
			@ErrorMessage VARCHAR(8000)

	DECLARE @ErrMsgTab AS TABLE (NoID SMALLINT IDENTITY (1,1), JobType VARCHAR(50), ErrMsg VARCHAR(500))
			
	SELECT @CurrentDate = CONVERT(DATE,CURRENT_TIMESTAMP,112)
	SELECT @CurrentHour = DATEPART(HOUR,CURRENT_TIMESTAMP)
	SELECT @Date = MIN(Winlostdate)
	FROM dbo.rptDepWinlost_Main WITH (NOLOCK)

	WHILE (@Date <= @CurrentDate)
	BEGIN
		IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.rptDepWinlost_Main WITH (NOLOCK) WHERE Winlostdate = @Date)
		BEGIN
			SELECT @ErrMsg = 'Missing data on: ' + CONVERT(VARCHAR(20),@Date)
			INSERT INTO @ErrMsgTab (JobType, ErrMsg) SELECT 'Check the adequacy of summarized days', @ErrMsg
		END
		SELECT @Date = DATEADD(DAY,1,@Date)
	END

	--Check realtime job status
	SELECT @ErrMsg = ''
	SELECT @Count = ISNULL(COUNT(LogID),0)
	FROM dbo.rptDepWinlost_Log WITH (NOLOCK)
	WHERE StatusID = 0 AND LogDate = @CurrentDate AND LogHour = @CurrentHour AND LogType = 4
	HAVING COUNT(LogID) >= 10
	
	IF @Count > 0
	BEGIN
		SELECT @ErrMsg = 'Realtime job failed for ' + CONVERT(VARCHAR(20),@Count) + ' time(s) on: ' + CONVERT(VARCHAR(20),@CurrentHour) 
						+ CASE WHEN @CurrentHour < 12 THEN ' AM ' ELSE ' PM ' END + 'range, day: ' + CONVERT(VARCHAR(20),@CurrentDate) + CHAR(13) --Line break
		INSERT INTO @ErrMsgTab (Jobtype, ErrMsg) SELECT 'REALTIME', @ErrMsg
	END
						  
	--Check hourly job status
	SELECT @ErrMsg = ''
	SELECT @Count = ISNULL(COUNT(LogID),0)
	FROM dbo.rptDepWinlost_Log WITH (NOLOCK)
	WHERE StatusID = 0 AND LogDate = @CurrentDate AND LogHour = @CurrentHour AND LogType = 3
	HAVING COUNT(LogID) >= 4
	
	IF @Count > 0
	BEGIN
		SELECT @ErrMsg = 'Hourly job failed for ' + CONVERT(VARCHAR(20),@Count) + ' time(s) on: ' + CONVERT(VARCHAR(20),@CurrentHour) 
					  + CASE WHEN @CurrentHour < 12 THEN ' AM ' ELSE ' PM ' END + 'range, day: ' + CONVERT(VARCHAR(20),@CurrentDate) + CHAR(13) --Line break
		INSERT INTO @ErrMsgTab (Jobtype, ErrMsg) SELECT 'HOURLY', @ErrMsg
	END

	--Check daily job status
	SELECT @ErrMsg = ''
	SELECT @Count = ISNULL(COUNT(LogID),0)
	FROM dbo.rptDepWinlost_Log WITH (NOLOCK)
	WHERE StatusID = 0 AND LogDate = @CurrentDate AND LogType = 2
	HAVING COUNT(LogID) >= 3
	
	IF @Count > 0
	BEGIN
		SELECT @ErrMsg = 'Daily job failed for ' + CONVERT(VARCHAR(20),@Count) + ' time(s) on: ' + CONVERT(VARCHAR(20),@CurrentHour) 
						  + CASE WHEN @CurrentHour < 12 THEN ' AM ' ELSE ' PM ' END + 'range, day: ' + CONVERT(VARCHAR(20),@CurrentDate) + CHAR(13) --Line break
	
		INSERT INTO @ErrMsgTab (Jobtype, ErrMsg) SELECT 'DAILY', @ErrMsg
	END
		
	IF EXISTS (SELECT TOP 1 1 FROM @ErrMsgTab)
	BEGIN
		SELECT @Subject = 'SQL Server Job System:'' bodb02: Deposit Report Summary'' completed on \\' + @@SERVERNAME
		
		SELECT @ErrorMessage = '<H3>Deposit Data Summary Job was run on ['+ CONVERT(VARCHAR(20),@CurrentDate) + ']. Status: FAILED</H3>'
							 + '<table border="1"> '
							 + '<tr><th>No.</th><th>Job type</th><th>Error Message</th></tr>'
							  + CAST(( SELECT    td = NoID, '',
												 td = JobType, '',
												 td = ErrMsg, ''
										FROM @ErrMsgTab
										FOR XML PATH('tr'), TYPE 
									) AS NVARCHAR(MAX) ) + N'</table>'
		
		EXEC msdb.dbo.sp_send_dbmail @recipients='dbaadmin@starixsoft.com'
					, @subject = @subject
					, @body = @ErrorMessage
					, @body_format = 'HTML'
	END
END