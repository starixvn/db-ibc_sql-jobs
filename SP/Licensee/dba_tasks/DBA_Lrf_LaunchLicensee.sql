/*<info serverAlias="DBCUST-bodb_Licensee" executers="" viewers="vnteam" isFunction="0"></info>*/  
CREATE PROCEDURE [dbo].[DBA_Lrf_LaunchLicensee]  
(  
 @LicenseeName VARCHAR(10),  
 @AffectedDate SMALLDATETIME =''  
)  
AS  
/*  
Created: 20150126@Jim  
Task : re-structure create new licensee flow  
DB: DBCUST.bodb_licensee  
Original :  
   
Revisions:  
   - 20180926@Sophia: migrate bodb_Licensee from DB052 to DBCUST [redmine: #99855]
Param's Explanation:  
  
   
*/  
  
BEGIN   
 DECLARE @LicenseeId INT  
      
 SELECT @LicenseeId  = LicenseeId   
 FROM dbo.Licensees WITH (NOLOCK)   
 WHERE LicenseeName = @LicenseeName  
   
 UPDATE dbo.Licensees   
 SET AffectedDate = @AffectedDate  
 WHERE LicenseeId = @LicenseeId  
    
END
GO