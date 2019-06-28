/*
	Created: 20190628@Johnson
	Task: add config for job to check suspend info
	DB: DBCHECK/[CheckResultDB]
*/


INSERT INTO [CheckResultDB].[dbo].[vnDBA_CheckSetting_RunningScripts]
           ([ScriptName]
           ,[VarKey]
           ,[Threads]
           ,[Command])
SELECT 'Status Suspend info Credit','CheckSettingThreadCount',1,'SET NOCOUNT ON;    EXECUTE DBA_CheckSuspendInfoStatus_Credit; UPDATE dbo.vnDBA_Service_Variables WITH (ROWLOCK)  SET  VarValue = ISNULL(CAST(VarValue AS SMALLINT), 0) - 1  WHERE VarKey = N''~~~'';  '

