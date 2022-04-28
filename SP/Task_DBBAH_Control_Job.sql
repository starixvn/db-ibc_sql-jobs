/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Task_DBBAH_Control_Job
(
	 @Jobname VARCHAR(100)	
	,@Waitfordelay VARCHAR(12) = NULL
)
AS
/* 
	Created by:20220428@Max
    Task: SQL Server Upgrade to 2019 for DBMSG & enhance related jobs on replicated servers [Redmine:#171913]
    DB: DBBAH/bodb02

	Revision:
		- 20220428@Max: Create SP [Redmine: #171913]

*/
/*
	--1. 	bodb02 : Task_BalanceRecord_Insert
*/
BEGIN

	DECLARE  @startDate		DATETIME
	SET  @startDate  = GETDATE()

	WHILE (1=1)
	BEGIN
	
		IF(@Jobname = 'bodb02 : Task_BalanceRecord_Insert')
		BEGIN
			--TransferData - BalanceTrigger to BalanceTrigger_ProcessData
			EXEC dbo.Task_BalanceTrigger_TransferData 1000

			--DELETE FROM balancetrigger with (rowlock)
			EXEC dbo.Task_BalanceRecord_Insert 1000
		END

		IF DATEDIFF(SECOND, @startDate, GETDATE() ) >= 600 -- loop within 10 minutes
			BREAK

		IF @Waitfordelay IS NOT NULL 
			WAITFOR DELAY @Waitfordelay

	END
END