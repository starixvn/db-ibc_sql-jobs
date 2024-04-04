/*<info serverAlias="DBCONSISTENCY-bodb_Consistency, DBAGE-bodb02, DBACC-bodb02" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_CheckMBUTicketCount]
	@Bettype SMALLINT = 0
AS 
/*
Created by: 20220819@Victoria
Task: Check MoveBet/BalanceUp Ticket Count
DB: DBCONSISTENCY-bodb_Consistency, DBAGE-bodb02, DBACC-bodb02
Revisions:
	- 20220907@Victoria: Rule #50 - Check ticket count of 19999/20000 with group by SiteDBGroupID, winlostdate [Redmine:#175881]
	- 20230915@July: Detect data consistency SiteDB and DBTP - Enhancement for rules #50 [Redmine:#194038]
	- 20231109@July: Data consistency - Add config DBAGE & DBACC [Redmine:#196690]
	- 20231114@July: Data Consistency - Update Rule #50 - Check data details [Redmine:#196572]
	- 20240405@July: Change the way of getting data - remove duplicate if page split occurs [Redmine:#202585]
	
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #tmp_betticketchecksum_detail
	(
		TransId BIGINT, SiteDBGroupID SMALLINT
	  , custid INT, WinlostDate SMALLDATETIME, stake MONEY, actual_stake MONEY
	  , winlost MONEY, awinlost MONEY, mwinlost MONEY, swinlost MONEY
	  , playercomm MONEY, comm MONEY, acomm MONEY, scomm MONEY
	)

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

		INSERT INTO #tmp_betticketchecksum_detail (
		    TransId, SiteDBGroupID
		  , custid, WinlostDate, stake, actual_stake
		  , winlost, awinlost, mwinlost, swinlost
		  , playercomm, comm, acomm, scomm
		)
		SELECT b.TransId, s.SiteDBGroupID
			  , b.custid, b.WinlostDate, b.stake, b.actual_stake
			  , b.Winlost, b.aWinlost, b.mWinlost, b.sWinlost
			  , b.playerComm, b.Comm, b.aComm, b.sComm
		FROM	bodb02.dbo.Transfer b WITH (NOLOCK) 
			INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.custid = b.CustId
			INNER JOIN bodb02.dbo.Site s WITH (NOLOCK) ON s.site = c.site
		WHERE	b.bettype = @Bettype 
			AND b.WinlostDate IN (SELECT RunningDay FROM @Days)
			AND s.SiteDBGroupID > 0

		-- Remove duplicate transid if page split occurs
		;WITH cteDuplicateTransId
		AS(
			SELECT	TransId
					,ROW_NUMBER() OVER(PARTITION BY TransId ORDER BY TransId) as rn 
			FROM	#tmp_betticketchecksum_detail
		)
		DELETE 
		FROM	cteDuplicateTransId
		WHERE	rn > 1

		SELECT  SiteDBGroupID, WinlostDate, COUNT(1) AS TotalCount
			    ,CHECKSUM_AGG(CHECKSUM( custid, WinlostDate, stake, actual_stake
									  , Winlost, aWinlost, mWinlost, sWinlost
									  , playerComm, Comm, aComm, sComm )) AS TotalCheckSumAgg
		FROM #tmp_betticketchecksum_detail
		GROUP BY SiteDBGroupID
			   , WinlostDate

	END
	ELSE IF @Bettype = 20000
	BEGIN
		DECLARE @BalanceUpDate SMALLDATETIME = NULL
		EXEC bodb02.dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @BalanceUpDate OUTPUT

		INSERT INTO #tmp_betticketchecksum_detail (
		    TransId, SiteDBGroupID
		  , custid, WinlostDate, stake, actual_stake
		  , winlost, awinlost, mwinlost, swinlost
		  , playercomm, comm, acomm, scomm
		)
		SELECT b.TransId, s.SiteDBGroupID
			  , b.custid, b.WinlostDate, b.stake, b.actual_stake
			  , b.Winlost, b.aWinlost, b.mWinlost, b.sWinlost
			  , b.playerComm, b.Comm, b.aComm, b.sComm
		FROM	bodb02.dbo.Transfer b WITH (NOLOCK) 
			INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.custid = b.CustId
			INNER JOIN bodb02.dbo.Site s WITH (NOLOCK) ON s.site = c.site
		WHERE	b.bettype = @Bettype 
			AND b.WinlostDate = @BalanceUpDate
			AND s.SiteDBGroupID > 0

		-- Remove duplicate transid if page split occurs
		;WITH cteDuplicateTransId
		AS(
			SELECT	TransId
					,ROW_NUMBER() OVER(PARTITION BY TransId ORDER BY TransId) as rn 
			FROM	#tmp_betticketchecksum_detail
		)
		DELETE 
		FROM	cteDuplicateTransId
		WHERE	rn > 1

		SELECT  SiteDBGroupID, WinlostDate, COUNT(1) AS TotalCount
			    ,CHECKSUM_AGG(CHECKSUM( custid, winlostdate, stake, actual_stake
									  , Winlost, aWinlost, mWinlost, sWinlost
									  , playerComm, Comm, aComm, sComm )) AS TotalCheckSumAgg
		FROM #tmp_betticketchecksum_detail
		GROUP BY SiteDBGroupID
			   , WinlostDate
	END
	
	DROP TABLE #tmp_betticketchecksum_detail
END
GO
