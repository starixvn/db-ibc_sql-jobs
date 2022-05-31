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
	
	Param's explanation:		
*/
/*
	--1. DBA: Task_DetectBet_TicketExceededBetLimit
*/
BEGIN

	DECLARE  @startDate		DATETIME
	SET  @startDate  = GETDATE()

	WHILE (1=1)
	BEGIN
	
		IF(@Jobname = 'DBA: Task_DetectBet_TicketExceededBetLimit')
			EXEC dbo.Task_DetectBet_TicketExceededBetLimit_Job

		IF DATEDIFF(SECOND, @startDate, GETDATE() ) >= 600 -- loop within 10 minutes
			BREAK

		IF @Waitfordelay IS NOT NULL 
			WAITFOR DELAY @Waitfordelay -- [SSB - Get settled tickets] waitfor

	END
END