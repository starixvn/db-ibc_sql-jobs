USE [Affiliate_12BET]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYNC_AFF12BET_TableStatistics]    Script Date: 01/20/2015 22:50:38 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYNC_AFF12BET_TableStatistics]

AS
/*
	Created by:Jamie
	Task: Sync tables ( only run at standby server)
	DB: DBAFF12BET/Affiliate_12bet
		+ ClickStatistics
		+ ClickStatistics1
		+ MemberClickDetail
	Original:
	Revisions:
		- 20141204@Dan: correct the logic to sync MemberClickDetail more exactly
	Param's Explanation:
	
*/
BEGIN
	SET NOCOUNT ON 
	DECLARE		@Today DATETIME,
				@OldDate DATETIME,
				@LastMonth DATETIME
	SELECT		@Today = CONVERT(VARCHAR(10),GETDATE(),120) 
				,@OldDate = @Today -10 
				,@LastMonth = @Today -31

	----[ClickStatistics]
	IF EXISTS (
			SELECT TOP 1 1
			FROM	DBAFF12BET.[Affiliate_12bet].[dbo].ClickStatistics WITH (NOLOCK)
			WHERE	UpdatedTime >=@OldDate 
					AND TrackingID > 0 
			)
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1
			FROM	[Affiliate_12bet].[dbo].ClickStatistics WITH (NOLOCK)
			WHERE	UpdatedTime >=@OldDate 
					AND TrackingID > 0 
		)
		BEGIN 
			DELETE FROM [Affiliate_12bet].[dbo].ClickStatistics WITH (ROWLOCK)
			WHERE	UpdatedTime >=@OldDate 
					AND TrackingID > 0 
		END
		INSERT INTO [Affiliate_12bet].[dbo].[ClickStatistics]
           ([TrackingID]
           ,[UpdatedTime]
           ,[IP]
           ,[Date]
           ,[Browser]
           ,[URLReferrer])
		SELECT	[TrackingID]
			   ,[UpdatedTime]
			   ,[IP]
			   ,[Date]
			   ,[Browser]
			   ,[URLReferrer]
		FROM	DBAFF12BET.[Affiliate_12bet].[dbo].ClickStatistics WITH (NOLOCK)
		WHERE	UpdatedTime >=@OldDate 
				AND TrackingID > 0
	END

	----[ClickStatistics1]
	IF EXISTS (
			SELECT TOP 1 1
			FROM	DBAFF12BET.[Affiliate_12bet].[dbo].ClickStatistics1 WITH (NOLOCK)
			WHERE	[Date] BETWEEN @OldDate AND @Today
					AND AffID > 0 
			)
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1
			FROM	[Affiliate_12bet].[dbo].ClickStatistics1 WITH (NOLOCK)
			WHERE	[Date] BETWEEN @OldDate AND @Today
					AND AffID > 0
		)
		BEGIN 
			DELETE FROM [Affiliate_12bet].[dbo].ClickStatistics1 WITH (ROWLOCK)
			WHERE	[Date] BETWEEN @OldDate AND @Today
					AND AffID > 0
		END
		SET IDENTITY_INSERT [ClickStatistics1] ON
		INSERT INTO [Affiliate_12bet].[dbo].[ClickStatistics1]
				   ([ClickID]
				   ,[AffID]
				   ,[UpdatedTime]
				   ,[IP]
				   ,[Date]
				   ,[Browser]
				   ,[URLReferrer]
				   ,[DomainReferrer]
				   ,[OS]
				   ,[Device]
				   ,[BrowserVersion]
				   ,[BrowserResolution]
				   ,[BrowserLanguage]
				   ,[UserAgent]
				   ,[Country]
				   ,[LanguageCode]
				   ,[SportCode]
				   ,[RedirectURL]
				   ,[Status])
		SELECT		[ClickID]
				   ,[AffID]
				   ,[UpdatedTime]
				   ,[IP]
				   ,[Date]
				   ,[Browser]
				   ,[URLReferrer]
				   ,[DomainReferrer]
				   ,[OS]
				   ,[Device]
				   ,[BrowserVersion]
				   ,[BrowserResolution]
				   ,[BrowserLanguage]
				   ,[UserAgent]
				   ,[Country]
				   ,[LanguageCode]
				   ,[SportCode]
				   ,[RedirectURL]
				   ,[Status]
		FROM	DBAFF12BET.[Affiliate_12bet].[dbo].ClickStatistics1 WITH (NOLOCK)
		WHERE	[Date] BETWEEN @OldDate AND @Today
					AND AffID > 0
		SET IDENTITY_INSERT [ClickStatistics1] OFF
	END 

	-- [MemberClickDetail]
	DECLARE @maxCreatedDate DATETIME 
	
	SELECT @maxCreatedDate = MAX([CreatedDate])
	FROM [dbo].[MemberClickDetail] WITH(NOLOCK)	

	SELECT @maxCreatedDate = DATEADD(d,-1, ISNULL(@maxCreatedDate,'2014-08-01'))
	
	INSERT INTO [dbo].[MemberClickDetail]
		(
		   [IBCCustID]
		  ,[ClickId]
		  ,[DomainReferrer]
		  ,[LanguageCode]
		  ,[SportCode]
		  ,[URLRedirect]
		  ,[URLReferrer]
		  ,[DeviceType]
		  ,[AffID]
		  ,[CreatedDate]
		  ,[DepositCustID]
		)
	SELECT [IBCCustID]
      ,[ClickId]
      ,[DomainReferrer]
      ,[LanguageCode]
      ,[SportCode]
      ,[URLRedirect]
      ,[URLReferrer]
      ,[DeviceType]
      ,[AffID]
      ,[CreatedDate]
      ,[DepositCustID]
	FROM [DBAFF12BET].[Affiliate_12BET].[dbo].[MemberClickDetail] m WITH(NOLOCK)
	WHERE [CreatedDate] > @maxCreatedDate
	AND NOT EXISTS (SELECT TOP 1 1 FROM [MemberClickDetail] m1 (NOLOCK) WHERE m1.DepositCustID = m.DepositCustID)
	
	----[ClickStatistics1Sum]
	----IF EXISTS (
	----		SELECT TOP 1 1
	----		FROM	DBAFF12BET.[Affiliate_12bet].[dbo].ClickStatistics1Sum WITH (NOLOCK)
	----		WHERE	[Date] BETWEEN @LastMonth AND @Today
	----				AND AffID > 0 
	----		)
	----BEGIN
	----	IF EXISTS(
	----		SELECT TOP 1 1
	----		FROM	[Affiliate_12bet].[dbo].ClickStatistics1Sum WITH (NOLOCK)
	----		WHERE	[Date] BETWEEN @LastMonth AND @Today
	----				AND AffID > 0
	----	)
	----	BEGIN 
	----		DELETE FROM [Affiliate_12bet].[dbo].ClickStatistics1Sum WITH (ROWLOCK)
	----		WHERE	[Date] BETWEEN @LastMonth AND @Today
	----				AND AffID > 0
	----	END
	----	INSERT INTO [Affiliate_12bet].[dbo].[ClickStatistics1Sum]
 ----          ([AffID]
 ----          ,[DomainReferrer]
 ----          ,[Date]
 ----          ,[SportCode]
 ----          ,[LanguageCode]
 ----          ,[TotalClick]
 ----          ,[UniqueClick]
 ----          ,[TotalSignup]
 ----          ,[TotalDeposit])
	----	SELECT	[AffID]
	----		   ,[DomainReferrer]
	----		   ,[Date]
	----		   ,[SportCode]
	----		   ,[LanguageCode]
	----		   ,[TotalClick]
	----		   ,[UniqueClick]
	----		   ,[TotalSignup]
	----		   ,[TotalDeposit]
	----	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].ClickStatistics1Sum WITH (NOLOCK)
	----	WHERE	[Date] BETWEEN @LastMonth AND @Today
	----			AND AffID > 0
	----END 

	--------[[ClickStatistics1_bk]]
	----IF EXISTS (
	----		SELECT TOP 1 1
	----		FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[ClickStatistics1_bk] WITH (NOLOCK)
	----		WHERE	[Date] BETWEEN @OldDate AND @Today
	----				AND AffID > 0 
	----		)
	----BEGIN
	----	IF EXISTS(
	----		SELECT TOP 1 1
	----		FROM	[Affiliate_12bet].[dbo].[ClickStatistics1_bk] WITH (NOLOCK)
	----		WHERE	[Date] BETWEEN @OldDate AND @Today
	----				AND AffID > 0
	----	)
	----	BEGIN 
	----		DELETE FROM [Affiliate_12bet].[dbo].[ClickStatistics1_bk] WITH (ROWLOCK)
	----		WHERE	[Date] BETWEEN @OldDate AND @Today
	----				AND AffID > 0
	----	END
	----	INSERT INTO [Affiliate_12bet].[dbo].[ClickStatistics1_bk]
 ----          ([ClickID]
 ----          ,[AffID]
 ----          ,[UpdatedTime]
 ----          ,[IP]
 ----          ,[Date]
 ----          ,[Browser]
 ----          ,[URLReferrer]
 ----          ,[DomainReferrer]
 ----          ,[OS]
 ----          ,[Device]
 ----          ,[BrowserVersion]
 ----          ,[BrowserResolution]
 ----          ,[BrowserLanguage]
 ----          ,[UserAgent]
 ----          ,[Country]
 ----          ,[LanguageCode]
 ----          ,[SportCode]
 ----          ,[RedirectURL]
 ----          ,[Status])
	----	SELECT	[ClickID]
	----		   ,[AffID]
	----		   ,[UpdatedTime]
	----		   ,[IP]
	----		   ,[Date]
	----		   ,[Browser]
	----		   ,[URLReferrer]
	----		   ,[DomainReferrer]
	----		   ,[OS]
	----		   ,[Device]
	----		   ,[BrowserVersion]
	----		   ,[BrowserResolution]
	----		   ,[BrowserLanguage]
	----		   ,[UserAgent]
	----		   ,[Country]
	----		   ,[LanguageCode]
	----		   ,[SportCode]
	----		   ,[RedirectURL]
	----		   ,[Status]
	----	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[ClickStatistics1_bk] WITH (NOLOCK)
	----	WHERE	[Date] BETWEEN @OldDate AND @Today
	----			AND AffID > 0 
	----END

END



GO


