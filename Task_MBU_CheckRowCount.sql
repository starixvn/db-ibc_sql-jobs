/*<info serverAlias="DBTP-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_MBU_CheckRowCount]
AS
/*
	Created: 20180925@Patrick
	Task: Check consistency data for archiving process
		
	Revisions:
		- 20180926@Patrick:	Initial - [RedmineId: #101207]
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #__archiveDate (rid INT PRIMARY KEY IDENTITY(1,1), winlostdate SMALLDATETIME)

	INSERT INTO #__archiveDate(winlostdate)
	SELECT TOP (10) winlostdate
	FROM DBTrans.bodb02.dbo.Task_ArchiveDate WITH(NOLOCK)
	ORDER BY 1

	CREATE TABLE #__activeResult (winlostdate SMALLDATETIME, tableName VARCHAR(128), activeRowCount INT)
	CREATE TABLE #__archiveResult (winlostdate SMALLDATETIME, tableName VARCHAR(128), archiveRowCount INT)

	DECLARE @rowIndex INT, @winlostdate SMALLDATETIME, @xmlData XML, @hasDiff BIT
	SET @rowIndex = 1
	WHILE EXISTS (SELECT TOP 1 1 FROM #__archiveDate WHERE rid = @rowIndex)
	BEGIN
		SELECT @winlostdate = winlostdate
		FROM #__archiveDate t
		WHERE rid = @rowIndex

		SET @rowIndex += 1
		IF @winlostdate IS NULL
			CONTINUE

		--Event in active
		SET @xmlData = NULL
		EXEC DB02.bodb02.dbo.Task_MBU_Event_BK_CheckRowCount_Sel
			@DateCheck = @winlostdate,
			@OutputData = @xmlData OUTPUT
		
		IF @xmlData IS NOT NULL
		BEGIN
			INSERT #__activeResult(winlostdate, tableName, activeRowCount)
			SELECT @winlostdate, r.value('./@t','varchar(128)'), r.value('./@r','int')
			FROM @xmlData.nodes('//root/r') AS RECORDS(r)
			OPTION (OPTIMIZE FOR (@xmlData = NULL ))
		END

		--Bet in active
		SET @xmlData = NULL
		EXEC DBTRANS.bodb02.dbo.Task_MBU_Bet_CheckRowCount_Sel
			@DateCheck = @winlostdate,
			@OutputData = @xmlData OUTPUT

		IF @xmlData IS NOT NULL
		BEGIN
			INSERT #__activeResult(winlostdate, tableName, activeRowCount)
			SELECT @winlostdate, r.value('./@t','varchar(128)'), r.value('./@r','int')
			FROM @xmlData.nodes('//root/r') AS RECORDS(r)
			OPTION (OPTIMIZE FOR (@xmlData = NULL ))
		END
		
		--//event in archive
		SET @xmlData = NULL
		EXEC DBARC.bodb_Archive.dbo.Task_MBU_Event_BK_CheckRowCount_Sel
			@DateCheck = @winlostdate,
			@OutputData = @xmlData OUTPUT
		
		IF @xmlData IS NOT NULL
		BEGIN
			INSERT #__archiveResult(winlostdate, tableName, archiveRowCount)
			SELECT @winlostdate, r.value('./@t','varchar(128)'), r.value('./@r','int')
			FROM @xmlData.nodes('//root/r') AS RECORDS(r)
			OPTION (OPTIMIZE FOR (@xmlData = NULL ))
		END

		--//Bet in archive
		SET @xmlData = NULL
		EXEC DBARC.bodb_Archive.dbo.Task_MBU_Bet_BK_CheckRowCount_Sel
			@DateCheck = @winlostdate,
			@OutputData = @xmlData OUTPUT
		
		IF @xmlData IS NOT NULL
		BEGIN
			INSERT #__archiveResult(winlostdate, tableName, archiveRowCount)
			SELECT @winlostdate, r.value('./@t','varchar(128)'), r.value('./@r','int')
			FROM @xmlData.nodes('//root/r') AS RECORDS(r)
			OPTION (OPTIMIZE FOR (@xmlData = NULL ))
		END
	END
	
	IF EXISTS (
		SELECT TOP 1 1
		FROM #__activeResult t
			FULL OUTER JOIN #__archiveResult tt ON t.winlostdate = tt.winlostdate AND t.tableName = tt.tableName
		WHERE ISNULL(t.activeRowCount, 0) <> ISNULL(tt.archiveRowCount, 0)
	)
	BEGIN
		SET @hasDiff = 1
	END

	 --build string to send email
    DECLARE @email_body NVARCHAR(MAX), @subject NVARCHAR(200)
    SET @email_body = '
	   <html>
		 <body>
		  <h1>Archiving Process Row Count Check!</h1>
		  <p><b>Check time:</b> ' + CONVERT(VARCHAR(50), GETDATE(), 121) + ' </p> ' +
		  CASE WHEN @hasDiff = 1 THEN '<div style="background-color:red;color:white;text-align:center">Failure</div> <p><b> Error message:</b> ' + 'Some things mismatch data between active and archive. Please check!!!' + ''
		  ELSE '<div style="background-color:green;color:white;text-align:center">Success</div>' END + '
		  <p></p>
		  {<table1>}
		</body>
		</html>'

	--send out the mail to notify
	DECLARE @table1 VARCHAR(MAX), @rowData VARCHAR(MAX)
	SET @table1 = '
		<table>
			<tr>
			<th style="text-align:center">WinlostDate</th>
			<th style="text-align:center">Table Name</th>
			<th style="text-align:center">Active Row Count</th>
			<th style="text-align:center">Archive Row Count</th>
			<th style="text-align:center">Diff</th>
			</tr>
			{<row>}
		</table>'

	SET @rowData = CONVERT(VARCHAR(MAX), (
		SELECT ISNULL(t.winlostdate, tt.winlostdate) AS 'td1'
			, ISNULL(t.tableName, tt.tableName) AS 'td2'
			, ISNULL(t.activeRowCount, 0) AS 'td1'
			, ISNULL(tt.archiveRowCount, 0) AS 'td2'
			, ISNULL(tt.archiveRowCount, 0) - ISNULL(tt.archiveRowCount, 0) AS 'td1'
		FROM #__activeResult t
		FULL OUTER JOIN #__archiveResult tt ON t.winlostdate = tt.winlostdate AND t.tableName = tt.tableName
		ORDER BY ISNULL(t.winlostdate, tt.winlostdate), ISNULL(t.tableName, tt.tableName)
		FOR XML PATH('tr'), TYPE
	))    
	
	SET @rowData = REPLACE(REPLACE(@rowData, 'td1>', 'td>'), 'td2>', 'td>')
	SET @table1 = REPLACE(@table1, '{<row>}', @rowData)
	SET @email_body = REPLACE(@email_body, '{<table1>}', @table1)

    SELECT @subject	= N'Archving process check - KBT@' + @@SERVERNAME
					
    EXECUTE msdb.dbo.sp_send_dbmail @profile_name	= DEFAULT
	   , @recipients			 = 'patrick.pham@starixsoft.com'
	   , @copy_recipients		 = ''
	   , @blind_copy_recipients	 = ''
	   , @subject				 = @subject
	   , @body					 = @email_body
	   , @body_format			 = 'HTML';

END
GO
