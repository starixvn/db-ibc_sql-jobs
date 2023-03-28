/*<info serverAlias="DB055-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
/*
    Created: 20230324@Louisa
	Task: Scaleout Credit - cleanup unuse objects related to LASDB [Redmine: #182677]
	DB: DB055/bodb02
*/ 

USE bodb_customerLog
GO

----SP
EXEC sp_rename 'LAS_WriteLog_UserLog_RunSP'		,'LAS_WriteLog_UserLog_RunSP_deleted'
GO

----table
EXEC sp_rename 'UserLog_RunSP_LAS', 'UserLog_RunSP_LAS_deleted'
GO