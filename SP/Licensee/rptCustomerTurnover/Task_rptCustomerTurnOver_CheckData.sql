/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" executers="" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_rptCustomerTurnOver_CheckData]
	@WinLostDate SMALLDATETIME
AS

/*
	Created: 20150910@Patrick
	Task: Check & correct data for rptCustomerTurnOver
	DB: DBLIC.bodb_LicenseeReport

	Revisions:
		- 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
		- 20170703@Paul: Check more columns - [Redmine: #79262]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
		- 20211117@Kos: Merge Sports Lottery into Sportsbook [RedmineID: #163191]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SportBettype TABLE(BetType SMALLINT, ProductCode VARCHAR(10), EventType TINYINT)

	INSERT INTO @SportBettype
	SELECT BetType, ProductPrefix, EventType
	FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', 1)
	WHERE ProductID IN (1, 3, 5, 27, 63)

	DECLARE @S_Winlost MONEY, @T_Winlost MONEY, @S_Turnover MONEY, @T_Turnover MONEY, @S_BetCount INT, @T_BetCount INT,
			@S_PlayerComm MONEY, @T_PlayerComm MONEY, @S_BetEffective MONEY, @T_BetEffective MONEY
	
	SELECT @S_Winlost = SUM(b.winlost - b.actual_stake)
		, @S_Turnover = SUM(ABS(b.stake))
		, @S_BetCount = COUNT(b.custid)
		, @S_PlayerComm = SUM(b.playercomm)
		, @S_BetEffective = SUM(ABS(b.winlost - b.actual_stake))
	FROM bodb02.dbo.bettrans14 AS b WITH (NOLOCK)
		INNER JOIN @SportBettype AS s ON s.BetType = b.bettype
		INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(0) lc ON b.recommend = lc.custid
	WHERE b.winlostdate = @WinlostDate
		AND b.statusID IN (111, 112, 113) --DRAW, WON, LOSE

	SELECT @T_Winlost = SUM(b.winlost)
		, @T_Turnover = SUM(b.stake)
		, @T_BetCount = SUM(b.betcount)
		, @T_PlayerComm = SUM(b.playercomm)
		, @T_BetEffective = SUM(b.BetEffective)
	FROM dbo.rptCustomerTurnover AS b WITH (NOLOCK)
		INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(0) AS lc ON b.recommend = lc.custid
	WHERE b.winlostdate = @WinlostDate
		AND b.statusID IN (111, 112, 113, 114, 115) --DRAW, WON, LOSE

	IF ISNULL(@S_Winlost, 0) <> ISNULL(@T_Winlost, 0)
		OR ISNULL(@S_Turnover, 0) <> ISNULL(@T_Turnover, 0)
		OR ISNULL(@S_BetCount, 0) <> ISNULL(@T_BetCount, 0)
		OR ISNULL(@S_PlayerComm, 0) <> ISNULL(@T_PlayerComm, 0)
		OR ISNULL(@S_BetEffective, 0) <> ISNULL(@T_BetEffective, 0)
	BEGIN
		PRINT 'Re-generate data for rptCustomerTurnover on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' date.'

		EXEC dbo.Task_rptCustomerTurnOver_Bettrans14 @Date = @WinlostDate

		RETURN
	END
END
GO
