/*<info serverAlias="DBPRT-bodb_report"></info>*/

/*
	Created: 20210802@Sophia
	DB: DBPRT-bodb_report
	Task: Re-gen Statement Void All day [RedmineID: #159511]
*/

USE bodb_report
GO
 
 EXEC[Task_rptStatement_14
	@WinlostDate = '20210728'
	,@CustIds	 ='53819807,53819834'