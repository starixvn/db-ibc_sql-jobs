/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/
/*	
	Created: 20211109@Sol
	DB: DBLIC-bodb_LicenseeReport
	RedmineID: Stop Automail Licensee Current Play report - [Redmine:162062]
 
*/

USE msdb

GO

DECLARE @jobId UNIQUEIDENTIFIER

SELECT @jobId = job_id 
FROM msdb.dbo.sysjobs 
WHERE (name = N'bodb_LicenseeReport: Daily Gen Daily rptLicIpBetting')
IF (@jobId IS NOT NULL)
BEGIN
    EXEC msdb.dbo.sp_update_job @job_id= @jobId, 
		@enabled=0
END
