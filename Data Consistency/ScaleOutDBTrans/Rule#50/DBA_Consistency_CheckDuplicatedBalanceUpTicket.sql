/*<info serverAlias="DBCONSISTENCY-bodb_Consistency, DBSIG-bodb02, DBAGE-bodb02, DBACC-bodb02" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_CheckDuplicatedBalanceUpTicket]
(
	 @CustId			INT = NULL
   , @WinlostDate		SMALLDATETIME = NULL
   , @Retry			    INT = 0
)
AS 
/*
Created by: 20220819@Victoria
Task: Check BalanceUp Ticket Duplicated
DB: DBCONSISTENCY-bodb_Consistency, DBSIG-bodb02, DBAGE-bodb02, DBACC-bodb02
Revisions:
	- 20220819@Victoria: Rule #50 - Check BalanceUp Ticket.
									Alert if exist more than 1 row of custid with group by custid and winlostdate [Redmine:#175881]
	- 20230705@July: Check ticket data consistency - Add SPs for SiteDB3 [Redmine:#190601]
	- 20230915@July: Detect data consistency SiteDB and DBTP - Enhancement for rules #50 [Redmine:#194038]
	- 20231109@July: Data consistency - Add config DBAGE & DBACC [Redmine:#196690]
	- 20240625@July: Change the way of getting data - remove duplicate if page split occurs [Redmine:#202585]
	
*/
BEGIN
	SET NOCOUNT ON
	
	IF @Retry = 1
	BEGIN
		SELECT  CustId, winlostdate AS WinlostDate, COUNT(1) AS TotalCount
		FROM	bodb02.dbo.Transfer WITH (NOLOCK) 
		WHERE	bettype = 20000 
			AND CustId = @CustId
			AND winlostdate = @WinlostDate
		GROUP BY CustId, winlostdate
		HAVING COUNT(1) > 1

		RETURN;
	END

	DECLARE @BalanceUpDate SMALLDATETIME = NULL
	EXEC bodb02.dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @BalanceUpDate OUTPUT

	SELECT  CustId, winlostdate AS WinlostDate, COUNT(1) AS TotalCount
	FROM	bodb02.dbo.Transfer WITH (NOLOCK) 
	WHERE	bettype = 20000 AND winlostdate = @BalanceUpDate
	GROUP BY CustId, winlostdate
	HAVING COUNT(1) > 1


END
