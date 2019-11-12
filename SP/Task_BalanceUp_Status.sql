/*<info serverAlias="DBEXT-bodb02,DBAGE-bodb02,DBACC-bodb02" executers="vnteam" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_BalanceUp_Status]
	@StatusID TINYINT = 0 OUTPUT
AS

/*
	Created by: 20191111@Bobby
    Task: BU has done yet?
    DB: DBACC.bodb02

	Revisions:
		- 20191111@Bobby: Initialize SP [RedmineID: #83787]
	
	Parameters Explanations:
		@StatusID = 0 --> BU has commpleted
		@StatusID = 1 --> BU has not commpleted yet (is running)

*/

BEGIN
	SET @StatusID = 1

	-- MB is running
	IF EXISTS (
		SELECT TOP 1 1 FROM dbo.SystemSettings WITH(NOLOCK)
		WHERE VName = 'isArchivingBet_Local' AND VValue <> '0'
	)
	BEGIN
		SET @StatusID = 1

		RETURN
	END

	-- MB has completed
	IF EXISTS (
		SELECT TOP 1 1 FROM dbo.SystemSettings WITH(NOLOCK)
		WHERE VName = 'isArchivingBet_Local' AND VValue = '0'
	)
	BEGIN
		SET @StatusID = 0

		RETURN
	END
END
GO