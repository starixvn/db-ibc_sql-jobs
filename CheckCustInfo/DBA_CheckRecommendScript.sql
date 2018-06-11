/*
Created: 20180606@Winnie
Task: Scripts check recommend setting for customers 
DB: DBCHECK.CheckResultDB
Revisions:
Param's Explanation: 
*/

USE [CheckResultDB]
GO

DECLARE @CurrentDate DATETIME
SELECT @CurrentDate=GETDATE() 

INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
SELECT 51,Custid,GETDATE()
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
WHERE ci.roleid=4 AND ci.custid<>ci.srecommend AND ci.creatdate<@CurrentDate

INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
SELECT 52,Custid,GETDATE()
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
WHERE ci.roleid=3 AND ci.custid<>ci.mrecommend AND ci.creatdate<@CurrentDate

INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
SELECT 53,Custid,GETDATE()
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
WHERE ci.roleid=3 AND ci.custid=ci.srecommend AND ci.creatdate<@CurrentDate

SELECT Custid,ci.srecommend,ci.currency
INTO #tempUplineOfMaster
FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
WHERE ci.roleid=3 AND ci.creatdate<@CurrentDate

INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
SELECT 54,t.Custid,GETDATE()
FROM #tempUplineOfMaster t
	INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON t.srecommend=ci.CustID
WHERE ci.roleid<>4

INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
SELECT 55,Custid,GETDATE()
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
WHERE ci.roleid=2 AND ci.custid<>ci.recommend AND ci.creatdate<@CurrentDate

INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
SELECT 56,Custid,GETDATE()
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
WHERE ci.roleid=2 AND (ci.custid=ci.srecommend OR ci.CustID=ci.mrecommend) AND ci.creatdate<@CurrentDate

SELECT Custid,ci.srecommend,ci.mrecommend,ci.currency
INTO #tempUplineOfAgent
FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
WHERE ci.roleid=2 AND ci.creatdate<@CurrentDate

INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
SELECT 57,t.Custid,GETDATE()
FROM #tempUplineOfAgent t
	INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON t.srecommend=ci.CustID
WHERE ci.roleid<>4

INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
SELECT 58,t.Custid,GETDATE()
FROM #tempUplineOfAgent t
	INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON t.mrecommend=ci.CustID
WHERE ci.roleid<>3

INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
SELECT 59,t.Custid,GETDATE()
FROM #tempUplineOfAgent t
	INNER JOIN CheckCustDB.dbo.customer m WITH(NOLOCK) ON t.mrecommend=m.CustID
	INNER JOIN CheckCustDB.dbo.customer s WITH(NOLOCK) ON t.srecommend=s.CustID
WHERE m.srecommend <> s.srecommend

INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
SELECT 60,Custid,GETDATE()
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
WHERE ci.roleid=1 AND (ci.custid=ci.srecommend OR ci.CustID=ci.mrecommend OR ci.CustID=ci.recommend) AND ci.creatdate<@CurrentDate

SELECT Custid,ci.srecommend,ci.mrecommend,ci.recommend,ci.currency
INTO #tempUplineOfMember
FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
WHERE ci.roleid=1 AND ci.creatdate<@CurrentDate

INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
SELECT 61,t.Custid,GETDATE()
FROM #tempUplineOfMember t
	INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON t.srecommend=ci.CustID
WHERE ci.roleid<>4

INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
SELECT 62,t.Custid,GETDATE()
FROM #tempUplineOfMember t
	INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON t.mrecommend=ci.CustID
WHERE ci.roleid<>3

INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
SELECT 63,t.Custid,GETDATE()
FROM #tempUplineOfMember t
	INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON t.recommend=ci.CustID
WHERE ci.roleid<>2

INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
SELECT 64,t.Custid,GETDATE()
FROM #tempUplineOfMember t
	INNER JOIN CheckCustDB.dbo.customer m WITH(NOLOCK) ON t.mrecommend=m.CustID
	INNER JOIN CheckCustDB.dbo.customer s WITH(NOLOCK) ON t.srecommend=s.CustID
	INNER JOIN CheckCustDB.dbo.customer r WITH(NOLOCK) ON t.recommend=r.CustID
