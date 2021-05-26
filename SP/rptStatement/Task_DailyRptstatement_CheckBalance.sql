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
		- 20210518@Danny: Enhance performance [RedmineId : #154536]
*/
BEGIN

	SET NOCOUNT ON;

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
	
	DECLARE @MBU TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	INSERT INTO @MBU (BalanceUpDay, MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	DECLARE @BalanceUpDay SMALLDATETIME, @MoveBetsDay SMALLDATETIME
	SELECT @BalanceUpDay = BalanceUpDay, @MoveBetsDay = MoveBetsDay FROM @MBU

	CREATE TABLE #temp(
		custid int,
		randid tinyint,
		openingbalance money,
		closingbalance money,
		winlostdate SMALLDATETIME
	)
	INSERT INTO #temp (custid, randid, openingbalance, closingbalance, winlostdate)
	SELECT custid, ROW_NUMBER()  OVER (PARTITION BY custid ORDER BY winlostdate asc) randid, openingbalance, closingbalance, winlostdate
	FROM dbo.rptStatement WITH (NOLOCK)
	WHERE winlostdate BETWEEN @BalanceUpDay AND @MoveBetsDay

	CREATE CLUSTERED INDEX CIX_#tempCustidRandid  ON #temp(custid, randid);   

	INSERT INTO #custChanged (custid,closingdate,closingbalance,openingdate,openingbalance,is_updated)
	SELECT t1.custid, t1.winlostdate as closingdate, t1.closingbalance, t2.winlostdate as openingdate, t2.openingbalance, 0
	FROM #temp t1 
	INNER JOIN #temp t2 ON t1.custid = t2.custid AND t1.randid = t2.randid - 1
	WHERE t1.closingbalance <> t2.openingbalance

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

	DROP TABLE #temp
	DROP TABLE #custChanged
END
GO