USE [bodb_NAPLOG]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_Sync_NAPLOG]    Script Date: 01/20/2015 05:50:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_Sync_NAPLOG]
AS 
/*
	Created: Jamie
	DB: DBNAPLOG/bodb_NAPLOG
	Task: Sync data from DBNAPLOG ( Run on standby db)
*/
BEGIN
	SET NOCOUNT ON 
	
	DECLARE	 @ServCurrent	SYSNAME
			,@ServRemote	SYSNAME
	
	SELECT	@ServCurrent = @@SERVERNAME
	SELECT	@ServRemote	 = (SELECT * FROM OPENQUERY(DBNAPLOG,'SELECT @@SERVERNAME'))
	
	IF @ServCurrent = @ServRemote RETURN ---- In the same server 

	DECLARE  @max_id BIGINT
			,@startday SMALLDATETIME
			,@logdate DATETIME

	SET @startday = DATEADD(dd, -7, CURRENT_TIMESTAMP)

	---- [NAPLog_UserLogin]
	SELECT	@max_id		= ISNULL(MAX(ID),-1)
			,@logdate	= ISNULL(MAX(LogDate),@startday)
	FROM	[dbo].[NAPLog_UserLogin] WITH (NOLOCK)
	WHERE	LogDate >= @startday

	IF @max_id <>-1 
	BEGIN
		SET IDENTITY_INSERT [NAPLog_UserLogin] ON 
		INSERT INTO [bodb_NAPLOG].[dbo].[NAPLog_UserLogin]
				   ([ID]
				   ,[UserId]
				   ,[SiteId]
				   ,[IP]
				   ,[LogDate]
				   ,[Doing]
				   ,[DomainName]
				   ,[BrowserName]
				   ,[Platform]
				   ,[CountryCode]
				   ,[Duration])
		SELECT	 [Id]
				,[UserId]
				,[SiteId]
				,[IP]
				,[LogDate]
				,[Doing]
				,[DomainName]
				,[BrowserName]
				,[Platform]
				,[CountryCode]
				,[Duration]
		FROM	DBNAPLOG.[bodb_NAPLOG].[dbo].[NAPLog_UserLogin] WITH (NOLOCK)
		WHERE	ID > @max_id
				AND LogDate >=@logdate

		SET IDENTITY_INSERT [NAPLog_UserLogin] OFF 
	END 

	---- [NAPLog_RUNSP]
	SELECT	@max_id		= ISNULL(MAX(ID),-1)
			,@logdate	= ISNULL(MAX(LogDate),@startday)
	FROM	[dbo].[NAPLog_RUNSP] WITH (NOLOCK)
	WHERE	LogDate >= @startday

	DECLARE	@tmpIDs TABLE( ID BIGINT)

	IF @max_id <>-1
	BEGIN
		SET IDENTITY_INSERT [NAPLog_RUNSP] ON 
		INSERT INTO [bodb_NAPLOG].[dbo].[NAPLog_RUNSP]
				   ([Id]
				   ,[UserId]
				   ,[SPName]
				   ,[ActionId]
				   ,[ObjectId]
				   ,[ObjectTypeId]
				   ,[langID]
				   ,[siteID]
				   ,[IP]
				   ,[LogDate]
				   ,[Duration])		
		OUTPUT	inserted.ID INTO @tmpIDs
		SELECT   [Id]
				,[UserId]
				,[SPName]
				,[ActionId]
				,[ObjectId]
				,[ObjectTypeId]
				,[langID]
				,[siteID]
				,[IP]
				,[LogDate]
				,[Duration]
		FROM	DBNAPLOG.[bodb_NAPLOG].[dbo].[NAPLog_RUNSP] WITH (NOLOCK) 
		WHERE	ID > @max_id
				AND LogDate >=@logdate

		SET IDENTITY_INSERT [NAPLog_RUNSP] OFF

		INSERT INTO [bodb_NAPLOG].[dbo].[NAPLOG_RUNSP_Detail]
           ([ID]
           ,[ActionID]
           ,[Data]
           ,[OldData])
		SELECT	[ID]
			   ,[ActionID]
			   ,[Data]
			   ,[OldData]
		FROM	DBNAPLOG.[bodb_NAPLOG].[dbo].[NAPLOG_RUNSP_Detail] WITH (NOLOCK)
		WHERE	ID IN (SELECT ID FROM @tmpIDs)
	END

END
GO


