/*<info serverAlias="DB055-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
/*
    Created: 20230324@Louisa
	Task: Scaleout Credit - cleanup unuse objects related to LASDB [Redmine: #185132]
	DB: DB055/bodb02
*/ 

USE bodb_customerLog
GO

----SP
DROP PROCEDURE LAS_WriteLog_UserLog_RunSP_deleted
GO

----table
DROP TABLE UserLog_RunSP_LAS_deleted
GO