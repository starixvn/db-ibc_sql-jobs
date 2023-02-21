/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" executers="" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_rptLicWinloss2_CheckData]
	@WinLostDate SMALLDATETIME
AS

/*
	Created: 20150910@Patrick
	Task: Check & correct data for licensee winloss2
	DB: DBLIC.bodb_LicenseeReport
	Revisions:
		- 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
		- 20170508@Paul: Check awinlost, comm - [Redmine: #76206]
		- 20170703@Paul: Check more columns - [Redmine: #79262]
		- 20190306@Amanda: Implement PP Promotion Prize [RedmineID: #109471]
		- 20191122@Amanda: Implement PP Tournament Prize [RedmineID: #123804]
		- 20200714@Hogan: Add 7 games for Jackpot and 2 bettype for Contribution (4297) and Jackpot Prize (4298) [RedmineID: #137290]
		- 20200728@Hogan: Integrate SA Gaming [RedmineID: #128493]
		- 20201020@Hogan: Integrate Arcadia Gaming Bonus [RedmineID: #143648]
		- 20201104@Hogan: Add new sport Saba.club Free Bets [RedmineID: #142369]
		- 20210119@Hogan: Integrate Four Guardians [RedmineID: #148100]
		- 20210518@Hogan: Integrate Vgaming [RedmineID: #151583]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
		- 20220106@Kos: Hotfix - Missing turnover of Vgaming Jackpot [RedmineID: #167065]
		- 20220126@Kos: Integrate Spadegaming Jackpot [RedmineID: #167035]
		- 20220223@Kos: Integrate Allbet Promotion [RedmineID: #167524]
		- 20221122@Evan: Integrate Player Tips [RedmineID: #180590]
		- 20230208@Evan: Inteagrate SG promotion prize [RedmineID: #183497]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @S_Winlost MONEY, @T_Winlost MONEY, @S_Turnover MONEY, @T_Turnover MONEY, @S_BetCount INT, @T_BetCount INT,
			@S_AWinlost MONEY, @T_AWinlost MONEY, @S_Comm MONEY, @T_Comm MONEY, @S_BetEffective MONEY, @T_BetEffective MONEY,
			@S_MWinlost MONEY, @T_MWinlost MONEY, @S_SWinlost MONEY, @T_SWinlost MONEY, @S_PlayerComm MONEY, @T_PlayerComm MONEY,
			@S_AComm MONEY, @T_AComm MONEY, @S_SComm MONEY, @T_SComm MONEY, @S_BuyBackAmt MONEY, @T_BuyBackAmt MONEY,
			@S_BABuyBackAmt MONEY, @T_BABuyBackAmt MONEY

	SELECT @S_Winlost = SUM(b.winlost - b.actual_stake)
		, @S_Turnover = SUM(ABS(b.stake))
		, @S_BetCount = COUNT(b.TransId)
		, @S_AWinlost = SUM(b.awinlost)
		, @S_Comm = SUM(b.comm)
		, @S_BetEffective = SUM(CASE
									WHEN b.statusID IN (112,113)
										AND (b.bettype NOT IN (4300, 4299, 4298, 4297, 3007, 1906, 1698, 1699, 3898, 3899, 4598, 4599, 4600, 2499)
										AND (b.bettype NOT BETWEEN 1611 AND 1697 OR b.matchid <> 150)
										AND (b.bettype NOT BETWEEN 3801 AND 3899 OR b.matchid <> 173) -- exclude PP Prize from BetEffective
										AND (b.bettype NOT BETWEEN 8700 AND 8709 OR b.matchid <> 157)) 
										THEN ABS(b.winlost - b.actual_stake)
									ELSE 0
								END)
		, @S_MWinlost = SUM(b.mwinlost)
		, @S_SWinlost = SUM(ISNULL(b.swinlost, 0))
		, @S_PlayerComm = SUM(b.playercomm)
		, @S_AComm = SUM(b.acomm)
		, @S_SComm = SUM(ISNULL(b.scomm, 0))
		, @S_BuyBackAmt = SUM(CASE
								WHEN b.bettype IN (902, 912) AND transid2 = 0 THEN b.actual_stake
								WHEN b.bettype IN (4297, 1698, 3898, 4599) THEN b.oddsspread
								ELSE 0
							END)
		, @S_BABuyBackAmt = SUM(CASE WHEN b.bettype IN (902, 912) AND b.transid2 = 1 THEN b.actual_stake ELSE 0 END)
	FROM bodb02.dbo.bettrans14 AS b WITH(NOLOCK)
		INNER JOIN bodb02.dbo.customer AS c WITH (NOLOCK) ON b.custid = c.custid
	WHERE b.winlostdate = @WinLostDate
		AND c.srecommend IN (SELECT custid FROM bodb02.dbo.f_DepSuper_1('All'))
		AND b.statusID IN (101, 111, 112, 113) --REJECT, DRAW, WON, LOSE
		AND b.bettype <= 19999
		AND c.roleid = 1
	OPTION (RECOMPILE)

	SELECT @T_Winlost = SUM(b.winlost)
		, @T_Turnover = SUM(b.turnover)
		, @T_BetCount = SUM(b.BetCount)
		, @T_AWinlost = SUM(b.awinlost)
		, @T_Comm = SUM(b.comm)
		, @T_BetEffective = SUM(b.BetEffective)
		, @T_MWinlost = SUM(b.mwinlost)
		, @T_SWinlost = SUM(b.swinlost)
		, @T_PlayerComm = SUM(b.playercomm)
		, @T_AComm = SUM(b.acomm)
		, @T_SComm = SUM(b.scomm)
		, @T_BuyBackAmt = SUM(b.BuyBackAmt)
		, @T_BABuyBackAmt = SUM(b.BABuyBackAmt)
	FROM dbo.rptLicWinloss2 AS b WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Customer AS c WITH (NOLOCK) ON b.custid = c.custid
	WHERE b.winlostdate = @WinLostDate
		AND c.srecommend IN (SELECT custid FROM bodb02.dbo.f_DepSuper_1('All'))
		AND b.statusID IN (101, 111, 112, 113, 114, 115) --REJECT, DRAW, WON, LOSE, HALF-WON, HALF-LOSE
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
		OR ISNULL(@S_BuyBackAmt, 0) <> ISNULL(@T_BuyBackAmt, 0)
		OR ISNULL(@S_BABuyBackAmt, 0) <> ISNULL(@T_BABuyBackAmt, 0)
	BEGIN
		PRINT 'Re-generate data for RptLicWinloss2 on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' date.'

		EXEC dbo.Task_DailyRptLicWinloss2 @WinLostDate = @WinLostDate

		RETURN
	END
END
GO
