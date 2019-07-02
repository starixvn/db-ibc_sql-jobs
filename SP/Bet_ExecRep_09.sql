/*<info serverAlias="DBTXN-bodb02" executers="" isFunction="0" isNested="0"></info>*/
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
		- 20190701@Percy: Update directly flag of MBBU process [RedmineID: #115877]

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
		DECLARE @VName VARCHAR(50)
		SELECT  @VName = CASE WHEN @mode IN (3,4) THEN 'isMovingBet_Local' WHEN @mode IN (5,6) THEN 'isArchivingBet_Local' END

		DECLARE @updatedFlag TABLE (VValue VARCHAR(200))

		--//@mode = 3,5: turn on flag --> input start time, @mode = 4,6: turn off flag --> input end time
		IF @mode IN (3,5)
		BEGIN
			UPDATE dbo.SystemSettings WITH (ROWLOCK)
			SET VValue = CONVERT(VARCHAR(200), CONVERT(SMALLINT, VValue) + 1)
			OUTPUT DELETED.VValue INTO @updatedFlag (VValue)
			WHERE VName = @VName

			IF EXISTS (SELECT 1 FROM @updatedFlag WHERE VValue = '0')
			BEGIN
				UPDATE dbo.SystemSettings WITH (ROWLOCK)
				SET VValue = CONVERT(VARCHAR(200), GETDATE(), 121)
				WHERE VName = 'StartMoving_Local'
			END
		END
		ELSE IF @mode IN (4,6)
		BEGIN
			UPDATE dbo.SystemSettings WITH (ROWLOCK)
			SET VValue = CONVERT(VARCHAR(200), CONVERT(SMALLINT, VValue) - 1)
			OUTPUT DELETED.VValue INTO @updatedFlag (VValue)
			WHERE VName = @VName

			IF EXISTS (SELECT 1 FROM @updatedFlag WHERE VValue = '0')
			BEGIN
				UPDATE dbo.SystemSettings WITH (ROWLOCK)
				SET VValue = CONVERT(VARCHAR(200), GETDATE(), 121)
				WHERE VName = 'EndMoving_Local'
			END
		END
	END
END
GO