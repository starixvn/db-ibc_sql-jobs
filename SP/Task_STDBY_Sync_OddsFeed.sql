USE [bodb_oddsfeed]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_Sync_OddsFeed]    Script Date: 01/20/2015 05:53:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_Sync_OddsFeed]

AS
/*
	Task: Sync OddsFeed ( run on standby server ONLY)
	DB: DBODDSFEED/bodb_OddsFeed
*/
BEGIN
	SET NOCOUNT ON 

	DECLARE	 @ServCurrent	SYSNAME
			,@ServRemote	SYSNAME
	
	SELECT	@ServCurrent = @@SERVERNAME
	SELECT	@ServRemote	 = (SELECT * FROM OPENQUERY(DBODDSFEED,'SELECT @@SERVERNAME'))
	
	IF @ServCurrent = @ServRemote RETURN ---- In the same server 

	----[AdminUser]
	TRUNCATE TABLE [AdminUser]
	SET IDENTITY_INSERT [AdminUser] ON 
	INSERT INTO [bodb_OddsFeed].[dbo].[AdminUser]
           ([UserID]
           ,[Username]
           ,[Password]
           ,[ParentID]
           ,[RoleID]
           ,[FirstName]
           ,[LastName]
           ,[Email]
           ,[IsActive]
           ,[Creator]
           ,[CreateDate]
           ,[LoginCount]
           ,[LastLogin]
           ,[LastLoginIP]
           ,[IsImport])
	SELECT	[UserID]
           ,[Username]
           ,[Password]
           ,[ParentID]
           ,[RoleID]
           ,[FirstName]
           ,[LastName]
           ,[Email]
           ,[IsActive]
           ,[Creator]
           ,[CreateDate]
           ,[LoginCount]
           ,[LastLogin]
           ,[LastLoginIP]
           ,[IsImport]
	FROM	DBODDSFEED.[bodb_OddsFeed].[dbo].[AdminUser] WITH (NOLOCK) 
	SET IDENTITY_INSERT [AdminUser] OFF 
	----END: AdminUser

	----START: [Domain]
	TRUNCATE TABLE [Domain]
	SET IDENTITY_INSERT [Domain] ON 
	INSERT INTO [bodb_OddsFeed].[dbo].[Domain]
           ([DomainID]
           ,[DomainName]
           ,[CreatedDate]
           ,[IP]
           ,[ISP]
           ,[Creator]
           ,[LastUpdate]
           ,[IsActive]
           ,[IsOddsDomain]
           ,[OldDomainID])
	SELECT	[DomainID]
			,[DomainName]
			,[CreatedDate]
			,[IP]
			,[ISP]
			,[Creator]
			,[LastUpdate]
			,[IsActive]
			,[IsOddsDomain]
			,[OldDomainID]
	 FROM	DBODDSFEED.[bodb_OddsFeed].[dbo].[Domain] WITH (NOLOCK) 
	 SET IDENTITY_INSERT [Domain] OFF  
	----END: Domain

	----START: [Partner]
	TRUNCATE TABLE [Partner]
	SET IDENTITY_INSERT [Partner] ON 
	INSERT INTO [bodb_OddsFeed].[dbo].[Partner]
           ([PartnerID]
		   ,[SystemID]
           ,[UserName]
           ,[Site]
           ,[IsAllowed]
           ,[Remark]
           ,[CreatedDate]
           ,[LastUpdate]
           ,[LastRequest]
           ,[Creator]
           ,[UpdatedBy]
           ,[ContactPerson]
           ,[ContactEmail]
           ,[IsDeleted]
           ,[OldPartnerID])
	SELECT [PartnerID]
		  ,[SystemID]
		  ,[UserName]
		  ,[Site]
		  ,[IsAllowed]
		  ,[Remark]
		  ,[CreatedDate]
		  ,[LastUpdate]
		  ,[LastRequest]
		  ,[Creator]
		  ,[UpdatedBy]
		  ,[ContactPerson]
		  ,[ContactEmail]
		  ,[IsDeleted]
		  ,[OldPartnerID]
	FROM	DBODDSFEED.[bodb_OddsFeed].[dbo].[Partner] WITH (NOLOCK) 
	SET IDENTITY_INSERT [Partner] OFF
	----END: [Partner]

	----START: [System]
	TRUNCATE TABLE [System]
	SET IDENTITY_INSERT [System] ON 
	INSERT INTO [bodb_OddsFeed].[dbo].[System]
           ([SystemID]
		   ,[SystemName]
           ,[Creator]
           ,[CreatedDate]
           ,[LastUpdate]
           ,[LicenseeID]
           ,[IsActive]
           ,[OldSystemID]
           ,[ContactEmail]
           ,[MoreContactEmail])
	SELECT [SystemID]
		  ,[SystemName]
		  ,[Creator]
		  ,[CreatedDate]
		  ,[LastUpdate]
		  ,[LicenseeID]
		  ,[IsActive]
		  ,[OldSystemID]
		  ,[ContactEmail]
		  ,[MoreContactEmail]
	 FROM DBODDSFEED.[bodb_OddsFeed].[dbo].[System] WITH (NOLOCK)
	 SET IDENTITY_INSERT [System] OFF
	 
	----START: [PartnerRequest]
	TRUNCATE TABLE [PartnerRequest]
	SET IDENTITY_INSERT [PartnerRequest] ON
	INSERT INTO [bodb_OddsFeed].[dbo].[PartnerRequest]
			   ([RequestID]
			   ,[PartnerID]
			   ,[Content]
			   ,[RequestDate]
			   ,[ResolvedBy]
			   ,[ResolveDate])
	SELECT	   [RequestID]
			  ,[PartnerID]
			  ,[Content]
			  ,[RequestDate]
			  ,[ResolvedBy]
			  ,[ResolveDate]
	FROM	DBODDSFEED.[bodb_OddsFeed].[dbo].[PartnerRequest] WITH (NOLOCK) 
	SET IDENTITY_INSERT [PartnerRequest] OFF
	----END: [PartnerRequest]

	/**** normal tables *****/

	----START: [AdminUserSystem]
	TRUNCATE TABLE [AdminUserSystem]
	INSERT INTO [bodb_OddsFeed].[dbo].[AdminUserSystem]
           ([SystemID]
           ,[UserID]
           ,[IsActive]
           ,[IsHost])
	SELECT [SystemID]
		  ,[UserID]
		  ,[IsActive]
		  ,[IsHost]
	FROM   DBODDSFEED.[bodb_OddsFeed].[dbo].[AdminUserSystem] WITH (NOLOCK)
	----END: AdminUserSystem

	----START: [CompanyIP]
	TRUNCATE TABLE [CompanyIP] 
	INSERT INTO [bodb_OddsFeed].[dbo].[CompanyIP]
           ([IPFrom]
           ,[IPTo]
           ,[Creator]
           ,[CreatedDate]
           ,[UpdatedBy]
           ,[LastUpdate]
           ,[Description])
	SELECT	 [IPFrom]
			,[IPTo]
			,[Creator]
			,[CreatedDate]
			,[UpdatedBy]
			,[LastUpdate]
			,[Description]
	FROM	DBODDSFEED.[bodb_OddsFeed].[dbo].[CompanyIP] WITH (NOLOCK)
	----END: CompanyIP

	----START: [OddsSystemProfile]
	TRUNCATE TABLE [OddsSystemProfile]
	INSERT INTO [bodb_OddsFeed].[dbo].[OddsSystemProfile]
           ([SystemID]
           ,[CreatedDate]
           ,[Creator]
           ,[Editable]
           ,[LastUpdate]
           ,[OddsType]
           ,[LanguageList]
           ,[OddsRegion]
           ,[SportIDList]
           ,[BetTypeIDList]
           ,[LeagueIDList]
           ,[CountryCodeList]
           ,[LeagueKeyword]
           ,[LeagueKeyword_O]
           ,[DelayTimes]
           ,[NumberOfIPs]
           ,[OddsTypeFlag]
           ,[LanguageListFlag]
           ,[OddsRegionFlag]
           ,[SportIDListFlag]
           ,[BetTypeIDListFlag]
           ,[LeagueIDListFlag]
           ,[CountryCodeListFlag]
           ,[LeagueKeywordFlag]
           ,[LeagueKeyword_OFlag]
           ,[DelayTimesFlag]
           ,[OutrightIDList])
	SELECT [SystemID]
		  ,[CreatedDate]
		  ,[Creator]
		  ,[Editable]
		  ,[LastUpdate]
		  ,[OddsType]
		  ,[LanguageList]
		  ,[OddsRegion]
		  ,[SportIDList]
		  ,[BetTypeIDList]
		  ,[LeagueIDList]
		  ,[CountryCodeList]
		  ,[LeagueKeyword]
		  ,[LeagueKeyword_O]
		  ,[DelayTimes]
		  ,[NumberOfIPs]
		  ,[OddsTypeFlag]
		  ,[LanguageListFlag]
		  ,[OddsRegionFlag]
		  ,[SportIDListFlag]
		  ,[BetTypeIDListFlag]
		  ,[LeagueIDListFlag]
		  ,[CountryCodeListFlag]
		  ,[LeagueKeywordFlag]
		  ,[LeagueKeyword_OFlag]
		  ,[DelayTimesFlag]
		  ,[OutrightIDList]
	  FROM DBODDSFEED.[bodb_OddsFeed].[dbo].[OddsSystemProfile] WITH (NOLOCK) 
	---- END: [OddsSystemProfile]

	----START: [PartnerDomain]
	TRUNCATE TABLE [PartnerDomain]
	INSERT INTO [bodb_OddsFeed].[dbo].[PartnerDomain]
			   ([PartnerID]
			   ,[DomainID])
	SELECT	[PartnerID]
			,[DomainID]
	FROM	DBODDSFEED.[bodb_OddsFeed].[dbo].[PartnerDomain] WITH (NOLOCK) 
	---- END: PartnerDomain

	----START: [PartnerIP]
	TRUNCATE TABLE [PartnerIP]
	INSERT INTO [bodb_OddsFeed].[dbo].[PartnerIP]
           ([PartnerID]
           ,[IPFrom]
           ,[IPTo]
           ,[Country]
           ,[Region]
           ,[City]
           ,[ISP])
	SELECT [PartnerID]
		  ,[IPFrom]
		  ,[IPTo]
		  ,[Country]
		  ,[Region]
		  ,[City]
		  ,[ISP]
	FROM	DBODDSFEED.[bodb_OddsFeed].[dbo].[PartnerIP] WITH (NOLOCK) 
	----END: [PartnerIP]

	----START: [PartnerProfile]
	TRUNCATE TABLE [PartnerProfile]
	INSERT INTO [bodb_OddsFeed].[dbo].[PartnerProfile]
           ([PartnerID]
           ,[UpdatedBy]
           ,[LastUpdate]
           ,[OddsType]
           ,[LanguageList]
           ,[OddsRegion]
           ,[SportIDList]
           ,[BetTypeIDList]
           ,[LeagueIDList]
           ,[CountryCodeList]
           ,[LeagueKeyword]
           ,[LeagueKeyword_O]
           ,[DelayTimes]
           ,[OutrightIDList]
           ,[NumberOfIPs])
	SELECT [PartnerID]
		  ,[UpdatedBy]
		  ,[LastUpdate]
		  ,[OddsType]
		  ,[LanguageList]
		  ,[OddsRegion]
		  ,[SportIDList]
		  ,[BetTypeIDList]
		  ,[LeagueIDList]
		  ,[CountryCodeList]
		  ,[LeagueKeyword]
		  ,[LeagueKeyword_O]
		  ,[DelayTimes]
		  ,[OutrightIDList]
		  ,[NumberOfIPs]
	FROM DBODDSFEED.[bodb_OddsFeed].[dbo].[PartnerProfile] WITH (NOLOCK) 
	----END: [PartnerProfile]

	----START: [PartnerStatistics]
	TRUNCATE TABLE [PartnerStatistics]
	INSERT INTO [bodb_OddsFeed].[dbo].[PartnerStatistics]
           ([PartnerID]
           ,[DomainID]
           ,[IP]
           ,[Date]
           ,[LastCallTime]
           ,[TotalRequest])
	SELECT [PartnerID]
		  ,[DomainID]
		  ,[IP]
		  ,[Date]
		  ,[LastCallTime]
		  ,[TotalRequest]
	FROM	DBODDSFEED.[bodb_OddsFeed].[dbo].[PartnerStatistics] WITH (NOLOCK)
	----END: [PartnerStatistics]

	----START: [SystemDomain]
	TRUNCATE TABLE [SystemDomain]
	INSERT INTO [bodb_OddsFeed].[dbo].[SystemDomain]
           ([SystemID]
           ,[DomainID])
	SELECT [SystemID]
		  ,[DomainID]
	FROM	DBODDSFEED.[bodb_OddsFeed].[dbo].[SystemDomain] WITH (NOLOCK)
	----END: [SystemDomain]

	----START: [SystemIP]
	TRUNCATE TABLE [SystemIP]
	INSERT INTO [bodb_OddsFeed].[dbo].[SystemIP]
           ([SystemID]
           ,[IPFrom]
           ,[IPTo]
           ,[Creator]
           ,[CreatedDate]
           ,[UpdatedBy]
           ,[LastUpdate])
	SELECT [SystemID]
		  ,[IPFrom]
		  ,[IPTo]
		  ,[Creator]
		  ,[CreatedDate]
		  ,[UpdatedBy]
		  ,[LastUpdate]
	FROM DBODDSFEED.[bodb_OddsFeed].[dbo].[SystemIP] WITH (NOLOCK) 
	----END: [SystemIP]

	----START: [UserPermission]
	TRUNCATE TABLE [UserPermission]
	INSERT INTO [bodb_OddsFeed].[dbo].[UserPermission]
           ([UserID]
           ,[UpdatedBy]
           ,[LastUpdate]
           ,[OddsTypeFlag]
           ,[LanguageListFlag]
           ,[OddsRegionFlag]
           ,[SportIDListFlag]
           ,[BetTypeIDListFlag]
           ,[LeagueIDListFlag]
           ,[CountryCodeListFlag]
           ,[LeagueKeywordFlag]
           ,[LeagueKeyword_OFlag]
           ,[DelayTimesFlag]
           ,[AddEditAffiliateFlag]
           ,[DeleteAffiliate])
	SELECT [UserID]
		  ,[UpdatedBy]
		  ,[LastUpdate]
		  ,[OddsTypeFlag]
		  ,[LanguageListFlag]
		  ,[OddsRegionFlag]
		  ,[SportIDListFlag]
		  ,[BetTypeIDListFlag]
		  ,[LeagueIDListFlag]
		  ,[CountryCodeListFlag]
		  ,[LeagueKeywordFlag]
		  ,[LeagueKeyword_OFlag]
		  ,[DelayTimesFlag]
		  ,[AddEditAffiliateFlag]
		  ,[DeleteAffiliate]
	 FROM	DBODDSFEED.[bodb_OddsFeed].[dbo].[UserPermission] WITH (NOLOCK) 
	 ----END: [UserPermission]
END
GO


