/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_rptWinlostbyleague_CheckData]
	@WinLostDate SMALLDATETIME
AS

/*
	Created: 20150910@Sophia
	Task: Check & correct data for rptWinlostbyleague
	DB: DBLIC.bodb_LicenseeReport

	Revisions:
		- 20160726@Francis: Move SP to bodb_LicenseeReport [Redmine: #60449]
		- 20170522@Paul: Check awinlost, comm [Redmine: #76206]
		- 20170703@Paul: Check more columns [Redmine: #79262]
		- 20210608@Kos: Support SB, NG, VS, CO only [RedmineID: #156599]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
		- 20210824@Hogan: Integrate BitCoin [RedmineID: #160160]
*/

BEGIN 
	SET NOCOUNT ON

	DECLARE @SportBettype TABLE(ProductId TINYINT, BetType SMALLINT, EventType TINYINT)

	INSERT INTO @SportBettype
	SELECT ProductID, BetType, EventType
	FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', 1)
	WHERE ProductID IN (1, 3, 5, 25, 27, 63, 69)

	DECLARE @B_Winlost MONEY, @R_Winlost MONEY
		,@B_Stake MONEY, @R_Stake MONEY
		,@B_BetCount INT, @R_BetCount INT
		,@B_AWinlost MONEY, @R_AWinlost MONEY
		,@B_Comm MONEY, @R_Comm MONEY
		,@B_PlayerComm MONEY, @R_PlayerComm MONEY

	SELECT
		@B_Winlost = SUM(b.winlost - b.actual_stake),
		@B_Stake = SUM (ABS(b.stake)),
		@B_BetCount = COUNT(*),
		@B_AWinlost = SUM(b.awinlost),
		@B_Comm = SUM(b.comm),
		@B_PlayerComm = SUM(b.playercomm)
	FROM bodb02.dbo.bettrans14 AS b WITH (NOLOCK)
		INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(0) AS LC ON b.recommend = lc.custid AND b.currency = lc.currency
		INNER JOIN @SportBettype AS s ON s.BetType = b.bettype
	WHERE b.winlostdate = @WinLostDate
		AND b.statusID IN (111, 112, 113)

	SELECT
		@R_Winlost = SUM(winlost),
		@R_Stake = SUM(ABS(stake)),
		@R_BetCount = SUM(betcount),
		@R_AWinlost = SUM(awinlost),
		@R_Comm = SUM(comm),
		@R_PlayerComm = SUM(playercomm)
	FROM dbo.rptWinlostbyLeague WITH (NOLOCK)
	WHERE winlostdate = @WinLostDate

	IF ISNULL(@B_Winlost, 0) <> ISNULL(@R_Winlost, 0)
		OR ISNULL(@B_Stake, 0) <> ISNULL(@R_Stake, 0)
		OR ISNULL(@B_BetCount, 0) <> ISNULL(@R_BetCount, 0)
		OR ISNULL(@B_AWinlost, 0) <> ISNULL(@R_AWinlost, 0)
		OR ISNULL(@B_Comm, 0) <> ISNULL(@R_Comm, 0)
		OR ISNULL(@B_PlayerComm, 0) <> ISNULL(@R_PlayerComm, 0)
	BEGIN
		PRINT 'Re-generate data for rptWinlostbyleague on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' date.'

		EXEC dbo.Task_rptWinlostbyleague_Bettrans14 @WinLostDate
	END
END
GO
