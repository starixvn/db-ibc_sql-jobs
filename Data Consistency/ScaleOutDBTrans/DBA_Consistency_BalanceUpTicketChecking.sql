/*<info serverAlias="DBCONSISTENCY-bodb_Consistency,DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_BalanceUpTicketChecking]
AS 
/*
Created by: 20220819@Victoria
Task: Check BalanceUp Ticket
DB: DBCONSISTENCY-bodb_Consistency,DBSIG-bodb02
Revisions:
	- 20220819@Victoria: Rule #50 - Check BalanceUp Ticket [Redmine:#175881]
	
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @WinlostDate SMALLDATETIME = NULL
	SET @WinlostDate = (SELECT	TOP 1  winlostdate
						FROM	bodb02.dbo.Transfer t WITH(NOLOCK)
						WHERE	bettype = 20000 AND custid = 3)

	SELECT  custid AS Custid, COUNT(1) AS TotalCount
	FROM	bodb02.dbo.Transfer WITH (NOLOCK, INDEX=IX_WinlostDate) 
	WHERE	bettype = 20000 AND winlostdate = @WinlostDate
	GROUP BY custid
	HAVING COUNT(1) > 1

END
