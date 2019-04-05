/*
	Creator:	20190405@Billy
	Task:		Description - [Redmine: #000000]
	Server:		DBCHECK.CheckResultDB
*/


USE	CheckResultDB;
GO

CREATE TABLE	dbo.vnDBA_Service_Variables (
					VarKey		NVARCHAR(128)	NOT NULL
				,	VarValue	SQL_VARIANT
				,	CONSTRAINT PK_Service_Variables PRIMARY KEY CLUSTERED (VarKey) ON DATA
				) ON DATA

