SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	dbo.vnDBA_sp_CheckSetting_Initiator
AS
/*
	Creator:	20180718@Billy
	Task:		Initiate Check Settings - [Redmine: #00000]
	Database:	DBDWCSS.CheckResultDB
	
	Revisions:
		- 20180718@Billy:	Initial - [Redmine: #00000]
		- 20180816@Billy:	Integrate Bet Limit & Stake Level checking - [Redmine: #99249]
		- 20180914@Billy:	Change initiation mechanism by using config table - [Redmine: #101011]
		
	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]
		
*/
BEGIN;
	SET NOCOUNT ON;
	
	DECLARE	@Message			NVARCHAR(MAX)
		,	@Dialog				UNIQUEIDENTIFIER
		,	@Threads			SMALLINT
		,	@Key				NVARCHAR(128)
		,	@ScriptId			INT
		;

	DECLARE	@Scripts	AS TABLE (
							ScriptId	INT
						);

	-- Initiate service variable --
	SELECT	@Key	= N'CheckSettingThreadCount';
	IF	NOT EXISTS (SELECT 1 FROM dbo.vnDBA_Service_Variables WITH (NOLOCK) WHERE VarKey = @Key)
	BEGIN;
		INSERT INTO	dbo.vnDBA_Service_Variables (VarKey, VarValue)
		VALUES	(@Key, 0);
	END;
	ELSE IF	NOT EXISTS (SELECT 1 FROM dbo.vnDBA_Service_Variables WITH (NOLOCK) WHERE VarKey = @Key AND CAST(VarValue AS SMALLINT) = 0)
	BEGIN;
		RAISERROR('Check setting are already run or was interrupted!', 16, 1) WITH NOWAIT;
		RETURN;
	END;

	-- Select running scripts --
	INSERT INTO	@Scripts (ScriptId)
	SELECT	scr.ScriptId
	FROM	dbo.vnDBA_CheckSetting_RunningScripts AS scr WITH (NOLOCK)
	WHERE	scr.VarKey = @Key
		AND	scr.Threads > 0;

	-- Push scripts to execution mechanism --
	WHILE	0 = 0
	BEGIN;
		SELECT	TOP(1)
				@ScriptId = scr.ScriptId
		FROM	@Scripts AS scr;

		IF	@@ROWCOUNT = 0
			BREAK;

		SELECT	@Threads	= scr.Threads
			,	@Message	= REPLACE(scr.Command, N'~~~', scr.VarKey)
		FROM	dbo.vnDBA_CheckSetting_RunningScripts AS scr WITH (NOLOCK)
		WHERE	scr.ScriptId = @ScriptId;

		UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
		SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) + @Threads
		WHERE	VarKey = @Key;
		
		WHILE	@Threads > 0
		BEGIN;
			BEGIN DIALOG CONVERSATION	@Dialog
			FROM SERVICE	CheckSettingInitiator
			TO SERVICE		'CheckSettingTarget'
			ON CONTRACT		CheckSettingContract
			WITH	ENCRYPTION	= OFF
				,	LIFETIME	= 172800
				;

			SEND ON CONVERSATION @Dialog MESSAGE TYPE CheckSettingMessage (@Message);

			END CONVERSATION @Dialog;

			SELECT	@Threads = @Threads - 1;
		END;

		DELETE	@Scripts
		WHERE	ScriptId = @ScriptId;
	END;
END;
GO
/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/