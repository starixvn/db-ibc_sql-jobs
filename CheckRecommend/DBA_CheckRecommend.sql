USE [CheckResultDB]
GO

ALTER PROCEDURE [dbo].[DBA_CheckRecommend]
	 @srecommend INT 
AS
BEGIN 
/*
Created: 20180514@Winnie
Task: Weekly check recommend setting for customers 
DB: DBCHECK.CheckResultDB
Revisions:
Param's Explanation: 
	Rule 51: Member level: custid=srecommend OR custid=mrecommend OR custid=recommend
	Rule 52: Agent  level: custid=srecommend OR custid=mrecommend
	Rule 53: Master level: custid=srecommend
	Rule 54: Master level: Master has wrong srecommend
	Rule 55: Agent  level: Agent has wrong srecommend
	Rule 56: Agent  level: Agent has wrong mrecommend
	Rule 57: Member level: Member has wrong srecommend
	Rule 58: Member level: Member has wrong mrecommend
	Rule 59: Member level: Member has wrong recommend
*/
	SET NOCOUNT ON 
	DECLARE @CurrentDate DATETIME
	SELECT @CurrentDate=GETDATE() 

	INSERT INTO CheckRecommendResult (RuleID,[CustID],srecommend,mrecommend,recommend,CreatedDate)
	SELECT 51,Custid,ci.srecommend,ci.mrecommend,ci.recommend,GETDATE()
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
	WHERE ci.roleid=1 AND (ci.custid=ci.srecommend OR ci.custid=ci.mrecommend OR ci.custid=ci.recommend) AND (ci.creatdate BETWEEN @CurrentDate-7 AND @CurrentDate)

	INSERT INTO CheckRecommendResult (RuleID,[CustID],srecommend,mrecommend,recommend,CreatedDate)
	SELECT 52,Custid,ci.srecommend,ci.mrecommend,ci.recommend,GETDATE()
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
	WHERE ci.roleid=2 AND (ci.custid=ci.srecommend OR ci.custid=ci.mrecommend) AND (ci.creatdate BETWEEN @CurrentDate-7 AND @CurrentDate)

	INSERT INTO CheckRecommendResult (RuleID,[CustID],srecommend,mrecommend,recommend,CreatedDate)
	SELECT 53,Custid,ci.srecommend,ci.mrecommend,ci.recommend,GETDATE()
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
	WHERE ci.roleid=3 AND ci.custid=ci.srecommend AND (ci.creatdate BETWEEN @CurrentDate-7 AND @CurrentDate) 	

	SELECT Custid,ci.srecommend
	INTO #tempMaster
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
	WHERE ci.roleid=3 AND (ci.creatdate BETWEEN @CurrentDate-7 AND @CurrentDate) 

	INSERT INTO CheckRecommendResult (RuleID,[CustID],srecommend,mrecommend,recommend,CreatedDate)
	SELECT 54,Custid,ci.srecommend,ci.mrecommend,ci.recommend,GETDATE()
	FROM #tempMaster t
		INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON t.srecommend=ci.CustID
	WHERE ci.roleid<>4

	SELECT Custid,ci.srecommend,ci.mrecommend
	INTO #tempAgent
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
	WHERE ci.roleid=2 AND (ci.creatdate BETWEEN @CurrentDate-7 AND @CurrentDate) 

	INSERT INTO CheckRecommendResult (RuleID,[CustID],srecommend,mrecommend,recommend,CreatedDate)
	SELECT 55,Custid,ci.srecommend,ci.mrecommend,ci.recommend,GETDATE()
	FROM #tempAgent t
		INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON t.srecommend=ci.CustID
	WHERE ci.roleid<>4

	INSERT INTO CheckRecommendResult (RuleID,[CustID],srecommend,mrecommend,recommend,CreatedDate)
	SELECT 56,Custid,ci.srecommend,ci.mrecommend,ci.recommend,GETDATE()
	FROM #tempAgent t
		INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON t.mrecommend=ci.CustID
	WHERE ci.roleid<>3
	
	SELECT Custid,ci.srecommend,ci.mrecommend,ci.recommend
	INTO #tempMember
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
	WHERE ci.roleid=1 AND (ci.creatdate BETWEEN @CurrentDate-7 AND @CurrentDate) 

	INSERT INTO CheckRecommendResult (RuleID,[CustID],srecommend,mrecommend,recommend,CreatedDate)
	SELECT 57,Custid,ci.srecommend,ci.mrecommend,ci.recommend,GETDATE()
	FROM #tempMember t
		INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON t.srecommend=ci.CustID
	WHERE ci.roleid<>4

	INSERT INTO CheckRecommendResult (RuleID,[CustID],srecommend,mrecommend,recommend,CreatedDate)
	SELECT 58,Custid,ci.srecommend,ci.mrecommend,ci.recommend,GETDATE()
	FROM #tempMember t
		INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON t.mrecommend=ci.CustID
	WHERE ci.roleid<>3
	
	INSERT INTO CheckRecommendResult (RuleID,[CustID],srecommend,mrecommend,recommend,CreatedDate)
	SELECT 59,Custid,ci.srecommend,ci.mrecommend,ci.recommend,GETDATE()
	FROM #tempMember t
		INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON t.recommend=ci.CustID
	WHERE ci.roleid<>2

END 

