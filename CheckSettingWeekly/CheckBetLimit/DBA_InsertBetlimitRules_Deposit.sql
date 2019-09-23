/*  
	Created: 20180816@Winnie
	Task: Insert rules to check betting limit setting deposit 
	DB: DBCHECK/CheckResultDB  

*/  

USE [CheckResultDB]
GO


INSERT INTO [dbo].[Rule_Credit]
           ([RuleId]
           ,[RuleName]
           ,[ModifiedDate])
SELECT 317,'Missing bet limit setting',GETDATE()
UNION
SELECT 318,'minbet < 0',GETDATE()
UNION
SELECT 319,'Super Minbet > Master Minbet > Agent Minbet (confirm Ann if need to exclude sub-agents)',GETDATE()
UNION
SELECT 320,'maxbet < 0',GETDATE()
UNION
SELECT 321,'Super Maxbet < Master Maxbet < Agent Maxbet (confirm Ann if need to exclude sub-agents)',GETDATE()
UNION
SELECT 322,'Max per match < 0',GETDATE()
UNION
SELECT 323,'Super mpx < Master mpx < Agent mpx (confirm Ann if need to exclude sub-agents)',GETDATE()
UNION
SELECT 324,'Max per ball < 0',GETDATE()
UNION
SELECT 325,'Super mpb < Master mpb < Agent mpb (confirm Ann if need to exclude sub-agents)',GETDATE()
UNION
SELECT 326,'Minbet > Maxbet',GETDATE()
UNION
SELECT 327,'Maxbet > Maxpermatch',GETDATE()
UNION
SELECT 328,'Maxbet > Max Per Ball',GETDATE()

