/*<info serverAlias="DBCONSISTENCY-bodb_Consistency,DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_CheckDuplicatedBalanceUpTicket]
AS 
/*
Created by: 20220819@Victoria
Task: Check BalanceUp Ticket Duplicated
DB: DBCONSISTENCY-bodb_Consistency,DBSIG-bodb02
Revisions:
	- 20220819@Victoria: Rule #50 - Check BalanceUp Ticket.
									Alert if exist more than 1 row of custid with group by custid and winlostdate [Redmine:#175881]
	- 20230705@July: Check ticket data consistency - Add SPs for SiteDB3 [Redmine:#190601]
	- 20230915@July: Detect data consistency SiteDB and DBTP - Enhancement for rules #50 [Redmine:#194038]
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @BalanceUpDate SMALLDATETIME = NULL
	EXEC bodb02.dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @BalanceUpDate OUTPUT

	SELECT  custid AS Custid, winlostdate AS WinlostDate, COUNT(1) AS TotalCount
	FROM	bodb02.dbo.Transfer WITH (NOLOCK) 
	WHERE	bettype = 20000 AND winlostdate = @BalanceUpDate
	GROUP BY custid, winlostdate
	HAVING COUNT(1) > 1

END
