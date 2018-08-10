/*<info serverAlias="DBLIC-bodb_Licensee" executers="" viewers="vnteam" isFunction="0"></info>*/
USE [bodb_Licensee]
GO

ALTER PROCEDURE [dbo].[Task_DetectBAMemberBreakRules]
AS 
/*
Created: 20150512@Winnie
Task : 
Description: Get members break rules BA and send mail to related person.
DB: DBLIC.bodb_licensee
Original:

Revisions:
	- 20160906@Sophia: Ignore Bettrade account because they do not BA or Non BA 
	- 20180809@Sophia: HA - remove LicenseeCustInfo table [Redmine: #99464]
Param explanation:

*/
BEGIN
SET NOCOUNT ON

DECLARE @CustList varchar(MAX)
SET @CustList = ''

SELECT @CustList = @CustList+','+ CONVERT(varchar,b.Custid) 
FROM LicenseeBAConfig a(NOLOCK) 
INNER JOIN LicenseeCust c (NOLOCK) ON a.LicenseeID=c.LicenseeID
INNER JOIN bodb02.dbo.Customer b (NOLOCK) ON c.CustID=b.recommend
WHERE EnableBA=1 
AND (a.LicenseeID=7 OR(a.LicenseeID=2 AND c.Currency IN(3,6)))
AND b.Custid NOT IN(SELECT aa.CustID FROM [LicenseeBAHistory] aa WITH (NOLOCK)) 
AND b.custID NOT IN (SELECT bb.CustID FROM DBCUST.CUSTDB.dbo.BettradeCust bb WITH (NOLOCK)) ---- Bettrade Account 
AND b.RoleID = 1 

IF (@CustList <>'')
BEGIN

	
DECLARE @body VARCHAR(MAX)
SET @body = 'There existed some member break rules, please check' 
+ CHAR(10) + CHAR(13) + @CustList
EXEC sp_addmessage 
    @msgnum = 60000, 
    @severity = 1,
    @msgtext = @body,
    @lang = 'us_english',
	@replace=  'replace' ;
 RAISERROR(60000,1,1,'There existed some member break rules, please check' )     

END
END
GO


