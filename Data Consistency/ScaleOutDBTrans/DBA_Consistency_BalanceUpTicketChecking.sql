/*<info serverAlias="DBCONSISTENCY-bodb_Consistency,DBSIG-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_BalanceUpTicketChecking]
AS 
/*
Created by: 20220819@Victoria
Task: Check BalanceUp Ticket
DB: DBCONSISTENCY-bodb_Consistency,DBSIG-bodb02
Revisions:
	- 20220819@Victoria: Check BalanceUp Ticket [Redmine:#175881]
	
*/
BEGIN
	SET NOCOUNT ON
	
	SELECT  COUNT(1) AS Total_Count
	FROM	bodb02.dbo.Transfer WITH (NOLOCK) 
	WHERE	bettype = 20000
	GROUP BY custid
	HAVING COUNT(1) > 1

END
