USE [bodb_LicenseeReport]
GO
ALTER PROCEDURE [dbo].[Task_PostStaging]     
AS  
/*
Created: Viet @ 20121031
Task: clean up staging data to save diskspace
DB: DBLIC.bodb_LicenseeReport

Revisions:
    -20170525@Paul: Check IsStagingBettrans flag before staging bettrans; insert sporttype, eventdate into staging match table [Redmine: #72914]
Param's Explanation:

*/
SET NOCOUNT ON

TRUNCATE TABLE dbo.bettrans
TRUNCATE TABLE dbo.match
TRUNCATE TABLE dbo.outright

DBCC SHRINKFILE (N'LicenseeReport_Staging_Data', 0, TRUNCATEONLY)

UPDATE bodb02.dbo.SystemSettings WITH(ROWLOCK, UPDLOCK)
SET VValue = 0
WHERE VName = 'IsStagingBettrans'
	AND VValue = 1