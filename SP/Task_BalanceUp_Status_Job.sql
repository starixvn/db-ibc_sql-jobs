/*<info serverAlias="DBEXT-bodb02,DBAGE-bodb02,DBACC-bodb02" executers="vnteam" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_BalanceUp_Status_Job]
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
	SET NOCOUNT ON

	DECLARE @BUStatusID TINYINT = 0

	EXEC dbo.[Task_BalanceUp_Status] @StatusID = @BUStatusID OUTPUT

	-- BU does not start yet or is running --> loop 15 minutes
	IF ISNULL(@BUStatusID, 0) <> 0
	BEGIN
		RAISERROR('* LOOP * Archive bets is processing. Automatically retry after 15mins.', 16, 1)
		RETURN
	END
END
GO