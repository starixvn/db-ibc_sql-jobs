/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Bet_ExecRep_09]
	@mode TINYINT = 0
AS

/*
	Created: 20180329@Percy
	DB: DBTXN.bodb02
	Task: Turn on/off MBBU process for bet execRep

	Revisions:
		- 20180329@Percy: Initialize SP [RedmineID: #92391]

	Param's Explanation:
		@mode:
			3: MB on
			4: MB off
			5: BU on
			6: BU off
*/
BEGIN
	IF EXISTS (
		SELECT TOP 1 1 
		FROM dbo.sysobjects WHERE name = 'SystemSettings'
	)
	BEGIN
		DECLARE @flag TINYINT, @VName VARCHAR(200)

		SELECT @VName = CASE WHEN @mode IN (3,4) THEN 'isMovingBet_Local' WHEN @mode IN (5,6) THEN 'isArchivingBet_Local' END

		SELECT @flag = CONVERT(TINYINT, VValue)
		FROM dbo.SystemSettings WITH (NOLOCK)
		WHERE VName = @VName
			
		--//@mode = 3,5: turn on flag --> input start time, @mode = 4,6: turn off flag --> input end time
		IF @mode IN (3,5)
		BEGIN
			IF @flag = 0
			BEGIN
				UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
				SET VValue = CONVERT(VARCHAR(200), GETDATE(), 121)
				WHERE VName = 'StartMoving_Local'
			END

			SELECT @flag = @flag + 1

			UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
			SET VValue = CONVERT(VARCHAR(200), @flag)
			WHERE VName = @VName
		END
		ELSE IF @mode IN (4,6)
		BEGIN
			IF @flag = 1
			BEGIN
				UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
				SET VValue = CONVERT(VARCHAR(200), GETDATE(), 121)
				WHERE VName = 'EndMoving_Local'
			END

			SELECT @flag = @flag - 1

			UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
			SET VValue = CONVERT(VARCHAR(200), @flag)
			WHERE VName = @VName
		END
	END
END
GO