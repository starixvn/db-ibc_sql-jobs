/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_ImportData_3rdProduct]
	@ProductId		INT,
	@WinlostDate	SMALLDATETIME
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Get data of aff's member - 3rd Products

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102322]
		- 20190117@Percy: Add Gold Deluxe [RedmineID: #106503]
		- 20190808@Percy: Add Exchange [RedmineID: #106504]
		- 20191220@Percy: Enhance performance - Split code merge rptMemberDaily to insert/update/delete [RedmineID: #117197]
		- 20200228@Percy: Return if input wrong @ProductId [RedmineID: #129442]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @tblrecommend TABLE (recommend INT PRIMARY KEY)
	
	INSERT INTO @tblrecommend (recommend)
	SELECT DISTINCT recommend FROM dbo.MemberInfo WITH (NOLOCK)

	CREATE TABLE #tempData
	(
		AffId		INT,
		IBCCustId	INT,
		Currency	INT,
		Turnover	MONEY,
		Winloss		MONEY,
		AWinloss	MONEY,
		AComm		MONEY
	)

	-- AG Casino
	IF @ProductId = 9
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			a.IBCCustId,
			a.currency,
			a.Turnover,
			a.Winloss
		FROM
		(
			SELECT
				b.custid AS IBCCustId,
				b.currency,
				SUM(ISNULL(b.stake, 0)) AS Turnover,
				SUM(ISNULL(b.winlost, 0) - ISNULL(b.actual_stake, 0)) AS Winloss
			FROM bodb_PlaytechCS.dbo.bettrans_AGCasino b WITH (NOLOCK)
				INNER JOIN @tblrecommend r ON b.recommend = r.recommend
			WHERE
				b.WinlostDate = @WinlostDate
				AND b.statusID IN (111, 112, 113)
			GROUP BY
				b.custid,
				b.currency
		) AS a
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON mi.IBCCustId = a.IBCCustId
		WHERE NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
	END
	-- Gold Deluxe
	ELSE IF @ProductId = 17
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			a.IBCCustId,
			a.currency,
			a.Turnover,
			a.Winloss
		FROM
		(
			SELECT
				b.custid AS IBCCustId,
				b.currency,
				SUM(ISNULL(b.stake, 0)) AS Turnover,
				SUM(ISNULL(b.winlost, 0) - ISNULL(b.stake, 0)) AS Winloss
			FROM bodb_PlaytechCS.dbo.bettrans_GoldDeluxe b WITH (NOLOCK)
				INNER JOIN @tblrecommend r ON b.recommend = r.recommend
			WHERE
				b.WinlostDate = @WinlostDate
				AND b.statusID IN (111, 112, 113)
			GROUP BY
				b.custid,
				b.currency
		) AS a
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON mi.IBCCustId = a.IBCCustId
		WHERE NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
	END
	-- Exchange
	ELSE IF @ProductId = 19
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss,
			AWinloss,
			AComm
		)
		SELECT
			a.AffId,
			a.IBCCustId,
			a.currency,
			a.Turnover,
			a.Winloss,
			-a.Winloss * (1 - ISNULL(r.Rate, 0)) AS AWinloss,
			a.AComm
		FROM
		(
			SELECT
				mi.AffId,
				mi.IBCCustId,
				mi.currency,
				SUM(ISNULL(b.stakeTotal / b.ExVirtualRate, 0))		AS Turnover,
				SUM(ISNULL(b.profitLoss / b.ExVirtualRate, 0))		AS Winloss,
				SUM(ISNULL(b.agentCommission / b.ExVirtualRate, 0)) AS AComm
			FROM bodb_3rdProduct.dbo.Sum_winloss_Exchange b WITH (NOLOCK)
				INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON mi.IBCCustId = b.custid
			WHERE b.settledDate >= @WinlostDate AND b.settledDate < DATEADD(DAY, 1, @WinlostDate)
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
						AND mi.IBCCustId = mr.IBCCustId
				)
			GROUP BY
				mi.AffId,
				mi.IBCCustId,
				mi.currency
		) AS a
			OUTER APPLY (
				SELECT DI_Rate AS Rate FROM bodb_licensee.dbo.LA_f_ChargeInfo('14', @WinlostDate, @WinlostDate, 'BX', 'OA', 1)
				WHERE DI_Rate > 0 AND ChargeType = 1
			) AS r
	END
	ELSE
	BEGIN
		-- Prevent input wrong ProductId
		RETURN
	END

	-- Import data
	BEGIN
		;WITH CTE_rptMemberDaily AS
		(
			SELECT IBCCustID, AffId, Currency, AffExRate, ExRate, Bonus, Turnover, Winloss, AWinloss, AComm
			FROM dbo.rptMemberDaily WITH (NOLOCK)
			WHERE winlostdate = @WinlostDate AND ProductId = @ProductId
		)
		SELECT
			CASE	WHEN t.IBCCustId IS NULL THEN -1 -- delete
					WHEN r.IBCCustId IS NULL THEN 1 -- insert
					ELSE 0 END AS ModifiedType-- update
			,ISNULL(t.IBCCustId, r.IBCCustId) AS IBCCustId
			,t.AffId, t.Currency, t.AffExRate, t.ExRate, t.Turnover, t.Winloss, t.AWinloss, t.AComm
		INTO #__Data
		FROM (
			SELECT AffId,IBCCustId,Turnover,Winloss,AWinloss,AComm,Currency,e.ActualRate AS ExRate,e.ActualRate2 AS AffExRate
			FROM #tempData d
				CROSS APPLY dbo.Aff_f_ExchangeRateById_Sel(d.Currency, @WinlostDate) e
		) t
			FULL OUTER JOIN CTE_rptMemberDaily r ON t.IBCCustId = r.IBCCustId

		DROP TABLE #tempData

		-- Delete
		IF EXISTS (SELECT 1 FROM #__Data WHERE ModifiedType = -1)
		BEGIN
			DELETE r WITH (ROWLOCK, UPDLOCK)
			FROM dbo.rptMemberDaily r
				INNER JOIN #__Data d ON d.IBCCustId = r.IBCCustId
			WHERE r.WinlostDate = @WinlostDate
				AND r.ProductId = @ProductId
				AND d.ModifiedType = -1

			DELETE #__Data WHERE ModifiedType = -1
		END
				
		-- Insert
		IF EXISTS (SELECT 1 FROM #__Data WHERE ModifiedType = 1)
		BEGIN
			DELETE #__Data
			OUTPUT @WinlostDate WinlostDate,DELETED.AffId,DELETED.IBCCustId,@ProductId ProductId
					,0 Deposit,0 Withdrawal,0 Bonus,0 Adjustment,DELETED.Turnover,DELETED.Winloss
					,DELETED.Currency,DELETED.ExRate,DELETED.AffExRate,DELETED.AWinloss,DELETED.AComm
			INTO dbo.rptMemberDaily(WinlostDate,AffId,IBCCustId,ProductId,Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,Currency,ExRate,AffExRate,AWinloss,AComm)
			WHERE ModifiedType = 1
		END

		-- Update
		IF EXISTS (SELECT 1 FROM #__Data WHERE ModifiedType = 0)
		BEGIN
			UPDATE r WITH (ROWLOCK)
			SET r.AffId = d.AffId
				,r.Deposit = 0
				,r.Withdrawal = 0
				,r.Bonus = 0
				,r.Adjustment = 0
				,r.Turnover = d.Turnover
				,r.Winloss = d.Winloss
				,r.Currency = d.Currency
				,r.ExRate = d.ExRate
				,r.AffExRate = d.AffExRate
				,r.AWinloss = d.AWinloss
				,r.AComm = d.AComm
			FROM dbo.rptMemberDaily r
				INNER JOIN #__Data d ON d.IBCCustId = r.IBCCustId
			WHERE r.WinlostDate = @WinlostDate
				AND r.ProductId = @ProductId
				AND d.ModifiedType = 0
				AND (
					r.AffId <> d.AffId
					OR r.Turnover <> d.Turnover
					OR r.Winloss <> d.Winloss
					OR r.AWinloss <> d.AWinloss
					OR r.AComm <> d.AComm
					OR r.Currency <> d.Currency
					OR r.ExRate <> d.ExRate
					OR r.AffExRate <> d.AffExRate
				)
		END

		DROP TABLE #__Data
	END
END
GO