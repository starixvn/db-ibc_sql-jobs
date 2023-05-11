/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_GeneralRules_bettransLCChecking] 
	 @CheckMode		INT
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT 
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20230420@July
	Task: Check data between bettrans & bettransLC
	DB: DBCONSISTENCY-bodb_Consistency
	Revision:
		- 20230420@July: Check data between bettrans & bettransLC [Redmine: #186426]
	
	Param's Expanation:
	@CheckMode:
		+ 1: Check ticket details between bettrans and bettransLC
		+ 2: Check wrong status of tickets in bettransLC
*/
BEGIN
	DECLARE @transId		VARCHAR(MAX)
			,@Today			SMALLDATETIME
			,@yesterday		SMALLDATETIME 
			,@ErrorTransIds VARCHAR(MAX) =''

	SET @transId = ''
	SET @Today = CAST(GETDATE() AS DATE)
	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
	
	IF @CheckMode = 1
	BEGIN
		DECLARE @Retry INT = 1

		EXEC DBA_Consistency_GeneralRules_TicketDetailChecking
				 @TableName	    = 'bettransLC' 
				,@Today         = @Today
				,@yesterday     = @yesterday
				,@ErrorTransIds = @ErrorTransIds OUTPUT
		
		IF ISNULL(@ErrorTransIds,'') <> ''
		BEGIN
			SET @transId = @ErrorTransIds
			SET @ErrorTransIds = ''

			WHILE (1=1)
			BEGIN
				Mode1_bettransLC:
				EXEC DBA_Consistency_GeneralRules_TicketDetailChecking
							@TableName	    = 'bettransLC' 
							,@Today         = @Today
							,@yesterday     = @yesterday
							,@transId       = @transId
							,@ErrorTransIds = @ErrorTransIds OUTPUT
			
				IF ISNULL(@ErrorTransIds, '') <> ''
				BEGIN
					IF @Retry < 3
					BEGIN
						WAITFOR DELAY '00:02:00:000' --retry after 2 minutes
						SET @Retry = @Retry + 1
						GOTO Mode1_bettransLC
					END

					SELECT	 @transId = SUBSTRING(@ErrorTransIds, 2, LEN(@ErrorTransIds) - 1)
							,@ErrCode = 100
							,@ErrMsg = 'Check ticket details between bettrans and bettransLC '
							,@SampleData = 'bettransLC.TransId in (' + @transId + ')'
					RETURN;
				END
			END
		END
	END
	
	IF @CheckMode = 2
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM bodb02.dbo.bettransLC WITH (NOLOCK)
		WHERE (winlostdate = @Today OR winlostdate = @yesterday)
		AND StatusId NOT IN (0,1)
			AND (
					(winlost > actual_stake AND status <> 'WON')										--Case 2: if winlost - actual_stake > 0 -> Issue: Status should be WON
				OR	(winlost = actual_stake AND status  NOT IN ('DRAW', 'REFUND', 'VOID', 'REJECT'))	--Case 3: if winlost - actual_stake = 0 -> Issue: Status should be DRAW/REFUND/VOID/REJECT
				OR	(winlost < actual_stake AND status <> 'LOSE')										--Case 4: if winlost - actual_stake < 0 -> Issue: Status should be LOSE
				)
			AND gameID NOT IN (2198, 2398, 2998, 1698, 3898, 4297, 4599)
	
		IF @transId <> ''
		BEGIN
			SELECT	 @transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
					,@ErrCode = 100
					,@ErrMsg = 'Check wrong status of tickets in bettransLC'
					,@SampleData = 'bettransLC.TransId in (' + @transId + ')'
		END
		RETURN;
		
	END
END
GO