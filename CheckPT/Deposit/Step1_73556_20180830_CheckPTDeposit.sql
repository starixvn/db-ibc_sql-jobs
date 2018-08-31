

/*
Created: 20180822@Winnie
Task: Monthly check PT for deposit customers - [Redmine:73556]
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
	INNER JOIN CheckCustDB.dbo.Dep_CustSuper s WITH(NOLOCK) ON ci.custid=s.custid
WHERE ci.roleid = 4 		
	AND ci.Enabled=1

WHILE (1 = 1)
BEGIN
	UPDATE TOP (1) #Supers
	SET isfinished = 1
		,@srecommend = custid			
	WHERE isfinished = 0
	
	IF @@ROWCOUNT = 0 BREAK	
		
	EXEC DBA_CheckPositionTaking_Deposit @srecommend=@srecommend,@RuleID=0
END

DROP TABLE #supers
