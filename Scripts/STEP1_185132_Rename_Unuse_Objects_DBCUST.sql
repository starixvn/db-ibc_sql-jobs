/*<info serverAlias="DBCUST-CustDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
/*
    Created: 20230324@Louisa
	Task: Scaleout Credit - cleanup unuse objects related to LASDB [Redmine: #185132]
	DB: DB055/bodb02
*/ 


----1.DBCUST/CustDB
USE CustDB
GO

EXEC sp_rename 'Las_Dep_AgentUpdateMemberDiscount'		,'Las_Dep_AgentUpdateMemberDiscount_deleted'
GO
EXEC sp_rename 'LAS_Custsetting_00'						,'LAS_Custsetting_00_deleted'
GO
EXEC sp_rename 'Las_Dep_AgentUpdateMemberDiscount3rd'	,'Las_Dep_AgentUpdateMemberDiscount3rd_deleted'
GO
EXEC sp_rename 'Las_Custsetting_03'						,'Las_Custsetting_03_deleted'
GO

----2.DBCUST/bodb_customerLog
USE bodb_customerLog
GO

EXEC sp_rename 'LAS_WriteLog_UserLog_RunSP'		,'LAS_WriteLog_UserLog_RunSP_deleted'
GO
