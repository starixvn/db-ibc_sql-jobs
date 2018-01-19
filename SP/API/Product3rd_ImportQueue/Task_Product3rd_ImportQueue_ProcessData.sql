/*<info serverAlias="DBLIC-bodb_3rdProduct" executers="" viewers="" isFunction="0" isNested="1"></info>*/
USE [bodb_3rdProduct]
GO

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
		- 20171117@Percy: Initial SP [RedmineID: #86477]

	Param's Explanation:
		@QueueID: manual import
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

	DECLARE @QueueID BIGINT = NULL, @XmlData XML, @LogDesc VARCHAR(2000) = NULL, @JobType TINYINT, @numOftry TINYINT, @startDate DATETIME, @endDate DATETIME

	-- Bettrans_exchange
	CREATE TABLE #tmpBettrans_Exchange
	(
		site			TINYINT NULL,
		currencyType	TINYINT NULL,
		eventType		SMALLINT NULL,
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
		matchAmount		MONEY NULL,
		unMatchAmount	MONEY NULL,
		reduction		MONEY NULL,
		userId			VARCHAR(16) NOT NULL,
		extension1		CHAR(7) NULL,
		matchStake		MONEY NULL,
		matchAvgOdds	SMALLMONEY NULL,
		profitLoss		MONEY NULL,
		dateMatched		DATETIME NULL,
		betstatus		VARCHAR(15) NULL,
		-- for BettransM_Exchange
		betTaken		DATETIME NULL,
		txStake			MONEY NULL,
		txOddsMatched	SMALLMONEY NULL,
		actualOdds		SMALLMONEY NULL,
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
		SettledDate DATETIME, ProfitLoss MONEY
		PRIMARY KEY (userId, eventId, marketId)
	)

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
			SELECT @QueueID = QueueID, @XmlData = XmlData, @JobType = JobType, @startDate = StartDate, @endDate = endDate
			FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData, @JobType = JobType, @startDate = StartDate, @endDate = endDate
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
				BEGIN TRY
					/* Sum_winloss_Exchange */
					IF @JobType IN (1,3,5)
					BEGIN
						TRUNCATE TABLE #tmpSum_winloss_Exchange
						TRUNCATE TABLE #tmpSum_winloss_Exchange_Detail

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
						
						-- filter duplicate data: per (userId, eventId, marketId) on resettledDate
						DELETE t
						FROM
						(
							SELECT *, ROW_NUMBER() OVER(PARTITION BY userId, eventId, marketId ORDER BY resettledDate DESC) AS rownum
							FROM #tmpSum_winloss_Exchange
						) AS t
						WHERE t.rownum > 1

						DELETE t
						FROM
						(
							SELECT *, ROW_NUMBER() OVER(PARTITION BY userId, eventId, marketId ORDER BY resettledDate DESC) AS rownum
							FROM #tmpSum_winloss_Exchange_Detail
						) AS t
						WHERE t.rownum > 1

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
						WHEN MATCHED AND ISNULL(s.resettledDate, @statisDate) < ISNULL(src.resettledDate, @statisDate) THEN
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
						OUTPUT INSERTED.userId, INSERTED.eventID, INSERTED.marketID, INSERTED.settledDate, INSERTED.profitLoss
							INTO @updated_userId (userId, eventId, marketId, SettledDate, ProfitLoss);

						IF @JobType = 3
						BEGIN
							MERGE dbo.Bettrans_Exchange AS s
							USING
								(
									SELECT betId, userId, eventId, marketId,
										SUM(txStake) AS txStake,
										SUM(profitLoss) AS profitLoss
									FROM #tmpSum_winloss_Exchange_Detail
									GROUP BY betId, userId, eventId, marketId
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
									SELECT userId, eventID, marketID, SUM(ISNULL(profitLoss, 0)) AS profitLoss
									FROM dbo.Bettrans_Exchange WITH (NOLOCK)
									GROUP BY userId, eventID, marketID
								) AS b ON u.userId = b.userId AND u.eventId = b.eventID AND u.marketId = b.marketID
							WHERE ISNULL(u.ProfitLoss, 0) <> ISNULL(b.ProfitLoss, 0)
						END
					END
					/* Bettrans_Exchange, BettransM_Exchange */
					ELSE IF @JobType IN (2,4,6)
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
							matchAmount,
							unMatchAmount,
							reduction,
							userId,
							extension1,
							matchStake,
							matchAvgOdds,
							profitLoss,
							dateMatched,
							betstatus,
							betTaken,
							txStake,
							txOddsMatched,
							actualOdds,
							custid,
							groupRow
						)
						SELECT
							t.c.value('@site', 'TINYINT') AS site,
							t.c.value('@currencyType', 'TINYINT') AS currencyType,
							t.c.value('@eventType', 'SMALLINT') AS eventType,
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
							t.c.value('@matchAmount', 'MONEY') AS matchAmount,
							t.c.value('@unMatchAmount', 'MONEY') AS unMatchAmount,
							t.c.value('@reduction', 'MONEY') AS reduction,
							t.c.value('@userId', 'VARCHAR(16)') AS userId,
							t.c.value('@extension1', 'CHAR(7)') AS extension1,
							t.c.value('@matchStake', 'MONEY') AS matchStake,
							t.c.value('@matchAvgOdds', 'SMALLMONEY') AS matchAvgOdds,
							t.c.value('@profitLoss', 'MONEY') AS profitLoss,
							t.c.value('@dateMatched', 'DATETIME') AS dateMatched,
							t.c.value('@betstatus', 'VARCHAR(15)') AS betstatus,
							-- for detail
							t1.c1.value('@betTaken', 'DATETIME') AS betTaken,
							t1.c1.value('@txStake', 'MONEY') AS txStake,
							t1.c1.value('@txOddsMatched', 'SMALLMONEY') AS txOddsMatched,
							t1.c1.value('@actualOdds', 'SMALLMONEY') AS actualOdds,
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
									matchAmount,unMatchAmount,reduction,userId,extension1,
									matchStake,matchAvgOdds,profitLoss,dateMatched,betstatus
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
								matchAmount,unMatchAmount,reduction,userId,extension1,
								matchStake,matchAvgOdds,profitLoss,dateMatched,betstatus
							)
							ON s.betId = src.betId
						WHEN MATCHED AND ((@JobType <> 2) OR (@JobType = 2 AND s.APIEndDate IS NOT NULL AND s.APIEndDate < @endDate)) THEN
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
								s.matchAmount = src.matchAmount,
								s.unMatchAmount = src.unMatchAmount,
								s.reduction = src.reduction,
								s.userId = src.userId,
								s.extension1 = src.extension1,
								s.matchStake = src.matchStake,
								s.matchAvgOdds = src.matchAvgOdds,
								s.profitLoss = src.profitLoss,
								s.dateMatched = src.dateMatched,
								s.betstatus = src.betstatus,
								s.APIEndDate = CASE WHEN @JobType = 2 THEN @endDate ELSE NULL END
						WHEN NOT MATCHED THEN
							INSERT
							(
								site,currencyType,eventType,eventTypeName,eventName,eventID,marketName,marketID,
								selectionName,selectionID,matchType,betID,betPlaced,ip,matchOddsReq,
								matchAmount,unMatchAmount,reduction,userId,extension1,
								matchStake,matchAvgOdds,profitLoss,dateMatched,betstatus,APIEndDate
							)
							VALUES
							(
								src.site,src.currencyType,src.eventType,src.eventTypeName,src.eventName,src.eventID,src.marketName,src.marketID,
								src.selectionName,src.selectionID,src.matchType,src.betID,src.betPlaced,src.ip,src.matchOddsReq,
								src.matchAmount,src.unMatchAmount,src.reduction,src.userId,src.extension1,
								src.matchStake,src.matchAvgOdds,src.profitLoss,src.dateMatched,src.betstatus,CASE WHEN @JobType = 2 THEN @endDate ELSE NULL END
							)
						OUTPUT INSERTED.betID INTO @updated_betId (betId);

						MERGE dbo.BettransM_Exchange AS s
						USING
							(
								SELECT betId,betTaken,txStake,txOddsMatched,actualOdds
								FROM #tmpBettrans_Exchange tmp
								WHERE EXISTS (SELECT 1 FROM @updated_betId b WHERE tmp.betID = b.betId)
							)
						AS src
							(
								betId,betTaken,txStake,txOddsMatched,actualOdds
							)
							ON s.betId = src.betId
						WHEN NOT MATCHED THEN
							INSERT
							(
								betId,betTaken,txStake,txOddsMatched,actualOdds
							)
							VALUES
							(
								src.betId,src.betTaken,src.txStake,src.txOddsMatched,src.actualOdds
							);

						IF @JobType = 4
						BEGIN
							UPDATE bh WITH (ROWLOCK, UPDLOCK)
							SET
								bh.Status = 'completed',
								bh.FinishedTime = GETDATE()
							FROM bodb_PlaytechCS.dbo.Product3rd_ResettledBetHistory bh
							WHERE EXISTS (
								SELECT 1 FROM #tmpBettrans_Exchange tmp
								WHERE bh.UserId = tmp.userId AND bh.EventId = tmp.eventID AND bh.MarketId = tmp.marketID)
							AND bh.Status = 'running'
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
			UPDATE bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (ROWLOCK, UPDLOCK)
			SET FinishedTime = CASE WHEN FinishedTime IS NULL THEN CURRENT_TIMESTAMP ELSE FinishedTime END,
				LogDesc = 'StartDate="' + CONVERT(VARCHAR(20), @startDate, 120) + '",EndDate="' + CONVERT(VARCHAR(20), @endDate, 120) + '",Msg="Successfull"'
			WHERE QueueID = @QueueID
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
		
		-- Case wrong data -- 
		/*
		/* SIT: ignore case, send mail */
		DECLARE @Subject VARCHAR(1000) = '', @Message VARCHAR(MAX) = ''

		IF 1 IN (@isInvalidUserId, @isDuplicatedBetId)
		BEGIN
			SELECT @Subject = 'SQL Server Job System: ''Import data of Exchange API'' had wrong data on ' + @@SERVERNAME
			
			SELECT @Message = 'QueueID = ' + CONVERT(VARCHAR(20), @QueueID)
								+ CASE WHEN @isInvalidUserId = 1 THEN ' - Wrong format userId' ELSE '' END
								+ CASE WHEN @isDuplicatedBetId = 1 THEN ' - Duplicated betId' ELSE '' END
			
			EXEC msdb.dbo.sp_send_dbmail
				@recipients		= 'jamie.dao@starixsoft.com;percy.nguyen@starixsoft.com',
				@subject		= @subject,
				@body			= @Message,
				@body_format	= 'HTML'
		END
		-- End case wrong data
		*/

		IF @QueueIDInput <> 0
			BREAK

		IF @ErrCode <> 0
			RETURN
	END
END
GO