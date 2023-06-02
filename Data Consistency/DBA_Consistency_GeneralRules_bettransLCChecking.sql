/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_GeneralRules_bettransLCChecking] 
	 @CheckMode		INT
   , @ErrCode		INT				= 0		OUTPUT
   , @ErrMsg		VARCHAR(MAX)	= ''	OUTPUT 
   , @SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20230420@July
	Task: Check data between bettrans & bettransLC
	DB: DBCONSISTENCY-bodb_Consistency
	Revision:
		- 20230420@July: Check data between bettrans & bettransLC [Redmine: #186426]
		- 20230531@July: Check ticket data consistency [Redmine: #186736]
	
	Param's Expanation:
	@CheckMode:
		+ 1: Check ticket details between bettrans and bettransLC
		+ 2: Check wrong status of tickets in bettransLC
		+ 3: Settled ticket in bettransLC are not yet summed to bettrans

*/
BEGIN
	DECLARE @transId		VARCHAR(MAX)
		  , @Today			SMALLDATETIME
		  , @yesterday		SMALLDATETIME 
		  , @CheckDate		SMALLDATETIME
		  , @ErrorTransIds  VARCHAR(MAX) =''
		  , @ProductId		INT

	SET @transId = ''
	SET @Today = CAST(GETDATE() AS DATE)
	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))

	SET @CheckDate = @yesterday
	DECLARE @tmpProductId TABLE (ProductId INT, IsFinish BIT)

	INSERT INTO @tmpProductId (ProductId) 
	SELECT DISTINCT SportType AS ProductId
	FROM bodb02.dbo.SportBettypeMatrix WITH(NOLOCK)
	WHERE RefTable = 2 AND Enabled = 1 AND IsTest = 0

	IF @CheckMode = 1
	BEGIN
		DECLARE @Retry INT = 1
		
		WHILE (1=1)
		BEGIN
			UPDATE TOP(1) t  
			SET  IsFinish = 1, @ProductId = ProductId
			FROM @tmpProductId t
			WHERE IsFinish IS NULL

			IF @@ROWCOUNT = 0 BREAK	
				
			WHILE @CheckDate <= @Today
			BEGIN
				EXEC DBA_Consistency_GeneralRules_TicketDetailChecking
						 @TableName	    = 'bettransLC' 
					   , @ProductId		= @ProductId
					   , @CheckDate     = @CheckDate
					   , @ErrorTransIds = @ErrorTransIds OUTPUT
		
				IF ISNULL(@ErrorTransIds,'') <> ''
				BEGIN
					SET @transId = @ErrorTransIds
					SET @ErrorTransIds = ''

					WHILE (1=1)
					BEGIN
						Mode1_bettransLC:
						EXEC DBA_Consistency_GeneralRules_TicketDetailChecking
									@TableName	    = 'bettransLC' 
								  , @ProductId		= @ProductId
								  , @CheckDate      = @CheckDate
								  , @transId        = @transId
								  , @ErrorTransIds  = @ErrorTransIds OUTPUT
			
						IF ISNULL(@ErrorTransIds, '') <> ''
						BEGIN
							IF @Retry < 3
							BEGIN
								WAITFOR DELAY '00:02:00:000' --retry after 2 minutes
								SET @Retry = @Retry + 1
								GOTO Mode1_bettransLC
							END

							SELECT	 @transId = SUBSTRING(@ErrorTransIds, 2, LEN(@ErrorTransIds) - 1)
								   , @ErrCode = 100
								   , @ErrMsg = 'Check ticket details between bettrans and bettransLC on product ' + CAST(@ProductId AS VARCHAR)
								   , @SampleData = 'bettransLC.Refno in (' + @transId + ')'
							RETURN;
						END
					END
				END
				SET @CheckDate =  DATEADD(DAY, 1, @CheckDate)
			END
		END
	END
	
	IF @CheckMode = 2
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM bodb02.dbo.bettransLC WITH (NOLOCK)
		WHERE (winlostdate = @Today OR winlostdate = @yesterday)
			AND StatusId NOT IN (0,1)
			AND custid <> 0
			AND (
					(winlost > actual_stake AND status <> 'WON')										--Case 2: if winlost - actual_stake > 0 -> Issue: Status should be WON
				OR	(winlost = actual_stake AND status  NOT IN ('DRAW', 'REFUND', 'VOID', 'REJECT'))	--Case 3: if winlost - actual_stake = 0 -> Issue: Status should be DRAW/REFUND/VOID/REJECT
				OR	(winlost < actual_stake AND status <> 'LOSE')										--Case 4: if winlost - actual_stake < 0 -> Issue: Status should be LOSE
				)
			AND gameID NOT IN (2198, 2398, 2998, 1698, 3898, 4297, 4599)
	
		IF @transId <> ''
		BEGIN
			SELECT	 @transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				   , @ErrCode = 100
				   , @ErrMsg = 'Check wrong status of tickets in bettransLC'
				   , @SampleData = 'bettransLC.TransId in (' + @transId + ')'
		END
		RETURN;
	END

	IF @CheckMode = 3
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM	bodb02.dbo.bettransLC b WITH (NOLOCK)
		WHERE	b.IsSum = 0 AND b.custid <> 0
			  AND DATEDIFF(MINUTE,b.transdate,@Today) > 15
			  AND b.statusID IN (111,112,113) --Draw,won,lose
			  AND b.winlostdate = @yesterday
	
		IF @transId <> ''
		BEGIN
			SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				  , @ErrCode = 100
				  , @ErrMsg = 'Settled ticket in bettransLC are not yet summed to bettrans '
				  , @SampleData = 'bettransLC.TransId in (' + @transId + ')'
		END
	
	END

END
GO