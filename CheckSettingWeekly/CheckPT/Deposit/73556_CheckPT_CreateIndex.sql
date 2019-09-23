
/*
Created: 20180906@Winnie
Task: Monthly check PT for deposit customers- Create index - [Redmine:73556]
DB: DB054.CheckResultDB
Revisions:

*/
USE [CheckCustDB]
GO

CREATE NONCLUSTERED INDEX IX_Dep_CustPTGroupSetting_Member_MasterPT
    ON Dep_CustPTGroupSetting_Member (MasterPT);   

CREATE NONCLUSTERED INDEX IX_Dep_CustPTGroupSetting_Member_AgentPT
    ON Dep_CustPTGroupSetting_Member (AgentPT);   

CREATE NONCLUSTERED INDEX IX_Dep_CustPTGroupSetting_Member_SuperPT
    ON Dep_CustPTGroupSetting_Member (SuperPT);
	
CREATE NONCLUSTERED INDEX IX_Dep_CustPTSetting_Member_MasterPT
    ON Dep_CustPTSetting_Member (MasterPT);   

CREATE NONCLUSTERED INDEX IX_Dep_CustPTSetting_Member_AgentPT
    ON Dep_CustPTSetting_Member (AgentPT);   

CREATE NONCLUSTERED INDEX IX_Dep_CustPTSetting_Member_SuperPT
    ON Dep_CustPTSetting_Member (SuperPT);   

CREATE NONCLUSTERED INDEX IX_Dep_CustSettingGame_SuperPT
    ON Dep_CustSettingGame (spositiontaking);    

CREATE NONCLUSTERED INDEX IX_Dep_CustSettingGame_MasterPT
    ON Dep_CustSettingGame (mpositiontaking);   

CREATE NONCLUSTERED INDEX IX_Dep_CustSettingGame_AgentPT
    ON Dep_CustSettingGame (apositiontaking);   

CREATE NONCLUSTERED INDEX IX_Dep_CustSetting3rd_SuperPT
    ON Dep_CustSetting3rd (spositiontaking);   

CREATE NONCLUSTERED INDEX IX_Dep_CustSetting3rd_MasterPT
    ON Dep_CustSetting3rd (mpositiontaking);   

CREATE NONCLUSTERED INDEX IX_Dep_CustSetting3rd_AgentPT
    ON Dep_CustSetting3rd (apositiontaking);   