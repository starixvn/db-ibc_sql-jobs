/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[ScaleOut_Consistency_MoveBetTicketChecking] @row_cnt INT OUTPUT
AS 
/*
Created by: 20220819@Victoria
Task: Check MoveBet Ticket
DB: DBCONSISTENCY-bodb_Consistency
Revisions:
	- 20220819@Victoria: Check MoveBet Ticket [Redmine:#175881]
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @MovebetDate SMALLDATETIME = NULL
	EXEC dbo.NAP_Admin_GetMovebetDate	@MovebetDate = @MovebetDate OUTPUT
	--SELECT @MovebetDate

	SET @row_cnt = 0

	SELECT  @row_cnt = COUNT(1)
	FROM dbo.Transfer WITH (NOLOCK) 
	WHERE	bettype = 19999 
		AND WinlostDate = @MovebetDate
	GROUP BY custid
	HAVING COUNT(1) > 1

END