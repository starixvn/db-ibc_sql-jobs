/*<info serverAlias="DBAGE-bodb_age" executers="" isFunction="0" isNested="0"></info>*/
CREATE PROC dbo.dba_cdc_task_job
(
	 @Jobname VARCHAR(100)
	,@WaitforDelay VARCHAR(12) = NULL
	
)
AS
/*
	Task: implement cdc for sum winloss
	DB: DBAGE-bodb_age
	Revision:
		20231201@Patrick: implement cdc for sum winloss [Redmine: #195357]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE  @startDate		DATETIME, @interval DATETIME
			,@WaitingTime	VARCHAR(10)
			,@IsWaiting		BIT

	SET  @startDate  = getdate()
	SET  @interval  = @startDate

	WHILE (1=1)
	BEGIN
		IF DATEDIFF(SECOND, @interval, GETDATE() ) >=  60
		BEGIN
			WHILE (1=1)
			BEGIN
				EXEC dbo.Task_JobDeploymentInfo @JobName = @Jobname
					, @WaitingTime = @WaitingTime OUTPUT
					, @IsWaiting = @IsWaiting OUTPUT
		
				IF @IsWaiting = 1
				BEGIN
					UPDATE dbo.SystemSettings WITH(ROWLOCK)
						SET VValue = @Jobname + '-' + CONVERT(VARCHAR(50),GETDATE())
					WHERE VName = 'JobDeploymentDate'
			
					WAITFOR DELAY @WaitingTime --cdc wait for deployment
			
				END
				ELSE
				BREAK
			END
			SET @interval  =  GETDATE()
		END
	
		IF(@Jobname = 'bodb_age : pull data 4 bettrans')
		BEGIN
			EXEC dbo.cdc_pull_data_bettrans
		END
		ELSE IF(@Jobname = 'bodb_Age: Age process bettrans_compact')
		BEGIN
			EXEC [dbo].[Task_CDC_Process_Bettrans_compact]
		END
		
		IF DATEDIFF(SECOND, @startDate, GETDATE() ) >= 600 -- loop within 10 minutes
			BREAK
	
		IF @Waitfordelay IS NOT NULL 
			WAITFOR DELAY @WaitforDelay --cdc waitfor delay job
	END
END