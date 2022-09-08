/*<info serverAlias="DBCONSISTENCY-bodb_Consistency,DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_CheckDuplicatedMoveBetTicket]
AS 
/*
Created by: 20220819@Victoria
Task: Check MoveBet Ticket Duplicated
DB: DBCONSISTENCY-bodb_Consistency,DBSIG-bodb02
Revisions:
	- 20220819@Victoria: Rule #50 - Check MoveBet Ticket,
									Alert if exist more than 1 row with group by custid and winlostdate [Redmine:#175881]
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Days AS TABLE (ScheduleId TINYINT, RunningDay DATETIME)
	INSERT INTO @Days (ScheduleId, RunningDay)
	EXEC DBCTG.bodb02.dbo.Task_MoveBetsDayByScheduleSel

	IF @@ROWCOUNT = 0
		RETURN

	SELECT  custid AS Custid, WinlostDate, COUNT(1) AS TotalCount
	FROM	bodb02.dbo.Transfer WITH (NOLOCK) 
	WHERE	bettype = 19999 
		AND WinlostDate IN (SELECT runningDay FROM @Days)
	GROUP BY custid, WinlostDate
	HAVING COUNT(1) > 1

END
GO