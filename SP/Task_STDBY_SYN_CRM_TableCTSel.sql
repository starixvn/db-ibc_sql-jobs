USE [bodb_CRM]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYN_CRM_TableCTSel]    Script Date: 01/27/2015 04:43:38 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYN_CRM_TableCTSel]
 @Type				INT		= 0 
,@ctCurrentVersion	BIGINT	= 0 
,@ctLastSyncVersion	BIGINT	= 0 
AS 
/*
	Created by: Jamie 
	Date: 2013-04-10
	DB: DBCRM/bodb_CRM
	Task: Synchronize data bodb_CRM (PUT ON Primary server) 
			
	Revisions:
		+ @Type = 1: CRMCustomer
		+ @Type = 2: crmCustomerLanguage
		+ @Type = 3: crmFeedback
		+ @Type = 4: crmFeedbackCustomer
		+ @Type = 5: crmRedemption
		+ @Type = 6: crmSetting
		+ @Type = 7: crmSettingRelation
		+ @Type = 8: crmSubjectTemplate
		+ @Type = 9: crmCustomerRemark

*/
BEGIN
	SET NOCOUNT ON 

	DECLARE	 @ctMinVersionCRMCustomer			BIGINT
			,@ctMinVersionCRMFeedback			BIGINT
			,@ctMinVersionCRMFeedbackCustomer	BIGINT
			,@ctMinVersionCRMSetting			BIGINT
			,@ctMinVersionCRMSettingRelation	BIGINT
			,@ctMinVersionCRMSubjectTemplate	BIGINT
			,@ctMinVersionCRMCustomerLanguage	BIGINT
			,@ctMinVersioncrmRedemption			BIGINT
			,@ctMinVersioncrmCustomerRemark		BIGINT


	SELECT	 @ctMinVersionCRMCustomer			= 485360
			,@ctMinVersionCRMFeedback			= 485360
			,@ctMinVersionCRMFeedbackCustomer	= 485360 
			,@ctMinVersionCRMSetting			= 485360
			,@ctMinVersionCRMSettingRelation	= 485360
			,@ctMinVersionCRMSubjectTemplate	= 485360
			,@ctMinVersionCRMCustomerLanguage	= 437606
			,@ctMinVersioncrmRedemption			= 437625  
			,@ctMinVersioncrmCustomerRemark		= 485360 
	
	----CRMCustomer
	IF @Type = 1 
	BEGIN
		SELECT	 c.SYS_CHANGE_OPERATION 
				,c.[CustID]
				,crm.[UserName]
				,crm.[TitleID]
				,crm.[FirstName]
				,crm.[LastName]
				,crm.[Phone]
				,crm.[MobilePhone]
				,crm.[Fax]
				,crm.[Email]
				,crm.[Birthday]
				,crm.[RefCode1]
				,crm.[RefCode2]
				,crm.[Pic1]
				,crm.[Pic2]
				,crm.[Pic3]
				,crm.[LanguageID]
				,crm.[Question]
				,crm.[Answer]
				,crm.[CountryID]
				,crm.[IsVIP]
				,crm.[RelatedCustID]
				,crm.[SiteID]
				,crm.[Wire_BankName]
				,crm.[Wire_BankAddress]
				,crm.[Wire_SwiftCode]
				,crm.[Wire_AccountName]
				,crm.[Wire_AccountNo]
				,crm.[Remark]
				,crm.[CreateDate]
				,crm.[CreatorID]
				,crm.[Remark2]
				,crm.[AccountHolderName]
				,crm.[Skype]
				,crm.[MSN]
				--,crm.[tstamp]
				,crm.[PhoneCountryCode]
				,crm.[PhoneAreaCode]
				,crm.[Phone2]
				,crm.[Phone2CountryCode]
				,crm.[Phone2AreaCode]
				,crm.[Phone3]
				,crm.[Phone3CountryCode]
				,crm.[Phone3AreaCode]
				,crm.[MobilePhoneCountryCode]
				,crm.[MobilePhoneAreaCode]
				,crm.[FaxCountryCode]
				,crm.[FaxAreaCode]
				,crm.[Pic4]
				,crm.[Passport]
				,crm.[Line1]
				,crm.[Line2]
				,crm.[Line3]
				,crm.[City]
				,crm.[Postcode]
				,crm.[State]
				,crm.[BankLine1]
				,crm.[BankLine2]
				,crm.[BankLine3]
				,crm.[BankCity]
				,crm.[BankCode]
				,crm.[BankState]
				,crm.[BankCountryID]
				,crm.[IsVerifyEmail]
				,crm.[IsVerifyPassport]
				,crm.[IsVerifyBirthday]
				,crm.[IsVerifySecretCode]
				,crm.[IsVerifyBetCredit]
				,crm.[IsVerifyGivenCredit]	
		FROM	CHANGETABLE(CHANGES dbo.crmCustomer,@ctLastSyncVersion) AS c
				LEFT JOIN dbo.crmCustomer crm WITH (NOLOCK) ON c.CustID = crm.CustID
		WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersionCRMCustomer AND @ctCurrentVersion 		
	END
	ELSE IF @Type = 2 ----crmCustomerLanguage
	BEGIN
		SELECT	 c.SYS_CHANGE_OPERATION 
				,c.[CustID]
				,c.[LanguageID]
		FROM	CHANGETABLE(CHANGES dbo.crmCustomerLanguage,@ctLastSyncVersion) AS c
				LEFT JOIN dbo.crmCustomerLanguage crm WITH (NOLOCK) ON c.CustID = crm.CustID AND c.LanguageID = crm.LanguageID
		WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersioncrmCustomerLanguage AND @ctCurrentVersion
	END
	ELSE IF @Type = 3 ---- crmFeedback
	BEGIN
		SELECT	 c.SYS_CHANGE_OPERATION 
				,c.[FeedbackID]
				,crm.[CustID]
				,crm.[TitleID]
				,crm.[FirstName]
				,crm.[LastName]
				,crm.[Phone]
				,crm.[MobilePhone]
				,crm.[Fax]
				,crm.[Email]
				,crm.[LanguageID]
				,crm.[CountryID]
				,crm.[CreateDate]
				,crm.[CreatorID]
				,crm.[FeedbackDate]
				,crm.[SolveDate]
				,crm.[CommunicationID]
				,crm.[StationID]
				,crm.[MainCategoryID]
				,crm.[SubCategoryID]
				,crm.[SiteID]
				,crm.[RoleID]
				,crm.[ProductID]
				,crm.[BetTypeID]
				,crm.[ResponseID]
				,crm.[StatusID]
				,crm.[Description]
				,crm.[Solution]
				,crm.[IsReviewed]
				,crm.[Review]
				,crm.[ReviewerID]
				,crm.[Subject]
				,crm.[Skype]
				,crm.[MSN]
				,crm.[ResolutionDate]
				,crm.[Pic1]
				,crm.[Pic2]
				,crm.[Pic3]
				,crm.[PhoneCountryCode]
				,crm.[PhoneAreaCode]
				,crm.[Phone2]
				,crm.[Phone2CountryCode]
				,crm.[Phone2AreaCode]
				,crm.[Phone3]
				,crm.[Phone3CountryCode]
				,crm.[Phone3AreaCode]
				,crm.[MobilePhoneCountryCode]
				,crm.[MobilePhoneAreaCode]
				,crm.[FaxCountryCode]
				,crm.[FaxAreaCode]
				,crm.[Pic4]
				,crm.[Passport]
				,crm.[Line1]
				,crm.[Line2]
				,crm.[Line3]
				,crm.[City]
				,crm.[Postcode]
				,crm.[State]
				,crm.[BankLine1]
				,crm.[BankLine2]
				,crm.[BankLine3]
				,crm.[BankCity]
				,crm.[BankCode]
				,crm.[BankState]
				,crm.[Birthday]
				,crm.[RefCode1]
				,crm.[RefCode2]
				,crm.[IsVip]
		FROM	CHANGETABLE(CHANGES dbo.crmFeedback,@ctLastSyncVersion) AS c
				LEFT JOIN dbo.crmFeedback crm WITH (NOLOCK) ON c.FeedbackID = crm.FeedbackID
		WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersioncrmFeedback AND @ctCurrentVersion
	END
	ELSE IF @Type = 4 ----crmFeedbackCustomer
	BEGIN
		SELECT	 c.SYS_CHANGE_OPERATION 
				,c.[FeedbackID]
				,c.[CustID]
				,crm.[IsRelated]
		FROM	CHANGETABLE(CHANGES dbo.crmFeedbackCustomer,@ctLastSyncVersion) AS c
				LEFT JOIN dbo.crmFeedbackCustomer crm WITH (NOLOCK) ON c.FeedbackID = crm.FeedbackID AND c.CustID = crm.CustID
		WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersioncrmFeedbackCustomer AND @ctCurrentVersion
	END 
	ELSE IF @Type = 5 ----crmRedemption
	BEGIN
		SELECT	 c.SYS_CHANGE_OPERATION 
				,c.[ID]
				,crm.[Subject]
				,crm.[ClaimTime]
				,crm.[Remark]
				,crm.[StatusID]
				,crm.[CustID]
				,crm.[CreateDate]
				,crm.[Creator]
		FROM	CHANGETABLE(CHANGES dbo.crmRedemption,@ctLastSyncVersion) AS c
				LEFT JOIN dbo.crmRedemption crm WITH (NOLOCK) ON c.ID = crm.ID 
		WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersioncrmRedemption AND @ctCurrentVersion
	END 
	ELSE IF @Type = 6 ----crmSetting
	BEGIN
		SELECT	 c.SYS_CHANGE_OPERATION 
				,crm.[SettingName]
				,c.[SettingID]
				,crm.[SettingValue]
				,crm.[DisplayOrder]
				,crm.[IsActive]
		FROM	CHANGETABLE(CHANGES dbo.crmSetting,@ctLastSyncVersion) AS c
				LEFT JOIN dbo.crmSetting crm WITH (NOLOCK) ON c.SettingID = crm.SettingID 
		WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersioncrmSetting AND @ctCurrentVersion
	END
	ELSE IF @Type = 7 ----crmSettingRelation
	BEGIN
		SELECT	 c.SYS_CHANGE_OPERATION 
				,c.[SettingID]
				,c.[ParentID]
				,crm.[DisplayOrder]
		FROM	CHANGETABLE(CHANGES dbo.crmSettingRelation,@ctLastSyncVersion) AS c
				LEFT JOIN dbo.crmSettingRelation crm WITH (NOLOCK) ON c.SettingID = crm.SettingID AND c.ParentID = crm.ParentID
		WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersioncrmSettingRelation AND @ctCurrentVersion
	END 
	ELSE IF @Type = 8 ---- crmSubjectTemplate
	BEGIN
		SELECT	 c.SYS_CHANGE_OPERATION 
				,c.[templateID]
				,crm.[subject]
				,crm.[IsActive]
		FROM	CHANGETABLE(CHANGES dbo.crmSubjectTemplate,@ctLastSyncVersion) AS c
				LEFT JOIN dbo.crmSubjectTemplate crm WITH (NOLOCK) ON c.templateID = crm.templateID 
		WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersioncrmSubjectTemplate AND @ctCurrentVersion		

	END 
	ELSE IF @Type = 9 ---crmCustomerRemark
	BEGIN
		SELECT	 c.SYS_CHANGE_OPERATION 
				,c.RemarkID
				,crm.[CustID]
				,crm.[Remark]
				,crm.[IsSpecial]
		FROM	CHANGETABLE(CHANGES dbo.crmCustomerRemark,@ctLastSyncVersion) AS c
				LEFT JOIN dbo.crmCustomerRemark crm WITH (NOLOCK) ON c.RemarkID = crm.RemarkID 
		WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersioncrmCustomerRemark AND @ctCurrentVersion	
	END 
END
GO


