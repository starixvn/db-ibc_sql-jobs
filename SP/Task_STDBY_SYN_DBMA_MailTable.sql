USE [bodb_maintenance]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYN_DBMA_MailTable]    Script Date: 01/20/2015 23:42:27 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYN_DBMA_MailTable]

AS
/*
	Created by: Jamie
	Date: 20140602
	Task: Mail sync (RUN ONLY ON STANDBY SERVER)
	DB: DBMA/bodb_Maintenance 
		+ [Mail_Config]
		+ [Mail_Error]
		+ [Mail_Function]
		+ [Mail_LinkedResource]
		+ [Mail_Setting]

*/
BEGIN
	SET NOCOUNT ON 

	/**IDENT TABLES **/

	----[Mail_Config]
	TRUNCATE TABLE [Mail_Config] 
	SET IDENTITY_INSERT [Mail_Config] ON 
	INSERT INTO [bodb_Maintenance].[dbo].[Mail_Config]
           ( [AppID]
			,[AppName]
			,[Description]
			,[SettingID]
			,[MailFrom]
			,[IsEncrypt])
	SELECT	 [AppID]
			,[AppName]
			,[Description]
			,[SettingID]
			,[MailFrom]
			,[IsEncrypt]
	FROM	DBMA.[bodb_Maintenance].[dbo].[Mail_Config] WITH (NOLOCK)
	SET IDENTITY_INSERT [Mail_Config] OFF 

	----[Mail_Error]
	TRUNCATE TABLE [Mail_Error] 
	SET IDENTITY_INSERT [Mail_Error] ON 
	INSERT INTO [bodb_Maintenance].[dbo].[Mail_Error]
           ( [ErrorID]
			,[MailID]
			,[AppID]
			,[Message]
			,[StackTrace]
			,[SettingName]
			,[ErrorTime])
	SELECT	 [ErrorID]
			,[MailID]
			,[AppID]
			,[Message]
			,[StackTrace]
			,[SettingName]
			,[ErrorTime]
	FROM	DBMA.[bodb_Maintenance].[dbo].[Mail_Error] WITH (NOLOCK)
	SET IDENTITY_INSERT [Mail_Error] OFF 

	----[Mail_Function]
	TRUNCATE TABLE [Mail_Function] 
	SET IDENTITY_INSERT [Mail_Function] ON 
	INSERT INTO [bodb_Maintenance].[dbo].[Mail_Function]
           ( [FuncID]
			,[FuncName]
			,[AppID]
			,[SettingID])
	SELECT	 [FuncID]
			,[FuncName]
			,[AppID]
			,[SettingID]
	FROM	DBMA.[bodb_Maintenance].[dbo].[Mail_Function] WITH (NOLOCK)
	SET IDENTITY_INSERT [Mail_Function] OFF 

	----[Mail_LinkedResource]
	TRUNCATE TABLE [Mail_LinkedResource] 
	SET IDENTITY_INSERT [Mail_LinkedResource] ON 
	INSERT INTO [bodb_Maintenance].[dbo].[Mail_LinkedResource]
           ( [LinkedID]
			,[MailID]
			,[FileName]
			,[ImageType]
			,[ContentCID]
			,[StreamContent]
			,[InsertDate])
	SELECT	 [LinkedID]
			,[MailID]
			,[FileName]
			,[ImageType]
			,[ContentCID]
			,[StreamContent]
			,[InsertDate]
	FROM	DBMA.[bodb_Maintenance].[dbo].[Mail_LinkedResource] WITH (NOLOCK)
	SET IDENTITY_INSERT [Mail_LinkedResource] OFF 

	----[Mail_Setting]
	TRUNCATE TABLE [Mail_Setting] 
	SET IDENTITY_INSERT [Mail_Setting] ON 
	INSERT INTO [bodb_Maintenance].[dbo].[Mail_Setting]
           ( [SettingID]
			,[SettingName]
			,[IsAuth]
			,[Username]
			,[Password]
			,[Server]
			,[Port])
	SELECT	 [SettingID]
			,[SettingName]
			,[IsAuth]
			,[Username]
			,[Password]
			,[Server]
			,[Port]
	FROM	DBMA.[bodb_Maintenance].[dbo].[Mail_Setting] WITH (NOLOCK)
	SET IDENTITY_INSERT [Mail_Setting] OFF 

END
GO


