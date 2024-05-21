/*<info serverAlias="DBAGE-bodb_AGE" isNested="0"></info>*/
/*
	Created by: 20240522@Bobby
	Task: 153357 - Alpha - CDC bettrans_compact - CheckSum Vs logs
	DB: DBAGE.bodb_AGE
		
*/

USE [bodb_AGE]
GO
ALTER TABLE  [dbo].[bettrans_compact_checkSum]
ADD [keyValue] [varchar](1000);
GO
