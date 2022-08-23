/*<info serverAlias="DBCONSISTENCY-bodb_Consistency,DBSIG-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_BalanceUpTicketChecking] @row_cnt INT OUTPUT
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
	
	SET @row_cnt = 0

	SELECT  @row_cnt = COUNT(1)
	FROM dbo.Transfer WITH (NOLOCK) 
	WHERE	bettype = 20000
	GROUP BY custid
	HAVING COUNT(1) > 1

END
