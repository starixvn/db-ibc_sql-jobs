/*<info serverAlias="DBEXT-bodb02,DBAGE-bodb02,DBACC-bodb02" executers="vnteam" viewers="" isFunction="0" isNested="1"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Task_MoveBets_Status]
	@StatusID TINYINT = 0 OUTPUT
AS

/*
	Created by 20180305@Percy
    Task: MB has done yet?
    DB: DBEXT.bodb02, DBAGE.bodb02, DBACC.bodb02

	Revisions:
		- 20180305@Percy: Initialize SP [RedmineID: #83787]
	
	Parameters Explanations:
		@StatusID = NULL --> this day not have MB
		@StatusID = 0 --> MB has commpleted
		@StatusID = 1 --> MB has not commpleted yet (is running)
		@StatusID = 2 --> MB does not start yet

*/

BEGIN
	SET @StatusID = 1

	DECLARE @MoveBetSchedule TABLE (ScheduleId TINYINT, MoveBetsDay DATE)
	INSERT INTO @MoveBetSchedule (ScheduleId, MoveBetsDay)
	EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel
	
	-- Not have MB
	IF NOT EXISTS (SELECT 1 FROM @MoveBetSchedule)
	BEGIN
		SET @StatusID = NULL

		RETURN
	END
	ELSE
	BEGIN
		-- MB is running
		IF EXISTS (
			SELECT TOP 1 1 FROM dbo.SystemSettings WITH(NOLOCK)
			WHERE VName = 'isMovingBet_Local' AND VValue <> '0'
		)
		BEGIN
			SET @StatusID = 1

			RETURN
		END

		-- MB has completed
		IF EXISTS (
			SELECT TOP 1 1 FROM @MoveBetSchedule 
			WHERE MoveBetsDay IN (SELECT MAX(winlostdate) FROM dbo.bettrans14 WITH(NOLOCK))
		)
		AND EXISTS (
			SELECT TOP 1 1 FROM dbo.SystemSettings WITH(NOLOCK)
			WHERE VName = 'isMovingBet_Local' AND VValue = '0'
		)
		BEGIN
			SET @StatusID = 0

			RETURN
		END

		-- MB does not start yet
		SET @StatusID = 2
	END
END
GO