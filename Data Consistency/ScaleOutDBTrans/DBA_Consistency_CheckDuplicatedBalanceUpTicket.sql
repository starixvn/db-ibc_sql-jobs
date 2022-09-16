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
	
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @WinlostDate SMALLDATETIME = NULL
	SET @WinlostDate = (SELECT	TOP 1  winlostdate
						FROM	bodb02.dbo.Transfer t WITH(NOLOCK)
						WHERE	bettype = 20000 AND custid = 3)

	SELECT  custid AS Custid, winlostdate AS WinlostDate, COUNT(1) AS TotalCount
	FROM	bodb02.dbo.Transfer WITH (NOLOCK) 
	WHERE	bettype = 20000 AND winlostdate = @WinlostDate
	GROUP BY custid, winlostdate
	HAVING COUNT(1) > 1

END
