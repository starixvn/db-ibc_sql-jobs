/*<info serverAlias="DBTP-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DBTP_Control_Job]
(
	 @Jobname VARCHAR(100)	
	,@Waitfordelay VARCHAR(12) = NULL
)
AS
/*	Created by: Max
	Date : 20220525
	Task: Detect player exceeded the bet limit of the Agent's setting [Redmine: #170739]
	DB: DBTP/bodb02
	
	Revisions: 
		- 20220525@Max: Create SP [Redmine: #170739]
		- 20220919@Tacy: HotFix [Redmine: #177701]
		- 20221024@July: Modify job DetectBet [Redmine: #177701]

	Param's explanation:		
*/
/*
	--1. DBA: Task_DetectBet_TicketExceededBetLimit
*/
BEGIN
	DECLARE  @startDate		DATETIME
			,@interval		DATETIME
			,@WaitingTime	VARCHAR(10)
			,@IsWaiting		BIT

	SET  @startDate  = GETDATE()
	SET  @interval  = @startDate

	WHILE (1=1)
	BEGIN
		IF DATEDIFF(SECOND, @interval, GETDATE() ) >=  60
		BEGIN
			-- CHECK flag for SP deployment
			WHILE (1=1)
			BEGIN
				EXEC dbo.Acc_JobDeploymentInfo
					@JobName = @Jobname
					,@WaitingTime = @WaitingTime OUTPUT
					,@IsWaiting	= @IsWaiting	 OUTPUT
		
				IF @IsWaiting = 1
				BEGIN
					UPDATE SystemSettings WITH(ROWLOCK)
						SET VValue = @Jobname + '-' + CONVERT(VARCHAR(50),GETDATE())
					WHERE VName = 'JobDeploymentDate'
			
					WAITFOR DELAY @WaitingTime
			
				END
				ELSE
				BREAK
			END
			SET @interval  =  GETDATE()
		END

		IF(@Jobname = 'DBA: Task_DetectBet_TicketExceededBetLimit')
		BEGIN
			EXEC dbo.Task_DetectBet_SyncBetSettingHistory
			EXEC dbo.Task_DetectBet_TicketExceededBetLimit_Job
		END

		IF DATEDIFF(SECOND, @startDate, GETDATE() ) >= 600 -- loop within 10 minutes
			BREAK
		
		IF @Waitfordelay IS NOT NULL 
			WAITFOR DELAY @Waitfordelay -- [Task_DetectBet_TicketExceededBetLimit] waitfor

	END
END