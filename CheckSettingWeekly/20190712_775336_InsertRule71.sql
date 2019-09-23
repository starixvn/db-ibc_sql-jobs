USE [CheckResultDB]
GO
/*
	Created: 20190709@Winnie
	Task: Check PT weekly - [Redmine:#775336]
	DBCHECK.[CheckResultDB]
*/ 
-- BEGIN STEP 1: Deploy this SP at DBCUST.CustDB, Run only in the FIRST running

INSERT INTO [dbo].[Rule_Credit]
           ([RuleId]
           ,[RuleName]
           ,[ModifiedDate])
SELECT 71,'A1 <> [PT_Deposit known values] OR M1<>0 OR S1<>0 (DCS products)',GETDATE()

