USE [CheckResultDB]
GO

/*
	Date: 2019-05-30
	Created: Winnie
	Task: 11 deposit accounts missing setting data due to All Site | Fiber Port Broken Issue IM#1008
	DB: DBCheck/[[CheckResultDB]]
*/
CREATE TABLE #temp (CustID INT)
INSERT INTO #temp(CustID)
SELECT 36460562
UNION
SELECT 36460471
UNION
SELECT 36460558
UNION
SELECT 36460561
UNION
SELECT 36460564
UNION
SELECT 36460472
UNION
SELECT 36460477
UNION
SELECT 36460559
UNION
SELECT 36460560
UNION
SELECT 36460563
UNION
SELECT 36460565

INSERT INTO [dbo].[IgnoredCust]
           ([CustID]
           ,[RoleID]
           ,[RuleID]
           ,[Sporttype]
           ,[Bettype]
           ,[AllLine]
           ,[ModifiedDate]
           ,[Remark])
SELECT CustID
           ,1
           ,0
           ,0
           ,0
           ,0
           ,GETDATE()
           ,''
FROM #temp


