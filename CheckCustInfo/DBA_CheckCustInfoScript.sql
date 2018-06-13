/*
Created: 201806013@Winnie
Task: Scripts check CustInfo setting for customers 
DB: DBCHECK.CheckResultDB test
Revisions:
Param's Explanation: 
*/

USE [CheckResultDB]
GO

DECLARE @CurrentDate	DATETIME
SELECT	@CurrentDate=	GETDATE() 
CREATE TABLE #DirectMaster	(CustID INT PRIMARY KEY,srecommend INT)
CREATE TABLE #DirectAgent	(CustID INT PRIMARY KEY,mrecommend INT,srecommend INT)
CREATE TABLE #DirectMember	(CustID INT PRIMARY KEY,recommend INT,mrecommend INT,srecommend INT)
CREATE TABLE #Dummy			(CustID INT PRIMARY KEY)

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
FROM DBEXT.bodb02.dbo.Customer WITH(NOLOCK) 
WHERE creatdate<@CurrentDate
	GROUP BY Username2 HAVING COUNT(Username2)>1

INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
SELECT 70,c.Custid,GETDATE()
FROM  DBEXT.bodb02.dbo.customer c WITH(NOLOCK) 
	INNER JOIN #tempUsername t ON c.username2=t.username2

INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
SELECT 71,t.Custid,GETDATE()
FROM #tempUplineOfMaster t
	INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON t.srecommend=ci.srecommend
WHERE t.currency<>ci.Currency AND ci.creatdate<@CurrentDate

INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
SELECT 72,t.Custid,GETDATE()
FROM #tempUplineOfAgent t
	INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON t.mrecommend=ci.mrecommend
WHERE t.currency<>ci.Currency AND ci.creatdate<@CurrentDate

INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
SELECT 72,t.Custid,GETDATE()
FROM #tempUplineOfAgent t
	INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON t.srecommend=ci.srecommend
WHERE t.currency<>ci.Currency AND ci.creatdate<@CurrentDate

INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
SELECT 73,t.Custid,GETDATE()
FROM #tempUplineOfMember t
	INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON t.recommend=ci.recommend
WHERE t.currency<>ci.Currency AND ci.creatdate<@CurrentDate

INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
SELECT 73,t.Custid,GETDATE()
FROM #tempUplineOfMember t
	INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON t.mrecommend=ci.mrecommend
WHERE t.currency<>ci.Currency AND ci.creatdate<@CurrentDate

INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
SELECT 73,t.Custid,GETDATE()
FROM #tempUplineOfMember t
	INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON t.srecommend=ci.srecommend
WHERE t.currency<>ci.Currency AND ci.creatdate<@CurrentDate

INSERT INTO #DirectMaster (CustID,srecommend)
SELECT ci.custid,ci.srecommend
FROM CheckCustDB.dbo.Customer ci with(nolock)
INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON ci.custid=c.custid
WHERE  ci.creatdate<@CurrentDate
	AND ci.custid NOT IN (SELECT custid from CheckCustDB.dbo.Acc_CustDirect WITH(NOLOCK))
	AND ci.srecommend IN (SELECT custid from CheckCustDB.dbo.Acc_CustDirect WITH(NOLOCK))
	AND ci.roleid=3 AND ci.srecommend <=100 
	AND c.Enabled=1
	
--- get direct agent
INSERT INTO #DirectAgent (CustID,srecommend,mrecommend)
SELECT ci.custid,ci.srecommend,ci.mrecommend
FROM CheckCustDB.dbo.Customer ci WITH(NOLOCK)
INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON ci.custid=c.custid
WHERE  ci.creatdate<@CurrentDate
	and ci.custid NOT IN (SELECT custid from CheckCustDB.dbo.Acc_CustDirect WITH(NOLOCK))
	and ci.mrecommend IN (SELECT custid from CheckCustDB.dbo.Acc_CustDirect WITH(NOLOCK))
	and ci.roleid=2 AND ci.srecommend <=100
	AND c.Enabled=1
	
INSERT INTO #DirectMember(CustID,srecommend,mrecommend,recommend)
SELECT c.custid,c.srecommend,c.mrecommend,c.recommend
FROM CheckCustDB.dbo.Customer c WITH(NOLOCK)
INNER JOIN CheckCustDB.dbo.Customer ca (nolock) on c.recommend=ca.custid 
INNER JOIN CheckCustDB.dbo.custInfo ci WITH(NOLOCK) ON ci.custid=c.custid
WHERE c.custid NOT IN (SELECT custid from CheckCustDB.dbo.Acc_CustDirect WITH(NOLOCK))
	AND c.recommend IN (SELECT custid from CheckCustDB.dbo.Acc_CustDirect WITH(NOLOCK))
	AND c.roleid=1 AND c.srecommend <=100
	AND   c.creatdate<@CurrentDate
	AND ci.Enabled=1

INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
SELECT 75,t.Custid,GETDATE()
FROM #DirectMaster t WHERE t.CustID NOT IN (SELECT CustID FROM DBEXT.bodb02.dbo.CustDirectAccount WITH(NOLOCK))

INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
SELECT 75,t.Custid,GETDATE()
FROM #DirectAgent t WHERE t.CustID NOT IN (SELECT CustID FROM DBEXT.bodb02.dbo.CustDirectAccount WITH(NOLOCK))

INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
SELECT 75,t.Custid,GETDATE()
FROM #DirectMember t WHERE t.CustID NOT IN (SELECT CustID FROM DBEXT.bodb02.dbo.CustDirectAccount WITH(NOLOCK))

INSERT INTO #Dummy (CustID)
SELECT DISTINCT d.mrecommend -- Master of direct agent
FROM #DirectAgent d
UNION 
SELECT DISTINCT d.mrecommend -- Master of direct member
FROM #DirectMember D 	
UNION 
-----------------------Agent--------------------------------------		
SELECT DISTINCT d.recommend	-- agent of direct member
FROM #DirectMember D 
----Super
UNION
SELECT DISTINCT d.srecommend -- Master of direct agent
FROM #DirectAgent d
UNION 
SELECT DISTINCT d.srecommend -- Master of direct member
FROM #DirectMember D
UNION 
SELECT DISTINCT d.srecommend -- Master of direct member
FROM #DirectMaster D

INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
SELECT 74,t.Custid,GETDATE()
FROM #Dummy t WHERE t.CustID NOT IN (SELECT CustID FROM CheckCustDB.dbo.acc_custdirect WITH(NOLOCK))

DROP TABLE #tempUplineOfAgent
DROP TABLE #tempUplineOfMaster
DROP TABLE #tempUplineOfMember
DROP TABLE #tempUsername
DROP TABLE #Dummy
DROP TABLE #DirectAgent
DROP TABLE #DirectMaster
DROP TABLE #DirectMember

















