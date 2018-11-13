/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
  
ALTER PROCEDURE [dbo].[DBA_Lrf_LaunchProduct]  
(  
	@LicenseeName VARCHAR(10),  
	@ProductCode   VARCHAR(100)='',  
	@EffectiveDate SMALLDATETIME =''  
)  
AS  
/*  
	Created: 20150126@Jim  
	Task : re-structure create new licensee flow  
	DB: DBCUST.bodb_licensee  
	Original :  
   
	Revisions:  
		-20180926@Sophia: migrate bodb_Licensee from DB052 to DBCUST [redmine: #99855]
		-20181112@Amanda: add product 'SB' [redmine: #83584]
	Param's Explanation:  
   
*/  
  
BEGIN   
	 DECLARE @LicenseeId	INT
			,@ProductID		INT

	 SELECT @LicenseeId  = LicenseeId
	 FROM dbo.Licensees WITH (NOLOCK)
	 WHERE LicenseeName = @LicenseeName
   
	 IF @ProductCode = 'SB'
	 BEGIN
		SET @ProductID = 0
	 END
	 ELSE
	 BEGIN
	 	 SELECT @ProductId = ProductId
		 FROM dbo.Product3rd WITH (NOLOCK)
		 WHERE ProductPrefix  = @ProductCode
	 END
   
	 UPDATE dbo.LicenseeProduct3rd
	 SET EffectiveDate = @EffectiveDate
	 WHERE LicenseeId = @LicenseeID
		AND ProductId = @ProductID
END
GO