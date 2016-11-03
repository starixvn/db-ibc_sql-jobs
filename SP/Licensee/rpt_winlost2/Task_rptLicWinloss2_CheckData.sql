USE [bodb_LicenseeReport]
GO
ALTER PROCEDURE [dbo].[Task_rptLicWinloss2_CheckData] @WinlostDate SMALLDATETIME
AS
/*
	Created: 20150910@Patrick
	Task : Check & correct data for licensee winloss2
	DB: DBLIC.bodb_LicenseeReport
	Original:
	Revisions:
	- 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @S_Winlost MONEY, @T_Winlost MONEY, @S_Turnover MONEY, @T_Turnover MONEY, @S_BetCount MONEY, @T_BetCount MONEY
	
	SELECT @S_Winlost = SUM(b.winlost - b.actual_stake)
		, @S_Turnover = SUM(CASE WHEN b.liveawayscore = 0 AND b.bettype IN(33,43) THEN ABS(b.stake/2) ELSE ABS(b.stake) END) --TurnOver
		, @S_BetCount = COUNT(b.TransId) --BetCount
	FROM bodb02.dbo.bettrans14 b WITH(NOLOCK)
		INNER JOIN bodb02.dbo.customer c WITH (NOLOCK) ON b.custid = c.custid
	WHERE b.winlostdate = @WinlostDate
		AND c.srecommend IN (SELECT custid FROM bodb02.dbo.f_DepSuper_1('All'))
		AND b.statusID IN (101,111,112,113) --REJECT, DRAW, WON, LOSE
		AND b.bettype <= 19999
		AND c.roleid = 1
	OPTION (RECOMPILE)

	SELECT @T_Winlost = SUM(winlost)
		, @T_Turnover = SUM(turnover)
		, @T_BetCount = SUM(BetCount)
	FROM dbo.rptLicWinloss2 b WITH(NOLOCK)
		INNER JOIN bodb02.dbo.customer c WITH (NOLOCK) ON b.custid = c.custid
	WHERE b.winlostdate = @WinlostDate
		AND c.srecommend IN (SELECT custid FROM bodb02.dbo.f_DepSuper_1('All'))
		AND b.statusID IN (101,111,112,113,114,115) --REJECT, DRAW, WON, LOSE, HALF-WON, HALF-LOSE
		AND b.bettype <= 19999
		AND b.roleid = 1

	--check winlost
	IF ISNULL(@S_Winlost, 0) <> ISNULL(@T_Winlost, 0)
		OR ISNULL(@S_Turnover, 0) <> ISNULL(@T_Turnover, 0)
		OR ISNULL(@S_BetCount, 0) <> ISNULL(@T_BetCount, 0)
	BEGIN
		PRINT 'Re-generate data for RptLicWinloss2 on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' date.'
				EXEC dbo.Task_DailyRptLicWinloss2 @winlostdate = @WinlostDate
		RETURN
	END
END