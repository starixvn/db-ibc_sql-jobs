USE [bodb_LCC]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYNC_LCC_TableOtherIns]    Script Date: 01/20/2015 23:25:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYNC_LCC_TableOtherIns]

AS
/*
	Created: Jamie
	Date: 20140609
	Task: Sync data from bodb_LCC ( Run on standby db)
*/
BEGIN
	SET NOCOUNT ON 
	DECLARE	 @ServCurrent	SYSNAME
			,@ServRemote	SYSNAME
	
	SELECT	@ServCurrent = @@SERVERNAME
	SELECT	@ServRemote	 = (SELECT * FROM OPENQUERY(DBLCC,'SELECT @@SERVERNAME'))
	
	IF @ServCurrent = @ServRemote RETURN ---- In the same server 

	/***IDENT TABLES***/
	----[BanWord]
	TRUNCATE TABLE [BanWord]
	SET IDENTITY_INSERT [BanWord]  ON 
	INSERT INTO [bodb_LCC].[dbo].[BanWord]
           ([BanWordId]
		   ,[BanWordText]
           ,[UpdateTime]
           ,[DeepChecking]
           ,[Deleted])
	SELECT	 [BanWordId]
			,[BanWordText]
			,[UpdateTime]
			,[DeepChecking]
			,[Deleted]
	FROM	DBLCC.[bodb_LCC].[dbo].[BanWord] WITH (NOLOCK)
	SET IDENTITY_INSERT [BanWord]  OFF

	----ChatMessage
	TRUNCATE TABLE [ChatMessage]
	SET IDENTITY_INSERT [ChatMessage]  ON 
	INSERT INTO [bodb_LCC].[dbo].[ChatMessage]
		(	 [ChatMessageId]
			,[ChatUserId]
			,[Content]
			,[ChatRoomId]
			,[CreateTime]
			,[IsDeleted]
			,[DeletedBy])
	SELECT	 [ChatMessageId]
			,[ChatUserId]
			,[Content]
			,[ChatRoomId]
			,[CreateTime]
			,[IsDeleted]
			,[DeletedBy]
	FROM	DBLCC.[bodb_LCC].[dbo].[ChatMessage] WITH (NOLOCK)	
	SET IDENTITY_INSERT [ChatMessage]  OFF

	----ChatRoom
	TRUNCATE TABLE [ChatRoom]
	SET IDENTITY_INSERT [ChatRoom]  ON 
	INSERT INTO [bodb_LCC].[dbo].[ChatRoom]
		(	 [ChatRoomId]
			,[ChatRoomName]
			,[MatchId]
			,[CreateTime]
			,[WelcomeMessage]
			,[Muted]
			,[Disabled])
	SELECT	 [ChatRoomId]
			,[ChatRoomName]
			,[MatchId]
			,[CreateTime]
			,[WelcomeMessage]
			,[Muted]
			,[Disabled]
	FROM	DBLCC.[bodb_LCC].[dbo].[ChatRoom] WITH (NOLOCK)	
	SET IDENTITY_INSERT [ChatRoom]  OFF

	----ChatUser
	TRUNCATE TABLE [ChatUser]
	SET IDENTITY_INSERT [ChatUser]  ON 
	INSERT INTO [bodb_LCC].[dbo].[ChatUser]
		(	 [ChatUserId]
			,[ChatName]
			,[MemberId]
			,[MemberName]
			,[CreateTime]
			,[ModifiedTime]
			,[IsBanned]
			,[AgreedTerms])
	SELECT	[ChatUserId]
			,[ChatName]
			,[MemberId]
			,[MemberName]
			,[CreateTime]
			,[ModifiedTime]
			,[IsBanned]
			,[AgreedTerms]
	FROM	DBLCC.[bodb_LCC].[dbo].[ChatUser] WITH (NOLOCK)	
	SET IDENTITY_INSERT [ChatUser]  OFF

	----ChatUserInRoom
	TRUNCATE TABLE [ChatUserInRoom]
	SET IDENTITY_INSERT [ChatUserInRoom]  ON 
	INSERT INTO [bodb_LCC].[dbo].[ChatUserInRoom]
		(	 [ChatUserInRoomId]
			,[ChatUserId]
			,[ChatRoomId]
			,[LastOnlineTime]
			,[Isleft]
			,[ConnectionId]
			,[KickedOut]
			,[Muted])
	SELECT	[ChatUserInRoomId]
			,[ChatUserId]
			,[ChatRoomId]
			,[LastOnlineTime]
			,[Isleft]
			,[ConnectionId]
			,[KickedOut]
			,[Muted]
	FROM	DBLCC.[bodb_LCC].[dbo].[ChatUserInRoom] WITH (NOLOCK)	
	SET IDENTITY_INSERT [ChatUserInRoom]  OFF

	----MemberBanned
	TRUNCATE TABLE [MemberBanned]
	SET IDENTITY_INSERT [MemberBanned]  ON 
	INSERT INTO [bodb_LCC].[dbo].[MemberBanned]
		(	 [MemberBannedId]
			,[MemberId]
			,[MemberName]
			,[IsBanned]
			,[UpdateTime])
	SELECT	[MemberBannedId]
			,[MemberId]
			,[MemberName]
			,[IsBanned]
			,[UpdateTime]
	FROM	DBLCC.[bodb_LCC].[dbo].[MemberBanned] WITH (NOLOCK)	
	SET IDENTITY_INSERT [MemberBanned]  OFF

	---ScorePredictionItem
	TRUNCATE TABLE [ScorePredictionItem]
	SET IDENTITY_INSERT [ScorePredictionItem]  ON 
	INSERT INTO [bodb_LCC].[dbo].[ScorePredictionItem]
		(	 [ScorePredictionId]
			,[MemberId]
			,[ScorePredictionOptionId]
			,[ScorePredictionTime]
			,[MatchId]
			,[HomeScore]
			,[AwayScore])
	SELECT	[ScorePredictionId]
			,[MemberId]
			,[ScorePredictionOptionId]
			,[ScorePredictionTime]
			,[MatchId]
			,[HomeScore]
			,[AwayScore]
	FROM	DBLCC.[bodb_LCC].[dbo].[ScorePredictionItem] WITH (NOLOCK)	
	SET IDENTITY_INSERT [ScorePredictionItem]  OFF

	---ScorePredictionOption
	TRUNCATE TABLE [ScorePredictionOption]
	SET IDENTITY_INSERT [ScorePredictionOption]  ON 
	INSERT INTO [bodb_LCC].[dbo].[ScorePredictionOption]
		(	 [ScorePredictionOptionId]
			,[MatchId]
			,[HomeScore]
			,[AwayScore]
			,[ScorePredictionCount]
			,[DummyCount]
			,[UpdateDummyTime]
			,[AdminId]
			,[AdminName])
	SELECT	[ScorePredictionOptionId]
			,[MatchId]
			,[HomeScore]
			,[AwayScore]
			,[ScorePredictionCount]
			,[DummyCount]
			,[UpdateDummyTime]
			,[AdminId]
			,[AdminName]
	FROM	DBLCC.[bodb_LCC].[dbo].[ScorePredictionOption] WITH (NOLOCK)	
	SET IDENTITY_INSERT [ScorePredictionOption]  OFF

	/***NORMAL TABLES***/
	----MatchTimePattern
	TRUNCATE TABLE [MatchTimePattern]
	INSERT INTO [bodb_LCC].[dbo].[MatchTimePattern]
		(	 [Mins]
			,[isLive])
	SELECT	[Mins]
			,[isLive]
	FROM	DBLCC.[bodb_LCC].[dbo].[MatchTimePattern] WITH (NOLOCK)	

END 
GO


