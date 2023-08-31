/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" executers="" isFunction="0" isNested="1"></info>*/
USE [bodb_LicenseeReport]
GO
ALTER PROCEDURE [dbo].[Task_PostStaging]     
	  @DateFrom		SMALLDATETIME = NULL
     ,@DateTo		SMALLDATETIME = NULL
AS  
/*
Created: Viet @ 20121031
Task: clean up staging data to save diskspace
DB: DBLIC.bodb_LicenseeReport, DBBAL-bodb_LicenseeReport

Revisions:
    -20170525@Paul: Check IsStagingBettrans flag before staging bettrans; insert sporttype, eventdate into staging match table [Redmine: #72914]
	- 20210816@Sophia: add DBBAL [Redmine: #154300]
	- 20230831@Danny: enhance processing data [Redmine: #190123]
	
Param's Explanation:

*/
SET NOCOUNT ON

DECLARE @FromDate SMALLDATETIME, @ToDate SMALLDATETIME

IF @DateFrom IS NOT NULL AND @DateTo IS NOT NULL
	SELECT @ToDate = CONVERT(VARCHAR(10), @DateTo, 120), @FromDate = CONVERT(VARCHAR(10), @DateFrom, 120)
ELSE
	SELECT @ToDate = CONVERT(VARCHAR(10), DATEADD(DAY, -1, GETDATE()), 120), @FromDate = DATEADD(DAY, -2, @ToDate)


DELETE dbo.bettrans WITH(ROWLOCK, UPDLOCK) WHERE winlostdate BETWEEN @FromDate AND @ToDate
DELETE dbo.match WITH(ROWLOCK, UPDLOCK) WHERE eventdate BETWEEN @FromDate AND @ToDate
DELETE dbo.outright WITH(ROWLOCK, UPDLOCK) WHERE eventdate BETWEEN @FromDate AND @ToDate 

IF @@SERVERNAME <> 'DBBAL'
BEGIN 
	DBCC SHRINKFILE (N'LicenseeReport_Staging_Data', 0, TRUNCATEONLY)
END

UPDATE bodb02.dbo.SystemSettings WITH(ROWLOCK, UPDLOCK)
SET VValue = 0
WHERE VName = 'IsStagingBettrans'
	AND VValue = 1