USE [Affiliate_12bet]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYNC_AFF12BET_TableInfoSel]    Script Date: 01/27/2015 04:37:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYNC_AFF12BET_TableInfoSel]
 @Type				INT		= 0 
,@ctCurrentVersion	BIGINT	= 0 
,@ctLastSyncVersion	BIGINT	= 0 
AS 
/*
	Created by: Jamie 
	Date: 2013-04-10
	DB: AFF12BET/Affiliate_12BET
	Task: Synchronize data AFF12BET (PUT ON Primary server) 
			
	Revisions:
		+ AffInfo = 1
		+ AffDetail = 2
		+ AffTrans = 3
		+ MemberInfo = 4
		+ ClickStatistics1_bk = 5 
		+ ClickStatistics1Sum = 6 
		--+ ClickStatistics1 = 7
		--+ ClickStatistics = 8


*/
BEGIN
	SET NOCOUNT ON
	DECLARE	 
			 @ctMinVersionAffInfo		BIGINT
			,@ctMinVersionAffDetail		BIGINT
			,@ctMinVersionAffTrans		BIGINT
			,@ctMinVersionMemberInfo	BIGINT
			,@ctMinVersionClickStatistics1_bk	BIGINT
			,@ctMinVersionClickStatistics1Sum	BIGINT
			,@ctMinVersionClickStatistics1		BIGINT
			,@ctMinVersionClickStatistics		BIGINT

	SELECT   @ctMinVersionAffInfo		= 0
			,@ctMinVersionAffDetail		= 0 
			,@ctMinVersionAffTrans		= 0
			,@ctMinVersionMemberInfo	= 0 
			,@ctMinVersionClickStatistics1_bk = 0 
			,@ctMinVersionClickStatistics1Sum = 0 
			,@ctMinVersionClickStatistics1	  = 0
			,@ctMinVersionClickStatistics	  = 0 
			
	--- AffInfo = 1
	IF @Type = 1
	BEGIN	
		SELECT   c.SYS_CHANGE_OPERATION 
				,c.AffID
				,i.[UserName]
				,i.[UserName2]
				,i.[FirstName]
				,i.[LastName]
				,i.[GroupID]
				,i.[Status]
				,i.[ApprovedDate]
				,i.[IsClosed]
				,i.[Currency]
				,i.[RegisteredDate]
				,i.[Email]
				,i.[Password]
				,i.[AffType]
				,i.[IsPageEnabled]
				,i.[Level]
				,i.[IsLocked]
				,i.[CasinoJoinedDate]
				,i.[ForceChangePass]
				,i.[EUAffID]
		FROM	CHANGETABLE(CHANGES dbo.AffInfo,@ctLastSyncVersion) AS c
				LEFT JOIN dbo.AffInfo i WITH (NOLOCK) ON c.AffID = i.AffID
		WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersionAffInfo AND @ctCurrentVersion 
		
	END
	--- AffDetail = 2
	ELSE IF @Type = 2
	BEGIN	
		SELECT	 c.SYS_CHANGE_OPERATION 
				,c.AffID
				,a.UserName
				,a.SiteURL
				,a.MoreSiteURLs
				,a.PreferredLanguage
				,a.Gender
				,a.Address
				,a.Postal
				,a.City
				,a.State
				,a.Country
				,a.Phone
				,a.MobilePhone
				,a.Fax
				,a.Question
				,a.Answer
				,a.PreferredPayment
				,a.Player_IBCCustID
				,a.Player_Username
				,a.Neteller_AccountID
				,a.Moneybookers_Email
				,a.Wire_BankName
				,a.Wire_BankAddress
				,a.Wire_SwiftCode
				,a.Wire_AccountName
				,a.Wire_AccountNo
				,a.Cheque_FullName
				,a.Cheque_Address
				,a.Cheque_City
				,a.Cheque_State
				,a.Cheque_Postal
				,a.Cheque_Country
				,a.BonusCode
				,a.LastLoginDate
				,a.LastLoginIP
				,a.LoginCount
				,a.ValidCode
				,a.CodeExpiry
				,a.MailOption
				,a.NoSiteDesc
		FROM	CHANGETABLE(CHANGES dbo.AffDetail,@ctLastSyncVersion) AS c
				LEFT JOIN dbo.AffDetail a WITH (NOLOCK) ON c.AffID = a.AffID
		WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersionAffDetail AND @ctCurrentVersion 
	END 
	--- AffTrans = 3
	ELSE IF @Type = 3
	BEGIN
		SELECT	 c.SYS_CHANGE_OPERATION 
				,c.TransID
				,a.AffID
				,a.TransDate
				,a.CompletedDate
				,a.Amount
				,a.Status
				,a.Description
				,a.Creator
				,a.Currency
				,a.ActualRate
				,a.TransType
				,a.RefID
				,a.AffExRate
		FROM	CHANGETABLE(CHANGES dbo.AffTrans,@ctLastSyncVersion) AS c
				LEFT JOIN dbo.AffTrans a WITH (NOLOCK) ON c.TransID = a.TransID
		WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersionAffTrans AND @ctCurrentVersion 
	END 
	--- MemberInfo = 4
	ELSE IF @Type = 4
	BEGIN
		SELECT	 c.SYS_CHANGE_OPERATION 
				,C.IBCCustID
				,a.AffID
				,a.UserName
				,a.IBCUserName
				,a.CreatedDate
				,a.RegisteredDate
				,a.IsRemoved
				,a.DepositCustID
				,a.FirstName
				,a.LastName
				,a.Currency
				,a.Email
				,a.Recommend
				,a.ClickId
				,a.EUAffID
				,a.AffAffectedDate
		FROM	CHANGETABLE(CHANGES dbo.MemberInfo,@ctLastSyncVersion) AS c
				LEFT JOIN dbo.MemberInfo a WITH (NOLOCK) ON c.IBCCustID = a.IBCCustID
		WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersionMemberInfo AND @ctCurrentVersion 
	END 
	----ClickStatistics1_bk
	ELSE IF @Type = 5
	BEGIN
		SELECT	 c.SYS_CHANGE_OPERATION 
				,c.[ClickID]
				,a.[AffID]
				,a.[UpdatedTime]
				,a.[IP]
				,a.[Date]
				,a.[Browser]
				,a.[URLReferrer]
				,a.[DomainReferrer]
				,a.[OS]
				,a.[Device]
				,a.[BrowserVersion]
				,a.[BrowserResolution]
				,a.[BrowserLanguage]
				,a.[UserAgent]
				,a.[Country]
				,a.[LanguageCode]
				,a.[SportCode]
				,a.[RedirectURL]
				,a.[Status]
				,a.[DeviceType]				
		FROM	CHANGETABLE(CHANGES dbo.ClickStatistics1_bk,@ctLastSyncVersion) AS c
				LEFT JOIN dbo.ClickStatistics1_bk a WITH (NOLOCK) ON c.ClickID = a.ClickID
		WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersionClickStatistics1_bk AND @ctCurrentVersion 
	END
	----ClickStatistics1Sum
	ELSE IF @Type = 6
	BEGIN
		SELECT	 c.SYS_CHANGE_OPERATION 
				,c.[AffID]
				,c.[DomainReferrer]
				,c.[Date]
				,c.[SportCode]
				,c.[LanguageCode]
				,a.[TotalClick]
				,a.[UniqueClick]
				,a.[TotalSignup]
				,a.[TotalDeposit]
				,a.[DeviceType]				
		FROM	CHANGETABLE(CHANGES dbo.ClickStatistics1Sum,@ctLastSyncVersion) AS c
				LEFT JOIN dbo.ClickStatistics1Sum a WITH (NOLOCK) 
					ON c.AffID = a.AffID AND c.DomainReferrer = a.DomainReferrer AND c.Date = a.Date 
					AND c.SportCode = a.SportCode AND c.LanguageCode = a.LanguageCode AND c.[DeviceType] = a.[DeviceType]
		WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersionClickStatistics1Sum AND @ctCurrentVersion 
	END
	------ClickStatistics1
	--ELSE IF @Type = 7
	--BEGIN
	--	SELECT	 c.SYS_CHANGE_OPERATION 
	--			,c.[ClickID]
	--			,a.[AffID]
	--			,a.[UpdatedTime]
	--			,a.[IP]
	--			,a.[Date]
	--			,a.[Browser]
	--			,a.[URLReferrer]
	--			,a.[DomainReferrer]
	--			,a.[OS]
	--			,a.[Device]
	--			,a.[BrowserVersion]
	--			,a.[BrowserResolution]
	--			,a.[BrowserLanguage]
	--			,a.[UserAgent]
	--			,a.[Country]
	--			,a.[LanguageCode]
	--			,a.[SportCode]
	--			,a.[RedirectURL]
	--			,a.[Status]				
	--	FROM	CHANGETABLE(CHANGES dbo.ClickStatistics1,@ctLastSyncVersion) AS c
	--			LEFT JOIN dbo.ClickStatistics1 a WITH (NOLOCK) ON c.ClickID = a.ClickID
	--	WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersionClickStatistics1 AND @ctCurrentVersion 
	--END
END
GO


