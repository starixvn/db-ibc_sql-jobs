/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_CheckMBUTicketCount]
	@Bettype SMALLINT = 0
AS 
/*
Created by: 20220819@Victoria
Task: Check MoveBet/BalanceUp Ticket Count
DB: DBCONSISTENCY-bodb_Consistency
Revisions:
	- 20220907@Victoria: Rule #50 - Check ticket count of 19999/20000 with group by SiteDBGroupID, winlostdate [Redmine:#175881]
	
*/
BEGIN
	SET NOCOUNT ON

	IF @Bettype = 19999
	BEGIN

		DECLARE @Days AS TABLE (ScheduleId TINYINT, RunningDay DATETIME)
		INSERT INTO @Days (ScheduleId, RunningDay)
		EXEC DBCTG.bodb02.dbo.Task_MoveBetsDayByScheduleSel

		IF @@ROWCOUNT = 0
		BEGIN
			SELECT 0 AS SiteDBGroupID, RunningDay AS WinlostDate, 0 AS TotalCount
			FROM @Days
		
			RETURN
		END

		SELECT  s.SiteDBGroupID, b.winlostdate AS WinlostDate, COUNT(1) AS TotalCount
		FROM	bodb02.dbo.Transfer b WITH (NOLOCK) 
			INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.custid = b.CustId
			INNER JOIN bodb02.dbo.Site s WITH (NOLOCK) ON s.site = c.site
		WHERE	b.bettype = @Bettype 
			AND b.winlostdate IN (SELECT RunningDay FROM @Days)
			AND s.SiteDBGroupID > 0
		GROUP BY s.SiteDBGroupID, b.winlostdate

	END
	ELSE IF @Bettype = 20000
	BEGIN
		DECLARE @WinlostDate SMALLDATETIME = NULL
		SET @WinlostDate = (SELECT	TOP 1  winlostdate
							FROM	bodb02.dbo.Transfer t WITH(NOLOCK)
							WHERE	bettype = 20000 AND custid = 3)

		SELECT  s.SiteDBGroupID, b.winlostdate AS WinlostDate, COUNT(1) AS TotalCount
		FROM	bodb02.dbo.Transfer b WITH (NOLOCK) 
			INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.custid = b.CustId
			INNER JOIN bodb02.dbo.Site s WITH (NOLOCK) ON s.site = c.site
		WHERE	b.bettype = @Bettype 
			AND b.winlostdate = @WinlostDate
			AND s.SiteDBGroupID > 0
		GROUP BY s.SiteDBGroupID, b.winlostdate
	END
	
END
GO