USE [bodb_EAS]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYNC_EAS]    Script Date: 01/20/2015 05:54:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYNC_EAS]

AS
/*
	Created by:Jamie
	Date: 2014-06-02
	DB: DBEAS/ bodb_EAS
	Task: Sync EAS (run on STANDBY server ONLY)
		+ [eaFunction]
		+ [eaGroup]
		+ [eaMenu]
		+ [eaUserInfo]
		+ [eaGroupPolicy]
		+ [eaUserPolicy]

*/
BEGIN
	SET NOCOUNT ON 

	/** IDENT TABLES **/
	---[eaFunction]
	TRUNCATE TABLE [eaFunction]
	SET IDENTITY_INSERT [eaFunction] ON 
	INSERT INTO [bodb_EAS].[dbo].[eaFunction]
           ( FuncID
			,FuncName
			,FuncDesc
			,FuncKey
			,ParentID
			,ParentName
			,CreatedDate
			,Creator
			,Modifier
			,ModifiedDate
			,DisplayOrder
			,isTest)
	SELECT	 FuncID
			,FuncName
			,FuncDesc
			,FuncKey
			,ParentID
			,ParentName
			,CreatedDate
			,Creator
			,Modifier
			,ModifiedDate
			,DisplayOrder
			,isTest
	FROM	DBEAS.[bodb_EAS].[dbo].[eaFunction] WITH (NOLOCK)
	SET IDENTITY_INSERT [eaFunction] OFF

	--[eaGroup]
	TRUNCATE TABLE [eaGroup]
	SET IDENTITY_INSERT [eaGroup] ON
	INSERT INTO [bodb_EAS].[dbo].[eaGroup]
           ( GroupID
			,GroupName
			,[Description]
			,CreatedDate
			,Creator)
	SELECT	 GroupID
			,GroupName
			,[Description]
			,CreatedDate
			,Creator
	FROM	DBEAS.[bodb_EAS].[dbo].[eaGroup] WITH (NOLOCK)
	SET IDENTITY_INSERT [eaGroup] OFF

	-- [eaMenu]
	TRUNCATE TABLE [eaMenu]
	SET IDENTITY_INSERT [eaMenu] ON
	INSERT INTO [bodb_EAS].[dbo].[eaMenu]
           (	 [MenuID]
				,[MenuName]
				,[MenuDesc]
				,[Url]
				,[FuncID]
				,[ParentID]
				,[ParentName]
				,[DisplayOrder]
				,[active]
				,[Creator]
				,[CreatedDate]
				,[Modifier]
				,[ModifiedDate]
			)
	SELECT	[MenuID]
			,[MenuName]
			,[MenuDesc]
			,[Url]
			,[FuncID]
			,[ParentID]
			,[ParentName]
			,[DisplayOrder]
			,[active]
			,[Creator]
			,[CreatedDate]
			,[Modifier]
			,[ModifiedDate]
	FROM	DBEAS.[bodb_EAS].[dbo].[eaMenu] WITH (NOLOCK)
	SET IDENTITY_INSERT [eaMenu] OFF
	---

	/** NORMAL TABLES **/

	---- [eaUserInfo]
	TRUNCATE TABLE [eaUserInfo]
	INSERT INTO [bodb_EAS].[dbo].[eaUserInfo]
			(	 [UserID]
				,[GroupID]
				,[enabled]
				,[creator]
				,[createddate])
	SELECT	 [UserID]
			,[GroupID]
			,[enabled]
			,[creator]
			,[createddate]
	FROM	DBEAS.[bodb_EAS].[dbo].[eaUserInfo] WITH (NOLOCK)

	---- eaGroupPolicy
	TRUNCATE TABLE [eaGroupPolicy]
	INSERT INTO [bodb_EAS].[dbo].[eaGroupPolicy]
		(	 [GroupID]
			,[FuncID]
			,[Policy])
	SELECT	 [GroupID]
			,[FuncID]
			,[Policy]
	FROM	DBEAS.[bodb_EAS].[dbo].[eaGroupPolicy] WITH (NOLOCK)
	
	----[eaUserPolicy]
	TRUNCATE TABLE [eaUserPolicy]
	INSERT INTO [bodb_EAS].[dbo].[eaUserPolicy]
		   ( [UserID]
			,[FuncID]
			,[Policy])
	SELECT	 [UserID]
			,[FuncID]
			,[Policy]
	FROM	DBEAS.[bodb_EAS].[dbo].[eaUserPolicy] WITH (NOLOCK)


END 
GO


