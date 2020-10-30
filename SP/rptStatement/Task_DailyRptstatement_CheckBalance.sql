/*<info serverAlias="DBRPT-bodb_Report" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DailyRptStatement_CheckBalance]
AS
/*  
	Created: 20200331@Bobby
	Task: ReCheck for closing/opening balance consistency
	DB: DBRPT.bodb_Report

	Revisions:
		- 20191111@Bobby: Initial [Redmine: #131490]
		- 20200619@Percy: Add server name in mail's subject [RedmineID: #134251]
		- 20201012@Malcolm :  Change email Starixsoft.com to starixvn.com [RedmineId : #143312]
*/
BEGIN

	SET NOCOUNT ON;
	DECLARE @cutoff_day DATE

	DECLARE @runningDays TABLE (
		winlostdate DATE
		,dayIdx INT identity(1, 1)
		);

	CREATE TABLE #custTemp (custid INT PRIMARY KEY);

	CREATE TABLE #custChanged (
		custid INT
		,closingdate DATE
		,openingdate DATE
		,closingbalance MONEY
		,openingbalance MONEY
		,is_updated BIT
		,CONSTRAINT PK_custchanged_custid_date PRIMARY KEY (
			custid
			,closingdate
			,openingdate
			)
		);

	CREATE TABLE #custOutput (
		custid INT
		,winlostdate DATE
		)

	SELECT @cutoff_day = MIN(winlostdate) --> it's BU day
	FROM bodb02.dbo.bettrans14 WITH(NOLOCK)

	INSERT INTO @runningDays (winlostdate)
	SELECT DISTINCT winlostdate
	FROM dbo.rptStatement WITH (NOLOCK)
	WHERE winlostdate >= @cutoff_day
	ORDER BY WinlostDate ASC

	DECLARE @dayIdx INT = 1
		,@winlostdate DATE

	WHILE EXISTS (
			SELECT 1
			FROM @runningDays
			WHERE dayIdx = @dayIdx
			)
	BEGIN
		DELETE #custTemp

		SELECT @winlostdate = winlostdate
		FROM @runningDays
		WHERE dayIdx = @dayIdx

		INSERT INTO #custTemp
		SELECT Custid
		FROM dbo.rptStatement WITH (NOLOCK)
		WHERE WinlostDate = @winlostdate

		INSERT INTO #custChanged (
			custid
			,closingdate
			,closingbalance
			,openingdate
			,openingbalance
			,is_updated
			)
		SELECT cl.Custid
			,cl.WinlostDate AS closingdate
			,cl.closingbalance
			,op.WinlostDate AS openingdate
			,op.OpeningBalance
			,0 AS is_updated
		FROM (
			SELECT cl.custid
				,isnull(closingbalance, 0) AS closingbalance
				,WinlostDate
			FROM dbo.rptStatement cl WITH (NOLOCK)
			INNER JOIN #custTemp ci ON ci.custid = cl.Custid
			WHERE cl.WinlostDate = @winlostdate
			) AS cl
		INNER JOIN (
			SELECT Custid
				,OpeningBalance
				,WinlostDate
			FROM (
				SELECT op.Custid
					,isnull(OpeningBalance, 0) AS OpeningBalance
					,WinlostDate
					,ROW_NUMBER() OVER (
						PARTITION BY op.custid ORDER BY op.winlostdate ASC
						) AS custIdx
				FROM dbo.rptStatement op WITH (NOLOCK)
				INNER JOIN #custTemp ci ON ci.custid = op.Custid
				WHERE op.WinlostDate > @winlostdate
				) AS op
			WHERE custIdx = 1
			) AS op ON op.Custid = cl.Custid
		WHERE op.OpeningBalance <> cl.ClosingBalance

		SET @dayIdx += 1;
	END

	IF EXISTS (SELECT 1 FROM #custChanged)
	BEGIN
		-- SEND email notification
		DECLARE	@subject	NVARCHAR(MAX)
		,	@bodymsg		NVARCHAR(MAX)

		SELECT	@subject	= N'Job - Daily RptStatement - Check Balance error(s) found ' + @@SERVERNAME;
		
		SELECT	@bodymsg	= N'\
								Dear All,</br>
								An error has been found while checking opening/closing balance data in the RptStatement.</br>
								Please take a look on the table below:</br> '
								+ '<table border="1"> '
								+ '<tr><th>Custid</th><th>ClosingDate</th><th>ClosingBalance</th><th>OpeningDate</th><th>OpeningBalance</th></tr>'
								+ CAST(( SELECT     td = CONVERT(VARCHAR(20), ISNULL(Custid, 0)), '',
													td = CONVERT(VARCHAR(20), ClosingDate, 120), '',
													td = CONVERT(VARCHAR(20), ISNULL(ClosingBalance, 0)), '',
													td = CONVERT(VARCHAR(20), OpeningDate, 120), '',
													td = CONVERT(VARCHAR(20), ISNULL(OpeningBalance, 0)), ''
										FROM #custChanged
										FOR XML PATH('tr'), TYPE 
									) AS NVARCHAR(MAX) ) + N'</table>'
								
								+ 'Best regards, </br> 
								This is an auto-mail from the Internal System. Please do not reply.';

		DECLARE @recipients NVARCHAR(500)
			,@server_name SYSNAME
			
		SELECT @server_name = @@SERVERNAME
			, @recipients	= CASE WHEN @server_name IN ('DB232', 'DB234') THEN 'dba_local@starixvn.com' ELSE 'dbaadmin@starixvn.com' END

		EXECUTE	msdb.dbo.sp_send_dbmail
					@recipients				= @recipients
				,	@copy_recipients		= ''
				,	@blind_copy_recipients	= ''
				,	@subject				= @subject
				,	@body					= @bodymsg
				,	@body_format			= 'HTML'
				;
	END

	DROP TABLE #custOutput
	DROP TABLE #custTemp
	DROP TABLE #custChanged
END
GO