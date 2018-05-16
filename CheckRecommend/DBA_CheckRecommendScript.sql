/*
Created: 20180514@Winnie
Task: Scripts check recommend setting for customers 
DB: DBCHECK.CheckResultDB
Revisions:
Param's Explanation: 
*/

USE [CheckResultDB]
GO

DECLARE @CurrentDate DATETIME
SELECT @CurrentDate=GETDATE() 

INSERT INTO CheckRecommendResult ([CustID],srecommend,mrecommend,recommend,CreatedDate)
SELECT Custid,ci.srecommend,ci.mrecommend,ci.recommend,GETDATE()
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
WHERE ci.roleid=2 AND (ci.custid=ci.srecommend OR ci.custid=ci.mrecommend) AND (ci.creatdate<@CurrentDate)

INSERT INTO CheckRecommendResult ([CustID],srecommend,mrecommend,recommend,CreatedDate)
SELECT Custid,ci.srecommend,ci.mrecommend,ci.recommend,GETDATE()
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
WHERE ci.roleid=3 AND ci.custid=ci.srecommend AND (ci.creatdate<@CurrentDate)

INSERT INTO CheckRecommendResult ([CustID],srecommend,mrecommend,recommend,CreatedDate)
SELECT Custid,ci.srecommend,ci.mrecommend,ci.recommend,GETDATE()
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
WHERE ci.roleid=1 AND (ci.custid=ci.srecommend OR ci.custid=ci.mrecommend OR ci.custid=ci.recommend) AND (ci.creatdate<@CurrentDate)
