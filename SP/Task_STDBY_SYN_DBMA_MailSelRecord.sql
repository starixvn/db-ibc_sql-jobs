USE [bodb_Maintenance]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYN_DBMA_MailSelRecord]    Script Date: 01/27/2015 04:54:43 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYN_DBMA_MailSelRecord]
 @Type				INT		= 0 
,@ctCurrentVersion	BIGINT	= 0 
,@ctLastSyncVersion	BIGINT	= 0
AS
/*
	Created by: Jamie
	Date: 20140602
	Task: Mail sync (RUN ONLY ON PRIMARY SERVER)
	DB: DBMA/bodb_Maintenance 
		+ Mail_Attachment
		+ Mail_Record

	Param's Explanation:
		+ @Type = 1: Mail_Attachment
		+ @Type = 2: Mail_Record

*/
BEGIN
	SET NOCOUNT ON 

	DECLARE	 
			 @ctMinVersionMail_Attachment	BIGINT
			,@ctMinVersionMail_Record		BIGINT

	SELECT   @ctMinVersionMail_Attachment	= 0
			,@ctMinVersionMail_Record		= 0 

	---- Mail_Attachment
	IF @Type = 1 
	BEGIN
		SELECT	 c.SYS_CHANGE_OPERATION 
				,c.[AttachmentID]
				,m.[MailID]
				,m.[FileName]
				,m.[ContentType]
				,m.[Content]
				,m.[InsertDate]
		FROM	CHANGETABLE(CHANGES dbo.Mail_Attachment,@ctLastSyncVersion) AS c
				LEFT JOIN dbo.Mail_Attachment m WITH (NOLOCK) ON c.AttachmentID = m.AttachmentID
		WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersionMail_Attachment AND @ctCurrentVersion 

	END 
	---- Mail_Record
	ELSE IF @Type = 2
	BEGIN
		SELECT	 c.SYS_CHANGE_OPERATION 
				,c.[MailID]
				,m.[AppID]
				,m.[FuncID]
				,m.[MailTo]
				,m.[Title]
				,m.[Subject]
				,m.[Body]
				,m.[MailCc]
				,m.[MailBcc]
				,m.[MailDate]
				,m.[Attachments]
				,m.[CountSend]
				,m.[SentSuccess]
				,m.[sentFail]
				,m.[MailUpdatedDate]
				,m.[IsEncrypt]
		FROM	CHANGETABLE(CHANGES dbo.Mail_Record,@ctLastSyncVersion) AS c
				LEFT JOIN dbo.Mail_Record m WITH (NOLOCK) ON c.MailID = m.MailID
		WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersionMail_Record AND @ctCurrentVersion	
	END 

END 
GO


