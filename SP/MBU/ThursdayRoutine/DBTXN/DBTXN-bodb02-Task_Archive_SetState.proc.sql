SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE [dbo].[task_Archive_SetState]
	@State varchar(50)
AS
/*
	Creator:	yyyymmdd@Unknown
	Task:		Description - [Redmine: #000000]
	Database:	DBTXN.bodb02

	Revisions:
		- yyyymmdd@Unknown:	Initial - [Redmine: #000000]
*/
	UPDATE dbo.SystemSettings WITH (ROWLOCK)
	SET VValue = @State
	WHERE VName = 'Task_Archive_State'
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/