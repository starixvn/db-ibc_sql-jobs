/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_Monthly_Commission]  
	@MonthDate		SMALLDATETIME,
	@IsForceUpdate	BIT = 0
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Job - Calculate commission monthly

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
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

	-- Check settings are archived
	IF NOT EXISTS (SELECT 1 FROM dbo.TierSettingHistory WITH (NOLOCK) WHERE MonthDate = @LastDayOfMonth)
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
			MonthDate			SMALLDATETIME,
			AffId				INT,
			GroupId				INT,
			ProductId			INT,
			Deposit				MONEY,
			Withdrawal			MONEY,
			Bonus				MONEY,
			Rebate				MONEY,
			Turnover			MONEY,
			Winloss				MONEY,
			-- Fees
			PlatFormFee			MONEY,
			OperationalFee		MONEY,
			DepositFee			MONEY,
			WithdrawalFee		MONEY,
			-- Calculation
			GrossWinloss		MONEY,
			NetWinloss			MONEY,
			ActivePlayer		INT,
			QualifiedMember		INT,
			QMTurnover			MONEY,
			CommissionRate		FLOAT,
			Commission			MONEY,
			SubAffCommission	MONEY
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
			Rebate,
			Turnover,
			Winloss,
			PlatFormFee,
			OperationalFee,
			DepositFee,
			WithdrawalFee,
			GrossWinloss,
			NetWinloss,
			ActivePlayer,
			QualifiedMember,
			QMTurnOver,
			CommissionRate,
			Commission,
			SubAffCommission
		)
		EXEC dbo.Aff_Commission_UnCalc
			@AffIds				= 'all',
			@FromMonthDate		= @FirstDayOfMonth,
			@ToMonthDate		= @LastDayOfMonth,
			@ProductIds			= '0',
			@BaseCurrency		= 0,
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

	DECLARE @AffCurrency INT, @AffRate FLOAT
	SELECT  @AffCurrency = CONVERT(INT, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AffCurrency'
	SELECt  @AffRate = Rate FROM dbo.Aff_f_ExchangeRate_Sel(@LastDayOfMonth, @AffCurrency, 0)

	INSERT INTO dbo.rptAffCommission
	(
		MonthDate,
		AffId,
		GroupId,
		ProductId,
		Deposit,
		Withdrawal,
		Bonus,
		Rebate,
		Adjustment,
		Turnover,
		Winloss,
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
		Rebate,
		0 AS Adjustment,
		Turnover,
		Winloss,
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
								WHEN 13 THEN tc.DepositFee
								WHEN 14 THEN tc.WithdrawalFee
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
		TransType,
		AffCurrency,
		AffRate
	)
	SELECT
		c.AffID,
		c.MonthDate AS TransDate,
		GETDATE() AS CompletedDate,
		t.Amount,
		'Approved' AS Status,
		'Monthly Earning' AS Description,
		148 AS Creator,
		t.TransType,
		@AffCurrency,
		@AffRate
	FROM #TempCommission c
		CROSS APPLY (
			SELECT 201 AS TransType, Commission AS Amount
			UNION ALL
			SELECT 204, SubAffCommission
		) t
	WHERE ProductId = 0

	-- Update Commission Date
	DECLARE @LaunchDate SMALLDATETIME

	IF @IsForceUpdate = 0
	BEGIN
		SELECT @LaunchDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'LaunchDate'

		IF @LastDayOfMonth >= DATEADD(DAY, -1, @LaunchDate)
		BEGIN
			UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
			SET SValue = CONVERT(VARCHAR(10), @LastDayOfMonth, 120)
			WHERE SName = 'AFF_CommissionDate'
		END
	END
END
GO