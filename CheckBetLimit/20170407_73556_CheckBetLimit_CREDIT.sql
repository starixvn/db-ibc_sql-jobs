/*
Created: 20170328@Helen
Task: Monthly check BetLimit setting for credit/deposit customers - [Redmine:73556]
DB: DB054.CheckResultDB
Revisions:

*/
USE CheckResultDB
GO
EXEC DBA_CheckBetLimit_Credit
GO
EXEC DBA_CheckBetLimit3rd_Credit
GO