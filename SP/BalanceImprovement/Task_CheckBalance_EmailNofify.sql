/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_CheckBalance_EmailNofify]
AS
/*
	Task: Email admins to notify about affected customers that have balance fixed
	Created: 20150610@Daniel
	Original: 
	Location: DBTXN.bodb02

	Revision: 
		- 20201022@Patrick: Change email to starixvn [Redmine: #143607]

*/

-- SEND warning email to DBA
--return--temp stop spam mail due to tight run schedule (1 min)

DECLARE @body VARCHAR(MAX), @sql nvarchar(max), @profile_name SYSNAME
DECLARE @lastRun datetime

SELECT TOP 1 @lastrun = msdb.DBO.AGENT_DATETIME(RUN_DATE, RUN_TIME)
FROM msdb.dbo.SYSJOBS SJ LEFT OUTER JOIN msdb.dbo.SYSJOBHISTORY JH ON SJ.job_id = JH.job_id
WHERE SJ.NAME = 'bodb02 : Task_BalanceCheck 3'
    AND jh.run_status = 1
    AND step_name = 'Task_CheckBalance - Email Notify'
--GROUP BY SJ.name, JH.run_status 
ORDER BY msdb.DBO.AGENT_DATETIME(RUN_DATE, RUN_TIME) desc

IF (NOT EXISTS(SELECT 1 FROM Task_Cust_BalanceProblem)) RETURN


SELECT TOP (1) @profile_name = name FROM MSDB.dbo.sysmail_profile

SELECT @sql = N'SELECT TOP 1000 c.username, c.custid, DiffBalance, LogDate, IsFixed, c.Remark
FROM Task_Cust_BalanceProblem c with (nolock)
	INNER JOIN custDB.dbo.Customer cust with (nolock) on c.custid = cust.custid 
	LEFT JOIN Task_Cust_CheckBalance_Exception ce with (nolock) on c.custid = ce.custid
	LEFT JOIN DBACC.bodb_ACC.dbo.Acc_DWLList dw with (nolock) on c.custid = dw.custid
WHERE ce.custid IS NULL AND dw.custid is null AND cust.currency <> 20
	AND LogDate > ''' + CONVERT(varchar(20),@lastrun,13) + '''
ORDER BY Diffbalance DESC'

EXEC dbo.DBA_QueryToHtmlTable_Daniel @html = @body OUTPUT, @query = @sql

IF @body IS NULL RETURN
--PRINT @body
				
EXEC msdb.dbo.sp_send_dbmail
@recipients=N'vndba@starixvn.com;it@starixvn.com;dbatw@onelab.tw',  --20150820 add TWDBA
--@recipients=N'daniel.truong@starixvn.com',
@body=@body,
@body_format ='HTML',
@sensitivity ='Personal',
@importance ='Normal',				
@copy_recipients ='vndba@starixvn.com',
@subject ='Balance Correction - Top 1000 customers',
@profile_name =@profile_name
GO


