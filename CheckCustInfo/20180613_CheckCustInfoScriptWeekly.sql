

/*
Created: 20180613@Winnie
Task: check CustInfo setting for credit customers 
DB: DB054.CheckResultDB
Revisions:

*/

USE CheckResultDB
GO

DECLARE @srecommend INT
CREATE TABLE #supers (custid int,isfinished bit default(0))
	
INSERT INTO #supers(custid)
SELECT ci.custid
FROM CheckCustDB.dbo.Customer ci WITH(NOLOCK)
WHERE ci.roleid = 4 			

WHILE (1 = 1)
BEGIN
	UPDATE TOP (1) #Supers
	SET isfinished = 1
		,@srecommend = custid			
	WHERE isfinished = 0
	
	IF @@ROWCOUNT = 0 BREAK	
		
	EXEC DBA_CheckCustInfoWeekly @srecommend=@srecommend
END

DROP TABLE #supers



