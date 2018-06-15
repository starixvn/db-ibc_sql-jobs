USE [CheckResultDB]
GO


ALTER PROCEDURE [dbo].[DBA_CheckCustInfoWeekly]
	 @srecommend INT 
AS
BEGIN 
/*
Created: 20180613@Winnie
Task: Weekly check Custinfo setting for customers 
DB: DBCHECK.CheckResultDB
Revisions:
Param's Explanation: 

*/
SET NOCOUNT ON 
	

	DECLARE @CurrentDate	DATETIME
	SELECT	@CurrentDate=	GETDATE() 
	CREATE TABLE #DirectMaster	(CustID INT PRIMARY KEY,srecommend INT)
	CREATE TABLE #DirectAgent	(CustID INT PRIMARY KEY,mrecommend INT,srecommend INT)
	CREATE TABLE #DirectMember	(CustID INT PRIMARY KEY,recommend INT,mrecommend INT,srecommend INT)
	CREATE TABLE #Dummy			(CustID INT PRIMARY KEY)
	CREATE TABLE #tempUsername	(Username2 VARCHAR(30))

	INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
	SELECT 51,Custid,GETDATE()
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
	WHERE ci.srecommend=@srecommend AND ci.roleid=4 AND ci.custid<>ci.srecommend AND ci.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate

	INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
	SELECT 52,Custid,GETDATE()
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
	WHERE ci.srecommend=@srecommend AND ci.roleid=3 AND ci.custid<>ci.mrecommend AND ci.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate

	INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
	SELECT 53,Custid,GETDATE()
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
	WHERE ci.srecommend=@srecommend AND ci.roleid=3 AND ci.custid=ci.srecommend AND ci.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate

	INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
	SELECT 54,ma.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer ma WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON ma.srecommend=ci.CustID
	WHERE ci.roleid<>4  AND ma.roleid=3 AND ma.srecommend=@srecommend AND ma.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate

	INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
	SELECT 55,Custid,GETDATE()
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
	WHERE ci.srecommend=@srecommend AND ci.roleid=2 AND ci.custid<>ci.recommend AND ci.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate

	INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
	SELECT 56,Custid,GETDATE()
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
	WHERE ci.srecommend=@srecommend AND ci.roleid=2 AND (ci.custid=ci.srecommend OR ci.CustID=ci.mrecommend) AND ci.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate

	INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
	SELECT 57,ag.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer ag WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON ag.srecommend=ci.CustID
	WHERE ci.roleid<>4 AND ag.roleid=2 AND ag.srecommend=@srecommend AND ag.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate

	INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
	SELECT 58,ag.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer ag WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON ag.mrecommend=ci.CustID
	WHERE ci.roleid<>3 AND ag.roleid=2 AND ag.srecommend=@srecommend AND ag.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate

	INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
	SELECT 59,ag.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer ag WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.customer m WITH(NOLOCK) ON ag.mrecommend=m.CustID
		INNER JOIN CheckCustDB.dbo.customer s WITH(NOLOCK) ON ag.srecommend=s.CustID
	WHERE m.srecommend <> s.srecommend  AND ag.roleid=2 AND ag.srecommend=@srecommend AND ag.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate

	INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
	SELECT 60,Custid,GETDATE()
	FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
	WHERE ci.srecommend=@srecommend AND ci.roleid=1 AND (ci.custid=ci.srecommend OR ci.CustID=ci.mrecommend OR ci.CustID=ci.recommend) 
		AND ci.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate

	INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
	SELECT 61,mem.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer mem WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON mem.srecommend=ci.CustID
	WHERE ci.roleid<>4 AND mem.roleid=1 AND mem.srecommend=@srecommend AND mem.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate
	
	INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
	SELECT 62,mem.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer mem WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON mem.mrecommend=ci.CustID
	WHERE ci.roleid<>3 AND mem.roleid=1 AND mem.srecommend=@srecommend AND mem.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate

	INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
	SELECT 63,mem.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer mem WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON mem.recommend=ci.CustID
	WHERE ci.roleid<>2 AND mem.roleid=1 AND mem.srecommend=@srecommend AND mem.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate

	INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
	SELECT 64,mem.Custid,GETDATE()
	FROM  CheckCustDB.dbo.customer mem WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.customer m WITH(NOLOCK) ON mem.mrecommend=m.CustID
		INNER JOIN CheckCustDB.dbo.customer s WITH(NOLOCK) ON mem.srecommend=s.CustID
		INNER JOIN CheckCustDB.dbo.customer r WITH(NOLOCK) ON mem.recommend=r.CustID
	WHERE mem.roleid=1 AND mem.srecommend=@srecommend AND mem.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate
		AND (m.srecommend <> s.srecommend OR r.srecommend<>m.srecommend OR r.srecommend<> s.srecommend)


	INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
	SELECT 65,mem.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer mem WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.customer m WITH(NOLOCK) ON mem.mrecommend=m.CustID
		INNER JOIN CheckCustDB.dbo.customer r WITH(NOLOCK) ON mem.recommend=r.CustID
	WHERE r.mrecommend<>m.mrecommend AND mem.roleid=1 AND mem.srecommend=@srecommend AND mem.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate		

	INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
	SELECT 66,c.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer c WITH(NOLOCK) 
		INNER JOIN CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) ON c.CustID=ci.CustID
	WHERE c.srecommend=@srecommend AND c.roleid=1  AND c.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate
		AND (c.mrecommend<>ci.mrecommend OR c.recommend<>ci.recommend OR c.srecommend<>ci.srecommend)
		
	INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
	SELECT 66,c.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer c WITH(NOLOCK) 
		INNER JOIN CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) ON c.CustID=ci.CustID
	WHERE c.srecommend=@srecommend AND c.roleid=2  AND c.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate
		AND (c.mrecommend<>ci.mrecommend OR c.recommend<>ci.recommend OR c.srecommend<>ci.srecommend)
	
	INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
	SELECT 66,c.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer c WITH(NOLOCK) 
		INNER JOIN CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) ON c.CustID=ci.CustID
	WHERE c.srecommend=@srecommend AND c.roleid=3  AND c.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate 
		AND (c.mrecommend<>ci.mrecommend OR c.recommend<>ci.recommend OR c.srecommend<>ci.srecommend)
	
	INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
	SELECT 66,c.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer c WITH(NOLOCK) 
		INNER JOIN CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) ON c.CustID=ci.CustID
	WHERE c.srecommend=@srecommend AND c.roleid=4  AND c.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate
		AND (c.mrecommend<>ci.mrecommend OR c.recommend<>ci.recommend OR c.srecommend<>ci.srecommend)
	
	INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
	SELECT 67,c.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer c WITH(NOLOCK) 	
	WHERE c.srecommend=@srecommend AND c.roleid=4 		
		AND c.Custid NOT IN (SELECT custid FROM CheckCustDB.dbo.Custsuper WITH(NOLOCK)) 
		AND c.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate	

	INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
	SELECT 68,c.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer c WITH(NOLOCK) 
	WHERE c.srecommend=@srecommend AND c.roleid=3
		AND c.Custid NOT IN (SELECT custid FROM CheckCustDB.dbo.Custmaster WITH(NOLOCK)) 
		AND c.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate

	INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
	SELECT 69,c.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer c WITH(NOLOCK) 
	WHERE c.srecommend=@srecommend AND c.roleid=2
		AND c.Custid NOT IN (SELECT custid FROM CheckCustDB.dbo.CustAgent WITH(NOLOCK)) 
		AND c.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate

	INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
	SELECT 71,ma.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer ma WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON ma.srecommend=ci.custid
	WHERE ma.currency<>ci.Currency AND ma.roleid=3 AND ma.srecommend=@srecommend AND ma.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate

	INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
	SELECT 72,ag.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer ag WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON ag.mrecommend=c.custid
	WHERE ag.currency<>c.Currency AND ag.roleid=2 AND ag.srecommend=@srecommend AND ag.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate

	INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
	SELECT 72,ag.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer ag WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON ag.srecommend=ci.custid
	WHERE ag.currency<>ci.Currency AND ag.roleid=2 AND ag.srecommend=@srecommend AND ag.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate

	INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
	SELECT 73,mem.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer mem WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.customer r WITH(NOLOCK) ON mem.recommend=r.custid
	WHERE mem.roleid=1 AND mem.srecommend=@srecommend AND mem.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate AND mem.currency<>r.Currency

	INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
	SELECT 73,mem.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer mem WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON mem.mrecommend=ci.custid
	WHERE	mem.roleid=1 AND mem.srecommend=@srecommend AND mem.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate AND mem.currency<>ci.Currency

	INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
	SELECT 73,mem.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer mem WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.customer ci WITH(NOLOCK) ON mem.srecommend=ci.custid
	WHERE mem.roleid=1 AND mem.srecommend=@srecommend AND mem.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate AND mem.currency<>ci.Currency 

	INSERT INTO #DirectMaster (CustID,srecommend)
	SELECT ci.custid,ci.srecommend
	FROM CheckCustDB.dbo.Customer ci with(nolock)
	INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON ci.custid=c.custid
	WHERE ci.srecommend=@srecommend AND ci.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate
		AND ci.custid NOT IN (SELECT custid from CheckCustDB.dbo.Acc_CustDirect WITH(NOLOCK))
		AND ci.srecommend IN (SELECT custid from CheckCustDB.dbo.Acc_CustDirect WITH(NOLOCK))
		AND ci.roleid=3 AND ci.srecommend <=100 
		AND c.Enabled=1
	
	--- get direct agent
	INSERT INTO #DirectAgent (CustID,srecommend,mrecommend)
	SELECT ci.custid,ci.srecommend,ci.mrecommend
	FROM CheckCustDB.dbo.Customer ci WITH(NOLOCK)
	INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON ci.custid=c.custid
	WHERE  ci.srecommend=@srecommend AND ci.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate
		AND ci.custid NOT IN (SELECT custid from CheckCustDB.dbo.Acc_CustDirect WITH(NOLOCK))
		AND ci.mrecommend IN (SELECT custid from CheckCustDB.dbo.Acc_CustDirect WITH(NOLOCK))
		AND ci.roleid=2 AND ci.srecommend <=100
		AND c.Enabled=1
	
	INSERT INTO #DirectMember(CustID,srecommend,mrecommend,recommend)
	SELECT c.custid,c.srecommend,c.mrecommend,c.recommend
	FROM CheckCustDB.dbo.Customer c WITH(NOLOCK)
	INNER JOIN CheckCustDB.dbo.Customer ca (nolock) on c.recommend=ca.custid 
	INNER JOIN CheckCustDB.dbo.custInfo ci WITH(NOLOCK) ON ci.custid=c.custid
	WHERE ci.srecommend=@srecommend 
		AND	c.custid NOT IN (SELECT custid from CheckCustDB.dbo.Acc_CustDirect WITH(NOLOCK))
		AND c.recommend IN (SELECT custid from CheckCustDB.dbo.Acc_CustDirect WITH(NOLOCK))
		AND c.roleid=1 AND c.srecommend <=100
		AND c.creatdate BETWEEN @CurrentDate-4 AND @CurrentDate
		AND ci.Enabled=1

	INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
	SELECT 75,t.Custid,GETDATE()
	FROM #DirectMaster t WHERE t.CustID NOT IN (SELECT CustID FROM CheckCustDB.dbo.CustDirectAccount WITH(NOLOCK))

	INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
	SELECT 75,t.Custid,GETDATE()
	FROM #DirectAgent t WHERE t.CustID NOT IN (SELECT CustID FROM CheckCustDB.dbo.CustDirectAccount WITH(NOLOCK))

	INSERT INTO CheckCustInfoResult (RuleID,[CustID],CreatedDate)
	SELECT 75,t.Custid,GETDATE()
	FROM #DirectMember t WHERE t.CustID NOT IN (SELECT CustID FROM CheckCustDB.dbo.CustDirectAccount WITH(NOLOCK))

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

	INSERT INTO #tempUsername(Username2)
	SELECT Username2	
	FROM  CheckCustDB.dbo.Customer  WITH(NOLOCK) 
	WHERE srecommend=@srecommend
		AND roleid=1
		AND creatdate BETWEEN @CurrentDate-4 AND @CurrentDate
		GROUP BY Username2 HAVING COUNT(Username2)>1

	INSERT INTO CheckCustInfoResult (RuleID,CustID,CreatedDate)
	SELECT 70,c.Custid,GETDATE()
	FROM CheckCustDB.dbo.customer c WITH(NOLOCK) 
		INNER JOIN #tempUsername t ON c.username2=t.username2

	DROP TABLE #Dummy
	DROP TABLE #DirectAgent
	DROP TABLE #DirectMaster
	DROP TABLE #DirectMember
	DROP TABLE #tempUsername

END 

