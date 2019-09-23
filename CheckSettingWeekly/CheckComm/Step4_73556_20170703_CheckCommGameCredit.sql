

/*
Created: 20170427@Winnie
Task: Monthly check comm setting for credit customers - [Redmine:73556]
DB: DB054.CheckResultDB
Revisions:

*/

USE CheckResultDB
GO

DECLARE @srecommend INT
CREATE TABLE #supers (custid int,isfinished bit default(0))
	
INSERT INTO #supers(custid)
SELECT ci.custid
FROM CheckCustDB.dbo.custInfo ci WITH(NOLOCK) 
	INNER JOIN CheckCustDB.dbo.custSuper s WITH(NOLOCK) ON ci.custid=s.custid
WHERE ci.roleid = 4 	
	AND ci.custid NOT IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK))
	AND ci.Enabled=1
	AND s.IsInternal = 0

WHILE (1 = 1)
BEGIN
	UPDATE TOP (1) #Supers
	SET isfinished = 1
		,@srecommend = custid			
	WHERE isfinished = 0
	
	IF @@ROWCOUNT = 0 BREAK	

	EXEC DBA_CheckCommGame_Credit @srecommend=@srecommend,@SportType=0,@RuleID=0
	
END

DROP TABLE #supers
