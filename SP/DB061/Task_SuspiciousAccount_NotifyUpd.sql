/*<info serverAlias="DBCUST-CustDB" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_SuspiciousAccount_NotifyUpd]
AS
/*
	Created: 20200309@Elodie
	Task: Update notify status of SuspiciousAccount
	DB: DBCUST/CustDB
	
	Revisions:
		- 20200309@Elodie: Initialize SP [RedmineID: #129119]
*/

BEGIN
	SET NOCOUNT ON
	CREATE TABLE #Notify2List (CustId INT)
	
	INSERT INTO #Notify2List (CustId)
	EXEC DBACC.bodb02.dbo.Task_SuspiciousAccount_CheckTicket

	UPDATE sc 
	SET sc.NotifyStatus2 = 1
	FROM dbo.SuspiciousCust sc WITH (ROWLOCK)
		INNER JOIN #Notify2List l ON l.CustId = sc.CustID

	DROP TABLE #Notify2List
END
GO