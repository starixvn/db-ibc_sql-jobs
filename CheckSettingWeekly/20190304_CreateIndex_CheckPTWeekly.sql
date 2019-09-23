/*
	Created: Winnie
	Task: check PT setting weekly
	DB: DBCheck/CheckCustDB
	Date: 20190304
*/ 
USE CheckCustDB
GO

CREATE NONCLUSTERED INDEX IX_Dep_CustSetting3rd_CheckPT
ON Dep_CustSetting3rd (CustID,Sporttype,Bettype,IsLive) INCLUDE(spositiontaking,mpositiontaking,apositiontaking);   

CREATE NONCLUSTERED INDEX IX_Dep_CustSetting_CheckPT
ON Dep_CustSetting (CustID,Sporttype,Bettype,IsLive) INCLUDE(spositiontaking,mpositiontaking,apositiontaking);  