/*<info serverAlias="DBLIC-bodb_3rdProduct,DBBAL-bodb_3rdProduct" executers="" isFunction="0" isNested="1"></info>*/
USE [bodb_3rdProduct]
GO

ALTER PROCEDURE [dbo].[Task_Product3rd_ImportQueue_CheckData_ProcessData]
	@QueueIDInput	BIGINT = 0,
	@ProductID		INT,
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20190401@Percy
	DB: DBLIC.bodb_3rdProduct,DBBAL-bodb_3rdProduct
	Task: Parse xml data for checking data monthly

	Revisions:
		- 20190401@Percy: Initialize SP [RedmineID: #110692]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
		- 20230414@Evan: Update formula agentCommission for new commercial terms [Redmine: #186609]

	Param's Explanation:
		@QueueID: manually import
*/

BEGIN
	SET NOCOUNT ON

	IF @QueueIDInput <> 0
	BEGIN
		IF NOT EXISTS (SELECT ProductID FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue_CheckData WITH (NOLOCK) WHERE QueueID = @QueueIDInput AND ProductID = @ProductID)
		BEGIN
			SELECT	@ErrCode = 100,
					@ErrMsg = 'Input QueueID is not compitable with the product, please check again!'
			RETURN
		END
	END
	ELSE IF @QueueIDInput = 0
	BEGIN
		DELETE bodb_PlaytechCS.dbo.Product3rd_ImportQueue_CheckData WITH (ROWLOCK, UPDLOCK)
		WHERE ProductID = @ProductID AND FinishedTime IS NOT NULL
	END

	DECLARE @QueueID BIGINT = NULL, @XmlData XML, @LogDesc VARCHAR(2000) = NULL, @numOftry TINYINT

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

	DECLARE @currentTime DATETIME, @statisDate DATETIME, @isInvalidUserId BIT
	SELECT  @statisDate = '1970-01-01', @isInvalidUserId = 0

	CREATE TABLE #LicenseeProductTable (LicenseeId INT, LicenseeName VARCHAR(50), CustID INT, CurrencyId INT)

	INSERT INTO #LicenseeProductTable(LicenseeId, LicenseeName, CustID, CurrencyId)
	SELECT l.LicenseeId, l.LicenseeName,c.CustID, c.Currency
	FROM bodb_licensee.dbo.LicenseeCust c WITH(NOLOCK)
		INNER JOIN	bodb_licensee.dbo.Licensees l WITH(NOLOCK) ON c.LicenseeId = l.LicenseeId
		INNER JOIN 	bodb_licensee.dbo.LicenseeProduct3rd p WITH(NOLOCK) ON c.LicenseeId = p.LicenseeId
	WHERE	p.ProductId = 31
	
	DECLARE @Party TABLE (PartyId INT)
	DECLARE @PartyList VARCHAR(4000)
	
	DELETE l 
	FROM #LicenseeProductTable l
		INNER JOIN DBCUST.CUSTDB.dbo.site s WITH (NOLOCK) ON l.LicenseeName = s.Site 
	WHERE s.SiteDBGroupID <> 0

	INSERT INTO @Party(PartyId)
	SELECT DISTINCT FromParty
	FROM bodb_licensee.dbo.OAS_ChargeInfo WITH (NOLOCK)
	WHERE ProductId = 31

	SELECT @PartyList = COALESCE(@PartyList + ',' + CAST(PartyId AS VARCHAR), CAST(PartyId AS VARCHAR))
	FROM @Party
	
	DECLARE @CutoffDate SMALLDATETIME
	SET @CutoffDate = '2023-05-01'

	WHILE
	(
		@QueueIDInput <> 0
		OR EXISTS (SELECT TOP 1 1 FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue_CheckData WITH (NOLOCK) WHERE FinishedTime IS NULL AND ProductID = @ProductID)
	)
	BEGIN
		-- Get XmlData
		IF @QueueIDInput <> 0
			SELECT @QueueID = QueueID, @XmlData = XmlData
			FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue_CheckData WITH (NOLOCK)
			WHERE QueueID = @QueueIDInput AND ProductID = @ProductID
		ELSE
			SELECT TOP 1 @QueueID = QueueID, @XmlData = XmlData
			FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue_CheckData WITH (NOLOCK)
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
						TRUNCATE TABLE #tmpSum_winloss_Exchange

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

						

						-- delete wrong data
						DELETE #tmpSum_winloss_Exchange
						WHERE ISNUMERIC(custId + '.e0') = 0

						IF @@ROWCOUNT <> 0
							SELECT @isInvalidUserId = 1

						IF @isInvalidUserId = 1
						BEGIN
							SELECT	@ErrCode = 100,
									@ErrMsg = CASE WHEN @isInvalidUserId = 1 THEN 'Wrong format userId' ELSE '' END
							BREAK
						END

						UPDATE t
						SET t.agentCommission =CASE WHEN t.settledDate >= @CutoffDate THEN (1 - ISNULL(cc.Rate, ci.DI_Rate)) * t.commission * -1 ELSE t.agentCommission END
						FROM  #tmpSum_winloss_Exchange t
							INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON t.custId = c.custid
							INNER JOIN #LicenseeProductTable l ON c.recommend = l.custid AND c.currency = l.currencyid
							CROSS APPLY(
								SELECT TOP 1 ChargeId, PartyId, LicenseeId, ChargeType, DI_Rate, FromDate, ToDate
								FROM 
								(
									SELECT ChargeId, PartyId, LicenseeId, ChargeType, DI_Rate, FromDate, ToDate
									FROM bodb_licensee.dbo.LA_f_ChargeInfo
									(@PartyList, CONVERT(VARCHAR(10), DATEADD(MONTH, DATEDIFF(MONTH, 0, t.settledDate) -1, 0), 112) , CONVERT(VARCHAR(10), t.settledDate, 112), 'BX', 'OA', 1) ch  
									WHERE  t.settledDate BETWEEN ch.FromDate AND ch.ToDate AND ch.ProductId = 31 AND LicenseeId = l.LicenseeID AND DI_Rate > 0 AND ChargeType IN (1,12)
									UNION ALL
									SELECT ChargeId, PartyId, LicenseeId, ChargeType, DI_Rate, FromDate, ToDate 
									FROM bodb_licensee.dbo.LA_f_GetChargeInfoWithTrialTime
									(@PartyList, CONVERT(VARCHAR(10), DATEADD(MONTH, DATEDIFF(MONTH, 0, t.settledDate) -1, 0), 112) , CONVERT(VARCHAR(10), t.settledDate, 112), 'BX', 'OA', 1) ch  
									WHERE  t.settledDate BETWEEN ch.FromDate AND ch.ToDate AND ch.ProductId = 31 AND LicenseeId = l.LicenseeID AND DI_Rate > 0 AND ChargeType IN (1,12) 
								) AS x
							)  ci 
							LEFT JOIN bodb_Licensee.dbo.LA_ChargeRateByCurrency cc ON cc.ChargeId = ci.ChargeId AND cc.CurrencyID = c.Currency

						-- Import data
						MERGE dbo.Sum_winloss_Exchange_CheckData AS s
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
							);

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
			UPDATE bodb_PlaytechCS.dbo.Product3rd_ImportQueue_CheckData WITH (ROWLOCK, UPDLOCK)
			SET FinishedTime = CASE WHEN FinishedTime IS NULL THEN CURRENT_TIMESTAMP ELSE FinishedTime END,
				LogDesc = 'Msg="Successfull"'
			WHERE QueueID = @QueueID
		END
		ELSE
		BEGIN
			UPDATE bodb_PlaytechCS.dbo.Product3rd_ImportQueue_CheckData WITH (ROWLOCK, UPDLOCK)
			SET LogDesc = 'Msg="' + @ErrMsg + '"'
			WHERE QueueID = @QueueID

			SELECT @ErrMsg = 'QueueID = ' + CONVERT(VARCHAR(20), @QueueID) + ', ProductID = 31, MsgError = ' + @ErrMsg
		END

		IF @QueueIDInput <> 0
			BREAK

		IF @ErrCode <> 0
			RETURN
	END

	DROP TABLE #tmpSum_winloss_Exchange
END
GO