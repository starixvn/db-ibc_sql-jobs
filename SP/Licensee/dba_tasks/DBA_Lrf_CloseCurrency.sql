/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[DBA_Lrf_CloseCurrency]  
(  
	@CurrencyCode  VARCHAR (3),
	@LicenseeNames VARCHAR (500)
)  
AS 
/*
	Created: 20170920@Harper
	Description : Close Currency for Licensee
	DB: DBCUST.bodb_licensee  
	
	Revisions:  
	  - 20150320@Harper: Document LRF Setting [RedmineID: #82673]
	  - 20180926@Sophia: migrate bodb_Licensee from DB052 to DBCUST [redmine: #99855]
*/
BEGIN
	DECLARE @CurrencyID INT
	DECLARE @tblLicensee AS TABLE (LicenseeId INT)

	SELECT @CurrencyID= exchangeid
	FROM CUSTDB.dbo.Exchange WITH (NOLOCK)
	WHERE Code = @CurrencyCode
 
	INSERT INTO @tblLicensee (LicenseeId)
	SELECT LicenseeID
	FROM dbo.Licensees WITH (NOLOCK) 
	WHERE LicenseeName IN ( SELECT val FROM CUSTDB.dbo.strSplit(@LicenseeNames, ',') )

	UPDATE dbo.CurrencyUser WITH (ROWLOCK,UPDLOCK)
	SET isActive = 0
	WHERE CurrencyID = @CurrencyID
		AND LicenseeID IN (SELECT LicenseeID FROM @tblLicensee)
END
GO