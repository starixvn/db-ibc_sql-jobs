/*<info serverAlias="DBTRANS-bodb02, DBTRANS-bodb_customerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
/*
    Created: 20230324@Louisa
	Task: Scaleout Credit - cleanup unuse objects related to LASDB [Redmine: #182677]
	DB: DBTRANS/bodb02, DBTRANS/bodb_customerLog
*/  

USE bodb02
GO

DROP PROCEDURE Admin_PreCalculate_1_deleted
GO

DROP PROCEDURE Admin_PreCalculate_24_deleted
GO

DROP PROCEDURE Admin_PreCalculate_3_deleted
GO

DROP PROCEDURE Admin_PreCalculate_4_deleted
GO

DROP PROCEDURE Admin_PreCalculate_5_deleted
GO

DROP PROCEDURE Admin_PreCalculate_6_deleted
GO

DROP PROCEDURE NAP_Admin_Settlement_Parlay_deleted
GO

USE bodb_customerLog
GO

DROP PROCEDURE LAS_WriteLog_UserLog_RunSP_deleted
GO

