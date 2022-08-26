/*<info serverAlias="DBTP-bodb02" executers="bodbAdminNet" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DetectBet_TicketExceededBetLimit_Job]
AS
/*	Created by: Max
	Date : 20220525
	Task: Detect player exceeded the bet limit of the Agent's setting [Redmine: #170739]
	DB: DBTP/bodb02
	
	Revisions: 
		- 20220525@Max: Create SP [Redmine: #170739]
		- 20220728@July: Scale out DBTRANS - Change maxTransIdSetting to SequenceIdSetting [Redmine: #175965]

	Param's explanation:	
		- Temp table #tmp_TransId will be created at each parent (Ex: Task_DetectBet_bettrans) SP for each table and will be used inheritance in Task_DetectBet_CustMaxBetSettingSel
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @maxSequenceId_bettrans BIGINT
		  , @maxSequenceId_bettransLC BIGINT
		  , @maxSequenceId_bettransRnG BIGINT
		  , @maxSequenceId_translog BIGINT
		  , @maxSequenceId_bettransG BIGINT
		  , @batchCount INT = 2000
	
	--1. bettrans
	EXEC dbo.Task_DetectBet_bettrans
		@batchCount = @batchCount
		, @maxSequenceId = @maxSequenceId_bettrans OUTPUT

	--Update Setting
	IF @maxSequenceId_bettrans IS NOT NULL
	BEGIN
		UPDATE c SET c.ConfigValue = @maxSequenceId_bettrans
		FROM dbo.CustMaxBetSetting_Config c WITH (ROWLOCK, UPDLOCK)
		WHERE c.ConfigName = 'bettrans'
	END
	-----------------------------------------------

	--2. bettransLC
	EXEC dbo.Task_DetectBet_bettransLC
		@batchCount = @batchCount
		, @maxSequenceId = @maxSequenceId_bettransLC OUTPUT

	IF @maxSequenceId_bettransLC IS NOT NULL
	BEGIN
		UPDATE c SET c.ConfigValue = @maxSequenceId_bettransLC
		FROM dbo.CustMaxBetSetting_Config c WITH (ROWLOCK, UPDLOCK)
		WHERE c.ConfigName = 'bettransLC'
    END
	------------------------------------------------

	--3. bettransRnG
	EXEC dbo.Task_DetectBet_bettransRnG
		@batchCount = @batchCount
		, @maxSequenceId = @maxSequenceId_bettransRnG OUTPUT

	IF @maxSequenceId_bettransRnG IS NOT NULL
	BEGIN
		UPDATE c SET c.ConfigValue = @maxSequenceId_bettransRnG
		FROM dbo.CustMaxBetSetting_Config c WITH (ROWLOCK, UPDLOCK)
		WHERE c.ConfigName = 'bettransRnG'
	END
	------------------------------------------------------

	--4. translog
	EXEC dbo.Task_DetectBet_translog
		@batchCount = @batchCount
		, @maxSequenceId = @maxSequenceId_translog OUTPUT

	IF @maxSequenceId_translog IS NOT NULL
	BEGIN
		UPDATE c SET c.ConfigValue = @maxSequenceId_translog
		FROM dbo.CustMaxBetSetting_Config c WITH (ROWLOCK, UPDLOCK)
		WHERE c.ConfigName = 'translog'
	END
	-----------------------------------------------------

	--5. bettransG
	EXEC dbo.Task_DetectBet_bettransG
		@batchCount = @batchCount
		, @maxSequenceId = @maxSequenceId_bettransG OUTPUT

	IF @maxSequenceId_bettransG IS NOT NULL
	BEGIN
		UPDATE c SET c.ConfigValue = @maxSequenceId_bettransG
		FROM dbo.CustMaxBetSetting_Config c WITH (ROWLOCK, UPDLOCK)
		WHERE c.ConfigName = 'bettransG'
    END
	------------------------------------------------

	--5. Send Mail
	EXEC dbo.Task_DetectBet_SendMail

END


