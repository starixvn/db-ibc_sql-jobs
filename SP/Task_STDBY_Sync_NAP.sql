USE [bodb_NAP]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_Sync_NAP]    Script Date: 01/20/2015 05:50:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_Sync_NAP]
AS 
/*
	Created: Jamie
	Task: Sync data from DBNAP ( Run on standby db)
	DB:
	
	Revision:
		- 20140827@Lukas: add more table [UserMarkedMenus]
*/
BEGIN
	SET NOCOUNT ON 
	DECLARE	 @ServCurrent	SYSNAME
			,@ServRemote	SYSNAME
	
	SELECT	@ServCurrent = @@SERVERNAME
	SELECT	@ServRemote	 = (SELECT * FROM OPENQUERY(DBNAP,'SELECT @@SERVERNAME'))
	
	IF @ServCurrent = @ServRemote RETURN ---- In the same server 

	-- IDENT Tables 
	TRUNCATE TABLE [Functions]
	SET IDENTITY_INSERT [Functions] ON 
	INSERT INTO [bodb_NAP].[dbo].[Functions]
			   ([FunctionId]
			   ,[SiteId]
			   ,[FunctionName]
			   ,[FunctionKey]
			   ,[Description]
			   ,[ParentId]
			   ,[ParentName]
			   ,[CRUD]
			   ,[DisplayOrder]
			   ,[IsActive]
			   ,[CreatedBy]
			   ,[CreatedDate]
			   ,[ModifiedBy]
			   ,[ModifiedDate]
			   ,[Environment])
	SELECT		[FunctionId]
			   ,[SiteId]
			   ,[FunctionName]
			   ,[FunctionKey]
			   ,[Description]
			   ,[ParentId]
			   ,[ParentName]
			   ,[CRUD]
			   ,[DisplayOrder]
			   ,[IsActive]
			   ,[CreatedBy]
			   ,[CreatedDate]
			   ,[ModifiedBy]
			   ,[ModifiedDate]
			   ,[Environment]
	FROM	DBNAP.bodb_NAP.dbo.[Functions] WITH (NOLOCK)
	SET IDENTITY_INSERT [Functions] OFF 
	--END: [Functions]

	/* START:[Groups] */
	TRUNCATE TABLE [Groups]
	SET IDENTITY_INSERT [Groups] ON 
	INSERT INTO [bodb_NAP].[dbo].[Groups]
           ([GroupId]
		   ,[GroupName]
           ,[Description]
           ,[IsActive]
           ,[CreatedBy]
           ,[CreatedDate]
           ,[ModifiedBy]
           ,[ModifiedDate])
	SELECT	[GroupId]
		   ,[GroupName]
           ,[Description]
           ,[IsActive]
           ,[CreatedBy]
           ,[CreatedDate]
           ,[ModifiedBy]
           ,[ModifiedDate]
	FROM	DBNAP.bodb_NAP.dbo.[Groups] WITH (NOLOCK)
	SET IDENTITY_INSERT [Groups] OFF 
	--END: [Groups]

	/*START: [MenuItems] */
	TRUNCATE TABLE [MenuItems]
	SET IDENTITY_INSERT [MenuItems] ON 
	INSERT INTO [bodb_NAP].[dbo].[MenuItems]
           ([MenuItemId]
		   ,[FunctionId]
           ,[SiteId]
           ,[MenuItemName]
           ,[Description]
           ,[ParentId]
           ,[ParentName]
           ,[Policy]
           ,[URL]
           ,[DisplayOrder]
           ,[IsActive]
           ,[CreatedBy]
           ,[CreatedDate]
           ,[ModifiedBy]
           ,[ModifiedDate]
           ,[Environment])
	SELECT	[MenuItemId]
		   ,[FunctionId]
           ,[SiteId]
           ,[MenuItemName]
           ,[Description]
           ,[ParentId]
           ,[ParentName]
           ,[Policy]
           ,[URL]
           ,[DisplayOrder]
           ,[IsActive]
           ,[CreatedBy]
           ,[CreatedDate]
           ,[ModifiedBy]
           ,[ModifiedDate]
           ,[Environment]
	FROM	DBNAP.bodb_NAP.dbo.[MenuItems] WITH (NOLOCK)
	SET IDENTITY_INSERT [MenuItems] OFF 
	-- END: [MenuItems]

	--START: Sites 
	TRUNCATE TABLE [Sites]
	SET IDENTITY_INSERT [Sites] ON 
	INSERT INTO [bodb_NAP].[dbo].[Sites]
           ([SiteId]
		   ,[SiteName]
           ,[Description]
           ,[URL]
           ,[TestURL]
           ,[IsActive]
           ,[Environment])
	SELECT	[SiteId]
		   ,[SiteName]
           ,[Description]
           ,[URL]
           ,[TestURL]
           ,[IsActive]
           ,[Environment]
	FROM	DBNAP.bodb_NAP.dbo.[Sites] WITH (NOLOCK)
	SET IDENTITY_INSERT [Sites] OFF 
	-- END: [Sites]

	--START: [SiteURL]
	TRUNCATE TABLE [SiteURL]
	SET IDENTITY_INSERT [SiteURL] ON 
	INSERT INTO [bodb_NAP].[dbo].[SiteURL]
           ([SiteURLId]
		   ,[SiteId]
           ,[URL]
           ,[Environment]
           ,[IsDefault]
           ,[IsActive])
	SELECT	[SiteURLId]
		   ,[SiteId]
           ,[URL]
           ,[Environment]
           ,[IsDefault]
           ,[IsActive]
	FROM	DBNAP.bodb_NAP.dbo.[SiteURL] WITH (NOLOCK)
	SET IDENTITY_INSERT [SiteURL] OFF 
	-- END: [[SiteURL]]

	/***** NORMAL TABLES  ***/
	-- START: [GroupFunction]
	TRUNCATE TABLE [GroupFunction]
	INSERT INTO [bodb_NAP].[dbo].[GroupFunction]
				([GroupId]
				,[FunctionId]
				,[SiteId]
				,[Policy]
				,[CreatedBy]
				,[CreatedDate]
				,[ModifiedBy]
				,[ModifiedDate])
	SELECT	 [GroupId]
			,[FunctionId]
			,[SiteId]
			,[Policy]
			,[CreatedBy]
			,[CreatedDate]
			,[ModifiedBy]
			,[ModifiedDate]
	FROM	DBNAP.bodb_NAP.dbo.[GroupFunction] WITH (NOLOCK)
	-- END:[GroupFunction]

	-- START: [ObjectType]
	TRUNCATE TABLE [ObjectType]
	INSERT INTO [bodb_NAP].[dbo].[ObjectType]
           ([ObjectTypeId]
           ,[ObjectTypeName])
	SELECT	[ObjectTypeId]
           ,[ObjectTypeName]
	FROM	DBNAP.bodb_NAP.dbo.[ObjectType] WITH (NOLOCK)
	-- END:[ObjectType]

	-- START: [UserFunction]
	TRUNCATE TABLE [UserFunction]
	INSERT INTO [bodb_NAP].[dbo].[UserFunction]
           ([UserId]
           ,[FunctionId]
           ,[SiteId]
           ,[Policy]
           ,[CreatedBy]
           ,[CreatedDate]
           ,[ModifiedBy]
           ,[ModifiedDate])
	SELECT	[UserId]
           ,[FunctionId]
           ,[SiteId]
           ,[Policy]
           ,[CreatedBy]
           ,[CreatedDate]
           ,[ModifiedBy]
           ,[ModifiedDate]
	FROM	DBNAP.bodb_NAP.dbo.[UserFunction] WITH (NOLOCK)
	-- END:[UserFunction]

	-- START:[Users]
	TRUNCATE TABLE [Users]
	INSERT INTO [bodb_NAP].[dbo].[Users]
           ([UserId]
           ,[GroupId]
           ,[LastLoginDate]
           ,[CreatedBy]
           ,[CreatedDate]
           ,[ModifiedBy]
           ,[ModifiedDate])
	SELECT	[UserId]
           ,[GroupId]
           ,[LastLoginDate]
           ,[CreatedBy]
           ,[CreatedDate]
           ,[ModifiedBy]
           ,[ModifiedDate]
	FROM	DBNAP.bodb_NAP.dbo.[Users] WITH (NOLOCK)
	-- END:[Users]

	--START: [UserSite]
	TRUNCATE TABLE [UserSite] 
	INSERT INTO [bodb_NAP].[dbo].[UserSite]
           ([UserId]
           ,[SiteId]
           ,[Level]
           ,[IsActive]
           ,[LastLoginDate]
           ,[CreatedBy]
           ,[CreatedDate]
           ,[ModifiedBy]
           ,[ModifiedDate])
	SELECT	[UserId]
           ,[SiteId]
           ,[Level]
           ,[IsActive]
           ,[LastLoginDate]
           ,[CreatedBy]
           ,[CreatedDate]
           ,[ModifiedBy]
           ,[ModifiedDate]
	FROM	DBNAP.bodb_NAP.dbo.[UserSite] WITH (NOLOCK)
	-- END:[UserSite]

	-- UserMarkedMenus
	TRUNCATE TABLE [UserMarkedMenus]
	INSERT INTO [bodb_NAP].[dbo].[UserMarkedMenus]
		( [UserId]
		  ,[MenuItemId]
		  ,[IsMarked]
		  ,[CreatedBy]
		  ,[CreatedDate]
		  ,[ModifiedBy]
		  ,[ModifiedDate]
      )
	SELECT [UserId]
      ,[MenuItemId]
      ,[IsMarked]
      ,[CreatedBy]
      ,[CreatedDate]
      ,[ModifiedBy]
      ,[ModifiedDate]
	FROM [DBNAP].[bodb_NAP].[dbo].[UserMarkedMenus] WITH(NOLOCK)
	
END
GO


