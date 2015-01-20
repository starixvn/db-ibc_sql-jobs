USE [Affiliate_12BET]
GO

/****** Object:  StoredProcedure [dbo].[Task_Aff_MemberDailySummary]    Script Date: 01/19/2015 23:53:19 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_Aff_MemberDailySummary    Script Date: 12/18/2014 9:54:29 AM ******/
CREATE PROCEDURE [dbo].[Task_Aff_MemberDailySummary] 
	@winlostdate DATETIME
AS
/*  
 Created: 20090701@Peter  
 Task : Summary data from 12BET Affiliates members, This task will occurs every 2 hours and every day at 00:00  
 DB: DB052.Affiliate_12Bet  
  
 Revisions:      
     20100527@Peter: Use new StatusID column instead of Status column on bettrans table     
     20100923@Peter : Change new way to calculate PSP fee ,   
         *** we cannot recalculate the PSP before 1 Oct 2010 (coz this time we use new formula to calculate)  
         + Before 1/4/2010   
          MemWinlostFake=MemWinlost  
         + From 1/4/2010-> 30/9/2010   
           
          MemWinlostFake = MemWinlost * NetPercentReceive  
          Select @MemWinlost=[dbo].[Aff_GetMemberWinlost] (@AffID, @SportsBookID, @monthdate)  
          select @NetPercentReceived = (case when @MemWinlost > 0 then 1 + @Percent else 1 - @Percent end)  
       + From 1/10/2010:  
          MemWinlostFake=(case when MemberWinlost>0 then MemberWinlost * (1 + @MarketingPercent + @OddsFeePercent) - PSP  
               else  MemberWinlost * (1 - @MarketingPercent - @OddsFeePercent) - PSP  
              end )  
     20101228@Henry: change bettype to new range        
     20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])  
     20120531@Peter: Just allow to calculate data for members who is assigned manually from the day they have been created on affiliate DB  
     20120716@Peter: Exclude HorseRacing data and waiting tickets, just calculate Sportsbook     
     20130306@Peter: Sportbook bettype is less than 999 and exclude bettype from 31 to 120
     20130307@Peter:  Get data from  DB052.bodb_Licensee
	 20140402@Dan:  exclude Keno product
	 20141125@Bobby:  Add 2 more columns OpeningBalance & ClosingBalance
	 20141217@Bobby:  Include Sporting Solution's tickets
	 
  
 Param's Explanation:  
 • @winlostdate: The data need to summary  
*/
-- HARD CODE: not cal before 1st OCt 2010 (New formula is lauched)  
-- HARD CODE: not cal before 1st Nov 2011 (Exclude Number Game from Sportsbook commission)  
BEGIN
	SET NOCOUNT ON

	IF @Winlostdate < '1 Nov 2011'
		OR @Winlostdate > current_timestamp RETURN

	IF EXISTS (
			SELECT TOP (1) *
			FROM AffCommission(NOLOCK)
			WHERE datediff(m, winlostdate, @Winlostdate) = 0
			) RETURN

	DECLARE @CutDate DATETIME
		,@MoveBetsDay DATETIME

	SELECT @CutDate = min(winlostdate)
	FROM DBRPT.bodb_report.dbo.rptdepwinlost WITH (NOLOCK)

	SELECT @MoveBetsDay = max(eventdate)
	FROM bodb02.dbo.match14 WITH (NOLOCK)

	DECLARE @AffExchange TABLE (
		ExchangeID INT PRIMARY KEY
		,ActualRate FLOAT
		,ActualRate2 FLOAT
		,DepositPercent FLOAT
		,WithdrawalPercent FLOAT
		)

	IF (datediff(d, @Winlostdate, current_timestamp) = 0)
	BEGIN
		INSERT INTO @AffExchange (
			ExchangeID
			,ActualRate
			,ActualRate2
			,DepositPercent
			,WithdrawalPercent
			)
		SELECT ExchangeID
			,ActualRate
			,ActualRate2
			,DepositPercent
			,WithdrawalPercent
		FROM Exchange_Current e WITH (NOLOCK)
	END
	ELSE
	BEGIN
		/*  
  ****** Note: We must insert at least on row for each currency into Exchange table  
      when new DB is launched  
  */
		INSERT INTO @AffExchange (
			ExchangeID
			,ActualRate
			,ActualRate2
			,DepositPercent
			,WithdrawalPercent
			)
		SELECT ExchangeID
			,ActualRate
			,ActualRate2
			,DepositPercent
			,WithdrawalPercent
		FROM Exchange e WITH (NOLOCK)
		WHERE e.UpdatedTime = (
				SELECT max(e1.UpdatedTime)
				FROM Exchange e1 WITH (NOLOCK)
				WHERE e1.ExchangeID = e.ExchangeID
					AND UpdatedTime <= @Winlostdate
				)
	END

	CREATE TABLE #Member (
		CustID INT
		,AffID INT
		,Currency INT
		)

	INSERT INTO #Member (
		CustID
		,AffID
		,Currency
		)
	SELECT IBCCustID
		,AffID
		,Currency
	FROM MemberInfo m WITH (NOLOCK)
	WHERE CreatedDate IS NOT NULL
		AND datediff(d, CreatedDate, @WinlostDate) >= 0
		AND IBCCustID NOT IN (
			SELECT IBCCustID
			FROM MemberRemoval WITH (NOLOCK)
			WHERE datediff(mm, RemovedDate, @Winlostdate) >= 0
			)

	CREATE TABLE #Data (
		IBCCustID INT PRIMARY KEY
		,Currency INT
		,Deposit MONEY
		,Withdrawal MONEY
		,Bonus MONEY
		,Adjustment MONEY
		,TurnOver MONEY
		,Outstanding MONEY
		,Winlost MONEY
		,DrawGame MONEY
		,AffExRate FLOAT
		,MemberExRate FLOAT
		,PSP MONEY
		,Marketing MONEY
		,AffID INT
		,OpeningBalance MONEY
		,ClosingBalance MONEY
		)

	IF DATEDIFF(d, @winlostdate, CURRENT_TIMESTAMP) <= 1
	BEGIN
		INSERT INTO #Data (
			IBCCustID
			,Deposit
			,Withdrawal
			,Bonus
			,Adjustment
			,TurnOver
			,DrawGame
			,Outstanding
			,Winlost
			,Currency
			,AffExRate
			,MemberExRate
			,AffID
			,OpeningBalance
			,ClosingBalance
			)
		SELECT b.custid
			,isnull(sum(CASE bettype
						WHEN 22001 THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
						ELSE 0
						END), 0) AS Deposit
			,- isnull(sum(CASE 
						WHEN bettype IN (22002, 22003) THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
						ELSE 0
						END), 0) AS Withdrawal
			,isnull(sum(CASE bettype
						WHEN 22004 THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
						ELSE 0
						END), 0) AS Bonus
			,isnull(sum(CASE 
						WHEN bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0)
						ELSE 0
						END), 0) AS Adjustment
			,isnull(sum(CASE 
						WHEN (bettype <= 999 
								OR ( bettype BETWEEN 1301 AND 1399)
							) THEN isnull(abs(stake), 0)
						ELSE 0
						END), 0) AS Turnover
			,isnull(sum(CASE 
						WHEN (bettype <= 999 
								OR ( bettype BETWEEN 1301 AND 1399)
							)
							AND StatusID = 111 /*status in ('DRAW')*/ THEN isnull(abs(stake), 0)
						ELSE 0
						END), 0) AS DrawGame
			,isnull(sum(CASE 
						WHEN (bettype <= 999 
								OR ( bettype BETWEEN 1301 AND 1399)
							)
							AND ruben = 0 THEN isnull(abs(actual_stake), 0)
						ELSE 0
						END), 0) AS Outstanding
			,isnull(sum(CASE 
						WHEN (bettype <= 999 
								OR ( bettype BETWEEN 1301 AND 1399)
							)
							AND ruben = 1 THEN isnull(winlost, 0) - isnull(abs(actual_stake), 0) + isnull(playercomm, 0)
						ELSE 0
						END), 0) AS Winlost
			,b.currency
			,e.ActualRate2
			,e.ActualRate
			,m.AffID
			,0 AS OpeningBalance
			,0 AS ClosingBalance
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #Member m
			ON m.CustID = b.custid
			INNER JOIN @AffExchange e
			ON e.ExchangeID = b.currency
		WHERE winlostdate = @winlostdate
			AND (
				bettype <= 999
				OR ( bettype BETWEEN 1301 AND 1399) -- SS tickets
				OR bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005)
			) --get SB only
			AND bettype NOT BETWEEN 31 AND 120 --Not include Casino and Number Game and finance
			AND bettype NOT IN (1000) --games
			AND bettype NOT BETWEEN 1101 AND 1199 -- Live Casino
			AND bettype NOT BETWEEN 1201 AND 1299 --Virtual Sport	
			AND bettype NOT BETWEEN 1501 AND 1599 -- Keno  
			AND StatusID NOT IN (101, 102, 103, 121, 1)
			
		GROUP BY b.custid
			,b.currency
			,e.ActualRate2
			,e.ActualRate
			,m.AffID
			
		-- update openning/closing balance
		UPDATE d
		SET d.OpeningBalance 	= rpt.OpeningBalance
			, d.ClosingBalance 	= rpt.ClosingBalance
			
		FROM #Data d
			INNER JOIN DBRPT.bodb_report.dbo.rptdepwinlost rpt with(nolock)
			ON d.IBCCustID = rpt.custid
				
		WHERE rpt.winlostdate = @winlostdate
				
	END
	ELSE IF @Winlostdate < @CutDate
	BEGIN
		INSERT INTO #Data (
			IBCCustID
			,TurnOver
			,DrawGame
			,Outstanding
			,Winlost
			,Currency
			,AffExRate
			,MemberExRate
			,AffID
			)
		SELECT b.CustID
			,isnull(b.turnover, 0)
			,isnull(b.drawTO, 0)
			,isnull(b.Outstanding, 0)
			,isnull(b.winlost, 0)
			,m.Currency
			,e.ActualRate2
			,e.ActualRate
			,m.AffID
		FROM DBRPT.bodb_Report.dbo.rptDepWinlostByProduct_bk b WITH (NOLOCK)
			INNER JOIN #Member m
			ON m.CustID = b.custid
			INNER JOIN @AffExchange e
			ON e.ExchangeID = m.currency
		WHERE b.winlostdate = @Winlostdate
			AND b.SportType = 0

		UPDATE d
		SET Deposit 			= isnull(b.deposit, 0)
			,Withdrawal 		= isnull(b.withdrawal, 0)
			,Bonus 				= isnull(b.Bonus, 0)
			,Adjustment 		= isnull(b.Adjustment, 0)
			,OpeningBalance 	= ISNULL(b.OpeningBalance, 0)
			,ClosingBalance 	= ISNULL(b.ClosingBalance, 0)
		FROM #Data d
			INNER JOIN DBRPT.bodb_Report.dbo.rptDepWinlost_bk b WITH (NOLOCK)
			ON b.CustID = d.IBCCustID
		WHERE b.winlostdate = @Winlostdate

		INSERT INTO #Data (
			IBCCustID
			,TurnOver
			,DrawGame
			,Outstanding
			,Winlost
			,Currency
			,AffExRate
			,MemberExRate
			,AffID
			,Deposit
			,Withdrawal
			,Bonus
			,Adjustment
			,OpeningBalance
			,ClosingBalance
			)
		SELECT m.CustID
			,0
			,0
			,0
			,0
			,m.Currency
			,e.ActualRate2
			,e.ActualRate
			,m.AffID
			,isnull(b.deposit, 0)
			,isnull(b.withdrawal, 0)
			,isnull(b.Bonus, 0)
			,isnull(b.Adjustment, 0)
			,ISNULL(b.OpeningBalance, 0)
			,ISNULL(b.ClosingBalance, 0)
		FROM DBRPT.bodb_Report.dbo.rptDepWinlost_bk b WITH (NOLOCK)
			INNER JOIN #Member m
			ON m.CustID = b.custid
			INNER JOIN @AffExchange e
			ON e.ExchangeID = m.currency
		WHERE b.winlostdate = @Winlostdate
			AND b.CustID NOT IN (
				SELECT IBCCustID
				FROM #Data WITH (NOLOCK)
				)
	END
	ELSE IF @Winlostdate >= @CutDate
	BEGIN
		INSERT INTO #Data (
			IBCCustID
			,TurnOver
			,DrawGame
			,Outstanding
			,Winlost
			,Currency
			,AffExRate
			,MemberExRate
			,AffID
			)
		SELECT b.CustID
			,isnull(b.turnover, 0)
			,isnull(b.drawTO, 0)
			,isnull(b.Outstanding, 0)
			,isnull(b.winlost, 0)
			,m.Currency
			,e.ActualRate2
			,e.ActualRate
			,m.AffID
		FROM DBRPT.bodb_Report.dbo.rptDepWinlostByProduct b WITH (NOLOCK)
			INNER JOIN #Member m
			ON m.CustID = b.custid
			INNER JOIN @AffExchange e
			ON e.ExchangeID = m.currency
		WHERE b.winlostdate = @Winlostdate
			AND b.SportType = 0

		UPDATE d
		SET Deposit 			= isnull(b.deposit, 0)
			,Withdrawal 		= isnull(b.withdrawal, 0)
			,Bonus 				= isnull(b.Bonus, 0)
			,Adjustment 		= isnull(b.Adjustment, 0)
			,OpeningBalance 	= ISNULL(b.OpeningBalance, 0)
			,ClosingBalance 	= ISNULL(b.ClosingBalance, 0)
		FROM #Data d
			INNER JOIN DBRPT.bodb_Report.dbo.rptDepWinlost b WITH (NOLOCK)
			ON b.CustID = d.IBCCustID
		WHERE b.winlostdate = @Winlostdate

		INSERT INTO #Data (
			IBCCustID
			,TurnOver
			,DrawGame
			,Outstanding
			,Winlost
			,Currency
			,AffExRate
			,MemberExRate
			,AffID
			,Deposit
			,Withdrawal
			,Bonus
			,Adjustment
			,OpeningBalance
			,ClosingBalance
			)
		SELECT m.CustID
			,0
			,0
			,0
			,0
			,m.Currency
			,e.ActualRate2
			,e.ActualRate
			,m.AffID
			,isnull(b.deposit, 0)
			,isnull(b.withdrawal, 0)
			,isnull(b.Bonus, 0)
			,isnull(b.Adjustment, 0)
			,ISNULL(b.OpeningBalance, 0)
			,ISNULL(b.ClosingBalance, 0)
		FROM DBRPT.bodb_Report.dbo.rptDepWinlost b WITH (NOLOCK)
			INNER JOIN #Member m
			ON m.CustID = b.Custid
			INNER JOIN @AffExchange e
			ON e.ExchangeID = m.currency
		WHERE b.winlostdate = @Winlostdate
			AND b.CustID NOT IN (
				SELECT IBCCustID
				FROM #Data WITH (NOLOCK)
				)
	END

	DROP TABLE #Member

	DECLARE @SportsBookID INT

	SELECT @SportsBookID = dbo.Aff_GetSportID('SportsBook')

	DELETE
	FROM MemberDaily
	WHERE winlostdate = @winlostdate
		AND SportType = @SportsBookID

	INSERT INTO MemberDaily (
		WinlostDate
		,IBCCustID
		,Sporttype
		,Currency
		,Deposit
		,Withdrawal
		,Bonus
		,Adjustment
		,Turnover
		,Outstanding
		,Winlost
		,AffExRate
		,MemberExRate
		,DrawGame
		,PSP
		,Marketing
		,AffID
		,MemOddsFee
		,MemWinlostFake
		,OpeningBalance
		,ClosingBalance
		)
	SELECT @WinlostDate
		,IBCCustID
		,@SportsBookID AS SportType
		,--SportsBook  
		Currency
		,Deposit
		,Withdrawal
		,Bonus
		,Adjustment
		,Turnover
		,Outstanding
		,Winlost
		,AffExRate
		,MemberExRate
		,DrawGame
		,(abs(Deposit) * e.DepositPercent + abs(Withdrawal) * e.WithdrawalPercent) AS PSP
		,abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, @SportsBookID, 'Marketing', @WinlostDate), 0) AS Marketing
		,AffID
		,abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, @SportsBookID, 'Odds Fee', @WinlostDate), 0) AS MemOddsFee
		,- (- Winlost - ((abs(Deposit) * e.DepositPercent + abs(Withdrawal) * e.WithdrawalPercent)) * isnull(dbo.Aff_GetDeductionPercent(AffID, @SportsBookID, 'PSP', @WinlostDate), 0) - abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, @SportsBookID, 'Marketing', @WinlostDate), 0) - abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, @SportsBookID, 'Odds Fee', @WinlostDate), 0)) AS MemWinlostFake
		,OpeningBalance
		,ClosingBalance
	FROM #Data d WITH (NOLOCK)
		INNER JOIN @AffExchange e
		ON e.ExchangeID = d.currency
	WHERE Deposit <> 0
		OR Withdrawal <> 0
		OR Bonus <> 0
		OR Adjustment <> 0
		OR TurnOver <> 0
		OR DrawGame <> 0
		OR Outstanding <> 0
		OR Winlost <> 0

	DROP TABLE #Data

	--Update table AffDaily.  
	DELETE
	FROM AffDaily
	WHERE winlostdate = @winlostdate
		AND sportid = @SportsBookID

	INSERT INTO AffDaily (
		[AffID]
		,[Currency]
		,[Winlostdate]
		,[SportID]
		,[ExRate2]
		,[MemDeposit]
		,[MemWithdrawal]
		,[MemTurnover]
		,[MemBonus]
		,[MemAdjustment]
		,[MemMarketing]
		,[MemPSP]
		,[MemWinlost]
		,[AffWinlost]
		,[HouseWinlost]
		,[AffNetWinlost]
		,[HouseNetWinlost]
		,[MemWinlostFake]
		,[MemOddsFee]
		)
	SELECT d.AffID AS AffID
		,d.Currency AS Currency
		,d.Winlostdate AS Winlostdate
		,d.SportType AS SportID
		,d.AffExRate AS Exrate2
		,SUM(isnull(d.Deposit, 0)) AS MemDeposit
		,SUM(isnull(d.Withdrawal, 0)) AS MemWithdrawal
		,SUM(isnull(d.Turnover, 0)) AS MemTurnover
		,SUM(isnull(d.Bonus, 0)) AS MemBonus
		,SUM(isnull(d.Adjustment, 0)) AS MemAdjustment
		,0 AS MemMarketing
		,SUM(isnull(d.PSP, 0)) AS MemPSP
		,SUM(isnull(d.Winlost, 0)) AS MemWinLost
		,0 AS AffWinLost
		,- SUM(d.Winlost) AS HouseWinLost
		,0 AS AffNetWinlost
		,0 AS HouseNetWinLost
		,0 AS MemWinlostFake
		,0 AS MemOddsFee
	FROM MemberDaily d WITH (NOLOCK)
	WHERE d.WinlostDate = @winlostdate
		AND SportType = @SportsBookID
	GROUP BY d.AffID
		,d.Winlostdate
		,d.Currency
		,d.SportType
		,d.AffExRate

	UPDATE AffDaily WITH (ROWLOCK, UPDLOCK)
	SET [MemMarketing] = abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', Winlostdate), 0)
		,MemOddsFee = abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', Winlostdate), 0)
		,HouseNetWinLost = HouseWinLost - isnull(MemBonus, 0) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Bonus', Winlostdate), 0) - isnull(MemAdjustment, 0) - isnull(MemPSP, 0) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'PSP', Winlostdate), 0) - abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', Winlostdate), 0) - abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', Winlostdate), 0)
		,MemWinlostFake = - (- isnull(MemWinlost, 0) - isnull(MemPSP, 0) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'PSP', Winlostdate), 0) - abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', Winlostdate), 0) - abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', Winlostdate), 0))
	WHERE WinlostDate = @winlostdate
		AND sportid = @SportsBookID

	DELETE
	FROM AffDailySummary
	WHERE winlostdate = @winlostdate
		AND sportid = @SportsBookID

	INSERT INTO [dbo].[AffDailySummary] (
		[AffID]
		,[Winlostdate]
		,[SportID]
		,[MemDeposit]
		,[MemWithdrawal]
		,[MemTurnover]
		,[MemBonus]
		,[MemAdjustment]
		,[MemMarketing]
		,[MemPSP]
		,[MemWinlost]
		,[AffWinlost]
		,[HouseWinlost]
		,[AffNetWinlost]
		,[HouseNetWinlost]
		,[MemOddsFee]
		,[MemWinlostFake]
		)
	SELECT [AffID]
		,[Winlostdate]
		,[SportID]
		,sum([MemDeposit] * ExRate2) AS MemDeposit
		,sum([MemWithdrawal] * ExRate2) AS MemWithdrawal
		,sum([MemTurnover] * ExRate2) AS MemTurnover
		,sum([MemBonus] * ExRate2) AS MemBonus
		,sum([MemAdjustment] * ExRate2) AS MemAdjustment
		,0 AS MemMarketing
		,sum([MemPSP] * ExRate2) AS MemPSP
		,sum([MemWinlost] * ExRate2) AS MemWinlost
		,sum([AffWinlost] * ExRate2) AS AffWinlost
		,sum([HouseWinlost] * ExRate2) AS HouseWinlost
		,sum([AffNetWinlost] * ExRate2) AS AffNetWinlost
		,sum([HouseNetWinlost] * ExRate2) AS HouseNetWinlost
		,0 AS MemOddsFee
		,0 AS MemWinlostFake
	FROM AffDaily(NOLOCK)
	WHERE WinlostDate = @winlostdate
		AND sportid = @SportsBookID
	GROUP BY AffID
		,Winlostdate
		,SportID

	UPDATE AffDailySummary WITH (ROWLOCK, UPDLOCK)
	SET MemOddsFee = abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', WinlostDate)
		,MemMarketing = abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', WinlostDate)
		,MemWinlostFake = - (- MemWinlost - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', WinlostDate) - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', WinlostDate) - MemPSP * dbo.Aff_GetDeductionPercent(AffID, SportID, 'PSP', WinlostDate))
		,HouseNetWinlost = (- MemWinlost - MemBonus * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Bonus', WinlostDate) - MemAdjustment - MemPSP * dbo.Aff_GetDeductionPercent(AffID, SportID, 'PSP', WinlostDate) - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', WinlostDate) - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', WinlostDate))
	WHERE WinlostDate = @winlostdate
		AND sportid = @SportsBookID

	/*update last MemWinlostFake of last transaction date for each acount  
 For example: Affiliate 1 : last day =28/11  
    Affiliate 2 : last day= 29/11  
    Affiliate 3 : last day= 31/11          
 */
	DECLARE @temp TABLE (
		affid INT
		,SportID INT
		,totalWinlost MONEY
		,oddsFeePercent FLOAT
		,marketingPercent FLOAT
		,PSPPercent FLOAT
		,WLFake MONEY
		,totalPSP MONEY
		,maxWinlostDate SMALLDATETIME
		,previousMaxWinlostDate SMALLDATETIME
		,firstday SMALLDATETIME
		)

	INSERT INTO @temp (
		Affid
		,maxWinlostDate
		,SportID
		)
	SELECT affid
		,max(winlostdate)
		,sportid
	FROM AffDailySummary(NOLOCK)
	WHERE datediff(m, @winlostdate, WinlostDate) = 0
		AND sportid = @SportsBookID
	GROUP BY affid
		,SportID
		,month(winlostdate)
		,year(winlostdate)

	UPDATE t
	SET t.previousMaxWinlostDate = isnull((
				SELECT max(winlostdate)
				FROM AffDailySummary(NOLOCK)
				WHERE sportid = t.SportID
					AND winlostdate < t.maxWinlostDate
					AND datediff(m, winlostdate, t.maxWinlostDate) = 0
					AND affid = t.affid
				), t.maxWinlostDate)
		,t.firstday = [dbo].[Aff_GetFirstDayOfMonth](t.maxWinlostDate)
		,t.oddsFeePercent = dbo.Aff_GetDeductionPercent(AffID, t.SportID, 'Odds Fee', [dbo].[Aff_GetLastDayOfMonth](t.maxWinlostDate))
		,t.marketingPercent = dbo.Aff_GetDeductionPercent(AffID, t.SportID, 'Marketing', [dbo].[Aff_GetLastDayOfMonth](t.maxWinlostDate))
		,t.PSPPercent = dbo.Aff_GetDeductionPercent(AffID, t.SportID, 'PSP', [dbo].[Aff_GetLastDayOfMonth](t.maxWinlostDate))
	FROM @temp t

	--reupdate WinlostFake of previousMaxWinlostDate for MemberDaily, AffDaily, AffDailySummary  
	UPDATE ad
	SET ad.MemWinlostFake = - (- isnull(ad.MemWinlost, 0) - abs(isnull(ad.MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID, t.SportID, 'Odds Fee', ad.Winlostdate), 0) - abs(isnull(ad.MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID, t.SportID, 'Marketing', ad.Winlostdate), 0) - isnull(ad.MemPSP, 0) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID, t.SportID, 'PSP', ad.Winlostdate), 0))
	FROM AffDailySummary ad WITH (ROWLOCK, UPDLOCK)
		INNER JOIN @temp t
		ON t.affid = ad.AffID
			AND t.previousMaxWinlostDate = ad.WinlostDate
			AND t.SportID = ad.SportID

	UPDATE d
	SET d.totalWinlost = isnull(c.totalwinlost, 0)
		,d.WLFake = isnull(c.memWinlostFake, 0)
		,d.totalPSP = isnull(c.memPSP, 0)
	FROM @temp d
		LEFT JOIN (
		SELECT t.affid
			,t.SportID
			,sum(ad.memwinlost) totalwinlost
			,sum(ad.memWinlostFake) memWinlostFake
			,sum(ad.MemPSP) AS memPSP
		FROM AffDailySummary ad(NOLOCK)
			INNER JOIN @temp t
			ON t.AffID = ad.AffID
				AND t.SportID = ad.SportID
		WHERE ad.WinlostDate BETWEEN t.firstday AND t.previousMaxWinlostDate
			AND ad.SportID = @SportsBookID
		GROUP BY t.Affid
			,t.SportID
		) c
		ON c.AffID = d.AffID
			AND c.SportID = d.SportID

	--select * from @temp  
	UPDATE d
	SET MemWinlostFake = - (- (d1.totalwinlost + d.memwinlost) - abs(d1.totalwinlost + d.memwinlost) * (d1.oddsFeePercent + d1.marketingPercent) - (d1.totalPSP + d.MemPSP) * d1.PSPPercent) - d1.WLFake
	FROM AffDailySummary d WITH (ROWLOCK, UPDLOCK)
		INNER JOIN @temp d1
		ON d1.affid = d.affid
			AND d1.maxWinlostDate = d.winlostdate
			AND d1.SportID = d.SportID
	WHERE d.sportid = @SportsBookID
		AND d1.previousMaxWinlostDate < d1.maxWinlostDate
END
GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_MemberDailySummary] TO [vnAffiliate] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Task_Aff_MemberDailySummary] TO [vnteam] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_MemberDailySummary] TO [vnteam] AS [dbo]
GO


