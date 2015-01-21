USE [bodb_ConnectionString]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYNC_DBCONN]    Script Date: 01/20/2015 05:55:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYNC_DBCONN]

AS
/*
	Created by: Jamie
	Date: 20140602
	Task: ConnectionString sync (RUN ONLY ON STANDBY SERVER)
	DB: DBCONN/bodb_ConnectionString

*/
BEGIN 
	SET NOCOUNT ON

	/** IDENT TABLES **/
	----Connection
	TRUNCATE TABLE Connection
	SET IDENTITY_INSERT Connection ON 
	INSERT INTO [bodb_ConnectionString].[dbo].[Connection]
			   ([ID]
			   ,[Name]
			   ,[DbServerId]
			   ,[DatabaseId]
			   ,[LoginName]
			   ,[Password]
			   ,[FreeText]
			   ,[IsActive]
			   ,[Creator]
			   ,[CreatedDate]
			   ,[Modifier]
			   ,[ModifiedDate])
	SELECT		[ID]
			   ,[Name]
			   ,[DbServerId]
			   ,[DatabaseId]
			   ,[LoginName]
			   ,[Password]
			   ,[FreeText]
			   ,[IsActive]
			   ,[Creator]
			   ,[CreatedDate]
			   ,[Modifier]
			   ,[ModifiedDate]
	FROM	DBCONN.[bodb_ConnectionString].[dbo].[Connection] WITH (NOLOCK)
	SET IDENTITY_INSERT Connection OFF

	----Database
	TRUNCATE TABLE [Database]
	SET IDENTITY_INSERT [Database] ON 
	INSERT INTO [bodb_ConnectionString].[dbo].[Database]
			(	 [Id]
				,[Name]
				,[DbServerId]
				,[ServerAlias]
				,[CreatorId]
				,[CreatedDate]
				,[ModifierId]
				,[ModifiedDate]
				,[IsActive])
	SELECT		[Id]
				,[Name]
				,[DbServerId]
				,[ServerAlias]
				,[CreatorId]
				,[CreatedDate]
				,[ModifierId]
				,[ModifiedDate]
				,[IsActive]
	FROM	DBCONN.[bodb_ConnectionString].[dbo].[Database] WITH (NOLOCK)
	SET IDENTITY_INSERT [Database] OFF

	----DatabaseServer
	TRUNCATE TABLE [DatabaseServer]
	SET IDENTITY_INSERT [DatabaseServer] ON 
	INSERT INTO [bodb_ConnectionString].[dbo].[DatabaseServer]
			(	 [Id]
				,[Name]
				,[ServerIP]
				,[Description]
				,[IsActive]
				,[Creator]
				,[CreatedDate]
				,[Modifier]
				,[ModifiedDate]
			)
	SELECT		 [Id]
				,[Name]
				,[ServerIP]
				,[Description]
				,[IsActive]
				,[Creator]
				,[CreatedDate]
				,[Modifier]
				,[ModifiedDate]
	FROM	DBCONN.[bodb_ConnectionString].[dbo].[DatabaseServer] WITH (NOLOCK)
	SET IDENTITY_INSERT [DatabaseServer] OFF

	----LogExecSp
	TRUNCATE TABLE [LogExecSp]
	SET IDENTITY_INSERT [LogExecSp] ON 
	INSERT INTO [bodb_ConnectionString].[dbo].[LogExecSp]
			(	 [Id]
				,[UserId]
				,[SPName]
				,[ActionId]
				,[ObjectId]
				,[ObjectTypeId]
				,[LogDate]
				,[Duration]
				,[Data]
				,[OldData] 
			)
	SELECT	 [Id]
			,[UserId]
			,[SPName]
			,[ActionId]
			,[ObjectId]
			,[ObjectTypeId]
			,[LogDate]
			,[Duration]
			,[Data]
			,[OldData]
	FROM	DBCONN.[bodb_ConnectionString].[dbo].[LogExecSp] WITH (NOLOCK)
	SET IDENTITY_INSERT [LogExecSp] OFF

	----Site
	TRUNCATE TABLE [Site]
	SET IDENTITY_INSERT [Site] ON 
	INSERT INTO [bodb_ConnectionString].[dbo].[Site]
			(	 [Id]
				,[Name]
				,[Description]
				,[IsActive]
				,[Creator]
				,[CreatedDate]
				,[Modifier]
				,[ModifiedDate]
			)
	SELECT		 [Id]
				,[Name]
				,[Description]
				,[IsActive]
				,[Creator]
				,[CreatedDate]
				,[Modifier]
				,[ModifiedDate]
	FROM	DBCONN.[bodb_ConnectionString].[dbo].[Site] WITH (NOLOCK)
	SET IDENTITY_INSERT [Site] OFF

	/** NORMAL TABLES **/
	--- [SiteConnection]
	TRUNCATE TABLE [SiteConnection]
	INSERT INTO [bodb_ConnectionString].[dbo].[SiteConnection]
			(	 [SiteId]
				,[ConnectionId])
	SELECT	 [SiteId]
			,[ConnectionId]
	FROM	DBCONN.[bodb_ConnectionString].[dbo].[SiteConnection] WITH (NOLOCK)

	--- [LogAction]
	TRUNCATE TABLE [LogAction]
	INSERT INTO [bodb_ConnectionString].[dbo].[LogAction]
			(	 [ActionId]
				,[ActionTypeId]
				,[SPName]
				,[ActionName]
				,[Items]
				,[SubItems]
				,[IsInternal]
			)
	SELECT	 [ActionId]
			,[ActionTypeId]
			,[SPName]
			,[ActionName]
			,[Items]
			,[SubItems]
			,[IsInternal]
	FROM	DBCONN.[bodb_ConnectionString].[dbo].[LogAction] WITH (NOLOCK)

	--- [LogActionType]
	TRUNCATE TABLE  [LogActionType]
	INSERT INTO [bodb_ConnectionString].[dbo]. [LogActionType]
			(	 [ActionTypeId]
				,[ActionTypeName])
	SELECT	[ActionTypeId]
			,[ActionTypeName]
	FROM	DBCONN.[bodb_ConnectionString].[dbo].[LogActionType] WITH (NOLOCK)
END 
GO


