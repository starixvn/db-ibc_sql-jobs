/*<info serverAlias="DBACC-bodb02"></info>*/

/*
	Created: 20220418@Hogan
	Task: Generate data of Macau Games [RedmineID: #170607]
	DB: DBACC-bodb02
	Remark: Regen data for Macau Games
*/

USE bodb02
GO

EXEC dbo.TASK_RealtimeSummaryDepData @Winlostdate = '2022-04-15 00:00:00'