/*<info serverAlias="DBTRANS-bodb02, DBTRANS-bodb_customerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
/*
    Created: 20230324@Louisa
	Task: Scaleout Credit - cleanup unuse objects related to LASDB [Redmine: #185132]
	DB: DBTRANS/bodb02, DBTRANS/bodb_customerLog
*/  

USE bodb02
GO

EXEC sp_rename 'Admin_PreCalculate_1'			,'Admin_PreCalculate_1_deleted'			--DBTrans
GO

EXEC sp_rename 'Admin_PreCalculate_24'			,'Admin_PreCalculate_24_deleted'		--DBTrans
GO

EXEC sp_rename 'Admin_PreCalculate_3'			,'Admin_PreCalculate_3_deleted'			--DBTrans
GO

EXEC sp_rename 'Admin_PreCalculate_4'			,'Admin_PreCalculate_4_deleted'			--DBTrans
GO

EXEC sp_rename 'Admin_PreCalculate_5'			,'Admin_PreCalculate_5_deleted'			--DBTrans
GO

EXEC sp_rename 'Admin_PreCalculate_6'			,'Admin_PreCalculate_6_deleted'			--DBTrans
GO

EXEC sp_rename 'NAP_Admin_Settlement_Parlay'	,'NAP_Admin_Settlement_Parlay_deleted'	--DBTrans
GO

USE bodb_customerLog
GO

EXEC sp_rename 'LAS_WriteLog_UserLog_RunSP'		,'LAS_WriteLog_UserLog_RunSP_deleted'	--DBTrans
GO

