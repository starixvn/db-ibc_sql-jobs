/*<info serverAlias="DBTP-bodb02" executers="bodbAdminNet" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DetectBet_TicketExceededBetLimit_Job]
AS
/*	Created by: Max
	Date : 20220525
	Task: Detect player exceeded the bet limit of the Agent's setting [Redmine: #170739]
	DB: DBTP/bodb02
	
	Revisions: 
		- 20220525@Max: Create SP [Redmine: #170739]
	
	Param's explanation:		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @maxTransId_bettrans BIGINT
		, @maxTransId_bettransLC BIGINT
		, @maxTransId_bettransRnG BIGINT
		, @maxTransId_translog BIGINT

		, @bachCount INT = 2000
	
	--1. bettrans
	EXEC dbo.Task_DetectBet_bettrans
		@batchCount = @bachCount
		, @maxTransId = @maxTransId_bettrans OUTPUT

	--2. bettransLC
	EXEC dbo.Task_DetectBet_bettransLC
		@batchCount = @bachCount
		, @maxTransId = @maxTransId_bettransLC OUTPUT

	--3. bettransRnG
	EXEC dbo.Task_DetectBet_bettransRnG
		@batchCount = @bachCount
		, @maxTransId = @maxTransId_bettransRnG OUTPUT

	--4. translog
	EXEC dbo.Task_DetectBet_translog
		@batchCount = @bachCount
		, @maxTransId = @maxTransId_translog OUTPUT

	--5. Send Mail
	EXEC dbo.Task_DetectBet_SendMail

	--6. Update Setting
	UPDATE c SET c.ConfigValue = @maxTransId_bettrans
	FROM dbo.CustMaxBetSetting_Config c WITH (ROWLOCK, UPDLOCK)
	WHERE c.ConfigName = 'bettrans'

	UPDATE c SET c.ConfigValue = @maxTransId_bettransLC
	FROM dbo.CustMaxBetSetting_Config c WITH (ROWLOCK, UPDLOCK)
	WHERE c.ConfigName = 'bettransLC'

	UPDATE c SET c.ConfigValue = @maxTransId_bettransRnG
	FROM dbo.CustMaxBetSetting_Config c WITH (ROWLOCK, UPDLOCK)
	WHERE c.ConfigName = 'bettransRnG'

	UPDATE c SET c.ConfigValue = @maxTransId_translog
	FROM dbo.CustMaxBetSetting_Config c WITH (ROWLOCK, UPDLOCK)
	WHERE c.ConfigName = 'translog'

END


