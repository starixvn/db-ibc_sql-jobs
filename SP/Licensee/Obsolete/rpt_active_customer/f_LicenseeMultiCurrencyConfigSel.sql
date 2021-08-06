/*<info serverAlias="DBLIC-bodb_Licensee,DBACC-bodb_Licensee" selecters="bodbAdminNet,bodbLicenseeNet" isFunction="1" isNested="1"></info>*/
USE [bodb_Licensee]
GO

ALTER FUNCTION [dbo].[f_LicenseeMultiCurrencyConfigSel]()
RETURNS @MultiCurrencies TABLE 
(Recommend INT, Currency INT, FromDate SMALLDATETIME, ToDate SMALLDATETIME)
AS

/*
	Created: 20150107@Patrick
	Task: Get all licensee who have multiple currencies
	DB: DBLIC.bodb_Licensee, DBACC.bodb_Licensee

	Revisions:
		- 20181031@Percy: Add new server: DBACC.bodb_Licensee [RedmineID: #103660]

	Param's Explanation:   
*/

BEGIN
	INSERT INTO @MultiCurrencies (Recommend, Currency, FromDate, ToDate)
	SELECT Recommend, Currency, FromDate, ToDate
	FROM dbo.LicenseeMultiCurrencyConfig WITH (NOLOCK) 
	WHERE Active = 1

	RETURN
END
GO