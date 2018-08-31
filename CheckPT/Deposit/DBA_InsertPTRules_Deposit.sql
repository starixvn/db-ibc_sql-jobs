/*  
	Created: 20180827@Winnie
	Task: Insert rules to check PT setting deposit 
	DB: DBCHECK/CheckResultDB  

*/  

USE [CheckResultDB]
GO


INSERT INTO [dbo].[Rule_Credit]
           ([RuleId]
           ,[RuleName]
           ,[ModifiedDate])
SELECT 43,'S1 < 0 OR M1 < 0 OR A1 < 0',GETDATE()
UNION
SELECT 44,'S4 <> M3',GETDATE()
UNION
SELECT 45,'M3 <> A2',GETDATE()
UNION
SELECT 46,'A1 <>A2',GETDATE()
UNION
SELECT 47,'M1 + S1 <>0 member level',GETDATE()
UNION
SELECT 48,'A1 <>0.85  (sportsbook,NG,VS)',GETDATE()
UNION
SELECT 49,'A1 <>0.85  (Allbet Athena,VS, VS2)',GETDATE()
UNION
SELECT 50,'A1<>0.9 (Keno, Lotery, Fishing World Athena)',GETDATE()
UNION
SELECT 51,'A1<>0.92 (Allbet API, Fishing World API)',GETDATE()
UNION
SELECT 52,'A1<> 0.93 (Macaugame)',GETDATE()
UNION
SELECT 53,'A1+M1+S1 <>0 (BA member )',GETDATE()
UNION
SELECT 54,'Missing PT group for Agent',GETDATE()
UNION
SELECT 55,'Missing PT setting SMA',GETDATE()
UNION
SELECT 56,'Missing member setting mode (Dep_CustSettingMode)',GETDATE()
UNION
SELECT 57,'HousePT <> 1 (Cashout) (TradeComm)',GETDATE()
UNION
SELECT 58,'BetTradeComm.HousePT <>0.5',GETDATE()
UNION
SELECT 59,'Missing PT row (bettrade, cashout)',GETDATE()


