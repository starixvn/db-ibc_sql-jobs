USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_Archive_SelectStatement]    Script Date: 03/07/2016 04:48:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_SelectStatement]
AS
/*
Created: 
Task : 
Process will archive
 - DB06.bodb_Report.dbo.statement
 - DB06.bodb_Archive.dbo.Transfer_BK
DB: DB06.bodb02
Original:

Revisions:
	- 20110516@Henry: change bettype to new range

	
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
	typenamee transtype,
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
group by custid, typenamee,transdesc,transdate,transid  
having sum(winlost-actual_stake) <> 0  

