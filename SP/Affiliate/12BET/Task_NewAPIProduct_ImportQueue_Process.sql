/*<info serverAlias="DBAFF12BET-Affiliate_12BET" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[Task_NewAPIProduct_ImportQueue_Process]
	@ProductId		INT,
	@QueueIdInput	INT = 0, -- manually import
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20221117@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Import Data Job - Parse xml data from Queue by Product

	Revisions:
		- 20221117@Malcolm: Initialize SP [RedmineID: #180311]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @QueueId BIGINT, @XmlData XML, @WinlostDate SMALLDATETIME, @LastQueueId BIGINT, @MaxWinlostDate SMALLDATETIME, @SuccessfullMsg NVARCHAR(200) = 'Successfully'
		,@StatusOfAPI VARCHAR(50) = '', @TpType INT = -1, @SubItem VARCHAR(200) = '', @TimeZone INT, @GMTData INT = 8

	DECLARE @Exchange TABLE (ExchangeDate SMALLDATETIME, ExchangeId INT, Currency NVARCHAR(50), ExRate FLOAT, AffExRate FLOAT)
	DECLARE @tmpWinlostDate TABLE (winlostdate SMALLDATETIME)

	SELECT @SubItem = s.SubItem, @TpType = s.tpType FROM dbo.APIProductMappingSettings s WITH(NOLOCK) WHERE s.ProductId = @ProductId 

	SELECT @TimeZone = SettingValue FROM dbo.APIProductSettings WITH(NOLOCK) WHERE ProductId = @ProductId AND SettingName = 'TimeZone' 

	IF ISNULL(@tpType, -1) = -1
		RETURN

	IF @TimeZone IS NULL
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Missing settings for Timezone, @ProductId = ' + CONVERT(VARCHAR(20), @ProductId)
		RETURN
	END

	-- Manually import
	IF @QueueIdInput <> 0
	BEGIN
		SELECT @QueueId = QueueId, @XmlData = XmlData
		FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
		WHERE tpType = @tpType AND SubItem = @SubItem AND JobType = 0 AND QueueId = @QueueIdInput
	END
	ELSE
	BEGIN
		SELECT @LastQueueId = CONVERT(BIGINT, SettingValue)
		FROM dbo.APIProductSettings WITH (NOLOCK)
		WHERE ProductId = @ProductId AND SettingName = 'LastQueueId'

		SELECT TOP 1 @QueueId = QueueId, @XmlData = XmlData
		FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
		WHERE tpType = @tpType AND SubItem = @SubItem AND QueueId >= @LastQueueId AND JobType = 0 AND FinishedTime IS NULL
		ORDER BY QueueId
	END

	DECLARE @IsErr BIT = 1
	
	WHILE @XmlData IS NOT NULL
	BEGIN
		BEGIN
			CREATE TABLE #bettrans_APIProducts
			(
				Bet						MONEY
				,BetStatus				INT
				,DataInfo				VARCHAR(200)
				,GamePlatform			VARCHAR(200)
				,IsHedgebet				BIT
				,ThirdPartyId			INT
				,TransactionbDatetime	DATETIME
				,TransactionId			BIGINT
				,Username				VARCHAR(500)
				,ValidBet				MONEY
				,Win					MONEY
				,WinlostDate			SMALLDATETIME
			)

			BEGIN TRY
				INSERT INTO #bettrans_APIProducts 
				(
					Bet
					,BetStatus
					,DataInfo
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
				SELECT	t.c.value('(Bet/text())[1]', 'MONEY') AS Bet,
						t.c.value('(BetStatus/text())[1]', 'INT') AS BetStatus,
						t.c.value('(DataInfo/text())[1]', 'VARCHAR(200)') AS DataInfo,
						t.c.value('(GamePlatform/text())[1]', 'VARCHAR(200)') AS GamePlatform,
						t.c.value('(IsHedgebet/text())[1]', 'BIT') AS IsHedgebet,		
						t.c.value('(ThirdPartyId/text())[1]', 'INT') AS ThirdPartyId,	
						t.c.value('(TransactionbDatetime/text())[1]', 'DATETIME') AS TransactionbDatetime,	
						t.c.value('(TransactionId/text())[1]', 'BIGINT') AS TransactionId,	
						t.c.value('(Username/text())[1]', 'VARCHAR(500)') AS Username,	
						t.c.value('(ValidBet/text())[1]', 'MONEY') AS ValidBet,	
						t.c.value('(Win/text())[1]', 'MONEY') AS Win,	
					    CONVERT(DATE, DATEADD(HOUR, @TimeZone - @GMTData, t.c.value('(TransactionbDatetime/text())[1]', 'SMALLDATETIME'))) AS WinlostDate 
				FROM @XmlData.nodes('root/item') AS t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				DELETE bt WITH (ROWLOCK, UPDLOCK)
				FROM dbo.bettrans_APIProducts bt	
				WHERE EXISTS (SELECT 1 FROM #bettrans_APIProducts t WHERE bt.TransactionId = t.TransactionId AND bt.TpType = @TpType AND bt.SubItem = @SubItem)
				
				INSERT INTO dbo.bettrans_APIProducts 
				(	
					TpType
					,SubItem
					,Bet
					,BetStatus
					,DataInfo
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
					,k.DataInfo
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
				SET ProductId = @ProductId, FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
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
			SET ProductId = @ProductId, FinishedTime = GETDATE(), WinlostDate = @WinlostDate, LogDesc = @SuccessfullMsg
			WHERE QueueId = @QueueId

			SELECT @LastQueueId = @QueueId

			SELECT @QueueId = NULL, @XmlData = NULL

			IF @QueueIdInput = 0
				SELECT TOP 1 @QueueId = QueueId, @XmlData = XmlData
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