WHERE m.srecommend <> s.srecommend OR r.srecommend<>m.srecommend OR r.srecommend<> s.srecommend

INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
SELECT 65,t.Custid,GETDATE()
FROM #tempUplineOfMember t
	INNER JOIN CheckCustDB.dbo.customer m WITH(NOLOCK) ON t.mrecommend=m.CustID
	INNER JOIN CheckCustDB.dbo.customer r WITH(NOLOCK) ON t.recommend=r.CustID
WHERE r.mrecommend<>m.mrecommend 		

INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
SELECT 66,c.Custid,GETDATE()
FROM CheckCustDB.dbo.customer c WITH(NOLOCK) 
	INNER JOIN CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) ON c.CustID=ci.CustID
WHERE c.mrecommend<>ci.mrecommend OR c.recommend<>ci.recommend OR c.srecommend<>ci.srecommend AND c.creatdate<@CurrentDate

INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
SELECT 67,c.Custid,GETDATE()
FROM CheckCustDB.dbo.customer c WITH(NOLOCK) 
	WHERE c.roleid=4 
	AND c.Custid NOT IN (SELECT custid FROM CheckCustDB.dbo.Custsuper WITH(NOLOCK)) 
	AND c.creatdate<@CurrentDate

INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
SELECT 68,c.Custid,GETDATE()
FROM CheckCustDB.dbo.customer c WITH(NOLOCK) 
	WHERE c.roleid=3
	AND c.Custid NOT IN (SELECT custid FROM CheckCustDB.dbo.Custmaster WITH(NOLOCK)) 
	AND c.creatdate<@CurrentDate

INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
SELECT 69,c.Custid,GETDATE()
FROM CheckCustDB.dbo.customer c WITH(NOLOCK) 
	WHERE c.roleid=2
	AND c.Custid NOT IN (SELECT custid FROM CheckCustDB.dbo.CustAgent WITH(NOLOCK)) 
	AND c.creatdate<@CurrentDate

SELECT Username2
INTO #tempUsername
FROM CheckCustDB.dbo.Customer WITH(NOLOCK) 
	WHERE creatdate<@CurrentDate
	GROUP BY Username2 HAVING COUNT(Username2)>1

INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
SELECT 70,c.Custid,GETDATE()
FROM CheckCustDB.dbo.customer c WITH(NOLOCK) 
	INNER JOIN #tempUsername t ON c.username2=t.username2


DROP TABLE #tempUplineOfAgent
DROP TABLE #tempUplineOfMaster
DROP TABLE #tempUplineOfMember
DROP TABLE #tempUsername


--INSERT INTO CheckRecommendResult ([CustID],srecommend,mrecommend,recommend,CreatedDate)
--SELECT Custid,ci.srecommend,ci.mrecommend,ci.recommend,GETDATE()
--	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
--WHERE ci.roleid=2 AND (ci.custid=ci.srecommend OR ci.custid=ci.mrecommend) AND (ci.creatdate<@CurrentDate)

--INSERT INTO CheckRecommendResult ([CustID],srecommend,mrecommend,recommend,CreatedDate)
--SELECT Custid,ci.srecommend,ci.mrecommend,ci.recommend,GETDATE()
--	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
--WHERE ci.roleid=3 AND ci.custid=ci.srecommend AND (ci.creatdate<@CurrentDate)

--INSERT INTO CheckRecommendResult ([CustID],srecommend,mrecommend,recommend,CreatedDate)
--SELECT Custid,ci.srecommend,ci.mrecommend,ci.recommend,GETDATE()
--	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
--WHERE ci.roleid=1 AND (ci.custid=ci.srecommend OR ci.custid=ci.mrecommend OR ci.custid=ci.recommend) AND (ci.creatdate<@CurrentDate)

















