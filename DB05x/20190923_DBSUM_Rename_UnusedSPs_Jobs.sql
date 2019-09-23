use bodb_Summary
go

/*
	Created: 20190923@Percy
	DB: DBSUM.bodb_Summary
	Task: Un-used SPs of jobs - Rename to DEL_xxx
*/

sp_rename 'Task_DailyRptCS_SumCancelled', 'DEL_Task_DailyRptCS_SumCancelled'
go
sp_rename 'Task_DailyRptCS_SumCancelled_CheckAndCorrect', 'DEL_Task_DailyRptCS_SumCancelled_CheckAndCorrect'
go
sp_rename 'Task_DailyRptCS_SumCancelled_CheckAndCorrect_Job', 'DEL_Task_DailyRptCS_SumCancelled_CheckAndCorrect_Job'
go
sp_rename 'Task_DailyRptCS_SumCancelled_Job', 'DEL_Task_DailyRptCS_SumCancelled_Job'
go
sp_rename 'Task_DailyRptCS_SumWinloss', 'DEL_Task_DailyRptCS_SumWinloss'
go
sp_rename 'Task_DailyRptCS_SumWinloss_CheckAndCorrect', 'DEL_Task_DailyRptCS_SumWinloss_CheckAndCorrect'
go
sp_rename 'Task_DailyRptCS_SumWinloss_CheckAndCorrect_Job', 'DEL_Task_DailyRptCS_SumWinloss_CheckAndCorrect_Job'
go
sp_rename 'Task_DailyRptCS_SumWinloss_Job', 'DEL_Task_DailyRptCS_SumWinloss_Job'
go