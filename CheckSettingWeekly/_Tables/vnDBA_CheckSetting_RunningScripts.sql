/*
	Creator:	20180914@Billy
	Task:		Config table for checking scripts - [Redmine: #101011]
	Server:		DB215
*/

USE	CheckResultDB;
GO

CREATE TABLE	dbo.vnDBA_CheckSetting_RunningScripts (
					ScriptId		INT				NOT NULL		IDENTITY(1, 1)
						CONSTRAINT	PK_CheckSetting_RunningScripts PRIMARY KEY CLUSTERED ON DATA
				,	ScriptName		NVARCHAR(128)	NOT NULL
						CONSTRAINT	UQ_CheckSetting_RunningScripts UNIQUE
				,	VarKey			NVARCHAR(128)	NOT NULL
				,	Threads			TINYINT			NOT NULL
						CONSTRAINT	DF_CheckSetting_RunningScripts_Threads DEFAULT (1)
				,	Command			NVARCHAR(MAX)	NULL
				);

CREATE NONCLUSTERED INDEX	IX_CheckSetting_RunningScripts_VarKey ON dbo.vnDBA_CheckSetting_RunningScripts (
								VarKey		ASC
							,	ScriptId	ASC
							) ON DATA;