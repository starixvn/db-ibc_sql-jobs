USE [bodb_maintenance]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYN_DBMA_MailInsRecord]    Script Date: 01/20/2015 23:42:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYN_DBMA_MailInsRecord]
AS
/*
	Created by: Jamie
	Date: 20140602
	Task: Mail sync (RUN ONLY ON STANDBY SERVER)
	DB: DBMA/bodb_Maintenance 
		+ Mail_Attachment
		+ Mail_Record

	Param's Explanation:
		+ @Type = 1: Mail_Attachment
		+ @Type = 2: Mail_Record

*/
BEGIN
	SET NOCOUNT ON 
	DECLARE	 @ctCurrentVersion			BIGINT
			,@ctLastSyncVersion			BIGINT
			,@Type						INT 

	EXEC DBMA.bodb_Maintenance.dbo.[Task_STDBY_SYNC_DBMA_currentVersion] @ctCurrentVersion = @ctCurrentVersion OUTPUT 

	PRINT @ctCurrentVersion 

	SELECT	@ctLastSyncVersion = LastSyncVersion
	FROM	DBMA.bodb_Maintenance.dbo.maCTLastSyncVersion WITH (NOLOCK)
	WHERE	CTID = 1 

	PRINT @ctLastSyncVersion

	IF	@ctLastSyncVersion >= @ctCurrentVersion RETURN	-- No changes 

	
	--- Mail_Attachment = 1
	CREATE TABLE #tmpMail_Attachment(
			ChangedOperation NVARCHAR(1),
			[AttachmentID] [int] NOT NULL,
			[MailID] [bigint] NOT NULL,
			[FileName] [nvarchar](250) NOT NULL,
			[ContentType] [nvarchar](100) NOT NULL,
			[Content] [image] NOT NULL,
			[InsertDate] [datetime] NULL
			)
	INSERT INTO #tmpMail_Attachment(
		 ChangedOperation
		,[AttachmentID]
		,[MailID]
		,[FileName]
		,[ContentType]
		,[Content]
		,[InsertDate]
	)
	EXEC DBMA.bodb_Maintenance.dbo.[Task_STDBY_SYN_DBMA_MailSelRecord] @Type = 1 ,@ctCurrentVersion = @ctCurrentVersion ,@ctLastSyncVersion = @ctLastSyncVersion
	IF @@ROWCOUNT<>0
	BEGIN
		SET IDENTITY_INSERT Mail_Attachment ON
		MERGE	Mail_Attachment AS TARGET 
		USING	#tmpMail_Attachment AS SOURCE ON ( TARGET.AttachmentID = SOURCE.AttachmentID)
		WHEN MATCHED AND SOURCE.ChangedOperation IN('U','I') THEN
			UPDATE SET 
				 TARGET.MailID= SOURCE.MailID
				,TARGET.FileName= SOURCE.FileName
				,TARGET.ContentType= SOURCE.ContentType
				,TARGET.Content= SOURCE.Content
				,TARGET.InsertDate= SOURCE.InsertDate
		WHEN MATCHED AND SOURCE.ChangedOperation IN('D') THEN 
			DELETE
		WHEN NOT MATCHED BY TARGET AND SOURCE.ChangedOperation IN('I') THEN 
			INSERT(
				 [AttachmentID]
				,[MailID]
				,[FileName]
				,[ContentType]
				,[Content]
				,[InsertDate]
			)
			VALUES(
			 SOURCE.[AttachmentID]
			,SOURCE.[MailID]
			,SOURCE.[FileName]
			,SOURCE.[ContentType]
			,SOURCE.[Content]
			,SOURCE.[InsertDate]
			);
		SET IDENTITY_INSERT Mail_Attachment OFF
	END

	--- Mail_Record = 2 
	CREATE TABLE #tmpMail_Record(
		ChangedOperation NVARCHAR(1),
		[MailID] [bigint] NOT NULL,
		[AppID] [int] NOT NULL,
		[FuncID] [int] NOT NULL,
		[MailTo] [nvarchar](500) NULL,
		[Title] [nvarchar](250) NOT NULL,
		[Subject] [nvarchar](250) NOT NULL,
		[Body] [ntext] NOT NULL,
		[MailCc] [nvarchar](500) NULL,
		[MailBcc] [nvarchar](500) NULL,
		[MailDate] [datetime] NULL,
		[Attachments] [nvarchar](250) NULL,
		[CountSend] [int] NULL,
		[SentSuccess] [int] NULL,
		[sentFail] [int] NULL,
		[MailUpdatedDate] [datetime] NULL,
		[IsEncrypt] [bit] NULL)
	INSERT INTO #tmpMail_Record(
		 ChangedOperation
		,[MailID]
		,[AppID]
		,[FuncID]
		,[MailTo]
		,[Title]
		,[Subject]
		,[Body]
		,[MailCc]
		,[MailBcc]
		,[MailDate]
		,[Attachments]
		,[CountSend]
		,[SentSuccess]
		,[sentFail]
		,[MailUpdatedDate]
		,[IsEncrypt]	
	)
	EXEC DBMA.bodb_Maintenance.dbo.[Task_STDBY_SYN_DBMA_MailSelRecord] @Type = 2 ,@ctCurrentVersion = @ctCurrentVersion ,@ctLastSyncVersion = @ctLastSyncVersion
	IF @@ROWCOUNT<>0
	BEGIN
		SET IDENTITY_INSERT Mail_Record ON
		MERGE	Mail_Record AS TARGET 
		USING	#tmpMail_Record AS SOURCE ON ( TARGET.MailID = SOURCE.MailID)
		WHEN MATCHED AND SOURCE.ChangedOperation IN('U','I') THEN
			UPDATE SET 
				 TARGET.AppID= SOURCE.AppID
				,TARGET.FuncID= SOURCE.FuncID
				,TARGET.MailTo= SOURCE.MailTo
				,TARGET.Title= SOURCE.Title
				,TARGET.[Subject]= SOURCE.[Subject]
				,TARGET.Body= SOURCE.Body
				,TARGET.MailCc= SOURCE.MailCc
				,TARGET.MailBcc= SOURCE.MailBcc
				,TARGET.MailDate= SOURCE.MailDate
				,TARGET.Attachments= SOURCE.Attachments
				,TARGET.CountSend= SOURCE.CountSend
				,TARGET.SentSuccess= SOURCE.SentSuccess
				,TARGET.sentFail= SOURCE.sentFail
				,TARGET.MailUpdatedDate= SOURCE.MailUpdatedDate
				,TARGET.IsEncrypt= SOURCE.IsEncrypt		
		WHEN MATCHED AND SOURCE.ChangedOperation IN('D') THEN 
			DELETE		
		WHEN NOT MATCHED BY TARGET AND SOURCE.ChangedOperation IN('I') THEN
			INSERT(
				 [MailID]
				,[AppID]
				,[FuncID]
				,[MailTo]
				,[Title]
				,[Subject]
				,[Body]
				,[MailCc]
				,[MailBcc]
				,[MailDate]
				,[Attachments]
				,[CountSend]
				,[SentSuccess]
				,[sentFail]
				,[MailUpdatedDate]
				,[IsEncrypt]			
			)
			VALUES(
				 SOURCE.[MailID]
				,SOURCE.[AppID]
				,SOURCE.[FuncID]
				,SOURCE.[MailTo]
				,SOURCE.[Title]
				,SOURCE.[Subject]
				,SOURCE.[Body]
				,SOURCE.[MailCc]
				,SOURCE.[MailBcc]
				,SOURCE.[MailDate]
				,SOURCE.[Attachments]
				,SOURCE.[CountSend]
				,SOURCE.[SentSuccess]
				,SOURCE.[sentFail]
				,SOURCE.[MailUpdatedDate]
				,SOURCE.[IsEncrypt]			
			);
		SET IDENTITY_INSERT Mail_Record OFF
	END

	UPDATE	DBMA.bodb_Maintenance.dbo.maCTLastSyncVersion WITH (UPDLOCK,ROWLOCK)
	SET		 LastSyncVersion = @ctCurrentVersion 
			,ExtractionDate	= GETDATE()
	WHERE	CTID = 1
	
	PRINT  @ctCurrentVersion

	DROP TABLE #tmpMail_Attachment
	DROP TABLE #tmpMail_Record
END 


GO


