/*  
	Created: 20191106@Bobby
	Task: Implement headline - Statement [Redmine: #119289] - UAT Clean Jobs
	DB: DBRPT.bodb_Report
*/

USE [msdb]
GO

/****** Object:  Job [bodb_Report: Daily Summary rptStatement_test]    Script Date: 11/6/2019 6:08:08 AM ******/
EXEC msdb.dbo.sp_delete_job @job_name=N'bodb_Report: Daily Summary rptStatement_test', @delete_unused_schedule=1
GO

/****** Object:  Job [bodb_Report: Daily Summary RptTotalBalance_Active_test]    Script Date: 11/6/2019 6:09:55 AM ******/
EXEC msdb.dbo.sp_delete_job @job_name=N'bodb_Report: Daily Summary RptTotalBalance_Active_test', @delete_unused_schedule=1
GO

/****** Object:  Job [bodb02: Check and Correct Data - After MoveBets  - Test]    Script Date: 11/6/2019 6:09:55 AM ******/
EXEC msdb.dbo.sp_delete_job @job_name=N'bodb02: Check and Correct Data - After MoveBets  - Test', @delete_unused_schedule=1
GO

/****** Object:  Job [bodb02 : Task CN88 Headline Balance - Test]    Script Date: 11/6/2019 6:09:55 AM ******/
EXEC msdb.dbo.sp_delete_job @job_name=N'bodb02 : Task CN88 Headline Balance - Test', @delete_unused_schedule=1
GO

