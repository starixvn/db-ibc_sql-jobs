/*<info serverAlias="DBGRP02L-bodb02, DBGRP02L-bodb_customerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
/*
    Created: 20230324@Louisa
	Task: Scaleout Credit - cleanup unuse objects related to LASDB [Redmine: #182677]
	DB: DBGRP02L/bodb02, DBGRP02L/bodb_customerLog
*/ 

USE bodb02
GO

EXEC sp_rename 'NAP_Admin_Calculate_22'			,'NAP_Admin_Calculate_22_deleted'		--DBGRP02N1
GO

EXEC sp_rename 'NAP_Admin_Calculate_9'			,'NAP_Admin_Calculate_9_deleted'		--DBGRP02N1
GO

EXEC sp_rename 'Admin_PreCalculate_1'			,'Admin_PreCalculate_1_deleted'			--DBGRP02N1
GO

EXEC sp_rename 'Admin_PreCalculate_24'			,'Admin_PreCalculate_24_deleted'		--DBGRP02N1
GO

EXEC sp_rename 'Admin_PreCalculate_3'			,'Admin_PreCalculate_3_deleted'			--DBGRP02N1
GO

EXEC sp_rename 'Admin_PreCalculate_4'			,'Admin_PreCalculate_4_deleted'			--DBGRP02N1
GO

EXEC sp_rename 'Admin_PreCalculate_5'			,'Admin_PreCalculate_5_deleted'			--DBGRP02N1
GO

EXEC sp_rename 'Admin_PreCalculate_6'			,'Admin_PreCalculate_6_deleted'			--DBGRP02N1
GO

EXEC sp_rename 'NAP_Admin_Settlement_Parlay'	,'NAP_Admin_Settlement_Parlay_deleted'	--DBGRP02N1
GO

USE bodb_customerLog
GO

EXEC sp_rename 'LAS_WriteLog_UserLog_RunSP'		,'LAS_WriteLog_UserLog_RunSP_deleted'	--DBGRP02L
GO
