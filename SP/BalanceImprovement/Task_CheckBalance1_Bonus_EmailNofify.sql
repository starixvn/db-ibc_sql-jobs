/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_CheckBalance1_Bonus_EmailNofify]
AS
/*
	Task: Email admins to notify about affected customers that have balance fixed
	Created: 20170928@Patrick
	Original: 
	Location: DBTXN.bodb02

	Revision: 
		- 20201022@Patrick: Change email to starixvn [Redmine: #143607]
		- 20210426@Sol: Alpha/NAP - Migrate from DBACC to DBCust - [Redmine: #154041]

*/

-- SEND warning email to DBA
DECLARE @body VARCHAR(MAX), @sql NVARCHAR(MAX), @profile_name SYSNAME
DECLARE @lastRun datetime

SELECT TOP 1 @lastrun = msdb.dbo.agent_datetime(run_date, run_time)
FROM msdb.dbo.sysjobs SJ 
	LEFT OUTER JOIN msdb.dbo.sysjobhistory jh ON sj.job_id = jh.job_id
WHERE sj.NAME = 'bodb02 : Task_BalanceCheck 4 for Bonus'
    AND jh.run_status = 1
    AND step_name = 'Task_BalanceCheck1 - Email Notify'
--GROUP BY SJ.name, JH.run_status 
ORDER BY msdb.dbo.agent_datetime(run_date, run_time) desc

IF (NOT EXISTS(SELECT 1 FROM dbo.Task_Cust_BalanceProblem1_Bonus)) RETURN

SELECT TOP (1) @profile_name = name FROM msdb.dbo.sysmail_profile

SELECT @sql = N'
	SELECT DISTINCT TOP(1000)  c.username, c.custid, c.bonusId, DiffBalance, LogDate, IsFixed, c.Remark
	FROM Task_Cust_BalanceProblem1_Bonus c with (nolock)
		INNER JOIN custDB.dbo.Customer cust with (nolock) on c.custid = cust.custid 
		LEFT JOIN dbo.Task_Cust_CheckBalance_Exception ce with (nolock) on c.custid = ce.custid
		LEFT JOIN DBCUST.CustDB.dbo.Acc_DWLList dw with (nolock) on c.custid = dw.custid
	WHERE ce.custid IS NULL AND dw.custid is null AND cust.currency <> 20
		AND LogDate > ''' + CONVERT(varchar(20), @lastrun, 13) + '''
	ORDER BY Diffbalance DESC'

EXEC dbo.DBA_QueryToHtmlTable_Daniel @html = @body OUTPUT, @query = @sql

IF @body IS NULL RETURN

--PRINT @body
--//
DECLARE @subject VARCHAR(200)
SET @subject = 'Balance Correction - Bonus (New Balance Tables) - Top 1000 members @' + @@Servername
EXEC msdb.dbo.sp_send_dbmail @recipients= N'dbaadmin@starixvn.com;dbatw@onelab.tw;allen.wu@onelab.tw;luna.ho@onelab.tw;'
	, @body = @body
	, @body_format ='HTML'
	, @sensitivity = 'Personal'
	, @importance = 'Normal'
	, @copy_recipients = 'daniel.truong@starixvn.com'
	, @subject = @subject
	, @profile_name = @profile_name
GO


