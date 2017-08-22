/*
Created: 20170328@Helen
Task: Monthly check BetLimit setting for credit/deposit customers - [Redmine:73556]
DB: DB054.CheckResultDB
Revisions:
For products using table custinfo to manage status	
*/
USE CheckResultDB
GO
EXEC DBA_CheckBetLimit_Deposit
GO
EXEC DBA_CheckBetLimit3rd_Deposit
GO