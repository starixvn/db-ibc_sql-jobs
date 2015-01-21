USE [Affiliate_12BET]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYNC_AFF12BET_LOG]    Script Date: 01/20/2015 22:53:23 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYNC_AFF12BET_LOG]

AS
/*
	Created: Jamie
	DB: DBAFF12BET/Affiliate_12BET
	Task: Sync LOG ( Run on standby db)
		+ UserLog_RunSP
		+ [UserLog]

*/
BEGIN
	SET NOCOUNT ON 
	
	DECLARE	 @ServCurrent	SYSNAME
			,@ServRemote	SYSNAME
	
	SELECT	@ServCurrent = @@SERVERNAME
	SELECT	@ServRemote	 = (SELECT * FROM OPENQUERY(DBAFF12BET,'SELECT @@SERVERNAME'))
	
	IF @ServCurrent = @ServRemote RETURN ---- In the same server 

	DECLARE  @max_id BIGINT
			,@startday SMALLDATETIME
			,@logdate DATETIME

	SET @startday = DATEADD(dd, -7, CURRENT_TIMESTAMP)

	---- [UserLog_RunSP]
	SELECT	@max_id		= ISNULL(MAX(LogID),-1)
			,@logdate	= ISNULL(MAX([LoggedDate]),@startday)
	FROM	[dbo].[UserLog_RunSP] WITH (NOLOCK)
	WHERE	[LoggedDate] >= @startday

	IF @max_id <>-1
	BEGIN
		SET IDENTITY_INSERT UserLog_RunSP ON
		INSERT INTO [Affiliate_12BET].[dbo].[UserLog_RunSP]
           ([LogID]
		   ,[AffID]
           ,[Creator]
           ,[SPName]
           ,[Details]
           ,[LoggedDate]
           ,[IsAdmin]
           ,[IP])
		SELECT	[LogID]
			   ,[AffID]
			   ,[Creator]
			   ,[SPName]
			   ,[Details]
			   ,[LoggedDate]
			   ,[IsAdmin]
			   ,[IP]
		FROM	DBAFF12BET.[Affiliate_12BET].[dbo].[UserLog_RunSP] WITH (NOLOCK)
		WHERE	[LoggedDate] >= @startday
				AND LogID > @max_id
		SET IDENTITY_INSERT UserLog_RunSP OFF
	END
	
	
	---- [UserLog]
	SELECT	@logdate	= DATEADD(hh,-2, ISNULL(MAX([LoggedDate]),@startday))	
	FROM	[dbo].[UserLog] WITH (NOLOCK)
	WHERE	[LoggedDate] >= @startday

	IF @@ROWCOUNT<>0
	BEGIN
		DELETE [UserLog] WITH (UPDLOCK, ROWLOCK)
		WHERE [LoggedDate] >= @logdate
				
		INSERT INTO [Affiliate_12BET].[dbo].[UserLog]
           (	[RefNo]
			  ,[TypeID]
			  ,[AffID]
			  ,[Creator]
			  ,[LoggedDate]
			  ,[SPName]
			  ,[Details]
			  ,[IP])
		SELECT	[RefNo]
		  ,[TypeID]
		  ,[AffID]
		  ,[Creator]
		  ,[LoggedDate]
		  ,[SPName]
		  ,[Details]
		  ,[IP]
		FROM	DBAFF12BET.[Affiliate_12BET].[dbo].[UserLog] WITH (NOLOCK)
		WHERE	[LoggedDate] >= @logdate						
	END
END
GO


