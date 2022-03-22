/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[GET_DepositDataToValidate_CustomerTurnover]
	@Date		SMALLDATETIME	= NULL,
	@DrawFilter	TINYINT			= 1
AS

/*
	Created: 20140312@Florent
	Task: Get deposit data from table db052.bodb_Licenseereport.dbo.rptCustomerTurnover
	DB: DBLIC.bodb_LicenseeReport

	Revisions:
		- 20150211@Florent: add Sporting Solution bettype
		- 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
		- 20181218@Joseph: Add new bet types for E-Sports 2.0 [RedmineID: #106592]
		- 20181219@Joseph: Integrate Happy 5 for NumberGame [RedmineID: #103698]
		- 20190307@Parsons: Implement BetBuilder [Redmine: #108995]
		- 20200225@Malcolm : change bettype for racing [Redmine : #129158]
		- 20200508@Vickie: Add new bet types for E-Sports 2.0 [RedmineID: #132548] 
		- 20201231@Louis: Integrate Happy 5 Linked Games [RedmineID: #147446]
		- 20210315@Hogan: Integrate Cricket AIO [RedmineID: #150386]
		- 20220211@Kos: Integrate Cricket phase 2 [RedmineID: #168034]
					- Don't support Racing and Live Casino anymore

	Param's Explanation:
		@DrawFilter, 1:Normal - 2:No Draws - 3:No Draws For Turnover Only
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SbTurnover		MONEY
		, @SbCustomerWl		MONEY
		, @SbBetCount		MONEY
		, @RbTurnover		MONEY
		, @RbCustomerWl		MONEY
		, @RbBetCount		MONEY
		, @NgTurnover		MONEY
		, @NgCustomerWl		MONEY
		, @NgBetCount		MONEY
		, @BaTurnover		MONEY
		, @BaCustomerWl		MONEY
		, @BaBetCount		MONEY
		, @CsTurnover		MONEY
		, @CsCustomerWl		MONEY
		, @CsBetCount		MONEY

	SELECT B.* 
	INTO #DATA
	FROM dbo.rptCustomerTurnover b WITH (NOLOCK)
	WHERE b.winlostdate = @DATE 
		AND b.currency NOT IN (20, 27, 28)

	DECLARE @SportBettype TABLE(ProductId TINYINT, BetType SMALLINT, EventType TINYINT)

	INSERT INTO @SportBettype
	SELECT ProductID, BetType, EventType
	FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', 1)
	WHERE ProductID IN (1, 3)

	-- Sportbook
	SELECT @SbTurnover = SUM(CASE
								WHEN @DrawFilter IN (2,3) THEN CASE
																	WHEN b.statusID = 111 THEN 0
																	WHEN b.statusID IN (114, 115) THEN 0.5
																	ELSE 1
																END
								ELSE 1
							END * b.stake)
		, @SbCustomerWl = SUM(b.winlost)
		, @SbBetCount = SUM(CASE 
								WHEN @DrawFilter = 2 AND b.statusID = 111 THEN 0 
								ELSE b.BetCount
							END)
	FROM #DATA AS B
		INNER JOIN @SportBettype AS s ON s.BetType = b.bettype
	WHERE s.ProductId = 1
		AND b.statusID IN (111, 112, 113, 114, 115)
		AND b.isBA = 0

	SELECT @SbTurnover = ISNULL (@SbTurnover, 0),
		@SbCustomerWl = ISNULL (@SbCustomerWl, 0),
		@SbBetCount = ISNULL (@SbBetCount, 0)

	-- Number Game
	SELECT @NgTurnover = SUM(CASE
								WHEN @DrawFilter IN (2, 3) AND b.statusID = 111 THEN 0 
								ELSE b.stake
							END)
		, @NgCustomerWl = SUM(b.winlost)
		, @NgBetCount = SUM(CASE
								WHEN @DrawFilter = 2 AND b.statusID = 111 THEN 0
								ELSE b.BetCount
							END)
	FROM #DATA AS B
		INNER JOIN @SportBettype AS s ON s.BetType = b.bettype
	WHERE s.ProductId = 3
		AND b.statusID IN (111, 112, 113, 114, 115)

	SELECT @NgTurnover = ISNULL(@NgTurnover, 0),
		@NgCustomerWl = ISNULL(@NgCustomerWl, 0),
		@NgBetCount = ISNULL(@NgBetCount, 0)

	-- BA
	SELECT @BaTurnover = SUM(CASE
								WHEN @DrawFilter IN (2, 3) THEN CASE
																	WHEN b.statusID = 111 THEN 0
																	WHEN b.statusID IN (114, 115) THEN 0.5
																	ELSE 1
																END
								ELSE 1
							END * b.stake)
		, @BaCustomerWl = SUM(b.winlost)
		, @BaBetCount = SUM(CASE
								WHEN @DrawFilter = 2 AND b.statusID = 111 THEN 0
								ELSE b.BetCount
							END)
	FROM #DATA B
	WHERE b.statusID IN (111, 112, 113, 114, 115)
		AND b.isba = 1

	SELECT @BaTurnover = ISNULL (@BaTurnover, 0),
		@BaCustomerWl = ISNULL (@BaCustomerWl, 0),
		@BaBetCount = ISNULL (@BaBetCount, 0)

	-- Result
	SELECT 1 AS Id, @SbTurnover AS Sb, 0 AS Rb, @NgTurnover AS Ng, @BaTurnover AS Ba, 0 AS Cs
	UNION
	SELECT 2, @SbCustomerWl, 0, @NgCustomerWl, @BaCustomerWl, 0
	UNION
	SELECT 3, @SbBetCount, 0, @NgBetCount, @BaBetCount, 0

	DROP TABLE #DATA

	SET NOCOUNT OFF
END
GO
