/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Bet_ExecRep14_01] 
	@Mode INT,
	@TableName VARCHAR(200)
AS
/*
 	Creator: 20210323@Patrick
	Task: Bet_ExecRep14_01
	DB: DBTXN/bodb02
	Revisions:
		- 20210323@Patrick: Initial [Redmine: #149927] 
 */

BEGIN
	SET NOCOUNT ON;
	IF @TableName = 'SystemSettings' AND OBJECT_ID('SystemSettings') IS NOT NULL
	BEGIN
		IF @Mode = 1
		BEGIN
			--==check if does not exist then insert
			IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.SystemSettings WHERE VName = 'MB_SWinloss_Local')
			BEGIN
				INSERT INTO dbo.SystemSettings(VName, VValue)
				VALUES('MB_SWinloss_Local', '0')
			END

			UPDATE dbo.SystemSettings WITH (ROWLOCK)
			SET VValue = '1'
			WHERE VName = 'MB_SWinloss_Local'

			DECLARE @__allowOn BIT = 0
			EXEC dbo.ExecRep_10 @FunctionName = 'WaitforMBCompleted', @Allow = @__allowOn OUTPUT

			IF @__allowOn = 1
			BEGIN
				EXEC DBTXN.bodb02.dbo.Task_UpdSystemSetting @VName = 'MB_ReadyUpdMBDate', @VValue = '1'
			END

		END
		ELSE IF @Mode = 2 -- end inserting sum_winloss
		BEGIN
			UPDATE dbo.SystemSettings WITH (ROWLOCK)
			SET VValue = '0'
			WHERE VName = 'MB_SWinloss_Local'

			DECLARE @__allowOff BIT = 0
			EXEC dbo.ExecRep_10 @FunctionName = 'WaitforMBCompleted', @Allow = @__allowOff OUTPUT

			IF @__allowOff = 1
			BEGIN
				EXEC DBTXN.bodb02.dbo.Task_UpdSystemSetting @VName = 'MB_ReadyUpdMBDate', @VValue = '-1'
			END
		END
		RETURN
	END
END
