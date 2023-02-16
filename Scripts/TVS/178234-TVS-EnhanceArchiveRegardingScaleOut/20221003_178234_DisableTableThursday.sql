/*<info serverAlias="DBARC-SSISDB" executers="" selecters="" viewers="" isFunction="0" isNested="0"></info>*/
/*
    Created: 20221003@Max
	Task: [TVS] Enhance archive process of TVS data regarding the Scale Out DB project - [Redmine: #178234]
	DB: DBARC-SSISDB

	Notes:
		- Deactive copy data for 'TicketVoiding_Queue', 'TicketVoiding_AutoVoidRequest_Queue'
*/

USE [SSISDB]
GO

UPDATE s SET s.Active = 0
FROM dbo.SSIS_DynamicMapping s WITH (ROWLOCK, UPDLOCK)
WHERE s.TableName IN ('TicketVoiding_Queue', 'TicketVoiding_AutoVoidRequest_Queue')


