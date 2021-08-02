SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
ALTER PROCEDURE [dbo].[Task_Archive_SetState]
	@State varchar(50),
	@VName varchar(50) = 'Task_Archive_Flag_61'
AS
/*
	Creator:	yyyymmdd@Unknown
	Task:		Description - [Redmine: #000000]
	Database:	DBTXN.bodb02

	Revisions:
		- yyyymmdd@Unknown:	Initial - [Redmine: #000000]
		- 20210729@Patrick: Update Job to Support Parlay Range up to 3 Weeks [Redmine: #156498]
*/
BEGIN
	SET NOCOUNT ON
	IF @State = 'Flag'
	BEGIN
		UPDATE dbo.SystemSettings WITH (ROWLOCK)
		SET VValue = '1'
		WHERE VName = @VName

	END
	ELSE IF @State = 'Done'
	BEGIN
		UPDATE dbo.SystemSettings WITH (ROWLOCK)
		SET VValue = '0'
		WHERE VName = @VName

		IF NOT EXISTS (
			SELECT TOP 1 1 
			FROM dbo.SystemSettings 
			WHERE VName IN ('Task_Archive_Flag_61', 'Task_Archive_Flag_06') AND VValue = '1'
		)
		BEGIN
			UPDATE dbo.SystemSettings WITH (ROWLOCK)
			SET VValue = @State
			WHERE VName = 'Task_Archive_State'
		END
	END
	ELSE
	BEGIN
		UPDATE dbo.SystemSettings WITH (ROWLOCK)
		SET VValue = @State
		WHERE VName = 'Task_Archive_State'
	END
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/