/*<info serverAlias="DBLIC-bodb_LicenseeReport" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_rptCustomerMatch_CheckData]
	@WinLostDate SMALLDATETIME
AS

/*
	Created: 20150910@Sophia
	Task: Check & correct data for rptCustomerMatch
	DB: DBLIC.bodb_LicenseeReport

	Revisions:
		- 20160726@Francis: Move SP to bodb_LicenseeReport [Redmine: #60449]
		- 20170522@Paul: Check awinlost, comm [Redmine: #76206]
		- 20170703@Paul: Check more columns [Redmine: #79262]
		- 20210608@Kos: Support SB, NG, VS, CO only [RedmineID: #156599]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SportBettype TABLE(ProductId TINYINT, BetType SMALLINT, EventType TINYINT)

	INSERT INTO @SportBettype
	SELECT ProductID, BetType, EventType
	FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', 1)
	WHERE ProductID IN (1, 3, 5, 25, 27)

	DECLARE @B_WinLost MONEY, @R_WinLost MONEY
		,@B_Stake MONEY, @R_Stake MONEY
		,@B_BetCount INT, @R_BetCount INT
		,@B_AWinLost MONEY, @R_AWinLost MONEY
		,@B_Comm MONEY, @R_Comm MONEY
		,@B_PlayerComm MONEY, @R_PlayerComm MONEY

	SELECT
		@B_WinLost = SUM(b.winlost - b.actual_stake),
		@B_Stake = SUM(ABS(b.stake)),
		@B_BetCount = COUNT(*),
		@B_AWinLost = SUM(b.awinlost),
		@B_Comm = SUM(b.comm),
		@B_PlayerComm = SUM(b.playercomm)
	FROM bodb02.dbo.bettrans14 AS b WITH (NOLOCK)
		INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(0) AS lc ON b.recommend = lc.custid AND b.currency = lc.currency
	WHERE b.winlostdate = @WinLostDate
		AND b.statusID IN (111, 112, 113)

	SELECT
		@R_WinLost = SUM(winlost),
		@R_Stake = SUM(ABS(stake)),
		@R_BetCount = SUM(betcount),
		@R_AWinLost = SUM(awinlost),
		@R_Comm = SUM(comm),
		@R_PlayerComm = SUM(playercomm)
	FROM dbo.rptCustomerMatch WITH (NOLOCK)
	WHERE winlostdate = @WinLostDate

	IF ISNULL(@B_WinLost, 0) <> ISNULL(@R_WinLost, 0)
		OR ISNULL(@B_Stake, 0) <> ISNULL(@R_Stake, 0)
		OR ISNULL(@B_BetCount, 0) <> ISNULL(@R_BetCount, 0)
		OR ISNULL(@B_AWinLost, 0) <> ISNULL(@R_AWinLost, 0)
		OR ISNULL(@B_Comm, 0) <> ISNULL(@R_Comm, 0)
		OR ISNULL(@B_PlayerComm, 0) <> ISNULL(@R_PlayerComm, 0)
	BEGIN
		PRINT 'Re-generate data for rptCustomerMatch on ' + CONVERT(VARCHAR(10), @WinLostDate, 112) + ' date.'

		EXEC dbo.Task_rptCustomerMatch_Bettrans14 @WinLostDate
	END
END
GO
