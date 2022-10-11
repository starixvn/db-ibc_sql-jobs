/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE Task_Check_LongRunning_BalanceUpdCreditSports
AS
/*
   Created:20221003@Louisa
   Task: Enhancement - avoid wrong balance value due to DBTrans got issue [Redmine:#178231]
 
	DB: DBTXN/bodb02
 	
	Revisions:
		- 20221003@Louisa: SP check Balance Pending process is slowly [Redmine:#178231]
 	
	Param's Explanation: 
 
*/
BEGIN

SET NOCOUNT ON

	DECLARE @PendingCS_State		VARCHAR(1)
			,@PendingCS_CreatedDate DATETIME
			
			,@StartTime		DATETIME
			,@CheckTime		DATETIME
			,@interval		INT
			,@errorMessage	VARCHAR(4000)
			,@Subject		VARCHAR(300)
			,@recipients	VARCHAR(500)
	
	SET @interval = 60
	SET @StartTime = GETDATE()
	SET @CheckTime = @StartTime

	IF @@SERVERNAME  = 'DBTrans' OR @@SERVERNAME LIKE 'DBGRP%'
		SET @recipients = 'dbaadmin@onelab.tw'
	ELSE
		SET @recipients = 'dba_local@starixvn.com;qa@starixvn.com'
			
	WHILE ( 1 = 1)
	BEGIN	

		WHILE ( 1 = 1)
		BEGIN
			SELECT	@PendingCS_State		= [PendingCS_State]
					,@PendingCS_CreatedDate = CAST([PendingCS_CreatedDate] AS DATETIME)
			FROM dbo.BalanceUpdateSetting b WITH(NOLOCK)
			PIVOT ( MAX(vvalue) FOR vname in ([PendingCS_State],[PendingCS_CreatedDate]) ) pv

			IF @PendingCS_State = '0' OR DATEDIFF(SECOND, @PendingCS_CreatedDate, @CheckTime) < @interval
			BEGIN
				BREAK
			END
			ELSE
			BEGIN
				SET @Subject	= N'Balance Pending process - Notification at ' + @@servername
				SET @errorMessage = N'<p>Hey guys, Balance Pending process is running at [' + @@servername + '] over [' + cast(@interval as varchar(20)) + '] seconds still not complete. 
				</br>Please check data at <b>bodb02.dbo.BalanceUpdateSetting</b> and <b>bodb02.dbo.BalCreditSportsPending_Staging</b></p>' ;
 
				EXECUTE msdb.dbo.sp_send_dbmail 
					@profile_name	= DEFAULT
					, @recipients	= @recipients	
					, @copy_recipients		 = ''
					, @blind_copy_recipients = ''
					, @subject				 = @subject
					, @body					 = @errorMessage
					, @body_format			 = 'HTML';

				EXECUTE	DBNOTI.NotificationDB.dbo.DBA_Letstalk_NewJobMessage @ServerName = @@ServerName
					, @JobId = NULL, @JobName = N'vndba:Check slowly BalanceUpdCreditSports processes'
					, @Message = @errorMessage
					, @CaseId = 1;

				WAITFOR DELAY '00:01:00'
				SET @CheckTime = GETDATE()

				IF DATEDIFF(SECOND, @StartTime, GETDATE() ) >= 600 -- loop within 10 minutes
				BREAK

			END
		END

		IF DATEDIFF(SECOND, @StartTime, GETDATE() ) >= 600 -- loop within 10 minutes
		BREAK

		WAITFOR DELAY '00:01:00'
		SET @CheckTime = GETDATE()

	END


END
GO
