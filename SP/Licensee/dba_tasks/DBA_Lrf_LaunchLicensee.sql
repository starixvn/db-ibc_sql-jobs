/****** Object:  Stored Procedure dbo.DBA_Lrf_LaunchLicensee    Script Date: 2/2/2015 6:27:46 PM ******/  
  
CREATE PROCEDURE [dbo].[DBA_Lrf_LaunchLicensee]  
(  
 @LicenseeName VARCHAR(10),  
 @AffectedDate SMALLDATETIME =''  
)  
AS  
/*  
Created: 20150126@Jim  
Task : re-structure create new licensee flow  
DB: DBLIC.bodb_licensee  
Original :  
   
Revisions:  
   
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