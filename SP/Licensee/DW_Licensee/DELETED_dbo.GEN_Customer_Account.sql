USE [bodb_Licensee]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GEN_Customer_Account]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GEN_Customer_Account]
GO

USE [bodb_Licensee]
GO


CREATE PROCEDURE [dbo].[GEN_Customer_Account] 
AS  
/*
Created: 20110617@Elly.Nguyen
Task : Generate data for Customer Account
DB: DB052.bodb_licensee

Revisions:
    
Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON	
	
	DECLARE @startdate as datetime
	
	SELECT @startdate=min(transdate) 
	FROM bodb02.dbo.bettrans b with (nolock)
	WHERE b.bettype > 19999 AND matchid = 0

	DELETE ca
	FROM dbo.tbl_Customer_Account ca with (nolock)
		inner join bodb02.dbo.bettrans b with (nolock) on b.transid = ca.transid
	WHERE b.bettype > 19999 AND b.matchid = 0 
		AND (ca.deleted=0 or ca.deleted is null) 
		AND b.custid <> 0--AND not deleted

	UPDATE ca
	SET deleted = 1
		,TransDesc = ca.TransDesc + ' deleted on: ' + CAST(CURRENT_TIMESTAMP as nvarchar(20))
	FROM dbo.tbl_Customer_Account ca with (nolock)
		inner join bodb02.dbo.bettrans b with (nolock) on b.transid = ca.transid
	WHERE b.bettype > 19999 AND matchid = 0 
		AND b.custid = 0 
		AND (ca.deleted=0 or ca.deleted is null) 

	INSERT INTO dbo.tbl_Customer_Account 
		([transid], [refno], [transtype], [custid],currency,recommend,mrecommend,srecommend, [transdate], [amount], [creator], [TransDesc],balanceduppreviousday)
	SELECT b.transid,b.refno,b.bettype, b.custid,b.currency,isnull(b.recommend,0),isnull(b.mrecommend,0),isnull(b.srecommend,0),b.transdate,
		winlost-b.actual_Stake Amount, b.creator, 
		CASE WHEN CHARINDEX('(',b.transdesc) = 0 THEN null ELSE SUBSTRING(b.transdesc,CHARINDEX('(',b.transdesc)+1,LEN(b.transdesc)-CHARINDEX('(',b.transdesc)-1) end  TransDesc,
		CASE WHEN (b.winlostdate+1)<=b.transdate THEN 1 ELSE 0 end balanceduppreviousday
	FROM bodb02.dbo.bettrans b with (nolock) 
		left join dbo.tbl_Customer_Account ca with (nolock)  on b.transid = ca.transid
	WHERE b.bettype > 19999 AND matchid = 0 
		AND ca.transid is null AND b.custid <> 0

	UPDATE ca 
	SET ca.OtherCustid = caother.custid
	FROM tbl_Customer_Account AS ca with (nolock) 
		inner join dbo.tbl_Customer_Account caOther with (nolock) ON caOther.refno = ca.refno 
			AND caOther.transid <> ca.transid
	WHERE ca.refno not in (-1,0) AND ca.transtype >= 21003 
		AND ca.transdate >= @startdate
		AND ca.othercustid is null AND caOther.othercustid is null 

	SET NOCOUNT OFF
END
/*
SET STATISTICS IO ON
SET STATISTICS TIME ON

DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE

GEN_Customer_Account
SELECT * FROM tbl_Customer_Account
truncate table tbl_Customer_Account
*/

GO



