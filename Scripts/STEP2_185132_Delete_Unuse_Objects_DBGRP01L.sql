/*
    Created: 20230324@Louisa
	Task: Scaleout Credit - cleanup unuse objects related to LASDB [Redmine: #182677]
	DB: DBGRP01L/bodb02, DBGRP01L/bodb_customerLog
*/  

USE bodb02
GO

DROP PROCEDURE NAP_Admin_Calculate_22_deleted
GO

DROP PROCEDURE NAP_Admin_Calculate_9_deleted
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

