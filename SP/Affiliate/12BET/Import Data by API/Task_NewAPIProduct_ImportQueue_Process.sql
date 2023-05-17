/*<info serverAlias="DBAFF12BET-Affiliate_12BET" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_NewAPIProduct_ImportQueue_Process]
	@TpType			INT,
	@SubItem		VARCHAR(200),
	@QueueIdInput	INT = 0, -- manually import
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20221117@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Import Data Job - Parse Json data from Queue by Product

	Revisions:
		- 20221117@Malcolm: Initialize SP [RedmineID: #180311]
		- 20230510@Eddie: Change datatype of 'TransactionId' and change 'TransactionId' to lowercase of products different from 'skywind'   [RedmineID: #180311]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @QueueId BIGINT, @WinlostDate SMALLDATETIME, @LastQueueId BIGINT, @MaxWinlostDate SMALLDATETIME, @SuccessfullMsg NVARCHAR(200) = 'Successfully'
		   ,@ProductId INT = -1, @TimeZone FLOAT, @GMTData INT = 8, @JsonData NVARCHAR(MAX)

	DECLARE @Exchange TABLE (ExchangeDate SMALLDATETIME, ExchangeId INT, Currency NVARCHAR(50), ExRate FLOAT, AffExRate FLOAT)
	DECLARE @tmpWinlostDate TABLE (winlostdate SMALLDATETIME)

	SELECT @ProductId = ProductId FROM dbo.APIProductMappingSettings s WITH(NOLOCK) WHERE s.TpType = @TpType AND s.SubItem = @SubItem

	SELECT @TimeZone = CONVERT(FLOAT, SettingValue) FROM dbo.APIProductSettings WITH(NOLOCK) WHERE ProductId = @ProductId AND SettingName = 'TimeZone' 

	IF ISNULL(@ProductId, -1) = -1
		RETURN

	IF @TimeZone IS NULL
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Missing settings for Timezone, @ProductId = ' + CONVERT(VARCHAR(20), @ProductId)
		RETURN
	END

	-- Manually import
	IF @QueueIdInput <> 0
	BEGIN
		SELECT @QueueId = QueueId, @JsonData = JsonData
		FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
		WHERE tpType = @tpType AND SubItem = @SubItem AND JobType = 0 AND QueueId = @QueueIdInput
	END
	ELSE
	BEGIN
		SELECT @LastQueueId = CONVERT(BIGINT, SettingValue)
		FROM dbo.APIProductSettings WITH (NOLOCK)
		WHERE ProductId = @ProductId AND SettingName = 'LastQueueId'

		SELECT TOP 1 @QueueId = QueueId, @JsonData = JsonData
		FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
		WHERE tpType = @tpType AND SubItem = @SubItem AND QueueId >= @LastQueueId AND JobType = 0 AND FinishedTime IS NULL
		ORDER BY QueueId
	END

	DECLARE @IsErr BIT = 1
	
	WHILE @QueueId IS NOT NULL 
	BEGIN
		BEGIN
			CREATE TABLE #bettrans_APIProducts
			(
				Bet						MONEY
				,BetStatus				VARCHAR(10)
				,GamePlatform			VARCHAR(20)
				,IsHedgebet				BIT
				,ThirdPartyId			INT
				,TransactionbDatetime	DATETIME
				,TransactionId			VARCHAR(50) COLLATE SQL_Latin1_General_CP1_CS_AS
				,Username				VARCHAR(50)
				,ValidBet				MONEY
				,Win					MONEY
				,WinlostDate			SMALLDATETIME
			)

			CREATE NONCLUSTERED INDEX IX_TransactionId ON #bettrans_APIProducts (TransactionId)
			BEGIN TRY
				INSERT INTO #bettrans_APIProducts 
				(
					Bet
					,BetStatus
					,GamePlatform
					,IsHedgebet
					,ThirdPartyId
					,TransactionbDatetime
					,TransactionId
					,Username
					,ValidBet
					,Win
					,WinlostDate 
				)
				SELECT 
					 d.Bet
					,d.BetStatus
					,d.GamePlatform
					,d.IsHedgebet
					,d.ThirdPartyId
					,d.TransactionbDatetime
					,CASE WHEN @TpType = 17 THEN d.TransactionId ELSE LOWER(d.TransactionId) END AS TransactionId -- @TpType = 17: 12Sapphire Skywind
					,d.Username
					,d.ValidBet
					,d.Win
					,CONVERT(DATE, DATEADD(HOUR, @TimeZone - @GMTData, d.TransactionbDatetime)) AS WinlostDate 
				FROM 
					OPENJSON(@JsonData, '$.BetTransTicket')
					WITH
					(
						Bet						MONEY 		   '$.bet'
						,BetStatus				VARCHAR(10)	   '$.betstatus'
						,GamePlatform			VARCHAR(20)    '$.gameplatform'
						,IsHedgebet				BIT			   '$.ishedgebet'
						,ThirdPartyId			INT   		   '$.thirdpartyid'
						,TransactionbDatetime	DATETIME	   '$.transactiondatetime'
						,TransactionId			VARCHAR(50)    '$.transactionid'
						,Username				VARCHAR(50)    '$.username'
						,ValidBet				MONEY		   '$.validbet'
						,Win					MONEY		   '$.win'
					) AS d

				DELETE bt WITH (ROWLOCK, UPDLOCK)
				FROM dbo.bettrans_APIProducts bt	
				WHERE EXISTS (SELECT 1 FROM #bettrans_APIProducts t WHERE bt.TransactionId = t.TransactionId AND bt.TpType = @TpType AND bt.SubItem = @SubItem)
				
				INSERT INTO dbo.bettrans_APIProducts 
				(	
					TpType
					,SubItem
					,Bet
					,BetStatus
					,GamePlatform
					,IsHedgebet
					,ThirdPartyId
					,TransactionbDatetime
					,TransactionId
					,Username
					,ValidBet
					,Win
					,WinlostDate 
					,IBCCustId
				)
				SELECT 
					@TpType   AS TpType
					,@SubItem  AS SubItem
					,k.Bet
					,k.BetStatus
					,k.GamePlatform
					,k.IsHedgebet
					,k.ThirdPartyId
					,k.TransactionbDatetime
					,k.TransactionId
					,k.Username
					,k.ValidBet
					,k.Win
					,k.WinlostDate 
					,m.IBCCustID
				FROM #bettrans_APIProducts k
					INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + k.Username = m.Username

				SELECT @WinlostDate = MIN(WinlostDate) FROM #bettrans_APIProducts

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH

			DROP TABLE #bettrans_APIProducts
		END

		IF @IsErr = 1
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'Please help check data in APIProduct_ImportQueue table with QueueId = ' + CONVERT(NVARCHAR(100), @QueueId)
			RETURN
		END
		ELSE
		BEGIN
			UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
			SET FinishedTime = GETDATE(), WinlostDate = @WinlostDate, LogDesc = @SuccessfullMsg
			WHERE QueueId = @QueueId

			SELECT @LastQueueId = @QueueId

			SELECT @QueueId = NULL, @JsonData = NULL

			IF @QueueIdInput = 0
				SELECT TOP 1 @QueueId = QueueId, @JsonData = JsonData
				FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
				WHERE tpType = @tpType AND SubItem = @SubItem AND QueueId >= @LastQueueId AND JobType = 0 AND FinishedTime IS NULL
				ORDER BY QueueId
		END
	END

	IF @IsErr = 0
	BEGIN
		UPDATE dbo.APIProductSettings WITH (ROWLOCK, UPDLOCK)
		SET SettingValue = CONVERT(VARCHAR(20), @LastQueueId)
		WHERE ProductId = @ProductId AND SettingName = 'LastQueueId'
	END
END
GO