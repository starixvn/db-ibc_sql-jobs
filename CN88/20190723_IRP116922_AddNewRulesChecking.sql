/*
	Created: 20190723@Johnson
	Task: add new rules checking for cn88 
	DB: DBCHECK-CheckResultDB
*/

--Add rules for cn88
INSERT INTO [CheckResultDB].[dbo].[Rule_Credit]
           ([RuleId]
           ,[RuleName])
SELECT 10001,'n4 > MaxPT'
UNION SELECT 10002,'l4 > MaxPT'
UNION SELECT 10003,'s3 > l4'
UNION SELECT 10004,'n4 > s1+m1+a1'
UNION SELECT 10005,'l4 < s1+m1+a1'
UNION SELECT 10006,'s3 < n4 - (m2+a2)'
UNION SELECT 10007,'s3 > l4 - MAX(m2+a2)'
UNION SELECT 10008,'m2 > l4'
UNION SELECT 10009,'a2 > l4'
UNION SELECT 10101,'Super discount > Default Max Discount'
UNION SELECT 10102,'Super''s discount < Downlines master''s discount'
UNION SELECT 10103,'Master''s discount < Downlines agent''s discount'
UNION SELECT 10104,'Agent discount < Individual downline''s discount'
UNION SELECT 10105,'Agent discount < Downlines group discount'
UNION SELECT 10201,'Super maxbet < Master maxbet'
UNION SELECT 10202,'Super MaxPerEvent < Master MaxPerEvent'
UNION SELECT 10203,'Master maxbet < Agent maxbet'
UNION SELECT 10204,'Master MaxPerEvent < Agent MaxPerEvent'
UNION SELECT 10205,'Agent maxbet < Member maxbet'
UNION SELECT 10206,'Agent MaxPerEvent < Member MaxPerEvent '
GO


--Add supers list for cn88
INSERT INTO [CheckResultDB].[dbo].[CS_Supers]([CustId])
SELECT custid
FROM dbo.customer WITH(NOLOCK)
WHERE site = 'cn88'
	AND roleid = 4
GO

INSERT INTO [CheckResultDB].[dbo].[vnDBA_CheckSetting_RunningScripts]
           ([ScriptName]
           ,[VarKey]
           ,[Threads]
           ,[Command])
SELECT 'PT CN88','CheckSettingThreadCount',1, 
	N'SET NOCOUNT ON;    

DECLARE @CustId INT;   
WHILE 0 = 0  
BEGIN   
	SELECT @CustId = NULL;  

	UPDATE TOP(1) dbo.CS_Supers   
	SET @CustId = CustId   , 
		PT = 2   
	WHERE PT = 0;     

	IF @CustId IS NULL BREAK;
	  
	EXECUTE dbo.DBA_CS_CheckPT @srecommend = @CustId, 
								@SportType = 0, 
								@RuleId = 0;   
								  
	UPDATE dbo.CS_Supers   
	SET PT = 1   
	WHERE CustId = @CustId   
		AND PT = 2;  
END;   

UPDATE dbo.vnDBA_Service_Variables WITH (ROWLOCK)  
SET  VarValue = ISNULL(CAST(VarValue AS SMALLINT), 0) - 1 
WHERE VarKey = N''~~~'';'


INSERT INTO [CheckResultDB].[dbo].[vnDBA_CheckSetting_RunningScripts]
           ([ScriptName]
           ,[VarKey]
           ,[Threads]
           ,[Command])
SELECT 'Commission CN88','CheckSettingThreadCount',1, 
	N'SET NOCOUNT ON;    

DECLARE @CustId INT;   
WHILE 0 = 0  
BEGIN   
	SELECT @CustId = NULL;  

	UPDATE TOP(1) dbo.CS_Supers   
	SET @CustId = CustId   , 
		Comm = 2   
	WHERE Comm = 0;     

	IF @CustId IS NULL BREAK;
	  
	EXECUTE dbo.DBA_CS_CheckComm @srecommend = @CustId, 
								@SportType = 0, 
								@RuleId = 0;   
								  
	UPDATE dbo.CS_Supers   
	SET Comm = 1   
	WHERE CustId = @CustId   
		AND Comm = 2;  
END;   

UPDATE dbo.vnDBA_Service_Variables WITH (ROWLOCK)  
SET  VarValue = ISNULL(CAST(VarValue AS SMALLINT), 0) - 1 
WHERE VarKey = N''~~~'';'


INSERT INTO [CheckResultDB].[dbo].[vnDBA_CheckSetting_RunningScripts]
           ([ScriptName]
           ,[VarKey]
           ,[Threads]
           ,[Command])
SELECT 'BetLimit CN88','CheckSettingThreadCount',1, 
	N'SET NOCOUNT ON;    

DECLARE @CustId INT;   
WHILE 0 = 0  
BEGIN   
	SELECT @CustId = NULL;  

	UPDATE TOP(1) dbo.CS_Supers   
	SET @CustId = CustId   , 
		BetLimit = 2   
	WHERE BetLimit = 0;     

	IF @CustId IS NULL BREAK;
	  
	EXECUTE dbo.DBA_CS_CheckBetLimit @srecommend = @CustId, 
								@SportType = 0, 
								@RuleId = 0;   
								  
	UPDATE dbo.CS_Supers   
	SET BetLimit = 1   
	WHERE CustId = @CustId   
		AND BetLimit = 2;  
END;   

UPDATE dbo.vnDBA_Service_Variables WITH (ROWLOCK)  
SET  VarValue = ISNULL(CAST(VarValue AS SMALLINT), 0) - 1 
WHERE VarKey = N''~~~'';'
