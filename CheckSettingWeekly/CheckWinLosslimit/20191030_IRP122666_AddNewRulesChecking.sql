/*
	Created: 20191030@Johnson
	Task: structure for checking win loss limit
	DB: DBCHECK-CheckResultDB
*/

--Add rules for checking winloss limit
INSERT INTO [CheckResultDB].[dbo].[Rule_Credit]
           ([RuleId]
           ,[RuleName])
SELECT 501, N'Missing win loss limit setting'
UNION SELECT 502, N'Super''s Maximum Win < Master''s Maximum Win'
UNION SELECT 503, N'Master''s Maximum Win < Agent''s Maximum Win'
UNION SELECT 504,N'Agent''s Maximum Win < Member''s Maximum Win'
UNION SELECT 505,N'Maximum Loss < MinLossLimit of LossLimit_GlobalSetting'
UNION SELECT 506,N'Super''s Maximum Loss < Master''s Maximum Loss'
UNION SELECT 507,N'Master''s Maximum Loss < Agent''s Maximum Loss'
UNION SELECT 508,N'Agent''s Maximum Loss < Member''s Maximum Loss'
UNION SELECT 509,N'Upline''s IsAutoReset = 0 , Downlines''s IsAutoReset = 1'
GO


INSERT INTO [CheckResultDB].[dbo].[vnDBA_CheckSetting_RunningScripts]
           ([ScriptName]
           ,[VarKey]
           ,[Threads]
           ,[Command])
SELECT 'Win Loss Limit','CheckSettingThreadCount',0, 
	N'SET NOCOUNT ON;    

DECLARE @CustId INT;   
WHILE 0 = 0  
BEGIN   
	SELECT @CustId = NULL;  

	UPDATE TOP(1) dbo.Credit_Supers   
	SET @CustId = CustId   , 
		WinLossLimit = 2   
	WHERE WinLossLimit = 0;     

	IF @CustId IS NULL BREAK;
	  
	EXECUTE dbo.DBA_CheckWinLossLimit_Credit @srecommend = @CustId, 
								@SportType = 0, 
								@RuleId = 0;   
								  
	UPDATE dbo.Credit_Supers   
	SET WinLossLimit = 1   
	WHERE CustId = @CustId   
		AND WinLossLimit = 2;  
END;   

UPDATE dbo.vnDBA_Service_Variables WITH (ROWLOCK)  
SET  VarValue = ISNULL(CAST(VarValue AS SMALLINT), 0) - 1 
WHERE VarKey = N''~~~'';'
GO


INSERT INTO [CheckResultDB].[dbo].[vnDBA_CheckSetting_RunningScripts]
           ([ScriptName]
           ,[VarKey]
           ,[Threads]
           ,[Command])
SELECT 'Win Loss Limit DCS','CheckSettingThreadCount',0, 
	N'SET NOCOUNT ON;    

DECLARE @CustId INT;   
WHILE 0 = 0  
BEGIN   
	SELECT @CustId = NULL;  

	UPDATE TOP(1) dbo.Credit_Supers   
	SET @CustId = CustId   , 
		WinLossLimitDCS = 2   
	WHERE WinLossLimitDCS = 0;     

	IF @CustId IS NULL BREAK;
	  
	EXECUTE dbo.DBA_CheckWinLossLimitDCS_Credit @srecommend = @CustId, 
								@SportType = 0, 
								@RuleId = 0;   
								  
	UPDATE dbo.Credit_Supers   
	SET WinLossLimitDCS = 1   
	WHERE CustId = @CustId   
		AND WinLossLimitDCS = 2;  
END;   

UPDATE dbo.vnDBA_Service_Variables WITH (ROWLOCK)  
SET  VarValue = ISNULL(CAST(VarValue AS SMALLINT), 0) - 1 
WHERE VarKey = N''~~~'';'
