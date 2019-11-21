/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_CheckBalance1_EmailNofify]
AS
/*
	Task: Email admins to notify about affected customers that have balance fixed
	Created: 20150610@Daniel
	Original: 
	Location: DBTXN.bodb02

	Revision: 
	- 20180403@Cooper(DBTrans):Replace alter email to luna.ho@onelab.tw from brian.yang@onelab.tw
	- 20190319@Patrick: Exclude CN88 account - push code to git [RedmineID: #110530]
	- 20191121@Patrick: Adding code to send message via skype/letstalk [RedmineID: #124080]
*/
BEGIN
	SET NOCOUNT ON
	-- SEND warning email to DBA
	DECLARE @body VARCHAR(MAX), @sql NVARCHAR(MAX), @profile_name SYSNAME
	DECLARE @lastRun DATETIME, @__jobName VARCHAR(200)

	SELECT @__jobName = 'bodb02 : Task_BalanceCheck 4'

	SELECT TOP 1 @lastrun = msdb.DBO.AGENT_DATETIME(RUN_DATE, RUN_TIME)
	FROM msdb.dbo.SYSJOBS SJ LEFT OUTER JOIN msdb.dbo.SYSJOBHISTORY JH ON SJ.job_id = JH.job_id
	WHERE SJ.NAME = @__jobName
		AND jh.run_status = 1
		AND step_name = 'Task_BalanceCheck1 - Email Notify'
	--GROUP BY SJ.name, JH.run_status 
	ORDER BY msdb.DBO.AGENT_DATETIME(RUN_DATE, RUN_TIME) DESC

	IF (NOT EXISTS(SELECT 1 FROM Task_Cust_BalanceProblem1)) 
		RETURN

	SELECT TOP (1) @profile_name = name FROM MSDB.dbo.sysmail_profile

	SELECT @sql = N'SELECT TOP 1000 c.username, c.custid, DiffBalance, LogDate, IsFixed, c.Remark
	FROM Task_Cust_BalanceProblem1 c with (nolock)
		INNER JOIN custDB.dbo.Customer cust with (nolock) on c.custid = cust.custid 
		LEFT JOIN Task_Cust_CheckBalance_Exception ce with (nolock) on c.custid = ce.custid
		LEFT JOIN DBACC.bodb_ACC.dbo.Acc_DWLList dw with (nolock) on c.custid = dw.custid
	WHERE ce.custid IS NULL AND dw.custid is null AND cust.currency <> 20
		AND LogDate > ''' + CONVERT(varchar(20),@lastrun,13) + '''
	ORDER BY Diffbalance DESC'

	EXEC dbo.DBA_QueryToHtmlTable_Daniel @html = @body OUTPUT, @query = @sql

	IF @body IS NULL 
		RETURN

	DECLARE @mailList NVARCHAR(1024)
	SET @mailList = N'dbaadmin@starixsoft.com;dbatw@onelab.tw;allen.wu@onelab.tw;luna.ho@onelab.tw;'

	IF @@SERVERNAME <> 'DBTRANS'
	BEGIN
		SET @mailList = 'pontus@starixsoft.com;'
	END
				
	EXEC msdb.dbo.sp_send_dbmail
		@recipients = @mailList, 
		@body  =@body,
		@body_format = 'HTML',
		@sensitivity = 'Personal',
		@importance = 'Normal',				
		@copy_recipients = 'daniel.truong@starixsoft.com',
		@subject = 'Balance Correction (New Balance Tables) - Top 1000 members',
		@profile_name = @profile_name

	--Send message to skype/letstalk
	--//only send letstalk and skype for KBT environment
	IF @@SERVERNAME = 'DBTRANS'
	BEGIN
		DECLARE @__affectedRows INT
		SELECT @__affectedRows = COUNT(1)
		FROM Task_Cust_BalanceProblem1 c with (nolock)
			INNER JOIN custDB.dbo.Customer cust with (nolock) on c.custid = cust.custid 
			LEFT JOIN Task_Cust_CheckBalance_Exception ce with (nolock) on c.custid = ce.custid
			LEFT JOIN DBACC.bodb_ACC.dbo.Acc_DWLList dw with (nolock) on c.custid = dw.custid
		WHERE ce.custid IS NULL AND dw.custid is null AND cust.currency <> 20
			AND LogDate > CONVERT(VARCHAR(20), @lastrun, 13)

		IF @__affectedRows > 0
		BEGIN

			DECLARE @__caseId TINYINT
			SELECT TOP (1) @__caseId = CaseId
			FROM DBNOTI.NotificationDB.dbo.DBA_CaseNotifications WITH(NOLOCK)
			WHERE ServerName = @@SERVERNAME AND JobName = @__jobName

			IF @__caseId IS NULL OR @__caseId = 0
				SET @__caseId = 1

			DECLARE @__message NVARCHAR(2000)
			SET @__message = CAST(@__affectedRows AS VARCHAR(30))+' account(s) has (have) been found & corrected. Please check e-mail for more details!' + char(10) + char(13)
			SET @__message = @__message + '========================'

			EXECUTE	DBNOTI.NotificationDB.dbo.DBA_Letstalk_NewJobMessage @ServerName = @@SERVERNAME, @Jobid = NULL, @JobName = @__jobName, @Message = @__message, @CaseId = @__caseId
		END
	END
END
GO