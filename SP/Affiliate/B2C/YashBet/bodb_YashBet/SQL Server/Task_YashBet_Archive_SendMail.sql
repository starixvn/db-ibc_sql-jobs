/*<info serverAlias="DBYASHBET-bodb_YashBet" isFunction="0" isNested=""></info>*/
USE bodb_YashBet
GO 

CREATE PROCEDURE [dbo].[Task_YashBet_Archive_SendMail]
AS

/*
	Created: 20240115@Sally
	DB: DBYASHBET-bodb_YashBet
	Task: Job - Archive data for TpBetRecord - Send mail

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON

	-- Remove old data
	DECLARE @tmpDate DATETIME = DATEADD(YEAR, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)) -- first day of current month last year
	DELETE dbo.JobLog WITH (ROWLOCK) WHERE WinlostDate < @tmpDate

	DECLARE @Log TABLE (LogId INT, DataSource VARCHAR(128), OldData VARCHAR(MAX), NewData VARCHAR(MAX), WinlostDate DATETIME)

	UPDATE dbo.JobLog WITH (ROWLOCK)
	SET IsSendMail = 1
		OUTPUT DELETED.LogId, DELETED.DataSource, DELETED.OldData, DELETED.NewData, DELETED.WinlostDate
		INTO @Log (LogId, DataSource, OldData, NewData, WinlostDate)
	WHERE IsSendMail = 0

	IF EXISTS (SELECT 1 FROM @Log)
	BEGIN
		DECLARE @Subject VARCHAR(1000), @Msg NVARCHAR(MAX)

		SELECT @Subject = 'SQL Server Job System: ''bodb_YashBet: Archive data'' found some updated tickets on ' + @@SERVERNAME

		SELECT @Msg = COALESCE(@Msg + ',', '') + CONVERT(VARCHAR(15), LogId) FROM @Log
		SELECT @Msg = '<H3>List of updated tickets</H3>'
						+ '<H4>SELECT * FROM bodb_YashBet.dbo.JobLog WITH (NOLOCK) WHERE LogId IN (' + @Msg + ')</H4>'
						+ '<table border="1"> '
						+ '<tr><th>LogId</th><th>DataSource</th><th>WinlostDate</th><th>OldData</th><th>NewData</th></tr>'
						+ CAST((SELECT	td = LogId, '',
										td = DataSource, '',
										td = ISNULL(CONVERT(VARCHAR(10), WinlostDate, 120), ''), '',
										td = ISNULL(OldData, ''), '',
										td = ISNULL(NewData, ''), ''
								FROM @Log
								FOR XML PATH('tr'), TYPE 
								) AS NVARCHAR(MAX))
						+ N'</table>'
			
		EXEC msdb.dbo.sp_send_dbmail
			@recipients		= 'sophia.nguyen@starixsoft.com;pontus@starixsoft.com',
			@subject		= @Subject,
			@body			= @Msg,
			@body_format	= 'HTML'
	END
END
GO