USE bodb_cdc
GO
CREATE PROC dbo.dba_cdc_task_job
(
	 @Jobname VARCHAR(100)
	,@WaitforDelay VARCHAR(12) = NULL
	
)
AS
/* 
	Created
    Task: 
    DB: DBCT/bodb_cdc

	Revision:
		- 20231201@Patrick: init [Redmine: #]

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
	
		IF(@Jobname = 'bodb_cdc : pull data 4 bettrans')
			EXEC dbo.cdc_pull_data_bettrans

		
		IF DATEDIFF(SECOND, @startDate, GETDATE() ) >= 600 -- loop within 10 minutes
			BREAK
	
		IF @Waitfordelay IS NOT NULL 
			WAITFOR DELAY @WaitforDelay --cdc waitfor delay job
	END
END