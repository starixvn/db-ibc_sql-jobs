/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20230420@July
	Task: Check Data Consistency - Drop SP un-used - [Redmine: #186736]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO

IF OBJECT_ID('DBA_Consistency_GodofFortuneChecking', 'P') IS NOT NULL
	DROP PROCEDURE DBA_Consistency_GodofFortuneChecking;
GO
IF OBJECT_ID('DBA_Consistency_DetectNetstakeforRNGChecking', 'P') IS NOT NULL
	DROP PROCEDURE DBA_Consistency_DetectNetstakeforRNGChecking;
GO
IF OBJECT_ID('DBA_Consistency_CheckWinlost3rd', 'P') IS NOT NULL
	DROP PROCEDURE DBA_Consistency_CheckWinlost3rd;
GO
IF OBJECT_ID('DBA_Consistency_ActualstakeWinlostPlayercommChecking', 'P') IS NOT NULL
	DROP PROCEDURE DBA_Consistency_ActualstakeWinlostPlayercommChecking;
GO
IF OBJECT_ID('DBA_Consistency_LaunchedSiteChecking', 'P') IS NOT NULL
	DROP PROCEDURE DBA_Consistency_LaunchedSiteChecking;
GO
IF OBJECT_ID('DBA_Consistency_StatusChecking_NotDelegateMatchId', 'P') IS NOT NULL
	DROP PROCEDURE DBA_Consistency_StatusChecking_NotDelegateMatchId;
GO






IF OBJECT_ID('Task_LC_DataConsistency_Check', 'P') IS NOT NULL
	DROP PROCEDURE Task_LC_DataConsistency_Check;
GO

IF OBJECT_ID('Task_MicroGamingLC_DataConsistency_Check', 'P') IS NOT NULL
	DROP PROCEDURE Task_MicroGamingLC_DataConsistency_Check;
GO

IF OBJECT_ID('Task_MicroGamingRNG_DataConsistency_Check', 'P') IS NOT NULL
	DROP PROCEDURE Task_MicroGamingRNG_DataConsistency_Check;
GO

IF OBJECT_ID('Task_RNG_Check_Data_Consistency_Job', 'P') IS NOT NULL
	DROP PROCEDURE Task_RNG_Check_Data_Consistency_Job;
GO

IF OBJECT_ID('Task_RNG_DataConsistency_Check', 'P') IS NOT NULL
	DROP PROCEDURE Task_RNG_DataConsistency_Check;
GO