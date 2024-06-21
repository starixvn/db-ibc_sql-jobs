/*<info serverAlias="DBTXN-bodb02, DBCUST-CustDB,DBAGE-bodb02" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE Task_CustSetting_JobManagement
(
	 @Jobname VARCHAR(100)
	,@Waitfordelay VARCHAR(12) = NULL
)
AS
/* 
	Created by: 20220406@Elodie
    Task: Reduce UM Count & Write Job History Log Into Disk for Customer Setting
    DB: DBTXN/bodb02, DBCUST/CustDB,DBAGE/bodb02

	Revision:
		- 20220406@Elodie: Initial SP	
		- 20220617@Elodie: Manage job on DBCUST
		- 20220816@Johnson: Scale out DBTXN [Redmine: #175278] 
		- 20221121@Eden: Enhance run time of trigger to capture data for Pending table [#180716]
		- 20240621@July: Adjust wait for delay 10s -> 1s - [Redmine:#206915]
		
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
			WHILE (1=1)
			BEGIN
				EXEC dbo.Task_CustSetting_JobDeploymentInfo
					@JobName = @Jobname
					,@WaitingTime = @WaitingTime OUTPUT
					,@IsWaiting	= @IsWaiting	 OUTPUT
		
				IF @IsWaiting = 1
				BEGIN
					UPDATE SystemSettings WITH(ROWLOCK)
						SET VValue = @Jobname + '-' + CONVERT(VARCHAR(50),GETDATE())
					WHERE VName = 'SettingJobDeploymentDate'
			
					WAITFOR DELAY @WaitingTime
			
				END
				ELSE
				BREAK
			END
			SET @interval  =  GETDATE()
		END
		
		IF @@SERVERNAME IN ('DBTrans','SITDBTRANS','TESTDBTRANS','TESTDB053\TESTSITEDB')
			OR 	@@SERVERNAME LIKE 'DBGRP%' 
			OR 	@@SERVERNAME LIKE 'SITDBGRP%'
		BEGIN
			IF(@Jobname = 'bodb02 : Game : ResetYesterday')
			BEGIN
				EXEC dbo.Task_BalanceGameResetYesterday_All

				DECLARE @WinlostDate SMALLDATETIME
				SET @WinlostDate = CAST(GETDATE() AS DATE)
				EXEC dbo.Task_Winlimit_ResetData @WinlostDate = @WinlostDate

				BREAK
			END

			ELSE IF (@Jobname = 'bodb02 : Game : Task_BalanceUpd')
			BEGIN
				EXEC dbo.Task_BalanceUpdCreditGame
				EXEC dbo.Task_BalanceUpdDebitGame
			END
		END
		ELSE IF @@SERVERNAME IN ('DBCUST','TESTDBCUST','SITDBCUST')
		BEGIN
			IF(@Jobname = 'dbcust - Winlimit Game - Task_block_member')
			BEGIN
				EXEC dbo.Task_Winlimit_BlockedUser			

				WAITFOR DELAY '00:00:03'
			END
			ELSE IF(@Jobname = 'CustDB: TOControl ProcessData')
			BEGIN
				EXEC dbo.TASK_TOControl_MergeTransition	

				WAITFOR DELAY '00:00:01'
			END
		END
		ELSE IF @@SERVERNAME IN ('DB053','DB052','TESTDB053','SITDB052')
		BEGIN
			IF(@Jobname = 'bodb02 - WLMonitored - SyncSetting')
			BEGIN
				EXEC dbo.Task_CustWLMonitored_Setting_Ins			

				--WAITFOR DELAY '00:00:01'
			END
		END

		IF DATEDIFF(SECOND, @startDate, GETDATE() ) >= 600 -- loop within 10 minutes
			BREAK
	
		IF @Waitfordelay IS NOT NULL 
			WAITFOR DELAY @Waitfordelay
	END
END