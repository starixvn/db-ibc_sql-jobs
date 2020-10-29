/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROC dbo.Task_ClearBalance_EmailNotify
AS
/*
	Created:
	DB: DBCUST/CustDB
	Task: Send email after automating transfer
	
	Revisions: 
	- 20201028@Malcolm: Send email after automating transfer [RedmineId : #143217]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @isTest BIT = 0, @Subject VARCHAR(1000), @Recipients VARCHAR(MAX),  @Msg NVARCHAR(MAX), @style NVARCHAR(300) = '', @Length int = 0

	CREATE TABLE #Tmp (Username VARCHAR(30), Status varchar(20))

	INSERT INTO #Tmp (Username, Status)
	SELECT c.username, cbl.status
	FROM dbo.Acc_ClearBalanceList cbl WITH(NOLOCK)
		INNER JOIN dbo.Customer c WITH(NOLOCK) ON c.custid = cbl.custid
	WHERE (status = 'failed' AND msg LIKE 'Transfer is under maintenance  from%') 
		OR status IN ('running', 'waiting')

	IF NOT EXISTS(SELECT 1 FROM #Tmp)
	BEGIN
		RETURN
	END

	SELECT @Length = MAX(LEN(Username))
	FROM #Tmp

	SELECT @style = 'border:1px solid black;border-collapse:collapse;'

	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)

	IF @isTest = 0 AND @@SERVERNAME = 'DBCUST'
	BEGIN
		SELECT @Recipients = 'dbaadmin@starixvn.com'
	END
	ELSE
	BEGIN
		SELECT @Recipients = 'dba_local@starixvn.com'
	END

	SELECT @Subject = '[Automate Transfer All] - Incomletely transferred SMA on ' + CONVERT(VARCHAR(10), GETDATE(), 101)

	SELECT @Msg = N'Dear all, </br>
				    The Automate Transfer All job reports the following incomletely transferred SMA on ' + CONVERT(VARCHAR(10), GETDATE(), 101) + '</br>' 					
					+ '<table style = "'+ @style +'">'
				    + '<tr><td style = "'+ @style +' text-align:center;min-width:'+ CONVERT (VARCHAR(20), @Length * 8)+'px" bgcolor= #C5D9F1>Username</td>
							<td style = "'+ @style +' text-align:center;min-width:80px" bgcolor= #C5D9F1>Status</td>
					   </tr>'
					+  ISNULL(CAST((SELECT @style		AS 'td/@style',
										   t.Username	AS td, '', 
										   @style		AS 'td/@style' ,
										   t.Status		AS td, '' 
								    FROM #Tmp t 
									ORDER BY t.Username 
									FOR XML PATH('tr')
								) AS NVARCHAR(MAX)),'')	
					+ '</table>' 
					+ 'Please check and carry out timely actions accordingly.</br>' 
					+ 'Thank you.</br>' 
					+ 'This is an auto-mail. Please do not reply.'

	EXEC msdb.dbo.sp_send_dbmail
			@recipients		= @recipients,
			@subject		= @subject,
			@body			= @Msg,
			@body_format	= 'HTML'

	DROP TABLE #Tmp
END