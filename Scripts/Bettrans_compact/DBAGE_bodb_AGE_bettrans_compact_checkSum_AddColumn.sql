/*<info serverAlias="DBAGE-bodb_AGE" isNested="0"></info>*/
/*
	Created by: 20240522@Bobby
	Task: 153357 - Alpha - CDC bettrans_compact - CheckSum Vs logs
	DB: DBAGE.bodb_AGE

	Revisions:
		- 20240602@Bobby: Enhance check & correct process [RedmineID: #205973]
*/

USE [bodb_AGE]
GO
--ALTER TABLE  [dbo].[bettrans_compact_checkSum]
--ADD [keyValue] [varchar](1000);
--GO

ALTER TABLE  [dbo].[bettrans_compact_checkSum]
ADD [roundCheck] [SMALLINT]
GO
