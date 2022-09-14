/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/
ALTER PROC [dbo].[NAP_Admin_Control_Job]
(
	 @Jobname VARCHAR(100)
	,@Waitfordelay VARCHAR(12) = NULL
	
)
AS
/*
    Created: 20220913@Helen
    Task: 
    DB: DBBAH/bodb02
    Revisions:
		- 20220912@Helen: scaleout project [176932]
		
*/
BEGIN

	DECLARE  @startDate		DATETIME, @interval DATETIME
			,@WaitingTime	VARCHAR(10)
			,@IsWaiting		BIT

	SET  @startDate  = getdate()
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

		IF(@Jobname = 'bodb02 : Task_SiteDB_BalanceTrigger_Sync')
			EXEC Task_BalanceRecord_SiteDBBalanceTrigger_Insert

		IF DATEDIFF(SECOND, @startDate, GETDATE() ) >= 600 -- loop within 10 minutes
			BREAK
	
		IF @Waitfordelay IS NOT NULL 
			WAITFOR DELAY @Waitfordelay
	END
END
GO


