/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_rptLicWinlossGMT_CheckData] 
	@WinlostDate SMALLDATETIME
AS
/*
 	Created: 20171130@Sophia
	Task: Check sum for RptLicWinlossGMT vs bettrans14
	DB: DBLIC.bodb_LicenseeReport
	Revisions:  
	- 20171130@Sophia: initial data. Apply for Sportsbook first [redmine: #84932]
	
	EXEC Task_rptLicWinlossGMT_CheckData '2017-11-30'

*/
BEGIN
	SET NOCOUNT ON
	DECLARE @S_Winlost MONEY, @T_Winlost MONEY, @S_Turnover MONEY, @T_Turnover MONEY, @S_BetCount INT, @T_BetCount INT,
			@S_AWinlost MONEY, @T_AWinlost MONEY, @S_Comm MONEY, @T_Comm MONEY, @S_BetEffective MONEY, @T_BetEffective MONEY,
			@S_MWinlost MONEY, @T_MWinlost MONEY, @S_SWinlost MONEY, @T_SWinlost MONEY, @S_PlayerComm MONEY, @T_PlayerComm MONEY,
			@S_AComm MONEY, @T_AComm MONEY, @S_SComm MONEY, @T_SComm MONEY
	
	SELECT @S_Winlost = SUM(b.winlost - b.actual_stake)
		, @S_Turnover = SUM(CASE WHEN b.liveawayscore = 0 AND b.bettype IN(33,43) THEN ABS(b.stake/2) ELSE ABS(b.stake) END) --TurnOver
		, @S_BetCount = COUNT(b.TransId) --BetCount
		, @S_AWinlost = SUM(awinlost)
		, @S_Comm = SUM(comm)
		, @S_BetEffective = SUM(CASE WHEN b.statusID IN (112,113)   
									THEN ABS(winlost-actual_stake)
									ELSE 0  
								END)
		, @S_MWinlost = SUM(mwinlost)
		, @S_SWinlost = SUM(ISNULL(swinlost,0))
		, @S_PlayerComm = SUM(playercomm)
		, @S_AComm = SUM(acomm)
		, @S_SComm = SUM(ISNULL(scomm,0))
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
		, @T_AWinlost = SUM(awinlost)
		, @T_Comm = SUM(comm)
		, @T_BetEffective = SUM(BetEffective)
		, @T_MWinlost = SUM(mwinlost)
		, @T_SWinlost = SUM(swinlost)
		, @T_PlayerComm = SUM(playercomm)
		, @T_AComm = SUM(acomm)
		, @T_SComm = SUM(scomm)		
	FROM dbo.rptLicWinlossGMT b WITH(NOLOCK)
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
		OR ISNULL(@S_AWinlost, 0) <> ISNULL(@T_AWinlost, 0)
		OR ISNULL(@S_Comm, 0) <> ISNULL(@T_Comm, 0)
		OR ISNULL(@S_BetEffective, 0) <> ISNULL(@T_BetEffective, 0)
		OR ISNULL(@S_MWinlost, 0) <> ISNULL(@T_MWinlost, 0)
		OR ISNULL(@S_SWinlost, 0) <> ISNULL(@T_SWinlost, 0)
		OR ISNULL(@S_PlayerComm, 0) <> ISNULL(@T_PlayerComm, 0)
		OR ISNULL(@S_AComm, 0) <> ISNULL(@T_AComm, 0)
		OR ISNULL(@S_SComm, 0) <> ISNULL(@T_SComm, 0)
	BEGIN
		PRINT 'Re-generate data for RptLicWinlossGMT on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' date.'
				EXEC dbo.Task_DailyRptLicWinlossGMT_bettrans14 @winlostdate = @WinlostDate
		RETURN
	END
END
GO