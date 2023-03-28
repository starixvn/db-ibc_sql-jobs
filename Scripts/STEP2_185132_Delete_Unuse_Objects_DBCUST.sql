/*<info serverAlias="DBCUST-CustDB, DBCUST/bodb_customerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
/*
    Created: 20230324@Louisa
	Task: Scaleout Credit - cleanup unuse objects related to LASDB [Redmine: #182677]
	DB: DBCUST/CustDB
*/ 


----1.DBCUST/CustDB
USE CustDB
GO

DROP PROCEDURE Las_Dep_AgentUpdateMemberDiscount_deleted
GO
DROP PROCEDURE LAS_Custsetting_00_deleted
GO
DROP PROCEDURE Las_Dep_AgentUpdateMemberDiscount3rd_deleted
GO
DROP PROCEDURE Las_Custsetting_03_deleted
GO

----2.DBCUST/bodb_customerLog
USE bodb_customerLog
GO

DROP PROCEDURE LAS_WriteLog_UserLog_RunSP_deleted
GO
