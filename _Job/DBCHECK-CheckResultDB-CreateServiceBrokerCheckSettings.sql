/*
	Creator:	20180718@Billy
	Task:		Check Setting SB Execution - [Redmine: #00000]
	Server:		DBDWCSS.CheckResultDB
*/


--	BEGIN STEP 1:
--		Message Type definition
----------------------------------------------------------------------------------------------------

USE	CheckResultDB;
GO

CREATE MESSAGE TYPE	CheckSettingMessage
	AUTHORIZATION dbo
	VALIDATION = NONE;
GO


--	BEGIN STEP 2:
--		Initiator Service
----------------------------------------------------------------------------------------------------

USE	CheckResultDB;
GO

CREATE CONTRACT	CheckSettingContract
	AUTHORIZATION dbo (
		CheckSettingMessage		SENT BY INITIATOR
	);

--GRANT REFERENCES ON CONTRACT::CheckSettingContract TO xxx;
GO

CREATE QUEUE	dbo.CheckSettingInitiatorQueue
	ON DATA;

--GRANT RECEIVE ON dbo.CheckSettingInitiatorQueue TO xxx;
GO

CREATE SERVICE	CheckSettingInitiator
	ON QUEUE	dbo.CheckSettingInitiatorQueue (
					CheckSettingContract
				);

--GRANT SEND ON SERVICE::CheckSettingInitiator TO PUBLIC;
GO


--	BEGIN STEP 3:
--		Target Service
----------------------------------------------------------------------------------------------------

USE	CheckResultDB;
GO

CREATE PROCEDURE	dbo.SB_CheckSettingTargetQueueActivator
AS
BEGIN;
	SET NOCOUNT ON;
END;
GO

CREATE QUEUE	dbo.CheckSettingTargetQueue
	WITH	ACTIVATION (
				STATUS				= ON
			,	PROCEDURE_NAME		= dbo.SB_CheckSettingTargetQueueActivator
			,	MAX_QUEUE_READERS	= 15
			,	EXECUTE AS OWNER
			) ON DATA;

--GRANT RECEIVE ON dbo.SB_CheckSettingTargetQueueActivator TO xxx;
GO

CREATE SERVICE	CheckSettingTarget
	ON QUEUE	dbo.CheckSettingTargetQueue (
					CheckSettingContract
				);

--GRANT SEND ON SERVICE::CheckSettingTarget TO PUBLIC;
GO


--	BEGIN STEP x:
--		Cleanup
----------------------------------------------------------------------------------------------------

/*

DROP SERVICE	CheckSettingTarget;
DROP QUEUE		dbo.CheckSettingTargetQueue;
DROP PROCEDURE	dbo.SB_CheckSettingTargetQueueActivator;

DROP SERVICE	CheckSettingInitiator;
DROP QUEUE		dbo.CheckSettingInitiatorQueue;

DROP CONTRACT	CheckSettingContract;

DROP MESSAGE TYPE	CheckSettingMessage;

*/
