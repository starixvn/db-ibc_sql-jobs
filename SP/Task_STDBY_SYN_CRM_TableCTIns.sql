USE [bodb_CRM]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYN_CRM_TableCTIns]    Script Date: 01/20/2015 05:48:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYN_CRM_TableCTIns]
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
	DECLARE	 @ctCurrentVersion			BIGINT
			,@ctLastSyncVersion			BIGINT

	EXEC DBCRM.bodb_CRM.dbo.[Task_STDBY_SYNC_CRM_currentVersion] @ctCurrentVersion = @ctCurrentVersion OUTPUT 

	PRINT @ctCurrentVersion 

	SELECT	@ctLastSyncVersion = LastSyncVersion
	FROM	DBCRM.bodb_CRM.dbo.crmCTLastSyncVersion WITH (NOLOCK)
	WHERE	CTID = 1 

	PRINT @ctLastSyncVersion

	IF	@ctLastSyncVersion >= @ctCurrentVersion RETURN	-- No changes 

	----@Type = 1: CRMCustomer
	CREATE TABLE #tmpCRMCustomer (
		ChangedOperation NVARCHAR(1) NULL,
		[CustID] [int] NOT NULL,
		[UserName] [nvarchar](50) NULL,
		[TitleID] [int] NULL,
		[FirstName] [nvarchar](50) NULL,
		[LastName] [nvarchar](50) NULL,
		[Phone] [nvarchar](50) NULL,
		[MobilePhone] [nvarchar](50) NULL,
		[Fax] [nvarchar](50) NULL,
		[Email] [nvarchar](254) NULL,
		[Birthday] [smalldatetime] NULL,
		[RefCode1] [nvarchar](50) NULL,
		[RefCode2] [nvarchar](50) NULL,
		[Pic1] [nvarchar](100) NULL,
		[Pic2] [nvarchar](100) NULL,
		[Pic3] [nvarchar](100) NULL,
		[LanguageID] [int] NULL,
		[Question] [nvarchar](300) NULL,
		[Answer] [nvarchar](300) NULL,
		[CountryID] [int] NULL,
		[IsVIP] [bit] NULL,
		[RelatedCustID] [int] NULL,
		[SiteID] [int] NULL,
		[Wire_BankName] [nvarchar](100) NULL,
		[Wire_BankAddress] [nvarchar](200) NULL,
		[Wire_SwiftCode] [nvarchar](50) NULL,
		[Wire_AccountName] [nvarchar](100) NULL,
		[Wire_AccountNo] [varchar](50) NULL,
		[Remark] [nvarchar](3000) NULL,
		[CreateDate] [datetime] NULL,
		[CreatorID] [int] NULL,
		[Remark2] [nvarchar](3000) NULL,
		[AccountHolderName] [nvarchar](100) NULL,
		[Skype] [nvarchar](100) NULL,
		[MSN] [nvarchar](100) NULL,
		--[tstamp] [timestamp] NOT NULL,
		[PhoneCountryCode] [nvarchar](20) NULL,
		[PhoneAreaCode] [nvarchar](20) NULL,
		[Phone2] [nvarchar](100) NULL,
		[Phone2CountryCode] [nvarchar](20) NULL,
		[Phone2AreaCode] [nvarchar](20) NULL,
		[Phone3] [nvarchar](100) NULL,
		[Phone3CountryCode] [nvarchar](20) NULL,
		[Phone3AreaCode] [nvarchar](20) NULL,
		[MobilePhoneCountryCode] [nvarchar](20) NULL,
		[MobilePhoneAreaCode] [nvarchar](20) NULL,
		[FaxCountryCode] [nvarchar](20) NULL,
		[FaxAreaCode] [nvarchar](20) NULL,
		[Pic4] [nvarchar](100) NULL,
		[Passport] [nvarchar](100) NULL,
		[Line1] [nvarchar](100) NULL,
		[Line2] [nvarchar](100) NULL,
		[Line3] [nvarchar](100) NULL,
		[City] [nvarchar](100) NULL,
		[Postcode] [nvarchar](100) NULL,
		[State] [nvarchar](100) NULL,
		[BankLine1] [nvarchar](200) NULL,
		[BankLine2] [nvarchar](200) NULL,
		[BankLine3] [nvarchar](300) NULL,
		[BankCity] [nvarchar](100) NULL,
		[BankCode] [nvarchar](100) NULL,
		[BankState] [nvarchar](100) NULL,
		[BankCountryID] [int] NULL,
		[IsVerifyEmail] [bit] NULL,
		[IsVerifyPassport] [bit] NULL,
		[IsVerifyBirthday] [bit] NULL,
		[IsVerifySecretCode] [bit] NULL,
		[IsVerifyBetCredit] [bit] NULL,
		[IsVerifyGivenCredit] [bit] NULL
	)
	INSERT INTO #tmpCRMCustomer(
		ChangedOperation
		,[CustID]
		,[UserName]
		,[TitleID]
		,[FirstName]
		,[LastName]
		,[Phone]
		,[MobilePhone]
		,[Fax]
		,[Email]
		,[Birthday]
		,[RefCode1]
		,[RefCode2]
		,[Pic1]
		,[Pic2]
		,[Pic3]
		,[LanguageID]
		,[Question]
		,[Answer]
		,[CountryID]
		,[IsVIP]
		,[RelatedCustID]
		,[SiteID]
		,[Wire_BankName]
		,[Wire_BankAddress]
		,[Wire_SwiftCode]
		,[Wire_AccountName]
		,[Wire_AccountNo]
		,[Remark]
		,[CreateDate]
		,[CreatorID]
		,[Remark2]
		,[AccountHolderName]
		,[Skype]
		,[MSN]
		--,[tstamp]
		,[PhoneCountryCode]
		,[PhoneAreaCode]
		,[Phone2]
		,[Phone2CountryCode]
		,[Phone2AreaCode]
		,[Phone3]
		,[Phone3CountryCode]
		,[Phone3AreaCode]
		,[MobilePhoneCountryCode]
		,[MobilePhoneAreaCode]
		,[FaxCountryCode]
		,[FaxAreaCode]
		,[Pic4]
		,[Passport]
		,[Line1]
		,[Line2]
		,[Line3]
		,[City]
		,[Postcode]
		,[State]
		,[BankLine1]
		,[BankLine2]
		,[BankLine3]
		,[BankCity]
		,[BankCode]
		,[BankState]
		,[BankCountryID]
		,[IsVerifyEmail]
		,[IsVerifyPassport]
		,[IsVerifyBirthday]
		,[IsVerifySecretCode]
		,[IsVerifyBetCredit]
		,[IsVerifyGivenCredit]
	)
	EXEC DBCRM.bodb_CRM.dbo.[Task_STDBY_SYN_CRM_TableCTSel] @Type = 1, @ctCurrentVersion = @ctCurrentVersion, @ctLastSyncVersion =@ctLastSyncVersion 
	IF @@ROWCOUNT <> 0
	BEGIN
		MERGE crmCustomer AS TARGET 
		USING #tmpCRMCustomer AS SOURCE ON (TARGET.CustID = SOURCE.CustID)
		WHEN MATCHED AND SOURCE.ChangedOperation IN ('I','U') THEN 
			UPDATE SET 
				 TARGET.UserName= SOURCE.UserName
				,TARGET.TitleID= SOURCE.TitleID
				,TARGET.FirstName= SOURCE.FirstName
				,TARGET.LastName= SOURCE.LastName
				,TARGET.Phone= SOURCE.Phone
				,TARGET.MobilePhone= SOURCE.MobilePhone
				,TARGET.Fax= SOURCE.Fax
				,TARGET.Email= SOURCE.Email
				,TARGET.Birthday= SOURCE.Birthday
				,TARGET.RefCode1= SOURCE.RefCode1
				,TARGET.RefCode2= SOURCE.RefCode2
				,TARGET.Pic1= SOURCE.Pic1
				,TARGET.Pic2= SOURCE.Pic2
				,TARGET.Pic3= SOURCE.Pic3
				,TARGET.LanguageID= SOURCE.LanguageID
				,TARGET.Question= SOURCE.Question
				,TARGET.Answer= SOURCE.Answer
				,TARGET.CountryID= SOURCE.CountryID
				,TARGET.IsVIP= SOURCE.IsVIP
				,TARGET.RelatedCustID= SOURCE.RelatedCustID
				,TARGET.SiteID= SOURCE.SiteID
				,TARGET.Wire_BankName= SOURCE.Wire_BankName
				,TARGET.Wire_BankAddress= SOURCE.Wire_BankAddress
				,TARGET.Wire_SwiftCode= SOURCE.Wire_SwiftCode
				,TARGET.Wire_AccountName= SOURCE.Wire_AccountName
				,TARGET.Wire_AccountNo= SOURCE.Wire_AccountNo
				,TARGET.Remark= SOURCE.Remark
				,TARGET.CreateDate= SOURCE.CreateDate
				,TARGET.CreatorID= SOURCE.CreatorID
				,TARGET.Remark2= SOURCE.Remark2
				,TARGET.AccountHolderName= SOURCE.AccountHolderName
				,TARGET.Skype= SOURCE.Skype
				,TARGET.MSN= SOURCE.MSN
				--,TARGET.tstamp= SOURCE.tstamp
				,TARGET.PhoneCountryCode= SOURCE.PhoneCountryCode
				,TARGET.PhoneAreaCode= SOURCE.PhoneAreaCode
				,TARGET.Phone2= SOURCE.Phone2
				,TARGET.Phone2CountryCode= SOURCE.Phone2CountryCode
				,TARGET.Phone2AreaCode= SOURCE.Phone2AreaCode
				,TARGET.Phone3= SOURCE.Phone3
				,TARGET.Phone3CountryCode= SOURCE.Phone3CountryCode
				,TARGET.Phone3AreaCode= SOURCE.Phone3AreaCode
				,TARGET.MobilePhoneCountryCode= SOURCE.MobilePhoneCountryCode
				,TARGET.MobilePhoneAreaCode= SOURCE.MobilePhoneAreaCode
				,TARGET.FaxCountryCode= SOURCE.FaxCountryCode
				,TARGET.FaxAreaCode= SOURCE.FaxAreaCode
				,TARGET.Pic4= SOURCE.Pic4
				,TARGET.Passport= SOURCE.Passport
				,TARGET.Line1= SOURCE.Line1
				,TARGET.Line2= SOURCE.Line2
				,TARGET.Line3= SOURCE.Line3
				,TARGET.City= SOURCE.City
				,TARGET.Postcode= SOURCE.Postcode
				,TARGET.State= SOURCE.State
				,TARGET.BankLine1= SOURCE.BankLine1
				,TARGET.BankLine2= SOURCE.BankLine2
				,TARGET.BankLine3= SOURCE.BankLine3
				,TARGET.BankCity= SOURCE.BankCity
				,TARGET.BankCode= SOURCE.BankCode
				,TARGET.BankState= SOURCE.BankState
				,TARGET.BankCountryID= SOURCE.BankCountryID
				,TARGET.IsVerifyEmail= SOURCE.IsVerifyEmail
				,TARGET.IsVerifyPassport= SOURCE.IsVerifyPassport
				,TARGET.IsVerifyBirthday= SOURCE.IsVerifyBirthday
				,TARGET.IsVerifySecretCode= SOURCE.IsVerifySecretCode
				,TARGET.IsVerifyBetCredit= SOURCE.IsVerifyBetCredit
				,TARGET.IsVerifyGivenCredit= SOURCE.IsVerifyGivenCredit
		WHEN MATCHED AND SOURCE.ChangedOperation IN ('D') THEN 
			DELETE		
		WHEN NOT MATCHED BY TARGET  AND SOURCE.ChangedOperation IN ('I') THEN 
			INSERT(
				 [CustID]
				,[UserName]
				,[TitleID]
				,[FirstName]
				,[LastName]
				,[Phone]
				,[MobilePhone]
				,[Fax]
				,[Email]
				,[Birthday]
				,[RefCode1]
				,[RefCode2]
				,[Pic1]
				,[Pic2]
				,[Pic3]
				,[LanguageID]
				,[Question]
				,[Answer]
				,[CountryID]
				,[IsVIP]
				,[RelatedCustID]
				,[SiteID]
				,[Wire_BankName]
				,[Wire_BankAddress]
				,[Wire_SwiftCode]
				,[Wire_AccountName]
				,[Wire_AccountNo]
				,[Remark]
				,[CreateDate]
				,[CreatorID]
				,[Remark2]
				,[AccountHolderName]
				,[Skype]
				,[MSN]
				--,[tstamp]
				,[PhoneCountryCode]
				,[PhoneAreaCode]
				,[Phone2]
				,[Phone2CountryCode]
				,[Phone2AreaCode]
				,[Phone3]
				,[Phone3CountryCode]
				,[Phone3AreaCode]
				,[MobilePhoneCountryCode]
				,[MobilePhoneAreaCode]
				,[FaxCountryCode]
				,[FaxAreaCode]
				,[Pic4]
				,[Passport]
				,[Line1]
				,[Line2]
				,[Line3]
				,[City]
				,[Postcode]
				,[State]
				,[BankLine1]
				,[BankLine2]
				,[BankLine3]
				,[BankCity]
				,[BankCode]
				,[BankState]
				,[BankCountryID]
				,[IsVerifyEmail]
				,[IsVerifyPassport]
				,[IsVerifyBirthday]
				,[IsVerifySecretCode]
				,[IsVerifyBetCredit]
				,[IsVerifyGivenCredit]
			)
			VALUES(
				 SOURCE.[CustID]
				,SOURCE.[UserName]
				,SOURCE.[TitleID]
				,SOURCE.[FirstName]
				,SOURCE.[LastName]
				,SOURCE.[Phone]
				,SOURCE.[MobilePhone]
				,SOURCE.[Fax]
				,SOURCE.[Email]
				,SOURCE.[Birthday]
				,SOURCE.[RefCode1]
				,SOURCE.[RefCode2]
				,SOURCE.[Pic1]
				,SOURCE.[Pic2]
				,SOURCE.[Pic3]
				,SOURCE.[LanguageID]
				,SOURCE.[Question]
				,SOURCE.[Answer]
				,SOURCE.[CountryID]
				,SOURCE.[IsVIP]
				,SOURCE.[RelatedCustID]
				,SOURCE.[SiteID]
				,SOURCE.[Wire_BankName]
				,SOURCE.[Wire_BankAddress]
				,SOURCE.[Wire_SwiftCode]
				,SOURCE.[Wire_AccountName]
				,SOURCE.[Wire_AccountNo]
				,SOURCE.[Remark]
				,SOURCE.[CreateDate]
				,SOURCE.[CreatorID]
				,SOURCE.[Remark2]
				,SOURCE.[AccountHolderName]
				,SOURCE.[Skype]
				,SOURCE.[MSN]
				--,SOURCE.[tstamp]
				,SOURCE.[PhoneCountryCode]
				,SOURCE.[PhoneAreaCode]
				,SOURCE.[Phone2]
				,SOURCE.[Phone2CountryCode]
				,SOURCE.[Phone2AreaCode]
				,SOURCE.[Phone3]
				,SOURCE.[Phone3CountryCode]
				,SOURCE.[Phone3AreaCode]
				,SOURCE.[MobilePhoneCountryCode]
				,SOURCE.[MobilePhoneAreaCode]
				,SOURCE.[FaxCountryCode]
				,SOURCE.[FaxAreaCode]
				,SOURCE.[Pic4]
				,SOURCE.[Passport]
				,SOURCE.[Line1]
				,SOURCE.[Line2]
				,SOURCE.[Line3]
				,SOURCE.[City]
				,SOURCE.[Postcode]
				,SOURCE.[State]
				,SOURCE.[BankLine1]
				,SOURCE.[BankLine2]
				,SOURCE.[BankLine3]
				,SOURCE.[BankCity]
				,SOURCE.[BankCode]
				,SOURCE.[BankState]
				,SOURCE.[BankCountryID]
				,SOURCE.[IsVerifyEmail]
				,SOURCE.[IsVerifyPassport]
				,SOURCE.[IsVerifyBirthday]
				,SOURCE.[IsVerifySecretCode]
				,SOURCE.[IsVerifyBetCredit]
				,SOURCE.[IsVerifyGivenCredit]			
			);
	END

	----@Type = 2: crmCustomerLanguage
	CREATE TABLE #tmpcrmCustomerLanguage(
		ChangedOperation NVARCHAR(1) NULL,
		[CustID] [int] NOT NULL,
		[LanguageID] [int] NOT NULL)

	INSERT INTO #tmpcrmCustomerLanguage(
		ChangedOperation
		,[CustID]
		,[LanguageID])
	EXEC DBCRM.bodb_CRM.dbo.[Task_STDBY_SYN_CRM_TableCTSel] @Type = 2, @ctCurrentVersion = @ctCurrentVersion, @ctLastSyncVersion =@ctLastSyncVersion 
	IF @@ROWCOUNT <>0
	BEGIN
		MERGE crmCustomerLanguage AS TARGET
		USING #tmpcrmCustomerLanguage AS SOURCE ON (TARGET.CustID = SOURCE.CustID AND TARGET.LanguageID = SOURCE.LanguageID)
		WHEN MATCHED AND SOURCE.ChangedOperation IN ('D') THEN 
			DELETE
		WHEN NOT MATCHED BY TARGET AND SOURCE.ChangedOperation IN ('I') THEN 
			INSERT(
				 [CustID]
				,[LanguageID]
			)
			VALUES(
				 SOURCE.[CustID]
				,SOURCE.[LanguageID]
			); 
	END

	----@Type = 3: crmFeedback
	CREATE TABLE #tmpcrmFeedback (
			ChangedOperation NVARCHAR(1),
			[FeedbackID] [int] NOT NULL,
			[CustID] [int] NULL,
			[TitleID] [int] NULL,
			[FirstName] [nvarchar](50) NULL,
			[LastName] [nvarchar](50) NULL,
			[Phone] [nvarchar](50) NULL,
			[MobilePhone] [nvarchar](50) NULL,
			[Fax] [nvarchar](50) NULL,
			[Email] [nvarchar](254) NULL,
			[LanguageID] [int] NULL,
			[CountryID] [int] NULL,
			[CreateDate] [datetime] NULL,
			[CreatorID] [int] NULL,
			[FeedbackDate] [datetime] NULL,
			[SolveDate] [datetime] NULL,
			[CommunicationID] [int] NULL,
			[StationID] [int] NULL,
			[MainCategoryID] [int] NULL,
			[SubCategoryID] [int] NULL,
			[SiteID] [int] NULL,
			[RoleID] [int] NULL,
			[ProductID] [int] NULL,
			[BetTypeID] [int] NULL,
			[ResponseID] [int] NULL,
			[StatusID] [int] NULL,
			[Description] [nvarchar](max) NULL,
			[Solution] [nvarchar](max) NULL,
			[IsReviewed] [bit] NULL,
			[Review] [nvarchar](MAX) NULL,
			[ReviewerID] [int] NULL,
			[Subject] [nvarchar](200) NULL,
			[Skype] [nvarchar](100) NULL,
			[MSN] [nvarchar](100) NULL,
			[ResolutionDate] [datetime] NULL,
			[Pic1] [nvarchar](100) NULL,
			[Pic2] [nvarchar](100) NULL,
			[Pic3] [nvarchar](100) NULL,
			[PhoneCountryCode] [nvarchar](20) NULL,
			[PhoneAreaCode] [nvarchar](20) NULL,
			[Phone2] [nvarchar](100) NULL,
			[Phone2CountryCode] [nvarchar](20) NULL,
			[Phone2AreaCode] [nvarchar](20) NULL,
			[Phone3] [nvarchar](100) NULL,
			[Phone3CountryCode] [nvarchar](20) NULL,
			[Phone3AreaCode] [nvarchar](20) NULL,
			[MobilePhoneCountryCode] [nvarchar](20) NULL,
			[MobilePhoneAreaCode] [nvarchar](20) NULL,
			[FaxCountryCode] [nvarchar](20) NULL,
			[FaxAreaCode] [nvarchar](20) NULL,
			[Pic4] [nvarchar](100) NULL,
			[Passport] [nvarchar](100) NULL,
			[Line1] [nvarchar](100) NULL,
			[Line2] [nvarchar](100) NULL,
			[Line3] [nvarchar](100) NULL,
			[City] [nvarchar](100) NULL,
			[Postcode] [nvarchar](100) NULL,
			[State] [nvarchar](100) NULL,
			[BankLine1] [nvarchar](100) NULL,
			[BankLine2] [nvarchar](100) NULL,
			[BankLine3] [nvarchar](100) NULL,
			[BankCity] [nvarchar](100) NULL,
			[BankCode] [nvarchar](100) NULL,
			[BankState] [nvarchar](100) NULL,
			[Birthday] [datetime] NULL,
			[RefCode1] [nvarchar](50) NULL,
			[RefCode2] [nvarchar](50) NULL,
			[IsVip] [bit] NULL
		)
		INSERT INTO #tmpcrmFeedback(
			ChangedOperation
			,[FeedbackID]
			,[CustID]
			,[TitleID]
			,[FirstName]
			,[LastName]
			,[Phone]
			,[MobilePhone]
			,[Fax]
			,[Email]
			,[LanguageID]
			,[CountryID]
			,[CreateDate]
			,[CreatorID]
			,[FeedbackDate]
			,[SolveDate]
			,[CommunicationID]
			,[StationID]
			,[MainCategoryID]
			,[SubCategoryID]
			,[SiteID]
			,[RoleID]
			,[ProductID]
			,[BetTypeID]
			,[ResponseID]
			,[StatusID]
			,[Description]
			,[Solution]
			,[IsReviewed]
			,[Review]
			,[ReviewerID]
			,[Subject]
			,[Skype]
			,[MSN]
			,[ResolutionDate]
			,[Pic1]
			,[Pic2]
			,[Pic3]
			,[PhoneCountryCode]
			,[PhoneAreaCode]
			,[Phone2]
			,[Phone2CountryCode]
			,[Phone2AreaCode]
			,[Phone3]
			,[Phone3CountryCode]
			,[Phone3AreaCode]
			,[MobilePhoneCountryCode]
			,[MobilePhoneAreaCode]
			,[FaxCountryCode]
			,[FaxAreaCode]
			,[Pic4]
			,[Passport]
			,[Line1]
			,[Line2]
			,[Line3]
			,[City]
			,[Postcode]
			,[State]
			,[BankLine1]
			,[BankLine2]
			,[BankLine3]
			,[BankCity]
			,[BankCode]
			,[BankState]
			,[Birthday]
			,[RefCode1]
			,[RefCode2]
			,[IsVip]
		)
		EXEC DBCRM.bodb_CRM.dbo.[Task_STDBY_SYN_CRM_TableCTSel] @Type = 3, @ctCurrentVersion = @ctCurrentVersion, @ctLastSyncVersion =@ctLastSyncVersion 
		IF @@ROWCOUNT <>0
		BEGIN
			SET IDENTITY_INSERT crmFeedback ON 
			MERGE crmFeedback AS TARGET
			USING #tmpcrmFeedback AS SOURCE ON (TARGET.FeedbackID = SOURCE.FeedbackID)
			WHEN MATCHED AND SOURCE.ChangedOperation IN ('I','U') THEN 
				UPDATE SET
					 TARGET.CustID= SOURCE.CustID
					,TARGET.TitleID= SOURCE.TitleID
					,TARGET.FirstName= SOURCE.FirstName
					,TARGET.LastName= SOURCE.LastName
					,TARGET.Phone= SOURCE.Phone
					,TARGET.MobilePhone= SOURCE.MobilePhone
					,TARGET.Fax= SOURCE.Fax
					,TARGET.Email= SOURCE.Email
					,TARGET.LanguageID= SOURCE.LanguageID
					,TARGET.CountryID= SOURCE.CountryID
					,TARGET.CreateDate= SOURCE.CreateDate
					,TARGET.CreatorID= SOURCE.CreatorID
					,TARGET.FeedbackDate= SOURCE.FeedbackDate
					,TARGET.SolveDate= SOURCE.SolveDate
					,TARGET.CommunicationID= SOURCE.CommunicationID
					,TARGET.StationID= SOURCE.StationID
					,TARGET.MainCategoryID= SOURCE.MainCategoryID
					,TARGET.SubCategoryID= SOURCE.SubCategoryID
					,TARGET.SiteID= SOURCE.SiteID
					,TARGET.RoleID= SOURCE.RoleID
					,TARGET.ProductID= SOURCE.ProductID
					,TARGET.BetTypeID= SOURCE.BetTypeID
					,TARGET.ResponseID= SOURCE.ResponseID
					,TARGET.StatusID= SOURCE.StatusID
					,TARGET.Description= SOURCE.Description
					,TARGET.Solution= SOURCE.Solution
					,TARGET.IsReviewed= SOURCE.IsReviewed
					,TARGET.Review= SOURCE.Review
					,TARGET.ReviewerID= SOURCE.ReviewerID
					,TARGET.Subject= SOURCE.Subject
					,TARGET.Skype= SOURCE.Skype
					,TARGET.MSN= SOURCE.MSN
					,TARGET.ResolutionDate= SOURCE.ResolutionDate
					,TARGET.Pic1= SOURCE.Pic1
					,TARGET.Pic2= SOURCE.Pic2
					,TARGET.Pic3= SOURCE.Pic3
					,TARGET.PhoneCountryCode= SOURCE.PhoneCountryCode
					,TARGET.PhoneAreaCode= SOURCE.PhoneAreaCode
					,TARGET.Phone2= SOURCE.Phone2
					,TARGET.Phone2CountryCode= SOURCE.Phone2CountryCode
					,TARGET.Phone2AreaCode= SOURCE.Phone2AreaCode
					,TARGET.Phone3= SOURCE.Phone3
					,TARGET.Phone3CountryCode= SOURCE.Phone3CountryCode
					,TARGET.Phone3AreaCode= SOURCE.Phone3AreaCode
					,TARGET.MobilePhoneCountryCode= SOURCE.MobilePhoneCountryCode
					,TARGET.MobilePhoneAreaCode= SOURCE.MobilePhoneAreaCode
					,TARGET.FaxCountryCode= SOURCE.FaxCountryCode
					,TARGET.FaxAreaCode= SOURCE.FaxAreaCode
					,TARGET.Pic4= SOURCE.Pic4
					,TARGET.Passport= SOURCE.Passport
					,TARGET.Line1= SOURCE.Line1
					,TARGET.Line2= SOURCE.Line2
					,TARGET.Line3= SOURCE.Line3
					,TARGET.City= SOURCE.City
					,TARGET.Postcode= SOURCE.Postcode
					,TARGET.State= SOURCE.State
					,TARGET.BankLine1= SOURCE.BankLine1
					,TARGET.BankLine2= SOURCE.BankLine2
					,TARGET.BankLine3= SOURCE.BankLine3
					,TARGET.BankCity= SOURCE.BankCity
					,TARGET.BankCode= SOURCE.BankCode
					,TARGET.BankState= SOURCE.BankState
					,TARGET.Birthday= SOURCE.Birthday
					,TARGET.RefCode1= SOURCE.RefCode1
					,TARGET.RefCode2= SOURCE.RefCode2
					,TARGET.IsVip= SOURCE.IsVip		
			WHEN MATCHED AND SOURCE.ChangedOperation IN ('D') THEN
				DELETE
			WHEN NOT MATCHED BY TARGET AND SOURCE.ChangedOperation IN ('I') THEN 
				INSERT(
					 [FeedbackID]
					,[CustID]
					,[TitleID]
					,[FirstName]
					,[LastName]
					,[Phone]
					,[MobilePhone]
					,[Fax]
					,[Email]
					,[LanguageID]
					,[CountryID]
					,[CreateDate]
					,[CreatorID]
					,[FeedbackDate]
					,[SolveDate]
					,[CommunicationID]
					,[StationID]
					,[MainCategoryID]
					,[SubCategoryID]
					,[SiteID]
					,[RoleID]
					,[ProductID]
					,[BetTypeID]
					,[ResponseID]
					,[StatusID]
					,[Description]
					,[Solution]
					,[IsReviewed]
					,[Review]
					,[ReviewerID]
					,[Subject]
					,[Skype]
					,[MSN]
					,[ResolutionDate]
					,[Pic1]
					,[Pic2]
					,[Pic3]
					,[PhoneCountryCode]
					,[PhoneAreaCode]
					,[Phone2]
					,[Phone2CountryCode]
					,[Phone2AreaCode]
					,[Phone3]
					,[Phone3CountryCode]
					,[Phone3AreaCode]
					,[MobilePhoneCountryCode]
					,[MobilePhoneAreaCode]
					,[FaxCountryCode]
					,[FaxAreaCode]
					,[Pic4]
					,[Passport]
					,[Line1]
					,[Line2]
					,[Line3]
					,[City]
					,[Postcode]
					,[State]
					,[BankLine1]
					,[BankLine2]
					,[BankLine3]
					,[BankCity]
					,[BankCode]
					,[BankState]
					,[Birthday]
					,[RefCode1]
					,[RefCode2]
					,[IsVip]
				)
				VALUES(
					 SOURCE.[FeedbackID]
					,SOURCE.[CustID]
					,SOURCE.[TitleID]
					,SOURCE.[FirstName]
					,SOURCE.[LastName]
					,SOURCE.[Phone]
					,SOURCE.[MobilePhone]
					,SOURCE.[Fax]
					,SOURCE.[Email]
					,SOURCE.[LanguageID]
					,SOURCE.[CountryID]
					,SOURCE.[CreateDate]
					,SOURCE.[CreatorID]
					,SOURCE.[FeedbackDate]
					,SOURCE.[SolveDate]
					,SOURCE.[CommunicationID]
					,SOURCE.[StationID]
					,SOURCE.[MainCategoryID]
					,SOURCE.[SubCategoryID]
					,SOURCE.[SiteID]
					,SOURCE.[RoleID]
					,SOURCE.[ProductID]
					,SOURCE.[BetTypeID]
					,SOURCE.[ResponseID]
					,SOURCE.[StatusID]
					,SOURCE.[Description]
					,SOURCE.[Solution]
					,SOURCE.[IsReviewed]
					,SOURCE.[Review]
					,SOURCE.[ReviewerID]
					,SOURCE.[Subject]
					,SOURCE.[Skype]
					,SOURCE.[MSN]
					,SOURCE.[ResolutionDate]
					,SOURCE.[Pic1]
					,SOURCE.[Pic2]
					,SOURCE.[Pic3]
					,SOURCE.[PhoneCountryCode]
					,SOURCE.[PhoneAreaCode]
					,SOURCE.[Phone2]
					,SOURCE.[Phone2CountryCode]
					,SOURCE.[Phone2AreaCode]
					,SOURCE.[Phone3]
					,SOURCE.[Phone3CountryCode]
					,SOURCE.[Phone3AreaCode]
					,SOURCE.[MobilePhoneCountryCode]
					,SOURCE.[MobilePhoneAreaCode]
					,SOURCE.[FaxCountryCode]
					,SOURCE.[FaxAreaCode]
					,SOURCE.[Pic4]
					,SOURCE.[Passport]
					,SOURCE.[Line1]
					,SOURCE.[Line2]
					,SOURCE.[Line3]
					,SOURCE.[City]
					,SOURCE.[Postcode]
					,SOURCE.[State]
					,SOURCE.[BankLine1]
					,SOURCE.[BankLine2]
					,SOURCE.[BankLine3]
					,SOURCE.[BankCity]
					,SOURCE.[BankCode]
					,SOURCE.[BankState]
					,SOURCE.[Birthday]
					,SOURCE.[RefCode1]
					,SOURCE.[RefCode2]
					,SOURCE.[IsVip]
				);		
			SET IDENTITY_INSERT crmFeedback OFF
		END

	----@Type = 4: crmFeedbackCustomer
	CREATE TABLE #tmpcrmFeedbackCustomer(
			ChangedOperation NVARCHAR(1),
			[FeedbackID] [int] NULL,
			[CustID] [int] NULL,
			[IsRelated] [bit] NULL)
	INSERT INTO #tmpcrmFeedbackCustomer(
		ChangedOperation
		,[FeedbackID]
		,[CustID]
		,[IsRelated]
	)
	EXEC DBCRM.bodb_CRM.dbo.[Task_STDBY_SYN_CRM_TableCTSel] @Type = 4, @ctCurrentVersion = @ctCurrentVersion, @ctLastSyncVersion =@ctLastSyncVersion 
	IF @@ROWCOUNT<>0
	BEGIN
		MERGE crmFeedbackCustomer AS TARGET
		USING #tmpcrmFeedbackCustomer AS SOURCE ON (TARGET.[FeedbackID] = SOURCE.[FeedbackID] AND TARGET.CustID = SOURCE.CustID)
		WHEN MATCHED AND ChangedOperation IN ('U','I') THEN 
			UPDATE SET
				 TARGET.IsRelated= SOURCE.IsRelated				
		WHEN MATCHED AND ChangedOperation IN ('D') THEN
			DELETE
		WHEN NOT MATCHED BY TARGET AND SOURCE.ChangedOperation IN ('I') THEN
			INSERT(
				 [FeedbackID]
				,[CustID]
				,[IsRelated]		
			)
			VALUES(
				 SOURCE.[FeedbackID]
				,SOURCE.[CustID]
				,SOURCE.[IsRelated]			
			);
	END

	---- @Type = 5: crmRedemption
	CREATE TABLE #tmpcrmRedemption(
		ChangedOperation NVARCHAR(1),
		[ID] [int] NULL,
		[Subject] [nvarchar](200) NULL,
		[ClaimTime] [datetime] NULL,
		[Remark] [ntext] NULL,
		[StatusID] [int] NULL,
		[CustID] [int] NULL,
		[CreateDate] [datetime] NULL,
		[Creator] [int] NULL)
	INSERT INTO #tmpcrmRedemption(
		ChangedOperation
		,[ID]
		,[Subject]
		,[ClaimTime]
		,[Remark]
		,[StatusID]
		,[CustID]
		,[CreateDate]
		,[Creator]
	)
	EXEC DBCRM.bodb_CRM.dbo.[Task_STDBY_SYN_CRM_TableCTSel] @Type = 5, @ctCurrentVersion = @ctCurrentVersion, @ctLastSyncVersion =@ctLastSyncVersion 
	IF @@ROWCOUNT <>0
	BEGIN
		SET IDENTITY_INSERT crmRedemption ON 
		MERGE crmRedemption AS TARGET
		USING #tmpcrmRedemption AS SOURCE ON (TARGET.ID = SOURCE.ID)
			WHEN MATCHED AND SOURCE.ChangedOperation IN ('I','U') THEN
				UPDATE SET
					 TARGET.Subject= SOURCE.Subject
					,TARGET.ClaimTime= SOURCE.ClaimTime
					,TARGET.Remark= SOURCE.Remark
					,TARGET.StatusID= SOURCE.StatusID
					,TARGET.CustID= SOURCE.CustID
					,TARGET.CreateDate= SOURCE.CreateDate
					,TARGET.Creator= SOURCE.Creator	
			WHEN MATCHED AND SOURCE.ChangedOperation IN ('D') THEN
				DELETE
			WHEN NOT MATCHED BY TARGET AND SOURCE.ChangedOperation IN ('I') THEN
				INSERT(
					 [ID]
					,[Subject]
					,[ClaimTime]
					,[Remark]
					,[StatusID]
					,[CustID]
					,[CreateDate]
					,[Creator]				
				)
				VALUES(
					 SOURCE.[ID]
					,SOURCE.[Subject]
					,SOURCE.[ClaimTime]
					,SOURCE.[Remark]
					,SOURCE.[StatusID]
					,SOURCE.[CustID]
					,SOURCE.[CreateDate]
					,SOURCE.[Creator]				
				); 				
		SET IDENTITY_INSERT crmRedemption OFF
	END

	----@Type = 6: crmSetting
	CREATE TABLE #tmpcrmSetting(
			ChangedOperation NVARCHAR(1),
			[SettingName] [varchar](50)  NULL,
			[SettingID] [int]  NULL,
			[SettingValue] [nvarchar](100)  NULL,
			[DisplayOrder] [int]  NULL,
			[IsActive] [bit]  NULL)
	INSERT INTO #tmpcrmSetting(
		ChangedOperation
		,[SettingName]
		,[SettingID]
		,[SettingValue]
		,[DisplayOrder]
		,[IsActive]
	)
	EXEC DBCRM.bodb_CRM.dbo.[Task_STDBY_SYN_CRM_TableCTSel] @Type = 6, @ctCurrentVersion = @ctCurrentVersion, @ctLastSyncVersion =@ctLastSyncVersion 
	IF @@ROWCOUNT <>0
	BEGIN
		MERGE crmSetting AS TARGET
		USING #tmpcrmSetting AS SOURCE ON (TARGET.SettingID = SOURCE.SettingID)
		WHEN MATCHED AND ChangedOperation IN ('U','I') THEN 
			UPDATE SET
				 TARGET.SettingName= SOURCE.SettingName
				,TARGET.SettingValue= SOURCE.SettingValue
				,TARGET.DisplayOrder= SOURCE.DisplayOrder
				,TARGET.IsActive= SOURCE.IsActive
		WHEN MATCHED AND ChangedOperation IN ('D') THEN
			DELETE
		WHEN NOT MATCHED BY TARGET AND ChangedOperation IN ('I') THEN
			INSERT(
				 [SettingName]
				,[SettingID]
				,[SettingValue]
				,[DisplayOrder]
				,[IsActive]			
			)
			VALUES(
				 SOURCE.[SettingName]
				,SOURCE.[SettingID]
				,SOURCE.[SettingValue]
				,SOURCE.[DisplayOrder]
				,SOURCE.[IsActive]			
			);				
	END

	----@Type = 7: crmSettingRelation
	CREATE TABLE #tmpcrmSettingRelation(
		ChangedOperation NVARCHAR(1),
		[SettingID] [int] NULL,
		[ParentID] [int] NULL,
		[DisplayOrder] [int] NULL)
	INSERT INTO #tmpcrmSettingRelation(
		ChangedOperation
		,[SettingID]
		,[ParentID]
		,[DisplayOrder]	
	)
	EXEC DBCRM.bodb_CRM.dbo.[Task_STDBY_SYN_CRM_TableCTSel] @Type = 7, @ctCurrentVersion = @ctCurrentVersion, @ctLastSyncVersion =@ctLastSyncVersion 
	IF @@ROWCOUNT<>0
	BEGIN
		MERGE crmSettingRelation AS TARGET
		USING #tmpcrmSettingRelation AS SOURCE ON (TARGET.SettingID = SOURCE.SettingID AND TARGET.ParentID = SOURCE.ParentID)
		WHEN MATCHED AND ChangedOperation IN ('U','I') THEN
			UPDATE SET
				TARGET.DisplayOrder= SOURCE.DisplayOrder			
		WHEN MATCHED AND ChangedOperation IN ('D') THEN
			DELETE
		WHEN NOT MATCHED BY TARGET AND ChangedOperation IN ('I') THEN
			INSERT(
				 [SettingID]
				,[ParentID]
				,[DisplayOrder]		
			)
			VALUES(
				 SOURCE.[SettingID]
				,SOURCE.[ParentID]
				,SOURCE.[DisplayOrder]			
			);
	END

	----@Type = 8: crmSubjectTemplate
	CREATE TABLE #tmpcrmSubjectTemplate(
		ChangedOperation NVARCHAR(1),
		[templateID] [int] NULL,
		[subject] [nvarchar](200) NULL,
		[IsActive] [bit] NULL)
	INSERT INTO #tmpcrmSubjectTemplate(
		ChangedOperation
		,[templateID]
		,[subject]
		,[IsActive]	
	)
	EXEC DBCRM.bodb_CRM.dbo.[Task_STDBY_SYN_CRM_TableCTSel] @Type = 8, @ctCurrentVersion = @ctCurrentVersion, @ctLastSyncVersion =@ctLastSyncVersion 
	IF @@ROWCOUNT <>0
	BEGIN
		SET IDENTITY_INSERT crmSubjectTemplate ON 
		MERGE crmSubjectTemplate AS TARGET 
		USING #tmpcrmSubjectTemplate AS SOURCE ON (TARGET.templateID = SOURCE.templateID)
		WHEN MATCHED AND SOURCE.ChangedOperation IN ('U','I') THEN
			UPDATE SET
				 TARGET.subject= SOURCE.subject
				,TARGET.IsActive= SOURCE.IsActive	
		WHEN MATCHED AND SOURCE.ChangedOperation IN ('D') THEN
			DELETE
		WHEN NOT MATCHED BY TARGET AND SOURCE.ChangedOperation IN ('I') THEN 
			INSERT(
				 [templateID]
				,[subject]
				,[IsActive]			
			)
			VALUES(
				 SOURCE.[templateID]
				,SOURCE.[subject]
				,SOURCE.[IsActive]			
			);
		SET IDENTITY_INSERT crmSubjectTemplate OFF		
	END

	--- @Type = 9: crmCustomerRemark
	CREATE TABLE #tmpcrmCustomerRemark(
		ChangedOperation NVARCHAR(1),
		[RemarkID] [int] NOT NULL,
		[CustID] [int] NULL,
		[Remark] [nvarchar](max) NULL,
		[IsSpecial] [bit] NULL)
	INSERT INTO #tmpcrmCustomerRemark(
		ChangedOperation
		,[RemarkID]
		,[CustID]
		,[Remark]
		,[IsSpecial]	
	)
	EXEC DBCRM.bodb_CRM.dbo.[Task_STDBY_SYN_CRM_TableCTSel] @Type = 9, @ctCurrentVersion = @ctCurrentVersion, @ctLastSyncVersion =@ctLastSyncVersion 
	IF @@ROWCOUNT <>0
	BEGIN
		SET IDENTITY_INSERT crmCustomerRemark ON 
		MERGE crmCustomerRemark AS TARGET
		USING #tmpcrmCustomerRemark AS SOURCE ON (TARGET.RemarkID = SOURCE.RemarkID)
		WHEN MATCHED AND SOURCE.ChangedOperation IN('I','U') THEN
			UPDATE SET
				 TARGET.CustID= SOURCE.CustID
				,TARGET.Remark= SOURCE.Remark
				,TARGET.IsSpecial= SOURCE.IsSpecial	
		WHEN MATCHED AND SOURCE.ChangedOperation IN('D') THEN	
			DELETE
		WHEN NOT MATCHED BY TARGET AND SOURCE.ChangedOperation IN ('I') THEN 
			INSERT(
				 [RemarkID]
				,[CustID]
				,[Remark]
				,[IsSpecial]			
			)	
			VALUES(
				 SOURCE.[RemarkID]
				,SOURCE.[CustID]
				,SOURCE.[Remark]
				,SOURCE.[IsSpecial]			
			);
		SET IDENTITY_INSERT crmCustomerRemark OFF
	END


	DROP TABLE #tmpCRMCustomer
	DROP TABLE #tmpcrmCustomerLanguage
	DROP TABLE #tmpcrmFeedback
	DROP TABLE #tmpcrmFeedbackCustomer
	DROP TABLE #tmpcrmRedemption
	DROP TABLE #tmpcrmSetting
	DROP TABLE #tmpcrmSettingRelation
	DROP TABLE #tmpcrmSubjectTemplate
	DROP TABLE #tmpcrmCustomerRemark

	UPDATE	DBCRM.bodb_CRM.dbo.crmCTLastSyncVersion WITH (ROWLOCK,UPDLOCK)
	SET		LastSyncVersion = @ctCurrentVersion
	WHERE	CTID = 1 

END 
GO


