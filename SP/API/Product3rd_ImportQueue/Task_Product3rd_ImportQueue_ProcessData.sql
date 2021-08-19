/*<info serverAlias="DBLIC-bodb_3rdProduct,DBBAL-bodb_3rdProduct" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_Product3rd_ImportQueue_ProcessData]
	@QueueIDInput	BIGINT = 0,
	@ProductID		INT,
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created by Percy
	Date: 2017-11-17
	DB: DBLIC.bodb_3rdProduct
	Task:

	Revisions:
		- 20171117@Percy: Initialize SP [RedmineID: #86477]
		- 20180507@Percy: Update condition of resettledDate for case re-import manually [RedmineID: #94555]
		- 20190401@Percy: Update JobType correctly [RedmineID: #110692]
		- 20200818@Percy: Integrate Fancy Bet [RedmineID: #138524]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]

	Param's Explanation:
		@QueueID: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT ProductID FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND ProductID = @ProductID)
		BEGIN
			SELECT	@ErrCode = 100,
					@ErrMsg = 'Input QueueID is not compitable with the product, please check again!'
			RETURN
		END
	END

	DECLARE @QueueID BIGINT = NULL, @XmlData XML, @LogDesc VARCHAR(2000) = NULL, @JobType TINYINT, @IsForceUpdate BIT,
		@numOftry TINYINT, @startDate DATETIME, @endDate DATETIME

	-- Bettrans_exchange
	CREATE TABLE #tmpBettrans_Exchange
	(
		site			TINYINT NULL,
		currencyType	TINYINT NULL,
		eventType		INT NULL,
		eventTypeName	VARCHAR(50) NULL,
		eventName		VARCHAR(500) NULL,
		eventID			INT NULL,
		marketName		VARCHAR(500) NULL,
		marketID		VARCHAR(50) NULL,
		selectionName	VARCHAR(100) NULL,
		selectionID		INT NULL,
		matchType		VARCHAR(10) NULL,
		betID			BIGINT NOT NULL,
		betPlaced		DATETIME NULL,
		ip				VARCHAR(15) NULL,
		matchOddsReq	SMALLMONEY NULL,
		unMatchAmount	MONEY NULL,
		reduction		MONEY NULL,
		userId			VARCHAR(16) NOT NULL,
		extension1		CHAR(7) NULL,
		matchStake		MONEY NULL,
		matchAvgOdds	SMALLMONEY NULL,
		profitLoss		MONEY NULL,
		dateMatched		DATETIME NULL,
		betstatus		VARCHAR(15) NULL,
		categoryType	SMALLINT NULL,
		fancyBetRuns	MONEY NULL,
		-- for BettransM_Exchange
		betTaken		DATETIME NULL,
		txStake			MONEY NULL,
		txOddsMatched	SMALLMONEY NULL,
		actualOdds		SMALLMONEY NULL,
		txFancyBetRuns	MONEY NULL,
		-- for checking existing custid
		custId			VARCHAR(16) NULL,
		-- for group betId
		groupRow		INT NULl
	)

	-- sum_winloss_exchange
	CREATE TABLE #tmpSum_winloss_Exchange
	(
		userId			VARCHAR(16) NOT NULL,
		agentId			VARCHAR(16) NULL,
		eventTypeName	VARCHAR(50) NULL,
		eventName		VARCHAR(500) NULL,
		eventID			INT NOT NULL,
		marketName		VARCHAR(500) NULL,
		marketID		VARCHAR(50) NOT NULL,
		startTime		DATETIME NULL,
		settledDate		DATETIME NOT NULL,
		profitLoss		MONEY NULL,
		marketTotal		MONEY NULL,
		commission		MONEY NULL,
		agentCommission MONEY NULL,
		stakeTotal		MONEY NULL,
		resettledDate	DATETIME NULL,
		-- for checking existing custid
		custId			VARCHAR(16) NULL
	)

	-- transaction detail for Resettled Summary Job (JobType = 3)
	CREATE TABLE #tmpSum_winloss_Exchange_Detail
	(
		userId			VARCHAR(16) NOT NULL,
		eventID			INT NOT NULL,
		marketID		VARCHAR(50) NOT NULL,
		resettledDate	DATETIME NULL,
		betId			BIGINT NOT NULL,
		selectionName	VARCHAR(100) NULL,
		txOddsMatched	SMALLMONEY NULL,
		txStake			MONEY NULL,
		matchType		VARCHAR(10) NULL,
		betPlaced		DATETIME NULL,
		profitLoss		MONEY NULL,
		betstatus		VARCHAR(15) NULL,
		-- for checking existing custid
		custId			VARCHAR(16) NULL,
		-- for group userId, eventId, marketId
		groupRow		INT
	)

	DECLARE @updated_betId TABLE (betId BIGINT)
	DECLARE @updated_userId TABLE
	(
		userId VARCHAR(16), eventId INT, marketId VARCHAR(50),
		SettledDate DATETIME, stakeTotal MONEY, MarketTotal MONEY
		--PRIMARY KEY (userId, eventId, marketId, SettledDate)
	)

	CREATE TABLE #tempId (Id BIGINT)

	DECLARE @currentTime DATETIME, @statisDate DATETIME, @isInvalidUserId BIT, @isDuplicatedBetId BIT, @winlostdatelist NVARCHAR(MAX)
	SELECT  @statisDate = '1970-01-01', @isInvalidUserId = 0, @isDuplicatedBetId = 0

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT TOP 1 1 FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (NOLOCK) WHERE FinishedTime IS NULL AND ProductID = @ProductID)
	)
	BEGIN
		-- Get XmlData
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData, @JobType = JobType, @startDate = StartDate, @endDate = endDate, @IsForceUpdate = IsForceUpdate
			FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND ProductID = @ProductID
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData, @JobType = JobType, @startDate = StartDate, @endDate = endDate, @IsForceUpdate = IsForceUpdate
			FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (NOLOCK)
			WHERE FinishedTime IS NULL AND ProductID = @ProductID
			ORDER BY QueueID ASC

		-- Parse XmlData and Import data into DB
		-- try 3 times
		SELECT @numOftry = 0

		WHILE (1 = 1)
		BEGIN
			IF @ProductID = 31 -- Exchange
			BEGIN
				/*
					@JobType:
						1: Settled Summary
						2: Settled Bet History
						3: Resettled Summary
						4: Resettled Bet History
						5: Bet History
						6: Settled Summary for whole month - for checking data
				*/
				BEGIN TRY
					/* Sum_winloss_Exchange */
					IF @JobType IN (1,3)
					BEGIN
						TRUNCATE TABLE #tmpSum_winloss_Exchange
						TRUNCATE TABLE #tmpSum_winloss_Exchange_Detail
						DELETE @updated_userId

						INSERT INTO #tmpSum_winloss_Exchange
						(
							userId,
							agentId,
							eventTypeName,
							eventName,
							eventId,
							marketName,
							marketId,
							startTime,
							settledDate,
							profitLoss,
							marketTotal,
							commission,
							agentCommission,
							stakeTotal,
							resettledDate,
							custId
						)
						SELECT
							t.c.value('@userId', 'VARCHAR(16)') AS userId,
							t.c.value('@agentId', 'VARCHAR(16)') AS agentId,
							t.c.value('@eventTypeName', 'VARCHAR(50)') AS eventTypeName,
							t.c.value('@eventName', 'VARCHAR(500)') AS eventName,
							t.c.value('@eventId', 'INT') AS eventId,
							t.c.value('@marketName', 'VARCHAR(500)') AS marketName,
							t.c.value('@marketId', 'VARCHAR(50)') AS marketId,
							t.c.value('@startTime', 'DATETIME') AS startTime,
							t.c.value('@settledDate', 'DATETIME') AS settledDate,
							t.c.value('@profitLoss', 'MONEY') AS profitLoss,
							t.c.value('@marketTotal', 'MONEY') AS marketTotal,
							t.c.value('@commission', 'MONEY') AS commission,
							t.c.value('@agentCommission', 'MONEY') AS agentCommission,
							t.c.value('@stakeTotal', 'MONEY') AS stakeTotal,
							NULLIF(t.c.value('@resettledDate', 'DATETIME'), '') AS resettledDate,
							REPLACE(REPLACE(REPLACE(t.c.value('@userId', 'VARCHAR(16)'), 'poc', ''), 'sit', ''), 'uat', '') AS custID
						FROM @XmlData.nodes('TransList/Transaction') t (c)
						OPTION (OPTIMIZE FOR (@XmlData = NULL))

						-- Resettled Summary (JobType = 3)
						IF @JobType = 3
						BEGIN
							INSERT INTO #tmpSum_winloss_Exchange_Detail
							(
								userId,
								eventID,
								marketID,
								resettledDate,
								betId,
								selectionName,
								txOddsMatched,
								txStake,
								matchType,
								betPlaced,
								profitLoss,
								betstatus,
								custId,
								groupRow
							)
							SELECT
								t.c.value('@userId', 'VARCHAR(16)') AS userId,
								t.c.value('@eventId', 'INT') AS eventId,
								t.c.value('@marketId', 'VARCHAR(50)') AS marketId,
								NULLIF(t.c.value('@resettledDate', 'DATETIME'), '') AS resettledDate,
								t1.c1.value('@betId', 'BIGINT') AS betId,
								t1.c1.value('@selectionName', 'VARCHAR(100)') AS selectionName,
								t1.c1.value('@txOddsMatched', 'SMALLMONEY') AS txOddsMatched,
								t1.c1.value('@txStake', 'MONEY') AS txStake,
								t1.c1.value('@matchType', 'VARCHAR(10)') AS matchType,
								t1.c1.value('@placed', 'DATETIME') AS betPlaced, -- placed --> betPlaced
								t1.c1.value('@txLiability', 'MONEY') AS profixLoss, -- txLiability --> profixLoss
								t1.c1.value('@betStatus', 'VARCHAR(15)') AS betStatus,
								REPLACE(REPLACE(REPLACE(t.c.value('@userId', 'VARCHAR(16)'), 'poc', ''), 'sit', ''), 'uat', '') AS custID,
								-- group by t.c
								DENSE_RANK() OVER(ORDER BY t.c) AS groupRow
							FROM @XmlData.nodes('TransList/Transaction') t (c)
								OUTER APPLY t.c.nodes('TransactionDetail') t1 (c1)
						END

						-- delete wrong data
						DELETE #tmpSum_winloss_Exchange
						WHERE ISNUMERIC(custId + '.e0') = 0

						IF @@ROWCOUNT <> 0
							SELECT @isInvalidUserId = 1

						DELETE #tmpSum_winloss_Exchange_Detail
						WHERE ISNUMERIC(custId + '.e0') = 0

						IF @@ROWCOUNT <> 0
							SELECT @isInvalidUserId = 1
						
						-- Detect duplicate betId per userId
						DELETE t
						FROM (
							SELECT *, DENSE_RANK() OVER(PARTITION BY betID ORDER BY groupRow) AS r
							FROM #tmpSum_winloss_Exchange_Detail
						) AS t
						WHERE r > 1

						IF @@ROWCOUNT <> 0
							SELECT @isDuplicatedBetId = 1

						IF @isInvalidUserId = 1 OR @isDuplicatedBetId = 1
						BEGIN
							SELECT	@ErrCode = 100,
									@ErrMsg = CASE WHEN @isInvalidUserId = 1 THEN 'Wrong format userId' ELSE '' END
											+ CASE WHEN @isDuplicatedBetId = 1 THEN ' - Duplicated betId' ELSE '' END

							BREAK
						END

						-- Import data
						IF @JobType IN (1,3)
						BEGIN
							MERGE dbo.Sum_winloss_Exchange AS s
							USING
								(
									SELECT
										t.userId,
										t.agentId,
										t.eventTypeName,
										t.eventName,
										t.eventId,
										t.marketName,
										t.marketId,
										t.startTime,
										t.settledDate,
										t.profitLoss,
										t.marketTotal,
										t.commission,
										t.agentCommission,
										t.stakeTotal,
										t.resettledDate,
										c.CustID,
										c.Currency,
										e.ExVirtualRate
									FROM #tmpSum_winloss_Exchange t
										INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON t.custId = c.custid
										INNER JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON c.currency = e.exchangeid
								)
							AS src
								(
									userId,agentId,eventTypeName,eventName,eventId,marketName,marketId,
									startTime,settledDate,profitLoss,marketTotal,commission,agentCommission,stakeTotal,
									resettledDate,CustID,Currency,ExVirtualRate
								)
								ON s.userId = src.userId AND s.eventID = src.eventId AND s.marketID = src.marketId AND s.settledDate = src.settledDate
							WHEN MATCHED AND ISNULL(s.resettledDate, @statisDate) <= ISNULL(src.resettledDate, @statisDate) THEN
								UPDATE SET
									s.agentId = src.agentId,
									s.eventTypeName = src.eventTypeName,
									s.eventName = src.eventName,
									s.marketName = src.marketName,
									s.startTime = src.startTime,
									s.profitLoss = src.profitLoss,
									s.marketTotal = src.marketTotal,
									s.commission = src.commission,
									s.agentCommission = src.agentCommission,
									s.stakeTotal = src.stakeTotal,
									s.resettledDate = src.resettledDate,
									s.CustID = src.CustID,
									s.Currency = src.Currency,
									s.ExVirtualRate = src.ExVirtualRate
							WHEN NOT MATCHED THEN
								INSERT
								(
									userId,agentId,eventTypeName,eventName,eventId,marketName,marketId,
									startTime,settledDate,profitLoss,marketTotal,commission,agentCommission,stakeTotal,
									resettledDate,CustID,Currency,ExVirtualRate
								)
								VALUES
								(
									src.userId,src.agentId,src.eventTypeName,src.eventName,src.eventId,src.marketName,src.marketId,
									src.startTime,src.settledDate,src.profitLoss,src.marketTotal,src.commission,src.agentCommission,src.stakeTotal,
									src.resettledDate,src.CustID,src.Currency,src.ExVirtualRate
								)
							OUTPUT INSERTED.userId, INSERTED.eventID, INSERTED.marketID, INSERTED.settledDate, INSERTED.stakeTotal, INSERTED.marketTotal
								INTO @updated_userId (userId, eventId, marketId, SettledDate, stakeTotal, MarketTotal);
						END

						IF @JobType = 3
						BEGIN
							MERGE dbo.Bettrans_Exchange AS s
							USING
								(
									SELECT d.betId, d.userId, d.eventId, d.marketId,
										SUM(d.txStake) AS txStake,
										SUM(d.profitLoss) AS profitLoss
									FROM #tmpSum_winloss_Exchange_Detail d
										INNER JOIN @updated_userId u ON d.userId = u.userId AND d.eventId = u.eventId AND d.marketId = u.marketId
									GROUP BY d.betId, d.userId, d.eventId, d.marketId
								)
							AS src
								(
									betId,userId,eventId,marketId,txStake,profitLoss
								)
								ON s.betId = src.betId
							WHEN MATCHED THEN
								UPDATE SET
									s.matchStake = src.txStake,
									s.profitLoss = src.profitLoss
							WHEN NOT MATCHED THEN
								INSERT
								(
									userId,eventID,marketID,betId,profitLoss
								)
								VALUES
								(
									src.userId,src.eventID,src.marketID,src.betId,src.profitLoss
								);

							SELECT @currentTime = GETDATE()
							
							INSERT INTO bodb_PlaytechCS.dbo.Product3rd_ResettledBetHistory (SettledDate, UserId, EventId, marketID, ProductId, CheckInTime, Status)
							SELECT u.SettledDate, u.userId, u.eventId, u.marketId, 31, @currentTime, 'waiting'
							FROM @updated_userId u
								LEFT JOIN (
									SELECT userId, eventID, marketID, SUM(ISNULL(profitLoss, 0)) AS profitLoss, SUM(ISNULL(matchStake, 0)) AS matchStake
									FROM dbo.Bettrans_Exchange WITH (NOLOCK)
									WHERE betstatus = 'Settled'
									GROUP BY userId, eventID, marketID
								) AS b ON u.userId = b.userId AND u.eventId = b.eventID AND u.marketId = b.marketID
							WHERE ABS(ISNULL(u.MarketTotal, 0) - ISNULL(b.ProfitLoss, 0)) > 0.01
								OR ABS(ISNULL(u.stakeTotal, 0) - ISNULL(b.matchStake, 0)) > 0.01
						END
					END
					/* Bettrans_Exchange, BettransM_Exchange */
					ELSE IF @JobType IN (2)
					BEGIN
						TRUNCATE TABLE #tmpBettrans_Exchange
						DELETE @updated_betId

						INSERT INTO #tmpBettrans_Exchange
						(
							site,
							currencyType,
							eventType,
							eventTypeName,
							eventName,
							eventID,
							marketName,
							marketID,
							selectionName,
							selectionID,
							matchType,
							betID,
							betPlaced,
							ip,
							matchOddsReq,
							unMatchAmount,
							reduction,
							userId,
							extension1,
							matchStake,
							matchAvgOdds,
							profitLoss,
							dateMatched,
							betstatus,
							categoryType,
							fancyBetRuns,
							betTaken,
							txStake,
							txOddsMatched,
							actualOdds,
							txFancyBetRuns,
							custid,
							groupRow
						)
						SELECT
							t.c.value('@site', 'TINYINT') AS site,
							t.c.value('@currencyType', 'TINYINT') AS currencyType,
							t.c.value('@eventType', 'INT') AS eventType,
							t.c.value('@eventTypeName', 'VARCHAR(50)') AS eventTypeName,
							t.c.value('@eventName', 'VARCHAR(500)') AS eventName,
							t.c.value('@eventId', 'INT') AS eventId,
							t.c.value('@marketName', 'VARCHAR(500)') AS marketName,
							t.c.value('@marketId', 'VARCHAR(50)') AS marketId,
							t.c.value('@selectionName', 'VARCHAR(100)') AS selectionName,
							t.c.value('@selectionID', 'INT') AS selectionID,
							t.c.value('@matchType', 'VARCHAR(10)') AS matchType,
							t.c.value('@betId', 'BIGINT') AS betId,
							t.c.value('@betPlaced', 'DATETIME') AS betPlaced,
							t.c.value('@ip', 'VARCHAR(15)') AS ip,
							t.c.value('@matchOddsReq', 'SMALLMONEY') AS matchOddsReq,
							t.c.value('@unMatchAmount', 'MONEY') AS unMatchAmount,
							t.c.value('@reduction', 'MONEY') AS reduction,
							t.c.value('@userId', 'VARCHAR(16)') AS userId,
							t.c.value('@extension1', 'CHAR(7)') AS extension1,
							t.c.value('@matchStake', 'MONEY') AS matchStake,
							t.c.value('@matchAvgOdds', 'SMALLMONEY') AS matchAvgOdds,
							t.c.value('@profitLoss', 'MONEY') AS profitLoss,
							NULLIF(t.c.value('@dateMatched', 'DATETIME'), '') AS dateMatched,
							t.c.value('@betstatus', 'VARCHAR(15)') AS betstatus,
							t.c.value('@categoryType', 'SMALLINT') AS categoryType,
							t.c.value('@fancyBetRuns', 'MONEY') AS fancyBetRuns,
							-- for detail
							t1.c1.value('@betTaken', 'DATETIME') AS betTaken,
							t1.c1.value('@txStake', 'MONEY') AS txStake,
							t1.c1.value('@txOddsMatched', 'SMALLMONEY') AS txOddsMatched,
							t1.c1.value('@actualOdds', 'SMALLMONEY') AS actualOdds,
							t1.c1.value('@txFancyBetRuns', 'MONEY') AS txFancyBetRuns,
							REPLACE(REPLACE(REPLACE(t.c.value('@userId', 'VARCHAR(16)'), 'poc', ''), 'sit', ''), 'uat', '') AS custID,
							-- group by t.c
							DENSE_RANK() OVER(ORDER BY t.c) AS groupRow
						FROM @XmlData.nodes('TransList/Transaction') AS t (c)
							OUTER APPLY t.c.nodes('TransactionDetail') AS t1 (c1)
						OPTION (OPTIMIZE FOR (@XmlData = NULL))

						-- delete wrong data
						DELETE #tmpBettrans_Exchange
						WHERE ISNUMERIC(custId + '.e0') = 0

						IF @@ROWCOUNT <> 0
							SELECT @isInvalidUserId = 1

						-- Detect duplicate betId per userId
						DELETE t
						FROM (
							SELECT DENSE_RANK() OVER(PARTITION BY betID ORDER BY groupRow) AS r
							FROM #tmpBettrans_Exchange
						) AS t
						WHERE r > 1

						IF @@ROWCOUNT <> 0
							SELECT @isDuplicatedBetId = 1
						
						IF @isInvalidUserId = 1 OR @isDuplicatedBetId = 1
						BEGIN
							SELECT	@ErrCode = 100,
									@ErrMsg = CASE WHEN @isInvalidUserId = 1 THEN 'Wrong format userId' ELSE '' END
											+ CASE WHEN @isDuplicatedBetId = 1 THEN ' - Duplicated betId' ELSE '' END

							BREAK
						END

						-- import data
						MERGE dbo.Bettrans_Exchange AS s
						USING
							(
								SELECT
									site,currencyType,eventType,eventTypeName,eventName,eventID,marketName,marketID,
									selectionName,selectionID,matchType,betID,betPlaced,ip,matchOddsReq,
									unMatchAmount,reduction,userId,extension1,
									matchStake,matchAvgOdds,profitLoss,dateMatched,betstatus,categoryType,fancyBetRuns
								FROM
								(
									SELECT *, ROW_NUMBER() OVER(PARTITION BY groupRow ORDER BY (SELECT NULL)) AS rownum
									FROM #tmpBettrans_Exchange e
									WHERE EXISTS (SELECT 1 FROM bodb02.dbo.custInfo c WITH (NOLOCK) WHERE e.custId = c.custid)
								) AS A
								WHERE A.rownum = 1
							)
						AS src
							(
								site,currencyType,eventType,eventTypeName,eventName,eventID,marketName,marketID,
								selectionName,selectionID,matchType,betID,betPlaced,ip,matchOddsReq,
								unMatchAmount,reduction,userId,extension1,
								matchStake,matchAvgOdds,profitLoss,dateMatched,betstatus,categoryType,fancyBetRuns
							)
							ON s.betId = src.betId
						WHEN MATCHED THEN
							UPDATE SET
								s.site = src.site,
								s.currencyType = src.currencyType,
								s.eventType = src.eventType,
								s.eventTypeName = src.eventTypeName,
								s.eventName = src.eventName,
								s.eventID = src.eventID,
								s.marketName = src.marketName,
								s.marketID = src.marketID,
								s.selectionName = src.selectionName,
								s.selectionID = src.selectionID,
								s.matchType = src.matchType,
								s.betID = src.betID,
								s.betPlaced = src.betPlaced,
								s.ip = src.ip,
								s.matchOddsReq = src.matchOddsReq,
								s.unMatchAmount = src.unMatchAmount,
								s.reduction = src.reduction,
								s.userId = src.userId,
								s.extension1 = src.extension1,
								s.matchStake = src.matchStake,
								s.matchAvgOdds = src.matchAvgOdds,
								s.profitLoss = src.profitLoss,
								s.dateMatched = src.dateMatched,
								s.betstatus = src.betstatus,
								s.categoryType = src.categoryType,
								s.fancyBetRuns = src.fancyBetRuns,
								s.APIEndDate = CASE WHEN @JobType = 2 THEN @endDate ELSE NULL END
						WHEN NOT MATCHED THEN
							INSERT
							(
								site,currencyType,eventType,eventTypeName,eventName,eventID,marketName,marketID,
								selectionName,selectionID,matchType,betID,betPlaced,ip,matchOddsReq,
								unMatchAmount,reduction,userId,extension1,
								matchStake,matchAvgOdds,profitLoss,dateMatched,betstatus,categoryType,fancyBetRuns,APIEndDate
							)
							VALUES
							(
								src.site,src.currencyType,src.eventType,src.eventTypeName,src.eventName,src.eventID,src.marketName,src.marketID,
								src.selectionName,src.selectionID,src.matchType,src.betID,src.betPlaced,src.ip,src.matchOddsReq,
								src.unMatchAmount,src.reduction,src.userId,src.extension1,
								src.matchStake,src.matchAvgOdds,src.profitLoss,src.dateMatched,src.betstatus,categoryType,fancyBetRuns,CASE WHEN @JobType = 2 THEN @endDate ELSE NULL END
							)
						OUTPUT INSERTED.betID INTO @updated_betId (betId);

						DELETE bm
						FROM dbo.BettransM_Exchange bm WITH (ROWLOCK, UPDLOCK)
						WHERE EXISTS (
								SELECT 1
								FROM @updated_betId b
									INNER JOIN #tmpBettrans_Exchange tmp ON b.betId = tmp.betId
								WHERE bm.betID = b.betId
							)
						
						INSERT INTO dbo.BettransM_Exchange
						(
							betId,betTaken,txStake,txOddsMatched,actualOdds,txFancyBetRuns
						)
						SELECT betId,betTaken,txStake,txOddsMatched,actualOdds,txFancyBetRuns
						FROM #tmpBettrans_Exchange tmp
						WHERE EXISTS (SELECT 1 FROM @updated_betId b WHERE tmp.betID = b.betId)

						IF @JobType = 2 AND @IsForceUpdate = 1
						BEGIN
							DECLARE @Ids VARCHAR(MAX)

							INSERT INTO #tempId (Id)
							SELECT DISTINCT h.Id
							FROM bodb_PlaytechCS.dbo.Product3rd_ResettledBetHistory h WITH (NOLOCK)
								INNER JOIN dbo.Bettrans_Exchange b WITH (NOLOCK) ON h.UserId = b.userId AND h.EventId = b.eventID AND h.MarketId = b.marketID
								INNER JOIN @updated_betId u ON b.betID = u.betId
							WHERE h.FinishedTime IS NULL
								AND h.Status = 'running'
								AND h.ProductId = @ProductId

							SELECT @Ids = STUFF(
								(SELECT ',' + CONVERT(VARCHAR(20), Id) FROM #tempId FOR XML PATH (''))
								, 1, 1, '')
							FROM #tempId

							EXEC bodb_PlaytechCS.dbo.Task_Product3rd_ResettledBetHistory_Upd
								@ProductId	= @ProductId,
								@Ids		= @Ids,
								@Status		= 'Completed',
								@ErrCode	= @ErrCode OUTPUT,
								@ErrMsg		= @ErrMsg OUTPUT

							IF @ErrCode <> 0
								BREAK
						END
					END
					
					-- if parse xml and insert/update data successfully --> break out of while
					BREAK
				END TRY
				BEGIN CATCH
					SELECT @numOftry = @numOftry + 1

					IF @numOftry = 3
					BEGIN
						SELECT	@ErrCode = 101,
								@ErrMsg = ERROR_MESSAGE()
						BREAK
					END
				END CATCH
			END
		END

		-- Update Queue
		IF @ErrCode = 0
		BEGIN
			UPDATE bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (ROWLOCK, UPDLOCK)
			SET FinishedTime = CASE WHEN FinishedTime IS NULL THEN CURRENT_TIMESTAMP ELSE FinishedTime END,
				LogDesc = 'StartDate="' + CONVERT(VARCHAR(20), @startDate, 120) + '",EndDate="' + CONVERT(VARCHAR(20), @endDate, 120) + '",Msg="Successfull"'
			WHERE QueueID = @QueueID
		END
		ELSE
		BEGIN
			UPDATE bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (ROWLOCK, UPDLOCK)
			SET LogDesc = 'StartDate="' + CONVERT(VARCHAR(20), @startDate, 120) + '",EndDate="' + CONVERT(VARCHAR(20), @endDate, 120) + '",Msg="' + @ErrMsg + '"'
			WHERE QueueID = @QueueID

			SELECT @ErrMsg = 'QueueID = ' + CONVERT(VARCHAR(20), @QueueID) + ', ProductID = 31, MsgError = ' + @ErrMsg
		END

		-- Add winlostdate into Product3rd_SummarizedDateHistory
		IF @ErrCode = 0
		BEGIN
			IF EXISTS (SELECT 1 FROM @updated_userId)
			BEGIN
				SELECT @winlostdatelist = COALESCE(@winlostdatelist + ',', '') + CONVERT(VARCHAR(20), WinlostDate, 120)
				FROM (
					SELECT DISTINCT CONVERT(DATE, settledDate) AS WinlostDate FROM @updated_userId
				) AS A
			END
			ELSE IF EXISTS (SELECT 1 FROM @updated_betId)
			BEGIN
				SELECT @winlostdatelist = COALESCE(@winlostdatelist + ',', '') + CONVERT(VARCHAR(20), WinlostDate, 120)
				FROM (
					SELECT DISTINCT CONVERT(DATE, s.settledDate) AS WinlostDate
					FROM @updated_betId b
						INNER JOIN dbo.Bettrans_Exchange bt WITH (NOLOCK) ON b.betId = bt.betID
						INNER JOIN dbo.Sum_winloss_Exchange s WITH (NOLOCK) ON s.userId = bt.userId AND s.eventID = bt.eventId AND s.marketID = bt.marketId
				) AS A
			END

			IF ISNULL(@winlostdatelist, '') <> ''
				EXEC dbo.Product3rd_SummarizedDateHistory_Ins @winlostdatelist = @winlostdatelist
		END

		IF @QueueIDInput <> 0
			BREAK

		IF @ErrCode <> 0
			RETURN
	END

	DROP TABLE #tempId
	DROP TABLE #tmpBettrans_Exchange
	DROP TABLE #tmpSum_winloss_Exchange
	DROP TABLE #tmpSum_winloss_Exchange_Detail
END
GO