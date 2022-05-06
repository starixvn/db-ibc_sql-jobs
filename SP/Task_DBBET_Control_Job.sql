/*<info serverAlias="DBBET-bk" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Task_DBBET_Control_Job @Jobname VARCHAR(128),	
	@Waitfordelay VARCHAR(12) = NULL

AS
/* 
	Created by:.
    Task: SQL Server Upgrade to 2019 [Redmine:#171913]
    DB: DBBET/bk

	Revision:
		- 20220505@Patrick: Create SP [Redmine: #171913]

*/
BEGIN
	SET NOCOUNT ON
	DECLARE @startDate DATETIME
	SET	@startDate = GETDATE()

	WHILE 1 = 1
	BEGIN
		
		IF @Jobname = 'BK : FC'
		BEGIN
			DECLARE @__transid BIGINT
			SELECT @__transid = MAX(transid) 
			FROM bk.dbo.bets WITH (ROWLOCK)

			EXEC dbo.Task_Bets_TransForecast @transid = @__transid

			EXEC dbo.Task_Bets_TranslogForecast
		END
		ELSE IF @Jobname = 'BK : FC Rej'
		BEGIN
			DECLARE @__rejectedTransId BIGINT
			SELECT @__rejectedTransId = MAX(transid) 
			FROM bk.dbo.betsreject WITH (ROWLOCK)

			EXEC dbo.Task_Bets_TransReject @transid = @__rejectedTransId

			EXEC dbo.Task_Bets_TranslogReject
		END
			
		IF DATEDIFF(SECOND, @startDate, GETDATE()) >= 600 -- loop within 10 minutes
		BEGIN
			BREAK
		END

		IF @Waitfordelay IS NOT NULL 
			WAITFOR DELAY @Waitfordelay -- BK FC waitfor

	END
END