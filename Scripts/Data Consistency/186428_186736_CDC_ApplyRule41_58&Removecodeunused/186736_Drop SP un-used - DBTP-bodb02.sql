/*<info serverAlias="DBTP-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20230420@July
	Task: Check Data Consistency - Drop SP un-used - [Redmine: #186736]
	DB: DBTP-bodb02

*/
USE bodb02
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