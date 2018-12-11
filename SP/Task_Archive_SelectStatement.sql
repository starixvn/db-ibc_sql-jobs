/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO
ALTER PROCEDURE [dbo].[Task_Archive_SelectStatement]
AS
/*
Created: 
Task : 
Process will archive
 - DB06.bodb_Report.dbo.statement
 - DB06.bodb_Archive.dbo.Transfer_BK
DB: DBTXN.bodb02
Original:

Revisions:
	- 20110516@Henry: change bettype to new range
	- 20181106@Sophia: Add transtype Coll [Redmine: #98621]

	
Param's Explanation: 

*/	  
	Declare @BU_Date datetime -- Next BalanceUp Date  
	Declare @CurrentBU_Date datetime  

	SELECT @BU_Date = DATEADD(day, 1, MAX(winlostdate))
	FROM dbo.Task_ArchiveDate

	SELECT TOP 1 @CurrentBU_Date = winlostdate  
	FROM dbo.bettrans with (nolock)  
	WHERE matchid = 0 AND bettype = 20000  
  
-- OpenBalance & Transfer for Statement  
--INSERT INTO DB06.bodb_Report.dbo.statement  (custid, accdate, totalamt, transtype, transdesc)  
select  
	custid, 
	transdate accdate,
	sum(winlost-actual_stake) totalamt,
	CASE WHEN OddsId = 1 THEN CONVERT (NVARCHAR(128),'COLL') ELSE typenamee END AS transtype,
	transdesc  
from  
	dbo.bettrans with (rowlock, INDEX=CIX_matchid_bettype)
	inner join dbo.bettype with (nolock) on bettrans.bettype=bettype.typeid  
where
	ruben = 1 AND
	matchid = 0 AND bettype >= 20000 --between 100 and 106 --AND transdate >= @fromdate   
	--AND winlostdate >= @CurrentBU_Date 
	AND winlostdate < @BU_Date
	and custid <> 0  
group by custid, typenamee,transdesc,transdate,transid,CASE WHEN OddsId = 1 THEN CONVERT (NVARCHAR(128),'COLL') ELSE typenamee END
having sum(winlost-actual_stake) <> 0  
GO
