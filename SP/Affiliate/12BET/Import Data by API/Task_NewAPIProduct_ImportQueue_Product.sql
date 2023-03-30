/*<info serverAlias="DBAFF12BET-Affiliate_12BET" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_NewAPIProduct_ImportQueue_Product]
	@ProductId		INT,
	@WinlostDate	SMALLDATETIME
AS

/*
	Created: 20221118@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Import Data Job - API Products

	Revisions:
		- 20221118@Malcolm: Initialize SP [RedmineID: #180311]
		
*/

BEGIN
	SET NOCOUNT ON

	CREATE TABLE #tempData
	(
		AffId		INT,
		IBCCustId	INT,
		Currency	INT,
		Turnover	MONEY,
		Winloss		MONEY
	)

	DECLARE @TpType INT = -1, @SubItem VARCHAR(200) = '', @ExcludeTicketStatus VARCHAR(200) = ''

	SELECT @ExcludeTicketStatus = SettingValue FROM dbo.APIProductSettings WITH(NOLOCK) WHERE ProductId = @ProductId AND SettingName = 'ExcludeTicketStatus'

	SELECT @TpType = TpType, @SubItem = SubItem FROM dbo.APIProductMappingSettings WITH(NOLOCK) WHERE ProductId = @ProductId  

	IF ISNULL(@TpType, -1) = -1
		RETURN

	--Get data
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
			mi.IBCCustId,
			mi.currency,
			SUM(ISNULL(b.ValidBet, 0)) AS Turnover,
			SUM(ISNULL(b.Win, 0) - ISNULL(b.ValidBet, 0)) AS Winloss
		FROM dbo.bettrans_APIProducts b WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON b.IBCCustId = mi.IBCCustId
		WHERE b.WinlostDate = @WinlostDate AND b.TpType = @TpType AND b.SubItem = @SubItem
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			) AND (@ExcludeTicketStatus = '' OR ',' + @ExcludeTicketStatus + ',' NOT LIKE '%,' + b.BetStatus + ',%')
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END

	-- Import data
	BEGIN
		;WITH CTE_rptMemberDaily AS
		(
			SELECT IBCCustID, AffId, Currency, AffExRate, ExRate, Bonus, Turnover, Winloss
			FROM dbo.rptMemberDaily WITH (NOLOCK)
			WHERE winlostdate = @WinlostDate AND ProductId = @ProductId
		)
		SELECT
			CASE	WHEN t.IBCCustId IS NULL THEN -1 -- delete
					WHEN r.IBCCustId IS NULL THEN 1 -- insert
					ELSE 0 END AS ModifiedType-- update
			,ISNULL(t.IBCCustId, r.IBCCustId) AS IBCCustId
			,t.AffId, t.Currency, t.AffExRate, t.ExRate, t.Turnover, t.Winloss
		INTO #__Data
		FROM (
			SELECT AffId,IBCCustId,Turnover,Winloss,Currency,e.ActualRate AS ExRate,e.ActualRate2 AS AffExRate
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
					,DELETED.Currency,DELETED.ExRate,DELETED.AffExRate,0 AWinloss,0 AComm
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
				,r.AWinloss = 0
				,r.AComm = 0
			FROM dbo.rptMemberDaily r
				INNER JOIN #__Data d ON d.IBCCustId = r.IBCCustId
			WHERE r.WinlostDate = @WinlostDate
				AND r.ProductId = @ProductId
				AND d.ModifiedType = 0
				AND (
					r.AffId <> d.AffId
					OR r.Turnover <> d.Turnover
					OR r.Winloss <> d.Winloss
					OR r.Currency <> d.Currency
					OR r.ExRate <> d.ExRate
					OR r.AffExRate <> d.AffExRate
				)
		END

		DROP TABLE #__Data
	END
END
GO