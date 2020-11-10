/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_Monthly_Commission]  
	@MonthDate		SMALLDATETIME,
	@IsForceUpdate	BIT = 0
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Job - Calculate commission monthly

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20181201@Percy: Exclude closed affiliates [RedmineID: #104892]
		- 20190808@Percy: Add Exchange [RedmineID: #106504]
		- 20191127@Percy: Deduct bonus amount from commission amount [RedmineID: #118992]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @FirstDayOfMonth SMALLDATETIME, @LastDayOfMonth SMALLDATETIME

	SELECT  @FirstDayOfMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @LastDayOfMonth  = DATEADD(DAY, -1, DATEADD(MONTH, 1, @FirstDayOfMonth))

	-- Check month of @MonthDate is completed
	IF @LastDayOfMonth > CURRENT_TIMESTAMP
	BEGIN
		SELECT 'This month is not completed yet!'

		RETURN
	END

	-- Check cutoffdate
	DECLARE @CutOffDate SMALLDATETIME
	SELECT  @CutOffDate = CONVERT(DATE, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CutOffReportDate'

	IF @LastDayOfMonth <= @CutOffDate
	BEGIN
		SELECT 'This month is still used old formula!'
		
		RETURN
	END

	-- Check settings are archived
	IF NOT EXISTS (SELECT 1 FROM dbo.CommGroupHistory WITH (NOLOCK) WHERE MonthDate = @LastDayOfMonth)
		OR NOT EXISTS (SELECT 1 FROM dbo.TierSettingHistory WITH (NOLOCK) WHERE MonthDate = @LastDayOfMonth)
		OR NOT EXISTS (SELECT 1 FROM dbo.DeductionSettingHistory WITH (NOLOCK) WHERE MonthDate = @LastDayOfMonth)
		OR NOT EXISTS (SELECT 1 FROM dbo.AffGroupHistory WITH (NOLOCK) WHERE MonthDate = @LastDayOfMonth)
	BEGIN
		SELECT 'Settings of this month are not archived yet!'

		RETURN
	END

	-- Check job run already
	IF @IsForceUpdate = 0
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.rptAffCommission WITH (NOLOCK) WHERE MonthDate = @LastDayOfMonth)
		BEGIN
			SELECT 'Data is already done for this month!'

			RETURN
		END
	END

	-- Process data
		-- Get Data
	BEGIN
		CREATE TABLE #TempCommission
		(
			MonthDate				SMALLDATETIME,
			AffId					INT,
			GroupId					INT,
			ProductId				INT,
			Deposit					MONEY,
			Withdrawal				MONEY,
			Bonus					MONEY,
			Turnover				MONEY,
			Winloss					MONEY,
			AWinloss				MONEY,
			AComm					MONEY,
			-- Fees
			PlatFormFee				MONEY,
			OperationalFee			MONEY,
			BankingFee				MONEY,
			ExchangeWinlossShare	MONEY,
			ExchangeCommShare		MONEY,
			-- Calculation
			GrossWinloss			MONEY,
			NetWinloss				MONEY,
			ActivePlayer			INT,
			QualifiedMember			INT,
			QMTurnover				MONEY,
			CommissionRate			FLOAT,
			Commission				MONEY
		)

		-- Uncalculated Months
		INSERT INTO #TempCommission
		(
			MonthDate,
			AffId,
			GroupId,
			ProductId,
			Deposit,
			Withdrawal,
			Bonus,
			Turnover,
			Winloss,
			AWinloss,
			AComm,
			PlatFormFee,
			OperationalFee,
			BankingFee,
			ExchangeWinlossShare,
			ExchangeCommShare,
			GrossWinloss,
			NetWinloss,
			ActivePlayer,
			QualifiedMember,
			QMTurnOver,
			CommissionRate,
			Commission
		)
		EXEC dbo.Aff_Commission_UnCalc
			@AffIds				= 'all',
			@FromMonthDate		= @FirstDayOfMonth,
			@ToMonthDate		= @LastDayOfMonth,
			@ProductIds			= '0',
			@IsSumAll			= 0,
			@GetRowTotalOnly	= 0
	END

		-- Remove invalid data
	DELETE tc
	FROM #TempCommission tc
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON tc.AffId = ai.AffId
	WHERE ai.Status <> 'Approved' AND ai.IsClosed = 0

		-- Import data
	IF @IsForceUpdate = 1
	BEGIN
		DELETE dbo.rptAffCommission WITH (ROWLOCK, UPDLOCK)
		WHERE MonthDate = @LastDayOfMonth

		DELETE dbo.rptAffDeduction WITH (ROWLOCK, UPDLOCK)
		WHERE MonthDate = @LastDayOfMonth

		DELETE dbo.AffTrans WITH (ROWLOCK, UPDLOCK)
		WHERE TransDate = @LastDayOfMonth
	END

	INSERT INTO dbo.rptAffCommission
	(
		MonthDate,
		AffId,
		GroupId,
		ProductId,
		Deposit,
		Withdrawal,
		Bonus,
		Adjustment,
		Turnover,
		Winloss,
		AWinloss,
		AComm,
		GrossWinloss,
		NetWinloss,
		QMTurnover,
		ActivePlayer,
		QualifiedMember,
		CommissionRate
	)
	SELECT
		MonthDate,
		AffId,
		GroupId,
		ProductId,
		Deposit,
		Withdrawal,
		Bonus,
		0 AS Adjustment,
		Turnover,
		Winloss,
		AWinloss,
		AComm,
		GrossWinloss,
		NetWinloss,
		QMTurnover,
		ActivePlayer,
		QualifiedMember,
		CommissionRate
	FROM #TempCommission

	INSERT INTO dbo.rptAffDeduction
	(
		MonthDate,
		AffId,
		GroupId,
		ProductId,
		GroupProductId,
		DeductionId,
		Amount
	)
	SELECT
		tc.MonthDate,
		tc.AffId,
		tc.GroupId,
		tc.ProductId,
		dsh.GroupProductId,
		dsh.DeductionId,
		CASE dsh.DeductionId	WHEN 10 THEN tc.PlatFormFee
								WHEN 11 THEN tc.OperationalFee
								WHEN 12 THEN tc.BankingFee
								WHEN 13 THEN tc.ExchangeWinlossShare
								WHEN 14 THEN tc.ExchangeCommShare
								END AS Amount
	FROM #TempCommission tc
		INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON tc.MonthDate = dsh.MonthDate AND tc.GroupId = dsh.GroupId AND tc.ProductId = dsh.ProductId

	INSERT INTO dbo.AffTrans
	(
		AffID,
		TransDate,
		CompletedDate,
		Amount,
		Status,
		Description,
		Creator,
		TransType
	)
	SELECT
		AffID,
		MonthDate AS TransDate,
		GETDATE() AS CompletedDate,
		ISNULL((NetWinloss - Bonus) * CommissionRate, 0) AS Amount,
		'Approved' AS Status,
		'Monthly Earning' AS Description,
		148 AS Creator,
		201 AS TransType
	FROM #TempCommission
	WHERE ProductId = 0
	
	IF @IsForceUpdate = 0
		UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
		SET SValue = CONVERT(VARCHAR(10), @LastDayOfMonth, 120)
		WHERE SName = 'AFF_CommissionDate'
END
GO