USE [Affiliate_12BET]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYNC_AFF12BET_TableOther]    Script Date: 01/20/2015 22:52:08 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYNC_AFF12BET_TableOther]

AS
/*
	Created by:Jamie
	Task: Sync tables ( only run at standby server)
	DB: DBAFF12BET/Affiliate_12bet
	Original:
	Revisions:
		- 20141204@Dan: Add more tables (CommGroupHistory, GroupSettingHistory, DeductionSettingHistory, AffGroupHistory)
	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON 
	DECLARE	 @ServCurrent	SYSNAME
			,@ServRemote	SYSNAME
	
	SELECT	@ServCurrent = @@SERVERNAME
	SELECT	@ServRemote	 = (SELECT * FROM OPENQUERY(DBAFF12BET,'SELECT @@SERVERNAME'))
	
	IF @ServCurrent = @ServRemote RETURN ---- In the same server 

	----IDENT TABLES
	TRUNCATE TABLE [12BetDomain]
	SET IDENTITY_INSERT [12BetDomain] ON 
	INSERT INTO [Affiliate_12BET].[dbo].[12BetDomain]
           ([DomainID]
		   ,[DomainName]
           ,[CreateDate]
           ,[ModifyDate]
           ,[Creator])
	SELECT  [DomainID]
		   ,[DomainName]
           ,[CreateDate]
           ,[ModifyDate]
           ,[Creator]
	FROM	DBAFF12BET.[Affiliate_12BET].[dbo].[12BetDomain] WITH (NOLOCK) 
	SET IDENTITY_INSERT [12BetDomain] OFF 

	----[AdminNotes]
	TRUNCATE TABLE [AdminNotes]
	SET IDENTITY_INSERT [AdminNotes] ON 
	INSERT INTO [Affiliate_12bet].[dbo].[AdminNotes]
           ([NoteID]
           ,[Note]
           ,[UpdatedDate]
           ,[AffID]
           ,[UpdatedBy])
	SELECT	[NoteID]
           ,[Note]
           ,[UpdatedDate]
           ,[AffID]
           ,[UpdatedBy]
	FROM	DBAFF12BET.[Affiliate_12BET].[dbo].[AdminNotes] WITH (NOLOCK)
	SET IDENTITY_INSERT [AdminNotes] OFF

	----[AffDomain]
	TRUNCATE TABLE [AffDomain]
	SET IDENTITY_INSERT [AffDomain] ON 
	INSERT INTO [Affiliate_12bet].[dbo].[AffDomain]
           ([DomainID]
           ,[DomainName]
           ,[CreateDate]
           ,[ModifyDate]
           ,[Creator])
	SELECT	[DomainID]
           ,[DomainName]
           ,[CreateDate]
           ,[ModifyDate]
           ,[Creator]
	FROM	DBAFF12BET.[Affiliate_12BET].[dbo].[AffDomain] WITH (NOLOCK) 
	SET IDENTITY_INSERT [AffDomain] OFF 


	----[AffDomainControl]
	TRUNCATE TABLE [AffDomainControl]
	SET IDENTITY_INSERT [AffDomainControl] ON 
	INSERT INTO [Affiliate_12bet].[dbo].[AffDomainControl]
           ([ID]
           ,[AffDomainID]
           ,[12BetDomainID]
           ,[MarketID]
           ,[CreateDate]
           ,[ModifyDate]
           ,[Creator]
           ,[Status])
	SELECT [ID]
           ,[AffDomainID]
           ,[12BetDomainID]
           ,[MarketID]
           ,[CreateDate]
           ,[ModifyDate]
           ,[Creator]
           ,[Status]
	FROM	DBAFF12BET.[Affiliate_12BET].[dbo].[AffDomainControl] WITH (NOLOCK)
	SET IDENTITY_INSERT [AffDomainControl] OFF

	---[AffFunctionInfo]
	TRUNCATE TABLE [AffFunctionInfo]
	SET IDENTITY_INSERT [AffFunctionInfo] ON 
	INSERT INTO [Affiliate_12bet].[dbo].[AffFunctionInfo]
           ([FuncID]
           ,[FuncName]
           ,[FuncNote]
           ,[FuncDesc]
           ,[FuncRender]
           ,[CreateDate]
           ,[ModifyDate]
           ,[DisplayOrder]
           ,[Creator]
           ,[ParentID]
           ,[Filenames]
           ,[System])
	SELECT	[FuncID]
           ,[FuncName]
           ,[FuncNote]
           ,[FuncDesc]
           ,[FuncRender]
           ,[CreateDate]
           ,[ModifyDate]
           ,[DisplayOrder]
           ,[Creator]
           ,[ParentID]
           ,[Filenames]
           ,[System]
	FROM	DBAFF12BET.[Affiliate_12BET].[dbo].[AffFunctionInfo] WITH (NOLOCK)
	SET IDENTITY_INSERT [AffFunctionInfo] OFF

	---[AffGroupInfo]
	TRUNCATE TABLE [AffGroupInfo]
	SET IDENTITY_INSERT [AffGroupInfo] ON 
	INSERT INTO [Affiliate_12bet].[dbo].[AffGroupInfo]
           ([GroupID]
           ,[GroupName]
           ,[GroupDesc]
           ,[CreateDate]
           ,[ModifyDate]
           ,[DisplayOrder]
           ,[Creator]
           ,[System])
	SELECT	[GroupID]
           ,[GroupName]
           ,[GroupDesc]
           ,[CreateDate]
           ,[ModifyDate]
           ,[DisplayOrder]
           ,[Creator]
           ,[System]
	FROM	DBAFF12BET.[Affiliate_12BET].[dbo].[AffGroupInfo] WITH (NOLOCK)
	SET IDENTITY_INSERT [AffGroupInfo] OFF 

	----[Affiliate_User]
	TRUNCATE TABLE [Affiliate_User]
	SET IDENTITY_INSERT [Affiliate_User] ON 
	INSERT INTO [Affiliate_12bet].[dbo].[Affiliate_User]
           ([CustID]
           ,[PageAccess]
           ,[createdate]
           ,[creator]
           ,[GroupID]
           ,[Closed]
           ,[logincount]
           ,[iplogin]
           ,[lastlogged]
           ,[on_sessionid]
           ,[Username]
           ,[UserPwd]
           ,[RoleId]
           ,[PwdExpiry]
           ,[FirstName]
           ,[LastName])
	SELECT	[CustID]
           ,[PageAccess]
           ,[createdate]
           ,[creator]
           ,[GroupID]
           ,[Closed]
           ,[logincount]
           ,[iplogin]
           ,[lastlogged]
           ,[on_sessionid]
           ,[Username]
           ,[UserPwd]
           ,[RoleId]
           ,[PwdExpiry]
           ,[FirstName]
           ,[LastName]
	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[Affiliate_User] WITH (NOLOCK)
	SET IDENTITY_INSERT [Affiliate_User] OFF
	
	----[AffPayout]
	TRUNCATE TABLE [AffPayout]
	SET IDENTITY_INSERT [AffPayout] ON  
	INSERT INTO [Affiliate_12bet].[dbo].[AffPayout]
           ([RefID]
           ,[AffID]
           ,[IBCCustID]
           ,[UserName]
           ,[IBCUserName]
           ,[Amount]
           ,[AffPayout]
           ,[AffCurrency]
           ,[MemberExRate]
           ,[AffExRate]
           ,[MemberCurrency]
           ,[TransDate]
           ,[CompletedDate]
           ,[Status]
           ,[AdminDesc]
           ,[AffDesc])
	SELECT	[RefID]
           ,[AffID]
           ,[IBCCustID]
           ,[UserName]
           ,[IBCUserName]
           ,[Amount]
           ,[AffPayout]
           ,[AffCurrency]
           ,[MemberExRate]
           ,[AffExRate]
           ,[MemberCurrency]
           ,[TransDate]
           ,[CompletedDate]
           ,[Status]
           ,[AdminDesc]
           ,[AffDesc]
	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[AffPayout] WITH (NOLOCK)

	SET IDENTITY_INSERT [AffPayout] OFF

	---[Banners]
	TRUNCATE TABLE [Banners]
	SET IDENTITY_INSERT [Banners] ON 
	INSERT INTO [Affiliate_12bet].[dbo].[Banners]
           ([BannerID]
           ,[FileName]
           ,[Category]
           ,[Language]
           ,[ImageType]
           ,[Size]
           ,[LastUpdate]
           ,[Currency]
           ,[CreatedDate]
           ,[UpdatedBy]
           ,[Creator]
           ,[Message]
           ,[Version]
           ,[Type])
	SELECT	[BannerID]
           ,[FileName]
           ,[Category]
           ,[Language]
           ,[ImageType]
           ,[Size]
           ,[LastUpdate]
           ,[Currency]
           ,[CreatedDate]
           ,[UpdatedBy]
           ,[Creator]
           ,[Message]
           ,[Version]
           ,[Type]
	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[Banners] WITH (NOLOCK)
	SET IDENTITY_INSERT [Banners] OFF

	----[Banners_1]
	TRUNCATE TABLE [Banners_1]
	SET IDENTITY_INSERT [Banners_1] ON 
	INSERT INTO [Affiliate_12bet].[dbo].[Banners_1]
           ([BannerID]
           ,[FileName]
           ,[Category]
           ,[Language]
           ,[ImageType]
           ,[Size]
           ,[LastUpdate]
           ,[Currency]
           ,[CreatedDate]
           ,[UpdatedBy]
           ,[Creator]
           ,[Message]
           ,[Type]
           ,[Version]
           ,[AffType])
	SELECT	[BannerID]
           ,[FileName]
           ,[Category]
           ,[Language]
           ,[ImageType]
           ,[Size]
           ,[LastUpdate]
           ,[Currency]
           ,[CreatedDate]
           ,[UpdatedBy]
           ,[Creator]
           ,[Message]
           ,[Type]
           ,[Version]
           ,[AffType]
	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[Banners_1] WITH (NOLOCK)
	
	SET IDENTITY_INSERT [Banners_1] OFF

	---[EmailHistory]
	TRUNCATE TABLE [EmailHistory]
	SET IDENTITY_INSERT [EmailHistory] ON
	INSERT INTO [Affiliate_12bet].[dbo].[EmailHistory]
           ([MID]
           ,[Content]
           ,[Sender]
           ,[Creator]
           ,[AffId]
           ,[AffName]
           ,[Email]
           ,[Subject]
           ,[CreatedDate]
           ,[IP]
           ,[Browser]
           ,[SessionID])
	SELECT	[MID]
           ,[Content]
           ,[Sender]
           ,[Creator]
           ,[AffId]
           ,[AffName]
           ,[Email]
           ,[Subject]
           ,[CreatedDate]
           ,[IP]
           ,[Browser]
           ,[SessionID]
	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[EmailHistory] WITH (NOLOCK)
	SET IDENTITY_INSERT [EmailHistory] OFF


	---[News]
	TRUNCATE TABLE [News]
	SET IDENTITY_INSERT [News] ON 
	INSERT INTO [Affiliate_12bet].[dbo].[News]
           ([MsgID]
           ,[Message_En]
           ,[Message_Cn]
           ,[Message_Tw]
           ,[Message_Es]
           ,[Message_Th]
           ,[Message_Id]
           ,[Message_Vi]
           ,[Creator]
           ,[PostedDate]
           ,[Important]
           ,[UpdatedBy]
           ,[UpdatedDate]
           ,[Message_Kr]
           ,[Message_Jp])
	SELECT	[MsgID]
           ,[Message_En]
           ,[Message_Cn]
           ,[Message_Tw]
           ,[Message_Es]
           ,[Message_Th]
           ,[Message_Id]
           ,[Message_Vi]
           ,[Creator]
           ,[PostedDate]
           ,[Important]
           ,[UpdatedBy]
           ,[UpdatedDate]
           ,[Message_Kr]
           ,[Message_Jp]
	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[News] WITH (NOLOCK)
	SET IDENTITY_INSERT [News] OFF

	---[TrackingCode]
	TRUNCATE TABLE [TrackingCode]
	SET IDENTITY_INSERT [TrackingCode] ON 
	INSERT INTO [Affiliate_12bet].[dbo].[TrackingCode]
           ([TrackingID]
		   ,[AffID]
           ,[TrackingCode]
           ,[CreatedDate]
           ,[IP])
	SELECT	[TrackingID]
		   ,[AffID]
           ,[TrackingCode]
           ,[CreatedDate]
           ,[IP]
	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[TrackingCode] WITH (NOLOCK)
	SET IDENTITY_INSERT [TrackingCode] OFF


	---END IDENT TABLES


	/***NORMAL TABLES**/
	TRUNCATE TABLE [AdminFavorite]
	INSERT INTO [Affiliate_12bet].[dbo].[AdminFavorite]
           ([AdminID]
           ,[AffID])
	SELECT	[AdminID]
			,[AffID]
	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[AdminFavorite] WITH (NOLOCK)


	---[AffGroupPolicy]
	TRUNCATE TABLE [AffGroupPolicy]
	INSERT INTO [Affiliate_12bet].[dbo].[AffGroupPolicy]
           ([GroupID]
           ,[FuncID]
           ,[Policy]
           ,[CreateDate]
           ,[ModifyDate]
           ,[Creator])
	SELECT	[GroupID]
           ,[FuncID]
           ,[Policy]
           ,[CreateDate]
           ,[ModifyDate]
           ,[Creator]
	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[AffGroupPolicy] WITH (NOLOCK)

	----[AffMemberPolicy]
	TRUNCATE TABLE [AffMemberPolicy]
	INSERT INTO [Affiliate_12bet].[dbo].[AffMemberPolicy]
           ([CustID]
           ,[FuncID]
           ,[Policy]
           ,[CreateDate]
           ,[ModifyDate]
           ,[Creator])
	SELECT	[CustID]
           ,[FuncID]
           ,[Policy]
           ,[CreateDate]
           ,[ModifyDate]
           ,[Creator]
	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[AffMemberPolicy] WITH (NOLOCK)


	----[BannerTypes]
	TRUNCATE TABLE [BannerTypes]
	INSERT INTO [Affiliate_12bet].[dbo].[BannerTypes]
           ([Type]
           ,[Value]
           ,[DisplayOrder])
	SELECT	[Type]
           ,[Value]
           ,[DisplayOrder]
	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[BannerTypes] WITH (NOLOCK)

	----[[BannerTypes_1]]
	TRUNCATE TABLE [BannerTypes_1]
	INSERT INTO [Affiliate_12bet].[dbo].[BannerTypes_1]
           ([Type]
           ,[Value]
           ,[DisplayOrder])
	SELECT	[Type]
           ,[Value]
           ,[DisplayOrder]
	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[BannerTypes_1] WITH (NOLOCK)

	---- [CommGroup]
	TRUNCATE TABLE [CommGroup]
	INSERT INTO [Affiliate_12bet].[dbo].[CommGroup]
           ([GroupID]
           ,[GroupName]
           ,[CreatedDate]
           ,[Creator]
           ,[IsDeleted]
           ,[Description])
	SELECT	[GroupID]
           ,[GroupName]
           ,[CreatedDate]
           ,[Creator]
           ,[IsDeleted]
           ,[Description]
	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[CommGroup] WITH (NOLOCK)

	----[DeductionSetting]
	TRUNCATE TABLE [DeductionSetting]
	INSERT INTO [Affiliate_12bet].[dbo].[DeductionSetting]
           ([GroupID]
           ,[DeductionID]
           ,[DeductedPercentage])
	SELECT	[GroupID]
           ,[DeductionID]
           ,[DeductedPercentage]
	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[DeductionSetting] WITH (NOLOCK)

	----[Exchange]
	TRUNCATE TABLE [Exchange]
	INSERT INTO [Affiliate_12bet].[dbo].[Exchange]
           ([UpdatedTime]
           ,[ExchangeID]
           ,[Currency]
           ,[ActualRate]
           ,[ActualRate2]
           ,[Creator]
           ,[DepositPercent]
           ,[WithdrawalPercent]
           ,[BuyingRate]
           ,[BuyingRate2])
	SELECT	[UpdatedTime]
           ,[ExchangeID]
           ,[Currency]
           ,[ActualRate]
           ,[ActualRate2]
           ,[Creator]
           ,[DepositPercent]
           ,[WithdrawalPercent]
           ,[BuyingRate]
           ,[BuyingRate2]
	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[Exchange] WITH (NOLOCK)

	---[Exchange_Current]
	TRUNCATE TABLE [Exchange_Current]
	INSERT INTO [Affiliate_12bet].[dbo].[Exchange_Current]
           ([ExchangeID]
           ,[Currency]
           ,[ActualRate]
           ,[ActualRate2]
           ,[Creator]
           ,[DepositPercent]
           ,[WithdrawalPercent]
           ,[BuyingRate]
           ,[BuyingRate2])
	SELECT	[ExchangeID]
           ,[Currency]
           ,[ActualRate]
           ,[ActualRate2]
           ,[Creator]
           ,[DepositPercent]
           ,[WithdrawalPercent]
           ,[BuyingRate]
           ,[BuyingRate2]
	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[Exchange_Current] WITH (NOLOCK)

	---[GroupSetting]
	TRUNCATE TABLE [GroupSetting]
	INSERT INTO [Affiliate_12bet].[dbo].[GroupSetting]
           ([GroupID]
           ,[SportType]
           ,[TierID]
           ,[MinAmount]
           ,[MaxAmount]
           ,[MinQM]
           ,[MaxQM]
           ,[Commission])
	SELECT	[GroupID]
           ,[SportType]
           ,[TierID]
           ,[MinAmount]
           ,[MaxAmount]
           ,[MinQM]
           ,[MaxQM]
           ,[Commission]
	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[GroupSetting] WITH (NOLOCK)

	---[MemberDailyRemoved]
	TRUNCATE TABLE [MemberDailyRemoved]
	INSERT INTO [Affiliate_12bet].[dbo].[MemberDailyRemoved]
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
           ,[MemOddsFee])
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
	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[MemberDailyRemoved] WITH (NOLOCK)

	-----[MissedMembers]
	--TRUNCATE TABLE [MissedMembers]
	--INSERT INTO [Affiliate_12bet].[dbo].[MissedMembers]
 --          ([UserName]
 --          ,[CreatedDate])
	--SELECT	[UserName]
 --          ,[CreatedDate]
	--FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[MissedMembers] WITH (NOLOCK) 

	---[Ref]
	TRUNCATE TABLE [Ref]
	INSERT INTO [Affiliate_12bet].[dbo].[Ref]
           ([RefName]
           ,[RefNo])
	SELECT	[RefName]
			,[RefNo]
	FROM	DBAFF12BET.[Affiliate_12bet].[dbo].[Ref] WITH (NOLOCK)


	-- CommGroupHistory, GroupSettingHistory, DeductionSettingHistory, AffGroupHistory
	DECLARE @LastDay SMALLDATETIME	
	IF (DAY(CURRENT_TIMESTAMP)<=5)
	BEGIN	
		Select @LastDay = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE()),0))
		print @LastDay 
		
		DELETE CommGroupHistory WHERE monthdate=@LastDay  
		DELETE GroupSettingHistory WHERE monthdate=@LastDay  
		DELETE DeductionSettingHistory WHERE monthdate=@LastDay  
		DELETE AffGroupHistory WHERE monthdate=@LastDay  

		  
		INSERT INTO CommGroupHistory (GroupID,MonthDate,GroupName,CreatedDate,Creator,IsDeleted,Description)   
		SELECT GroupID,MonthDate,GroupName,CreatedDate,Creator,IsDeleted,[Description]  
		FROM DBAFF12BET.[Affiliate_12bet].[dbo].CommGroupHistory WITH (NOLOCK)
		WHERE monthdate=@LastDay  
		  
		INSERT INTO GroupSettingHistory(GroupID,SportType,TierID,MonthDate,MinAmount,MaxAmount,MinQM,MaxQM,Commission)  
		SELECT GroupID,SportType,TierID,MonthDate,MinAmount,MaxAmount,MinQM,MaxQM,Commission
		FROM DBAFF12BET.[Affiliate_12bet].[dbo].GroupSettingHistory WITH (NOLOCK)
		WHERE monthdate=@LastDay  
		     
		INSERT INTO DeductionSettingHistory(GroupID,MonthDate,DeductionID,DeductedPercentage)  
		SELECT GroupID,MonthDate,DeductionID,DeductedPercentage
		FROM DBAFF12BET.[Affiliate_12bet].[dbo].DeductionSettingHistory WITH (NOLOCK)
		WHERE monthdate=@LastDay  
		  
		INSERT INTO AffGroupHistory(AffID,MonthDate,GroupID)  
		SELECT AffID,MonthDate,GroupID
		FROM DBAFF12BET.[Affiliate_12bet].[dbo].AffGroupHistory WITH (NOLOCK)		
		WHERE monthdate=@LastDay  
	END

END
GO


