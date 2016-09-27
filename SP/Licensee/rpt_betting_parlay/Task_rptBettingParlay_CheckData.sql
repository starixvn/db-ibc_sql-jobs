USE [bodb_LicenseeReport]
GO
ALTER PROCEDURE [dbo].[Task_rptBettingParlay_CheckData] @WinlostDate SMALLDATETIME
AS
/*
	Created: 20150910@Patrick
	Task : Check & correct data for rptBettingParlay
	DB: DBLIC.bodb_LicenseeReport
	Original:
	Revisions:	
	- 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @S_Winlost MONEY, @T_Winlost MONEY, @S_Turnover MONEY, @T_Turnover MONEY, @S_BetCount MONEY, @T_BetCount MONEY
	
	--get winlost
	SELECT @S_Winlost = SUM(b.winlost - b.actual_stake)
		, @S_Turnover = SUM(b.stake)
		, @S_BetCount = COUNT(b.TransId)
	FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)  
		INNER JOIN bodb_licensee.dbo.licenseecust lc WITH (NOLOCK) ON b.recommend = lc.CustID
	WHERE b.bettype IN (9,29)  
		AND b.custid > 0  
		AND b.statusid NOT IN (0,101,102,121)
		AND b.winlostdate = @winlostdate

	SELECT @T_Winlost = SUM(winloss)
		, @T_Turnover = SUM(Turnover)
		, @T_BetCount = SUM(BetCount)
	FROM dbo.rpt_BettingParlay b WITH(NOLOCK)
	WHERE b.rptDate = @WinlostDate
	
	--if diff then generate data again
	IF ISNULL(@S_Winlost, 0) <> ISNULL(@T_Winlost, 0)
		OR ISNULL(@T_Turnover, 0) <> ISNULL(@S_Turnover, 0)
		OR ISNULL(@T_BetCount, 0) <> ISNULL(@S_BetCount, 0)
	BEGIN
		PRINT 'Re-generate data for rptBettingParlay on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' date.'
		EXEC dbo.GEN_rptBetting_Parlay14 @datefrom = @WinlostDate, @dateto = @WinlostDate
		RETURN
	END

END