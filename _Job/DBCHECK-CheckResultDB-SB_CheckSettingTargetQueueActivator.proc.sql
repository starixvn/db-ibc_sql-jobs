SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	dbo.SB_CheckSettingTargetQueueActivator
WITH EXECUTE AS OWNER
AS
/*
	Creator:	20180718@Billy
	Task:		Activator for Check Setting Target Service Queue - [Redmine: #00000]
	Database:	DBDWCSS.StarixDB
	
	Revisions:
		- 20180702@Billy:	Initial - [Redmine: #00000]
		
	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]
		
*/
BEGIN;
	SET NOCOUNT ON;

	
	-- Service Broker variables --
	DECLARE	@dialog				UNIQUEIDENTIFIER
		,	@type				NVARCHAR(256)
		,	@message			NVARCHAR(MAX)
		;

	-- Get message from queue --
	RECEIVE	TOP(1)
			@dialog		= conversation_handle
		,	@type		= message_type_name
		,	@message	= CAST(message_body AS NVARCHAR(MAX))
	FROM	dbo.CheckSettingTargetQueue;
	
	-- Execute new monitoring task --
	IF	@type = N'CheckSettingMessage'
	BEGIN;
		BEGIN TRY
			EXECUTE	sys.sp_executesql @query = @message;
		END TRY
		BEGIN CATCH
			INSERT INTO	dbo.vnDBA_ServiceBroker_CheckSettingFailedLog (LogDate, Msg, ErrorMsg)
			SELECT	GETDATE(), @message, ERROR_MESSAGE();
		END CATCH;
	END;
	
	IF	@type = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
	BEGIN;
		END CONVERSATION @dialog WITH CLEANUP;
	END;
END;
GO

ADD SIGNATURE TO OBJECT::dbo.SB_CheckSettingTargetQueueActivator
BY CERTIFICATE CheckSettingAuthenticationCertificate
WITH PASSWORD = '[{Cr0ssD@t@b@s31e6e1}]';
GO
/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/