USE [bodb_LicenseeReport]
GO
ALTER PROCEDURE [dbo].[Task_PostStaging]     
AS  
/*
Created: Viet @ 20121031
Task: clean up staging data to save diskspace
DB: DBLIC.bodb_LicenseeReport

Revisions:
    
Param's Explanation:

*/
SET NOCOUNT ON

TRUNCATE TABLE dbo.bettrans
TRUNCATE TABLE dbo.match
TRUNCATE TABLE dbo.outright

DBCC SHRINKFILE (N'LicenseeReport_Staging_Data', 0, TRUNCATEONLY)