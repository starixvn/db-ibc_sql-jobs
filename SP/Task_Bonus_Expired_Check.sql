/*<info serverAlias="DBTP-bodb02" executers="" viewers="" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_Bonus_Expired_Check] @DateCheck SMALLDATETIME = NULL
	, @IsDebug BIT = 0
/*	
	Created by: 20180523@Patrick
	Task: Check bonus expired
	The rules:
		1) Error - Having bonus programs not expired yet.
		2) Error - Having bonus customer status not expired yet.
		3) Error - Having bonus customer status not expired yet for 1st deposit case.
		4) Error - Having member join Bonus program after ending time.
		5) Error - Having custinfo.BonusWalletFlag value is wrong.
		6) Error - Having different amount on bettype 22200 between bettrans and BonusWalletCredit or init bonus amount not match with setting.
		7) Error - Having Bonus cust status has expired but status on wallet credit has not expired yet.
		8) Error - Having deducting amount in case bonus expired is wrong.
	
	Revision:
		- 20201022@Patrick: Change email to starixvn [Redmine: #143607]
*/
AS
BEGIN
	SET NOCOUNT ON
	IF @DateCheck IS NULL
		SET @DateCheck = CAST(GETDATE() AS DATE)

	DECLARE @BeforeDateCheck DATE
	SET @BeforeDateCheck = DATEADD(DAY, -1, @DateCheck)

	CREATE TABLE #__ErrorMessages (Id INT IDENTITY(1,1), Message VARCHAR(200))

	DECLARE @__Ignore_SiteList TABLE (SiteId INT)
	INSERT INTO @__Ignore_SiteList(SiteId)
	VALUES(4200800), (4202600), (4200800), (4200200)
	--SELECT SiteId FROM DBCUST.SiteConfig.dbo.LicVendorProfile with(nolock) WHERE SiteName IN ('Spondemo_x', 'Athena000', 'Spondemo')
	
	--//check bonus program expired or not
	IF EXISTS (
		SELECT TOP 1 1
		FROM dbo.BonusSetting WITH(NOLOCK)
		WHERE @DateCheck > EndDate AND Enabled = 1
			AND SiteId NOT IN (SELECT t.SiteId FROM @__Ignore_SiteList t)
	)
	BEGIN
		INSERT INTO #__ErrorMessages(Message) VALUES('Error - Having bonus programs not expired yet.')
	END

	--//check member expired or not
	IF EXISTS (
		SELECT TOP 1 1 
		FROM dbo.BonusSetting s WITH(NOLOCK)
			INNER JOIN dbo.BonusCustomerStatus c WITH(NOLOCK) ON s.BonusID = c.BonusID
		WHERE ISNULL(s.DefaultExpiredDay, 0) <> 0 
			AND c.ExpiredDate < @DateCheck
			AND StatusID = 4
			AND s.SiteId NOT IN (SELECT t.SiteId FROM @__Ignore_SiteList t)
	)
	BEGIN
		INSERT INTO #__ErrorMessages(Message) VALUES('Error - Having bonus customer status not expired / completed / cancelled yet.')
	END

	--//check member expired or not - 1st depoist case
	IF EXISTS (
		SELECT TOP 1 1 
		FROM dbo.BonusSetting s WITH(NOLOCK)
			INNER JOIN dbo.BonusCustomerStatus c WITH(NOLOCK) ON s.BonusID = c.BonusID
		WHERE ISNULL(s.DepositExpiredDay, 0) <> 0
			AND DepositExpiredDate < @DateCheck
			AND StatusID = 4
			AND s.SiteId NOT IN (SELECT t.SiteId FROM @__Ignore_SiteList t)
	)
	BEGIN
		INSERT INTO #__ErrorMessages(Message) VALUES('Error - Having bonus customer status not expired / completed / cancelled yet for 1st deposit case.')
	END

	--//having member join bonus program after bonus end date
	IF EXISTS (
		SELECT TOP 1 1 
		FROM dbo.BonusSetting s WITH(NOLOCK)
			INNER JOIN dbo.BonusCustomerStatus c WITH(NOLOCK) ON s.BonusID = c.BonusID
		WHERE c.ApprovedDate > s.EndDate
			AND s.SiteId NOT IN (SELECT t.SiteId FROM @__Ignore_SiteList t)
	)
	BEGIN
		INSERT INTO #__ErrorMessages(Message) VALUES('Error - Having member join Bonus program after ending time.')
	END

	--//check wallet flag in custifo
	IF EXISTS (
		SELECT TOP 1 1
		FROM dbo.BonusCustomerStatus c WITH(NOLOCK)
			INNER JOIN dbo.custinfo ci WITH(NOLOCK) ON c.CustID = ci.custid
		WHERE ci.BonusWalletFlag = 1 AND c.StatusID NOT IN (7, 6, 4)
			AND SiteId NOT IN (SELECT t.SiteId FROM @__Ignore_SiteList t)
	)
	BEGIN
		INSERT INTO #__ErrorMessages(Message) VALUES('Error - Having custinfo.BonusWalletFlag value is wrong.')
	END

	--//check valid amount for bettype 22200 --> todo
	DECLARE @__BonuSettingCurrencyTemp TABLE (BonusId INT, CurrencyId INT, MinRange MONEY, MaxRange MONEY, MinPayout MONEY, MaxPayout MONEY, Rate MONEY, Rollover SMALLMONEY)
	INSERT INTO @__BonuSettingCurrencyTemp(BonusId, CurrencyId, MinRange, MaxRange, MinPayout, MaxPayout, Rate, Rollover)
	SELECT cs.BonusID, cs.Currency, cs.MinRange, cs.MaxRange, cs.MinPayout, cs.MaxPayout, cs.ReturnRate / 100, cs.Rollover
	FROM dbo.BonusCurrencySetting cs WITH(NOLOCK)
		INNER JOIN dbo.BonusSetting s WITH(NOLOCK) ON cs.BonusID = s.BonusID
	WHERE SiteId NOT IN (SELECT t.SiteId FROM @__Ignore_SiteList t)
		AND s.EndDate >= @BeforeDateCheck AND s.EndDate <= @DateCheck

	IF EXISTS (
		SELECT TOP 1 1
		FROM dbo.bettrans b WITH(NOLOCK)
			INNER JOIN dbo.bettrans bb WITH(NOLOCK) ON b.custid = bb.custid AND b.BonusID = bb.BonusID
			INNER JOIN @__BonuSettingCurrencyTemp s ON b.BonusID = s.BonusId AND b.currency = s.CurrencyId
			CROSS APPLY (
				SELECT InitBonus
				FROM DBTrans.bodb02.dbo.BonusWalletCredit c WITH(NOLOCK)
				WHERE c.custid = b.custid AND c.BonusId = b.BonusId
			)t
		WHERE b.winlostdate >= @BeforeDateCheck AND b.winlostdate <= @DateCheck
			AND b.bettype = 22001 AND bb.bettype = 22200 
			AND b.BonusID > 0
			AND 1 = CASE WHEN t.InitBonus <> (bb.winlost - bb.actual_stake) THEN 1
						 WHEN (bb.winlost - bb.actual_stake) <> CASE WHEN (b.winlost - b.actual_stake) * s.Rate > s.MaxPayout THEN s.MaxPayout ELSE (b.winlost - b.actual_stake) * s.Rate END THEN 1
					ELSE 0 END
	)
	BEGIN
		INSERT INTO #__ErrorMessages(Message) VALUES('Error - Having different amount on bettype 22200 between bettrans and BonusWalletCredit or init bonus amount not match with setting.')
	END

	--//check deduct amount after expiring bonus
	CREATE TABLE #__CustList (CustId INT, BonusId INT, StatusId INT, CurrencyId INT, Rollover SMALLMONEY)
	INSERT INTO #__CustList(CustId, BonusId, CurrencyId, StatusId, Rollover)
	SELECT DISTINCT custid, cs.BonusId, bcs.Currency, cs.StatusID, bcs.Rollover
	FROM dbo.DBA_BonusCustomerStatus_Check cs WITH(NOLOCK)
		INNER JOIN dbo.BonusSetting s WITH(NOLOCK) ON cs.BonusID = s.BonusID
		INNER JOIN dbo.BonusCurrencySetting bcs WITH(NOLOCK) ON cs.BonusID = bcs.BonusID
	WHERE CaptureDate = @DateCheck AND CustID IS NOT NULL
		AND cs.SiteId NOT IN (SELECT t.SiteId FROM @__Ignore_SiteList t)

	IF @@ROWCOUNT > 10000
	BEGIN
		RAISERROR('Having big data in #__CustList. Please check!', 16, 1)
		RETURN
	END

	CREATE TABLE #__WalletCreditTemp (CustId INT, BonusId INT, StatusId TINYINT, InitBonus MONEY, LockedAmt MONEY, Amount MONEY)
	INSERT INTO #__WalletCreditTemp(CustId, BonusId, StatusId, InitBonus, LockedAmt, Amount)
	SELECT tt.CustId, tt.BonusId, t.StatusId, t.InitBonus, t.LockedAmt, t.Amount
	FROM #__CustList tt
	CROSS APPLY (
		SELECT StatusId, InitBonus, LockedAmt, Amount
		FROM DBTrans.bodb02.dbo.BonusWalletCredit c WITH(NOLOCK)
		WHERE c.custid = tt.custid AND c.BonusId = tt.BonusId
	)t

	CREATE TABLE #__WalletDebitTemp (CustId INT, BonusId INT, Amount MONEY)
	INSERT INTO #__WalletDebitTemp(CustId, BonusId, Amount)
	SELECT tt.CustId, tt.BonusId, t.Amount
	FROM #__CustList tt
	CROSS APPLY (
		SELECT Amount
		FROM DBTrans.bodb02.dbo.BonusWalletDebit c WITH(NOLOCK)
		WHERE c.custid = tt.custid AND c.BonusId = tt.BonusId
	)t

	CREATE TABLE #__Bet_Winloss (CustId INT, BonusId INT, Winloss MONEY)
	INSERT INTO #__Bet_Winloss(CustId, BonusId, Winloss)
	SELECT b.CustId, b.BonusId, SUM(b.stake) AS winloss
	FROM dbo.bettrans b WITH(NOLOCK)
		INNER JOIN #__CustList t ON t.CustId = b.custid AND t.BonusId = b.BonusID
	WHERE bettype < 19999 AND b.BonusId > 0
	GROUP BY b.CustId, b.BonusId

	UNION ALL
	SELECT b.CustId, b.BonusId, SUM(b.stake) AS winloss
	FROM dbo.bettrans14 b WITH(NOLOCK)
		INNER JOIN #__CustList t ON t.CustId = b.custid AND t.BonusId = b.BonusID
	WHERE b.BonusId > 0
	GROUP BY b.CustId, b.BonusId

	UNION ALL
	SELECT b.CustId, b.BonusId, SUM(b.stake) AS winloss
	FROM bodb_Archive.dbo.bettrans_bk b WITH(NOLOCK, Index=IX_custid)
		INNER JOIN #__CustList t ON t.CustId = b.custid AND t.BonusId = b.BonusID
	WHERE b.BonusId > 0 AND winlostdate > DATEADD(DAY, -180, @DateCheck)
	GROUP BY b.CustId, b.BonusId

	CREATE TABLE #__DeductAmountTemp (CustId INT, BonusId INT, WinlostAmount MONEY, DeductAmount MONEY, InitBonus MONEY, LockedAmount MONEY)
	
	;WITH __bet AS (
		SELECT t.CustId, t.BonusId, SUM(ISNULL(t.Winloss, 0)) AS Amount
		FROM #__Bet_Winloss t
		GROUP BY t.CustId, t.BonusId
	), __balance AS (
		SELECT ISNULL(t.CustId, tt.CustId) AS CustId, ISNULL(t.BonusId, tt.BonusId) AS BonusId, SUM(ISNULL(t.InitBonus, 0)) AS InitBonus, SUM(ISNULL(t.LockedAmt, 0)) AS LockedAmt, SUM(ISNULL(t.Amount, 0) + ISNULL(tt.Amount, 0)) AS Amount, SUM(ISNULL(t.InitBonus, 0) + ISNULL(t.Amount, 0) - ISNULL(tt.Amount, 0)) AS RemainingAmount
		FROM #__WalletCreditTemp t
			FULL OUTER JOIN #__WalletDebitTemp tt ON t.CustId = tt.CustId AND t.BonusId = tt.BonusId
		GROUP BY ISNULL(t.CustId, tt.CustId), ISNULL(t.BonusId, tt.BonusId)
	)
	
	INSERT INTO #__DeductAmountTemp(CustId, BonusId, WinlostAmount, DeductAmount, InitBonus, LockedAmount)
	SELECT b.CustId, b.BonusId, b.Amount
		, CASE WHEN RemainingAmount < 0 THEN 0
			WHEN RemainingAmount <= bb.InitBonus THEN -RemainingAmount
			WHEN bb.InitBonus < RemainingAmount AND RemainingAmount <= LockedAmt + InitBonus THEN -InitBonus
			WHEN RemainingAmount > LockedAmt + InitBonus THEN -(RemainingAmount - LockedAmt) END AS DeductAmount
		, ISNULL(bb.InitBonus, 0) AS InitBonus
		, ISNULL(bb.LockedAmt, 0) AS LockedAmt
	FROM __bet b
		INNER JOIN __balance bb ON b.CustId = bb.CustId AND b.BonusId = bb.BonusId

	IF EXISTS (
		SELECT TOP 1 1
		FROM @__BonuSettingCurrencyTemp t
			INNER JOIN dbo.BonusCustomerStatus bs WITH(NOLOCK) ON t.BonusId = bs.BonusID AND t.CurrencyId = bs.Currency
			INNER JOIN #__DeductAmountTemp tt ON bs.CustID = tt.CustId AND bs.BonusID = tt.BonusId
		 WHERE 1 = CASE WHEN tt.WinlostAmount >= (InitBonus + LockedAmount) * t.Rollover AND bs.StatusID = 1 THEN 1
						WHEN tt.WinlostAmount < (InitBonus + LockedAmount) * t.Rollover AND bs.StatusID = 1 AND bs.ExpiredDate = @BeforeDateCheck THEN 1
						ELSE 0 END
	)
	BEGIN
		INSERT INTO #__ErrorMessages(Message) VALUES('Error - Bonus cust status has expired but status on wallet credit has not expired yet.')
	END

	--//check deduct amount when member cancel bonus or expired
	IF EXISTS (
		SELECT TOP 1 1
		FROM dbo.bettrans b WITH(NOLOCK)
			INNER JOIN #__DeductAmountTemp t ON b.custid = t.CustId AND b.BonusID = t.BonusId
		WHERE b.bettype = 22201
			AND transdesc LIKE '%Deposit Site Bonus%'
			AND (winlost - actual_stake) <> DeductAmount
	)
	BEGIN
		INSERT INTO #__ErrorMessages(Message) VALUES('Error - Deducting amount in case bonus expired is wrong.')
	END


	IF EXISTS (
		SELECT TOP 1 1 FROM #__ErrorMessages
	)
	BEGIN
		DECLARE @email_body NVARCHAR(MAX)
				, @subject NVARCHAR(200)
				, @DataRow VARCHAR(MAX)
			
		SELECT @email_body = '
			<html>
				<body>
				<style>
					table {border-collapse: collapse;}
					table, td, th {border: 1px solid black;}
					th {text-align: left}
				</style>

				<p><b>Check time: ' + convert(varchar(50), getdate(), 121) + '</p>
				<div style="background-color:red;color:white;text-align:center;padding: 8px;">Failure</div>
				<p></p>
				<table>
					<tr>
						<th style="text-align:center">Id</th>
						<th style="text-align:center">Message</th>
					</tr>
					{<dataRow>}
				</table>
				</body>
			</html>'
		, @subject	= N'Bonus - Check Bonus Expire'
		
		SET @DataRow = CONVERT(VARCHAR(MAX), (SELECT Id AS 'td1', Message AS 'td2'
											FROM #__ErrorMessages
											FOR XML PATH('tr'), TYPE
											))
		SET @DataRow = REPLACE(REPLACE(@DataRow, 'td1>', 'td>'), 'td2>', 'td>')
		SET @email_body = REPLACE(@email_body, '{<dataRow>}', @DataRow)


		IF @IsDebug = 0
		BEGIN
			EXECUTE msdb.dbo.sp_send_dbmail @profile_name	= DEFAULT
				, @recipients			 = 'pontus@starixvn.com'
				, @copy_recipients		 = ''
				, @blind_copy_recipients = ''
				, @subject				 = @subject
				, @body					 = @email_body
				, @body_format			 = 'HTML';
		END

		IF @IsDebug = 1
		BEGIN
			SELECT @email_body AS '@email_body'
		END
	END

	DROP TABLE #__ErrorMessages
	DROP TABLE #__Bet_Winloss
	DROP TABLE #__CustList
	DROP TABLE #__DeductAmountTemp
	DROP TABLE #__WalletCreditTemp
	DROP TABLE #__WalletDebitTemp

END
GO


