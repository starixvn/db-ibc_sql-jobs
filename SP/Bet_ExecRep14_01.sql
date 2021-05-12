/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Bet_ExecRep14_01] 
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
			IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.SystemSettings WHERE VName = 'Movebet_DoneSumWinloss_Local')
			BEGIN
				INSERT INTO dbo.SystemSettings(VName, VValue)
				VALUES('Movebet_DoneSumWinloss_Local', '0')
			END

			UPDATE dbo.SystemSettings WITH (ROWLOCK)
			SET VValue = '1'
			WHERE VName = 'Movebet_DoneSumWinloss_Local'

			IF @@SERVERNAME IN ('DB06C2\DB06', 'DB061', 'DB055', 'DB054C2\DB054', 'DB052', 'DB053')
			BEGIN
				EXEC DBTXN.bodb02.dbo.Task_UpdSystemSetting @VName = 'Movebet_ReadyUpdMBDate', @VValue = '1'
			END

		END
		ELSE IF @Mode = 2 -- end inserting sum_winloss
		BEGIN
			UPDATE dbo.SystemSettings WITH (ROWLOCK)
			SET VValue = '0'
			WHERE VName = 'Movebet_DoneSumWinloss_Local'

			IF @@SERVERNAME IN ('DB06C2\DB06', 'DB061', 'DB055', 'DB054C2\DB054', 'DB052', 'DB053')
			BEGIN
				EXEC DBTXN.bodb02.dbo.Task_UpdSystemSetting @VName = 'Movebet_ReadyUpdMBDate', @VValue = '-1'
			END
		END
		RETURN
	END
END
