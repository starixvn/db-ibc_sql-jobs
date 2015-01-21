USE [Affiliate_12BET]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYNC_AFF12BET_TableInfoIns]    Script Date: 01/20/2015 22:48:27 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYNC_AFF12BET_TableInfoIns]
AS 
/*
	Created by: Jamie 
	Date: 2013-04-10
	Task: Synchronize data AFF12BET (PUT ON Primary server) 
			
	Revisions:
		+ AffInfo = 1
		+ AffDetail = 2
		+ AffTrans = 3
		+ MemberInfo = 4
		+ ClickStatistics1_bk = 5 
		+ ClickStatistics1Sum = 6 

*/
BEGIN
	SET NOCOUNT ON
	DECLARE	 @ctCurrentVersion			BIGINT
			,@ctLastSyncVersion			BIGINT
			,@Type						INT 

	EXEC DBAFF12BET.Affiliate_12BET.dbo.[Task_STDBY_SYNC_AFF12BET_TableInfoSel_currentVersion] @ctCurrentVersion = @ctCurrentVersion OUTPUT 

	PRINT @ctCurrentVersion 

	SELECT	@ctLastSyncVersion = LastSyncVersion
	FROM	DBAFF12BET.Affiliate_12BET.dbo.affCTLastSyncVersion WITH (NOLOCK)
	WHERE	CTID = 1 

	PRINT @ctLastSyncVersion

	IF	@ctLastSyncVersion >= @ctCurrentVersion RETURN	-- No changes 

	
	--- AffInfo = 1

	CREATE TABLE #tmpAffInfo(
		ChangedOperation NVARCHAR(1) NULL,
		[AffID] [int] NULL,
		[UserName] [nvarchar](30) NOT NULL,
		[UserName2] [nvarchar](30) NULL,
		[FirstName] [nvarchar](50) NULL,
		[LastName] [nvarchar](50) NULL,
		[GroupID] [int] NULL,
		[Status] [varchar](30) NULL,
		[ApprovedDate] [smalldatetime] NULL,
		[IsClosed] [bit] NULL,
		[Currency] [tinyint] NULL,
		[RegisteredDate] [smalldatetime] NULL,
		[Email] [nvarchar](50) NULL,
		[Password] [varchar](40) NULL,
		[AffType] [tinyint] NULL,
		[IsPageEnabled] [bit] NULL,
		[Level] [tinyint] NULL,
		[IsLocked] [bit] NULL,
		[CasinoJoinedDate] [smalldatetime] NULL,
		[ForceChangePass] [bit] NULL,
		[EUAffID] [int] NULL
		)
	
	INSERT INTO #tmpAffInfo(
		   ChangedOperation
		  ,[AffID]
		  ,[UserName]
		  ,[UserName2]
		  ,[FirstName]
		  ,[LastName]
		  ,[GroupID]
		  ,[Status]
		  ,[ApprovedDate]
		  ,[IsClosed]
		  ,[Currency]
		  ,[RegisteredDate]
		  ,[Email]
		  ,[Password]
		  ,[AffType]
		  ,[IsPageEnabled]
		  ,[Level]
		  ,[IsLocked]
		  ,[CasinoJoinedDate]
		  ,[ForceChangePass]
		  ,[EUAffID]	
	)
	EXEC DBAFF12BET.Affiliate_12bet.dbo.[Task_STDBY_SYNC_AFF12BET_TableInfoSel] @Type = 1, @ctCurrentVersion = @ctCurrentVersion, @ctLastSyncVersion =@ctLastSyncVersion 
	
	IF @@ROWCOUNT <> 0 
	BEGIN 
		SET IDENTITY_INSERT AffInfo ON  
		MERGE	AffInfo AS TARGET 
		USING	#tmpAffInfo AS SOURCE ON (TARGET.AffID = SOURCE.AffID)
		WHEN MATCHED AND SOURCE.ChangedOperation IN('I','U') THEN 
			UPDATE SET
				 TARGET.AffType= SOURCE.AffType
				,TARGET.ApprovedDate= SOURCE.ApprovedDate
				,TARGET.CasinoJoinedDate= SOURCE.CasinoJoinedDate
				,TARGET.Currency= SOURCE.Currency
				,TARGET.Email= SOURCE.Email
				,TARGET.EUAffID= SOURCE.EUAffID
				,TARGET.FirstName= SOURCE.FirstName
				,TARGET.ForceChangePass= SOURCE.ForceChangePass
				,TARGET.GroupID= SOURCE.GroupID
				,TARGET.IsClosed= SOURCE.IsClosed
				,TARGET.IsLocked= SOURCE.IsLocked
				,TARGET.IsPageEnabled= SOURCE.IsPageEnabled
				,TARGET.LastName= SOURCE.LastName
				,TARGET.Level= SOURCE.Level
				,TARGET.Password= SOURCE.Password
				,TARGET.RegisteredDate= SOURCE.RegisteredDate
				,TARGET.Status= SOURCE.Status
				,TARGET.UserName= SOURCE.UserName
				,TARGET.UserName2= SOURCE.UserName2
		WHEN MATCHED AND SOURCE.ChangedOperation IN('D')  THEN
			DELETE 
		WHEN NOT MATCHED BY TARGET AND SOURCE.ChangedOperation IN('I') THEN 
			INSERT(	 AffID
					,AffType
					,ApprovedDate
					,CasinoJoinedDate
					,Currency
					,Email
					,EUAffID
					,FirstName
					,ForceChangePass
					,GroupID
					,IsClosed
					,IsLocked
					,IsPageEnabled
					,LastName
					,Level
					,Password
					,RegisteredDate
					,Status
					,UserName
					,UserName2				  
				  )

			VALUES(
				 SOURCE.AffID
				,SOURCE.AffType
				,SOURCE.ApprovedDate
				,SOURCE.CasinoJoinedDate
				,SOURCE.Currency
				,SOURCE.Email
				,SOURCE.EUAffID
				,SOURCE.FirstName
				,SOURCE.ForceChangePass
				,SOURCE.GroupID
				,SOURCE.IsClosed
				,SOURCE.IsLocked
				,SOURCE.IsPageEnabled
				,SOURCE.LastName
				,SOURCE.Level
				,SOURCE.Password
				,SOURCE.RegisteredDate
				,SOURCE.Status
				,SOURCE.UserName
				,SOURCE.UserName2
			 );
		SET IDENTITY_INSERT AffInfo OFF 
	END

	--- AffDetail = 2
	CREATE TABLE #tmpAffDetail(
		ChangedOperation NVARCHAR(1) NULL,
		[AffID] [int] NULL,
		[UserName] [varchar](30) NOT NULL,
		[SiteURL] [varchar](100) NOT NULL,
		[MoreSiteURLs] [varchar](1000) NULL,
		[PreferredLanguage] [varchar](11) NULL,
		[Gender] [bit] NULL,
		[Address] [nvarchar](250) NULL,
		[Postal] [nvarchar](50) NULL,
		[City] [nvarchar](250) NULL,
		[State] [nvarchar](50) NULL,
		[Country] [nvarchar](50) NULL,
		[Phone] [varchar](50) NULL,
		[MobilePhone] [varchar](50) NULL,
		[Fax] [varchar](50) NULL,
		[Question] [nvarchar](300) NULL,
		[Answer] [nvarchar](300) NULL,
		[PreferredPayment] [varchar](20) NULL,
		[Player_IBCCustID] [int] NULL,
		[Player_Username] [varchar](100) NULL,
		[Neteller_AccountID] [varchar](50) NULL,
		[Moneybookers_Email] [nvarchar](50) NULL,
		[Wire_BankName] [nvarchar](100) NULL,
		[Wire_BankAddress] [nvarchar](200) NULL,
		[Wire_SwiftCode] [nvarchar](50) NULL,
		[Wire_AccountName] [nvarchar](100) NULL,
		[Wire_AccountNo] [varchar](50) NULL,
		[Cheque_FullName] [nvarchar](200) NULL,
		[Cheque_Address] [nvarchar](200) NULL,
		[Cheque_City] [nvarchar](50) NULL,
		[Cheque_State] [nvarchar](50) NULL,
		[Cheque_Postal] [nvarchar](50) NULL,
		[Cheque_Country] [nvarchar](50) NULL,
		[BonusCode] [varchar](20) NULL,
		[LastLoginDate] [smalldatetime] NULL,
		[LastLoginIP] [nvarchar](20) NULL,
		[LoginCount] [tinyint] NULL,
		[ValidCode] [nvarchar](11) NULL,
		[CodeExpiry] [datetime] NULL,
		[MailOption] [bit] NULL,
		[NoSiteDesc] [nvarchar](1000) NULL
	)
	INSERT INTO #tmpAffDetail(
		ChangedOperation
		,AffID
		,UserName
		,SiteURL
		,MoreSiteURLs
		,PreferredLanguage
		,Gender
		,Address
		,Postal
		,City
		,State
		,Country
		,Phone
		,MobilePhone
		,Fax
		,Question
		,Answer
		,PreferredPayment
		,Player_IBCCustID
		,Player_Username
		,Neteller_AccountID
		,Moneybookers_Email
		,Wire_BankName
		,Wire_BankAddress
		,Wire_SwiftCode
		,Wire_AccountName
		,Wire_AccountNo
		,Cheque_FullName
		,Cheque_Address
		,Cheque_City
		,Cheque_State
		,Cheque_Postal
		,Cheque_Country
		,BonusCode
		,LastLoginDate
		,LastLoginIP
		,LoginCount
		,ValidCode
		,CodeExpiry
		,MailOption
		,NoSiteDesc		
	)
	EXEC DBAFF12BET.Affiliate_12bet.dbo.[Task_STDBY_SYNC_AFF12BET_TableInfoSel] @Type = 2, @ctCurrentVersion = @ctCurrentVersion, @ctLastSyncVersion =@ctLastSyncVersion 
	IF @@ROWCOUNT<>0
	BEGIN
		MERGE	AffDetail AS TARGET
		USING	#tmpAffDetail AS SOURCE ON (TARGET.AffID = SOURCE.AffID)
		WHEN	MATCHED AND SOURCE.ChangedOperation IN ('I','U') THEN
			UPDATE SET 
				 TARGET.UserName= SOURCE.UserName
				,TARGET.SiteURL= SOURCE.SiteURL
				,TARGET.MoreSiteURLs= SOURCE.MoreSiteURLs
				,TARGET.PreferredLanguage= SOURCE.PreferredLanguage
				,TARGET.Gender= SOURCE.Gender
				,TARGET.Address= SOURCE.Address
				,TARGET.Postal= SOURCE.Postal
				,TARGET.City= SOURCE.City
				,TARGET.State= SOURCE.State
				,TARGET.Country= SOURCE.Country
				,TARGET.Phone= SOURCE.Phone
				,TARGET.MobilePhone= SOURCE.MobilePhone
				,TARGET.Fax= SOURCE.Fax
				,TARGET.Question= SOURCE.Question
				,TARGET.Answer= SOURCE.Answer
				,TARGET.PreferredPayment= SOURCE.PreferredPayment
				,TARGET.Player_IBCCustID= SOURCE.Player_IBCCustID
				,TARGET.Player_Username= SOURCE.Player_Username
				,TARGET.Neteller_AccountID= SOURCE.Neteller_AccountID
				,TARGET.Moneybookers_Email= SOURCE.Moneybookers_Email
				,TARGET.Wire_BankName= SOURCE.Wire_BankName
				,TARGET.Wire_BankAddress= SOURCE.Wire_BankAddress
				,TARGET.Wire_SwiftCode= SOURCE.Wire_SwiftCode
				,TARGET.Wire_AccountName= SOURCE.Wire_AccountName
				,TARGET.Wire_AccountNo= SOURCE.Wire_AccountNo
				,TARGET.Cheque_FullName= SOURCE.Cheque_FullName
				,TARGET.Cheque_Address= SOURCE.Cheque_Address
				,TARGET.Cheque_City= SOURCE.Cheque_City
				,TARGET.Cheque_State= SOURCE.Cheque_State
				,TARGET.Cheque_Postal= SOURCE.Cheque_Postal
				,TARGET.Cheque_Country= SOURCE.Cheque_Country
				,TARGET.BonusCode= SOURCE.BonusCode
				,TARGET.LastLoginDate= SOURCE.LastLoginDate
				,TARGET.LastLoginIP= SOURCE.LastLoginIP
				,TARGET.LoginCount= SOURCE.LoginCount
				,TARGET.ValidCode= SOURCE.ValidCode
				,TARGET.CodeExpiry= SOURCE.CodeExpiry
				,TARGET.MailOption= SOURCE.MailOption
				,TARGET.NoSiteDesc= SOURCE.NoSiteDesc 
		WHEN MATCHED AND SOURCE.ChangedOperation IN('D')  THEN
			DELETE 
		WHEN NOT MATCHED BY TARGET AND SOURCE.ChangedOperation IN('I') THEN 
			INSERT(
				 AffID
				,UserName
				,SiteURL
				,MoreSiteURLs
				,PreferredLanguage
				,Gender
				,Address
				,Postal
				,City
				,State
				,Country
				,Phone
				,MobilePhone
				,Fax
				,Question
				,Answer
				,PreferredPayment
				,Player_IBCCustID
				,Player_Username
				,Neteller_AccountID
				,Moneybookers_Email
				,Wire_BankName
				,Wire_BankAddress
				,Wire_SwiftCode
				,Wire_AccountName
				,Wire_AccountNo
				,Cheque_FullName
				,Cheque_Address
				,Cheque_City
				,Cheque_State
				,Cheque_Postal
				,Cheque_Country
				,BonusCode
				,LastLoginDate
				,LastLoginIP
				,LoginCount
				,ValidCode
				,CodeExpiry
				,MailOption
				,NoSiteDesc				
			)
			VALUES(
				 SOURCE.AffID
				,SOURCE.UserName
				,SOURCE.SiteURL
				,SOURCE.MoreSiteURLs
				,SOURCE.PreferredLanguage
				,SOURCE.Gender
				,SOURCE.Address
				,SOURCE.Postal
				,SOURCE.City
				,SOURCE.State
				,SOURCE.Country
				,SOURCE.Phone
				,SOURCE.MobilePhone
				,SOURCE.Fax
				,SOURCE.Question
				,SOURCE.Answer
				,SOURCE.PreferredPayment
				,SOURCE.Player_IBCCustID
				,SOURCE.Player_Username
				,SOURCE.Neteller_AccountID
				,SOURCE.Moneybookers_Email
				,SOURCE.Wire_BankName
				,SOURCE.Wire_BankAddress
				,SOURCE.Wire_SwiftCode
				,SOURCE.Wire_AccountName
				,SOURCE.Wire_AccountNo
				,SOURCE.Cheque_FullName
				,SOURCE.Cheque_Address
				,SOURCE.Cheque_City
				,SOURCE.Cheque_State
				,SOURCE.Cheque_Postal
				,SOURCE.Cheque_Country
				,SOURCE.BonusCode
				,SOURCE.LastLoginDate
				,SOURCE.LastLoginIP
				,SOURCE.LoginCount
				,SOURCE.ValidCode
				,SOURCE.CodeExpiry
				,SOURCE.MailOption
				,SOURCE.NoSiteDesc			
			); 
			
	END

	-- AffTrans = 3
	CREATE TABLE #tmpAffTrans(
		ChangedOperation NVARCHAR(1) NULL,
		[TransID] [bigint] NULL,
		[AffID] [int] NULL,
		[TransDate] [datetime] NULL,
		[CompletedDate] [datetime] NULL,
		[Amount] [money] NULL,
		[Status] [nvarchar](50) NULL,
		[Description] [nvarchar](300) NULL,
		[Creator] [int] NULL,
		[Currency] [int] NULL,
		[ActualRate] [float] NULL,
		[TransType] [int] NULL,
		[RefID] [bigint] NULL,
		[AffExRate] [float] NULL
	)
	INSERT INTO #tmpAffTrans(
		ChangedOperation
		,TransID
		,AffID
		,TransDate
		,CompletedDate
		,Amount
		,Status
		,Description
		,Creator
		,Currency
		,ActualRate
		,TransType
		,RefID
		,AffExRate		
	)
	EXEC DBAFF12BET.Affiliate_12bet.dbo.[Task_STDBY_SYNC_AFF12BET_TableInfoSel] @Type = 3, @ctCurrentVersion = @ctCurrentVersion, @ctLastSyncVersion =@ctLastSyncVersion	
	IF @@ROWCOUNT <>0
	BEGIN
		SET IDENTITY_INSERT AffTrans ON
		MERGE	AffTrans AS TARGET
		USING	#tmpAffTrans AS SOURCE ON (TARGET.TransID = SOURCE.TransID)
		WHEN MATCHED  AND SOURCE.ChangedOperation IN('I','U') THEN 
			UPDATE SET
				 TARGET.AffID= SOURCE.AffID
				,TARGET.TransDate= SOURCE.TransDate
				,TARGET.CompletedDate= SOURCE.CompletedDate
				,TARGET.Amount= SOURCE.Amount
				,TARGET.Status= SOURCE.Status
				,TARGET.Description= SOURCE.Description
				,TARGET.Creator= SOURCE.Creator
				,TARGET.Currency= SOURCE.Currency
				,TARGET.ActualRate= SOURCE.ActualRate
				,TARGET.TransType= SOURCE.TransType
				,TARGET.RefID= SOURCE.RefID
				,TARGET.AffExRate= SOURCE.AffExRate	
		WHEN MATCHED AND SOURCE.ChangedOperation IN('D') THEN
			DELETE 
		WHEN NOT MATCHED BY TARGET AND SOURCE.ChangedOperation IN('I') THEN 
			INSERT(
				 TransID
				,AffID
				,TransDate
				,CompletedDate
				,Amount
				,Status
				,Description
				,Creator
				,Currency
				,ActualRate
				,TransType
				,RefID
				,AffExRate			
			)
			VALUES(
				 SOURCE.TransID
				,SOURCE.AffID
				,SOURCE.TransDate
				,SOURCE.CompletedDate
				,SOURCE.Amount
				,SOURCE.Status
				,SOURCE.Description
				,SOURCE.Creator
				,SOURCE.Currency
				,SOURCE.ActualRate
				,SOURCE.TransType
				,SOURCE.RefID
				,SOURCE.AffExRate			
			); 		
		SET IDENTITY_INSERT AffTrans OFF
	END

    -- MemberInfo = 4
	CREATE TABLE #tmpMemberInfo(
		ChangedOperation NVARCHAR(1),
		[IBCCustID] [int] NOT NULL PRIMARY KEY,
		[AffID] [int] NULL,
		[UserName] [varchar](30) NULL,
		[IBCUserName] [varchar](30) NULL,
		[CreatedDate] [datetime] NULL,
		[RegisteredDate] [datetime] NULL,
		[IsRemoved] [bit] NOT NULL,
		[DepositCustID] [int] NULL,
		[FirstName] [nvarchar](50) NULL,
		[LastName] [nvarchar](50) NULL,
		[Currency] [int] NOT NULL,
		[Email] [nvarchar](50) NULL,
		[Recommend] [int] NOT NULL,
		[ClickId] [bigint] NULL,
		[EUAffID] [int] NULL,
		[AffAffectedDate] [datetime] NULL
	)
	INSERT INTO #tmpMemberInfo(
		ChangedOperation 
		,IBCCustID
		,AffID
		,UserName
		,IBCUserName
		,CreatedDate
		,RegisteredDate
		,IsRemoved
		,DepositCustID
		,FirstName
		,LastName
		,Currency
		,Email
		,Recommend
		,ClickId
		,EUAffID
		,AffAffectedDate		
	)
	EXEC DBAFF12BET.Affiliate_12bet.dbo.[Task_STDBY_SYNC_AFF12BET_TableInfoSel] @Type = 4, @ctCurrentVersion = @ctCurrentVersion, @ctLastSyncVersion =@ctLastSyncVersion
	IF @@ROWCOUNT <>0
	BEGIN
		MERGE	MemberInfo AS TARGET 
		USING	#tmpMemberInfo AS SOURCE ON (TARGET.IBCCustID = SOURCE.IBCCustID)
		WHEN MATCHED AND SOURCE.ChangedOperation IN ('I','U') THEN 
			UPDATE SET 
				 TARGET.IBCCustID= SOURCE.IBCCustID
				,TARGET.AffID= SOURCE.AffID
				,TARGET.UserName= SOURCE.UserName
				,TARGET.IBCUserName= SOURCE.IBCUserName
				,TARGET.CreatedDate= SOURCE.CreatedDate
				,TARGET.RegisteredDate= SOURCE.RegisteredDate
				,TARGET.IsRemoved= SOURCE.IsRemoved
				,TARGET.DepositCustID= SOURCE.DepositCustID
				,TARGET.FirstName= SOURCE.FirstName
				,TARGET.LastName= SOURCE.LastName
				,TARGET.Currency= SOURCE.Currency
				,TARGET.Email= SOURCE.Email
				,TARGET.Recommend= SOURCE.Recommend
				,TARGET.ClickId= SOURCE.ClickId
				,TARGET.EUAffID= SOURCE.EUAffID
				,TARGET.AffAffectedDate= SOURCE.AffAffectedDate
		WHEN MATCHED AND SOURCE.ChangedOperation IN('D') THEN
			DELETE 
		WHEN NOT MATCHED BY TARGET AND SOURCE.ChangedOperation IN('I') THEN 
			INSERT(
				 IBCCustID
				,AffID
				,UserName
				,IBCUserName
				,CreatedDate
				,RegisteredDate
				,IsRemoved
				,DepositCustID
				,FirstName
				,LastName
				,Currency
				,Email
				,Recommend
				,ClickId
				,EUAffID
				,AffAffectedDate			
			)
			VALUES(
				 SOURCE.IBCCustID
				,SOURCE.AffID
				,SOURCE.UserName
				,SOURCE.IBCUserName
				,SOURCE.CreatedDate
				,SOURCE.RegisteredDate
				,SOURCE.IsRemoved
				,SOURCE.DepositCustID
				,SOURCE.FirstName
				,SOURCE.LastName
				,SOURCE.Currency
				,SOURCE.Email
				,SOURCE.Recommend
				,SOURCE.ClickId
				,SOURCE.EUAffID
				,SOURCE.AffAffectedDate			
			);
	END

	----ClickStatistics1_bk = 5
	CREATE TABLE #tmpClickStatistics1_bk(
		ChangedOperation NVARCHAR(1),
		[ClickID] [bigint] NOT NULL PRIMARY KEY,
		[AffID] [int] NOT NULL,
		[UpdatedTime] [datetime] NOT NULL,
		[IP] [varchar](23) NOT NULL,
		[Date] [smalldatetime] NOT NULL,
		[Browser] [nvarchar](50) NOT NULL,
		[URLReferrer] [nvarchar](300) NOT NULL,
		[DomainReferrer] [nvarchar](300) NOT NULL,
		[OS] [nvarchar](50) NULL,
		[Device] [nvarchar](50) NULL,
		[BrowserVersion] [nvarchar](16) NULL,
		[BrowserResolution] [nvarchar](16) NULL,
		[BrowserLanguage] [nvarchar](8) NULL,
		[UserAgent] [nvarchar](256) NULL,
		[Country] [nvarchar](256) NULL,
		[LanguageCode] [varchar](10) NULL,
		[SportCode] [varchar](50) NULL,
		[RedirectURL] [nvarchar](256) NULL,
		[Status] [tinyint] NULL,
		[DeviceType] [tinyint] NULL)
	INSERT INTO #tmpClickStatistics1_bk(
		ChangedOperation
		,[ClickID]
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
		,[DeviceType]
	)
	EXEC DBAFF12BET.Affiliate_12bet.dbo.[Task_STDBY_SYNC_AFF12BET_TableInfoSel] @Type = 5, @ctCurrentVersion = @ctCurrentVersion, @ctLastSyncVersion =@ctLastSyncVersion		
	IF @@ROWCOUNT<>0
	BEGIN
		MERGE ClickStatistics1_bk AS TARGET
		USING #tmpClickStatistics1_bk AS SOURCE ON (TARGET.ClickID = SOURCE.ClickID)
		WHEN MATCHED AND SOURCE.ChangedOperation IN ('I','U') THEN
			UPDATE SET
				 TARGET.AffID= SOURCE.AffID
				,TARGET.UpdatedTime= SOURCE.UpdatedTime
				,TARGET.IP= SOURCE.IP
				,TARGET.Date= SOURCE.Date
				,TARGET.Browser= SOURCE.Browser
				,TARGET.URLReferrer= SOURCE.URLReferrer
				,TARGET.DomainReferrer= SOURCE.DomainReferrer
				,TARGET.OS= SOURCE.OS
				,TARGET.Device= SOURCE.Device
				,TARGET.BrowserVersion= SOURCE.BrowserVersion
				,TARGET.BrowserResolution= SOURCE.BrowserResolution
				,TARGET.BrowserLanguage= SOURCE.BrowserLanguage
				,TARGET.UserAgent= SOURCE.UserAgent
				,TARGET.Country= SOURCE.Country
				,TARGET.LanguageCode= SOURCE.LanguageCode
				,TARGET.SportCode= SOURCE.SportCode
				,TARGET.RedirectURL= SOURCE.RedirectURL
				,TARGET.Status= SOURCE.Status	
				,TARGET.DeviceType= SOURCE.DeviceType	
		WHEN MATCHED AND SOURCE.ChangedOperation IN ('D') THEN 
			DELETE
		WHEN NOT MATCHED BY TARGET AND SOURCE.ChangedOperation IN ('I') THEN 
			INSERT (
				 [ClickID]
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
				,[DeviceType]
			)	
			VALUES(
				 SOURCE.[ClickID]
				,SOURCE.[AffID]
				,SOURCE.[UpdatedTime]
				,SOURCE.[IP]
				,SOURCE.[Date]
				,SOURCE.[Browser]
				,SOURCE.[URLReferrer]
				,SOURCE.[DomainReferrer]
				,SOURCE.[OS]
				,SOURCE.[Device]
				,SOURCE.[BrowserVersion]
				,SOURCE.[BrowserResolution]
				,SOURCE.[BrowserLanguage]
				,SOURCE.[UserAgent]
				,SOURCE.[Country]
				,SOURCE.[LanguageCode]
				,SOURCE.[SportCode]
				,SOURCE.[RedirectURL]
				,SOURCE.[Status]			
				,SOURCE.[DeviceType]
			);
	END
	----ClickStatistics1Sum
	CREATE TABLE #tmpClickStatistics1Sum(
		ChangedOperation NVARCHAR(1),
		[AffID] [int] NOT NULL,
		[DomainReferrer] [nvarchar](300) NOT NULL,
		[Date] [smalldatetime] NOT NULL,
		[SportCode] [nvarchar](50) NOT NULL,
		[LanguageCode] [nvarchar](10) NOT NULL,
		[TotalClick] [int] NULL,
		[UniqueClick] [int] NULL,
		[TotalSignup] [int] NULL,
		[TotalDeposit] [int] NULL,
		[DeviceType] [int] NOT NULL )
	INSERT INTO #tmpClickStatistics1Sum(
		ChangedOperation
		,[AffID]
		,[DomainReferrer]
		,[Date]
		,[SportCode]
		,[LanguageCode]
		,[TotalClick]
		,[UniqueClick]
		,[TotalSignup]
		,[TotalDeposit]	
		,[DeviceType]
	)
	EXEC DBAFF12BET.Affiliate_12bet.dbo.[Task_STDBY_SYNC_AFF12BET_TableInfoSel] @Type = 6, @ctCurrentVersion = @ctCurrentVersion, @ctLastSyncVersion =@ctLastSyncVersion		
	IF @@ROWCOUNT<>0
	BEGIN
		MERGE ClickStatistics1Sum AS TARGET
		USING #tmpClickStatistics1Sum AS SOURCE 
			ON (TARGET.AffID = SOURCE.AffID AND TARGET.DomainReferrer = SOURCE.DomainReferrer 
				AND TARGET.Date = SOURCE.Date AND TARGET.SportCode = SOURCE.SportCode
				AND TARGET.LanguageCode = SOURCE.LanguageCode
				AND TARGET.DeviceType = SOURCE.DeviceType
				)
		WHEN MATCHED AND SOURCE.ChangedOperation IN ('I','U') THEN
			UPDATE SET		
				 TARGET.TotalClick= SOURCE.TotalClick
				,TARGET.UniqueClick= SOURCE.UniqueClick
				,TARGET.TotalSignup= SOURCE.TotalSignup
				,TARGET.TotalDeposit= SOURCE.TotalDeposit
		WHEN MATCHED AND SOURCE.ChangedOperation IN ('D') THEN
			DELETE
		WHEN NOT MATCHED BY TARGET AND SOURCE.ChangedOperation IN ('I') THEN
			INSERT(
				 [AffID]
				,[DomainReferrer]
				,[Date]
				,[SportCode]
				,[LanguageCode]
				,[TotalClick]
				,[UniqueClick]
				,[TotalSignup]
				,[TotalDeposit]			
				,[DeviceType]
			)
			VALUES(
				 SOURCE.[AffID]
				,SOURCE.[DomainReferrer]
				,SOURCE.[Date]
				,SOURCE.[SportCode]
				,SOURCE.[LanguageCode]
				,SOURCE.[TotalClick]
				,SOURCE.[UniqueClick]
				,SOURCE.[TotalSignup]
				,SOURCE.[TotalDeposit]
				,SOURCE.[DeviceType]
			);
	END


	UPDATE	DBAFF12BET.[Affiliate_12BET].dbo.AffCTLastSyncVersion WITH (UPDLOCK,ROWLOCK)
	SET		 LastSyncVersion = @ctCurrentVersion 
			,ExtractionDate	= GETDATE()
	WHERE	CTID = 1
	
	PRINT  @ctCurrentVersion

	DROP TABLE #tmpAffInfo
	DROP TABLE #tmpAffDetail
	DROP TABLE #tmpAffTrans
	DROP TABLE #tmpMemberInfo
	DROP TABLE #tmpClickStatistics1_bk
	DROP TABLE #tmpClickStatistics1Sum
END
GO


