USE [Affiliate_12BET]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYNC_AFF12BET_TableSUM]    Script Date: 01/20/2015 22:49:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYNC_AFF12BET_TableSUM]

AS
/*
	Created by:Jamie
	Task: Sync tables ( only run at standby server)
	DB: DBAFF12BET/Affiliate_12bet
		+ [AffCommission]
		+ [AffDaily]
		+ AffDailySummary
		+ MemberDaily

*/
BEGIN
	SET NOCOUNT ON 
	DECLARE		@Today DATETIME,
				@OldDate DATETIME 
	SELECT		@Today = CONVERT(VARCHAR(10),GETDATE(),120) 
				,@OldDate = @Today -10 

	----[AffCommission]
	IF EXISTS (
			SELECT TOP 1 1
			FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[AffCommission] WITH (NOLOCK)
			WHERE	WinlostDate BETWEEN @OldDate AND @Today
			)
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1
			FROM	[Affiliate_12bet].[dbo].[AffCommission] WITH (NOLOCK)
			WHERE	WinlostDate BETWEEN @OldDate AND @Today
		)
		BEGIN 
			DELETE FROM [Affiliate_12bet].[dbo].[AffCommission] WITH (ROWLOCK)
			WHERE	WinlostDate BETWEEN @OldDate AND @Today
		END

		SET IDENTITY_INSERT [AffCommission] ON 
		INSERT INTO [Affiliate_12bet].[dbo].[AffCommission]
           ([RefID]
           ,[RelNo]
           ,[AffID]
           ,[GroupID]
           ,[SportID]
           ,[WinlostDate]
           ,[QualifiedMember]
           ,[Commission]
           ,[HasBonus]
           ,[HasAdjustment]
           ,[HasMarketing]
           ,[HasPSP]
           ,[AffWinlost]
           ,[Status]
           ,[MemberWinlost]
           ,[MemberBonus]
           ,[MemberAdjustment]
           ,[MemberPSP]
           ,[MemberSum]
           ,[MemberTurnover]
           ,[MemberDeposit]
           ,[Marketing]
           ,[HasOddsFee]
           ,[MemOddsFee]
           ,[HasPlayTechFee]
           ,[MemPlayTechFee])
		SELECT	[RefID]
			   ,[RelNo]
			   ,[AffID]
			   ,[GroupID]
			   ,[SportID]
			   ,[WinlostDate]
			   ,[QualifiedMember]
			   ,[Commission]
			   ,[HasBonus]
			   ,[HasAdjustment]
			   ,[HasMarketing]
			   ,[HasPSP]
			   ,[AffWinlost]
			   ,[Status]
			   ,[MemberWinlost]
			   ,[MemberBonus]
			   ,[MemberAdjustment]
			   ,[MemberPSP]
			   ,[MemberSum]
			   ,[MemberTurnover]
			   ,[MemberDeposit]
			   ,[Marketing]
			   ,[HasOddsFee]
			   ,[MemOddsFee]
			   ,[HasPlayTechFee]
			   ,[MemPlayTechFee]
		FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[AffCommission] WITH (NOLOCK)
		WHERE	WinlostDate BETWEEN @OldDate AND @Today
		SET IDENTITY_INSERT [AffCommission] OFF 
	END

	----[AffDaily]
	IF EXISTS (
		SELECT TOP 1 1
		FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[AffDaily] WITH (NOLOCK)
		WHERE	WinlostDate BETWEEN @OldDate AND @Today
		)
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1
			FROM	[Affiliate_12bet].[dbo].[AffDaily] WITH (NOLOCK)
			WHERE	WinlostDate BETWEEN @OldDate AND @Today
		)
		BEGIN 
			DELETE FROM [Affiliate_12bet].[dbo].[AffDaily] WITH (ROWLOCK)
			WHERE	WinlostDate BETWEEN @OldDate AND @Today
		END
		INSERT INTO [Affiliate_12bet].[dbo].[AffDaily]
			   ([AffID]
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
			   ,[MemPLayTechFee])
		SELECT	[AffID]
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
			   ,[MemPLayTechFee]
		FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[AffDaily] WITH (NOLOCK)
		WHERE	WinlostDate BETWEEN @OldDate AND @Today
	END 

	---[AffDailySummary]
	IF EXISTS (
		SELECT TOP 1 1
		FROM	DBAFF12BET.[Affiliate_12bet].[dbo].AffDailySummary WITH (NOLOCK)
		WHERE	WinlostDate BETWEEN @OldDate AND @Today
		)
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1
			FROM	[Affiliate_12bet].[dbo].AffDailySummary WITH (NOLOCK)
			WHERE	WinlostDate BETWEEN @OldDate AND @Today
		)
		BEGIN 
			DELETE FROM [Affiliate_12bet].[dbo].AffDailySummary WITH (ROWLOCK)
			WHERE	WinlostDate BETWEEN @OldDate AND @Today
		END
		INSERT INTO [Affiliate_12bet].[dbo].[AffDailySummary]
				   ([AffID]
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
				   ,[MemPLayTechFee])
		SELECT	   [AffID]
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
				,[MemPLayTechFee]
		 FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[AffDailySummary]  WITH (ROWLOCK)
		 WHERE	WinlostDate BETWEEN @OldDate AND @Today
	END

	--- [MemberDaily]
	IF EXISTS (
		SELECT TOP 1 1
		FROM	DBAFF12BET.[Affiliate_12bet].[dbo].MemberDaily WITH (NOLOCK)
		WHERE	WinlostDate BETWEEN @OldDate AND @Today
		)
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1
			FROM	[Affiliate_12bet].[dbo].MemberDaily WITH (NOLOCK)
			WHERE	WinlostDate BETWEEN @OldDate AND @Today
		)
		BEGIN 
			DELETE FROM [Affiliate_12bet].[dbo].MemberDaily WITH (ROWLOCK)
			WHERE	WinlostDate BETWEEN @OldDate AND @Today
		END
		INSERT INTO [Affiliate_12bet].[dbo].[MemberDaily]
           ([WinlostDate]
           ,[IBCCustID]
           ,[SportType]
           ,[Currency]
           ,[Deposit]
           ,[Withdrawal]
           ,[Bonus]
           ,[Adjustment]
           ,[Turnover]
           ,[Outstanding]
           ,[Winlost]
           ,[AWinlost]
           ,[ABonus]
           ,[AffExRate]
           ,[MemberExRate]
           ,[DrawGame]
           ,[PSP]
           ,[Marketing]
           ,[AffID]
           ,[MemWinlostFake]
           ,[MemOddsFee]
           ,[MemPLayTechFee]
           ,[OpeningBalance]
           ,[ClosingBalance])
		SELECT	[WinlostDate]
			,[IBCCustID]
			,[SportType]
			,[Currency]
			,[Deposit]
			,[Withdrawal]
			,[Bonus]
			,[Adjustment]
			,[Turnover]
			,[Outstanding]
			,[Winlost]
			,[AWinlost]
			,[ABonus]
			,[AffExRate]
			,[MemberExRate]
			,[DrawGame]
			,[PSP]
			,[Marketing]
			,[AffID]
			,[MemWinlostFake]
			,[MemOddsFee]
			,[MemPLayTechFee]
			,[OpeningBalance]
			,[ClosingBalance]	
		FROM	DBAFF12BET.[Affiliate_12bet].[dbo].MemberDaily WITH (NOLOCK)
		WHERE	WinlostDate BETWEEN @OldDate AND @Today
	END
END


GO


