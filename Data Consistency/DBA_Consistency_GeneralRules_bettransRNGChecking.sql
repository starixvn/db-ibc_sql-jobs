/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_GeneralRules_bettransRNGChecking] 
	 @CheckMode		INT
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT 
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20230420@July
	Task: Check data between bettrans & bettransRNG 
	DB: DBCONSISTENCY-bodb_Consistency
	Revision:
		- 20230420@July: Check data between bettrans & bettransRNG [Redmine: #186426]
	
	Param's Expanation:
	@CheckMode:
		+ 1: Check ticket details between bettrans and bettransRNG
		+ 2: Check wrong status of tickets in bettransRNG
		+ 3: Settled ticket in bettransRNG are not yet summed to bettrans
		+ 4: Detect netstake <> 0 for RNG products (void/reject/refund)
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
				 @TableName	    = 'bettransRNG' 
				,@Today         = @Today
				,@yesterday     = @yesterday
				,@ErrorTransIds = @ErrorTransIds OUTPUT
		
		IF ISNULL(@ErrorTransIds,'') <> ''
		BEGIN
			SET @transId = @ErrorTransIds
			SET @ErrorTransIds = ''

			WHILE (1=1)
			BEGIN
				Mode1_bettransRNG:
				EXEC DBA_Consistency_GeneralRules_TicketDetailChecking
							@TableName	    = 'bettransRNG'
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
						GOTO Mode1_bettransRNG;
					END

					SELECT	 @transId = SUBSTRING(@ErrorTransIds, 2, LEN(@ErrorTransIds) - 1)
							,@ErrCode = 100
							,@ErrMsg = 'Check ticket details between bettrans and bettransRNG '
							,@SampleData = 'bettransRNG.Refno in (' + @transId + ')'
					RETURN;
				END
			END
		END
	END
	
	IF @CheckMode = 2
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM bodb02.dbo.bettransRNG WITH (NOLOCK)
		WHERE (winlostdate = @Today OR winlostdate = @yesterday)
			AND StatusId NOT IN (0,1)
			AND custid <> 0
			AND (
					(winlost > actual_stake AND status <> 'WON')										--Case 2: if winlost - actual_stake > 0 -> status=WON
				OR	(winlost = actual_stake AND status  NOT IN ('DRAW', 'REFUND', 'VOID', 'REJECT'))	--Case 3: if winlost - actual_stake = 0 -> status=DRAW
				OR	(winlost < actual_stake AND status <> 'LOSE')										--Case 4: if winlost - actual_stake < 0 -> status=LOSE
				)
			AND gameID NOT IN (2198, 2398, 2998, 1698, 3898, 4297, 4599)
	
		IF @transId <> ''
		BEGIN
			SELECT	 @transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
					,@ErrCode = 100
					,@ErrMsg = 'Check wrong status of tickets in bettransRNG'
					,@SampleData = 'bettransRNG.TransId in (' + @transId + ')'
		END
		RETURN;
		
	END

	IF @CheckMode = 3
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM	#tempdata b WITH (NOLOCK)
		WHERE	b.IsSum = 0
			  AND DATEDIFF(MINUTE,b.transdate,@Today) > 15
			  AND b.statusID IN (111,112,113) --Draw,won,lose
			  AND b.winlostdate = @yesterday
	
		IF @transId <> ''
		BEGIN
			SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
					,@ErrCode = 100
					,@ErrMsg = 'Settled ticket in bettransRNG are not yet summed to bettrans '
					,@SampleData = 'bettransRNG.TransId in (' + @transId + ')'
		END
	
	END
	
	IF @CheckMode = 4
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM	#tempdata b WITH (NOLOCK)
		WHERE	b.BetStake <> 0 
				AND b.statusID IN (101,102,103) --Reject/Void/Refund 
				AND b.GameID NOT IN (2198, 2398, 2998, 4297, 1698, 3898, 4599)
				AND b.winlostdate = @yesterday
	
		IF @transId <> ''
		BEGIN
			SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
					,@ErrCode = 100
					,@ErrMsg = 'Detect Netstake <> 0 for RNG products'
					,@SampleData = 'bettransRNG.TransId in (' + @transId + ')'
		END
	
	END
END
GO