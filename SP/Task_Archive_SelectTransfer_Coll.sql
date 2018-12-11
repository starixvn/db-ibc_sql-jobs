/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO
ALTER PROCEDURE [dbo].[Task_Archive_SelectTransfer_Coll]
AS
/*
	Created: 20181106@Sophia
	Task : 	Process will archive to DB06.bodb_Archive.dbo.Transfer_Coll_BK 
	DB: DBTXN.bodb02
	Original:

	Revisions:
		- 20181107@Sophia: Initial SP [Redmine: #98621]
		
	Param's Explanation: 

*/	  
	Declare @BU_Date datetime -- Next BalanceUp Date  

	SELECT @BU_Date = DATEADD(day, 1, MAX(winlostdate))
	FROM dbo.Task_ArchiveDate


-- Transfer Archive  
-- INSERT INTO DB06.bodb_Archive.dbo.Transfer_Coll_BK  
-- (CustId,WinlostDate,TransDate,Bettype,Debit,Credit,Currency,ActualRate,TransID,RefNo,Username,Recommend,MRecommend,SRecommend,Creator,TransDesc,IP)  

SELECT  
	CustId,
	WinlostDate,
	TransDate,
	Bettype,
	Debit,
	Credit,
	Currency,
	ActualRate,
	TransID,
	RefNo,
	Username,
	Recommend,
	MRecommend,
	SRecommend,
	Creator,
	TransDesc,
	IP
FROM dbo.Transfer_Coll WITH(NOLOCK)
WHERE winlostdate < @BU_Date  

GO
	  

