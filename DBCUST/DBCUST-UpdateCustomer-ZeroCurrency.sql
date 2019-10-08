/*
	- Creator: 20191008@Bobby
	- Task: Correct zero currency super customer [RedmineID: #121652]
	- DB: DBCUST.CustDB

*/
USE CustDB
GO

update ci WITH(UPDLOCK)
SET currency = 20
from dbo.custinfo ci
where custid in (1285658,1291378) and roleid = 4 and currency = 0
GO

update ci WITH(UPDLOCK)
SET currency = 20
from dbo.Customer ci
where custid in (1285658,1291378) and roleid = 4 and currency = 0