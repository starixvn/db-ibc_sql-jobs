/*<info serverAlias="DBEXT-bodb02,DBAGE-bodb02,DBACC-bodb02" executers="vnteam" viewers="" isFunction="0" isNested="1"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Task_MoveBets_Status]
	@StatusID TINYINT = 0 OUTPUT

/*
	Created by 20180305@Percy
    Task: MB has done yet?
    DB: DBEXT.bodb02, DBAGE.bodb02, DBACC.bodb02

	Revisions:
		- 20180305@Percy: Initialize SP [RedmineID: #83787]
	
	Parameters Explanations:
		@StatusID = 0 --> this day not have MB
		@StatusID = 1 --> MB has not commpleted yet (running)
		@StatusID = 2 --> MB has commpleted

*/

AS
BEGIN
	SET @StatusID = 1

	DECLARE @MoveBetSchedule TABLE (ScheduleId TINYINT, MoveBetsDay DATE)
	INSERT INTO @MoveBetSchedule (ScheduleId, MoveBetsDay)
	EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel
	 
	IF EXISTS (
		SELECT TOP 1 1 FROM @MoveBetSchedule
	)
	BEGIN
		IF EXISTS (
			SELECT TOP 1 1 FROM dbo.SystemSettings WITH(NOLOCK)
			WHERE VName = 'isMovingBet_Local' AND VValue = '1'
		)
		BEGIN
			SET @StatusID = 1

			RETURN
		END

		IF EXISTS (
			SELECT TOP 1 1 FROM @MoveBetSchedule 
			WHERE MoveBetsDay IN (SELECT MAX(winlostdate) FROM dbo.bettrans14 WITH(NOLOCK))
		)
		AND EXISTS (
			SELECT TOP 1 1 FROM dbo.SystemSettings WITH(NOLOCK)
			WHERE VName = 'isMovingBet_Local' AND VValue = '0'
		)
		BEGIN
			SET @StatusID = 2

			RETURN
		END
	END

	SET @StatusID = 0
END
GO