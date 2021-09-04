/*<info serverAlias="DBEXT-bodb02,DBAGE-bodb02,DBACC-bodb02,DBBAL-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Task_MoveBets_Status_Job]
AS

/*
	Created by 20180305@Percy
    Task: MB has done yet?
    DB: DBEXT.bodb02, DBAGE.bodb02, DBACC.bodb02, DBBAL-bodb02

	Revisions:
		- 20180305@Percy: Initialize SP [RedmineID: #83787]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MBStatusID TINYINT = 0

	EXEC dbo.Task_MoveBets_Status @StatusID = @MBStatusID OUTPUT

	-- MB does not start yet or is running --> loop 15 minutes
	IF ISNULL(@MBStatusID, 0) <> 0
	BEGIN
		RAISERROR('* LOOP * Move bets is processing. Automatically retry after 15mins.', 16, 1)
		RETURN
	END
END
GO