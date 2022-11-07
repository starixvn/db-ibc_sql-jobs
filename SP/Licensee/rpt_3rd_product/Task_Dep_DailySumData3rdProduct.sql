/*<info serverAlias="DBTXN-bodb02" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Task_Dep_DailySumData3rdProduct
	@WinlostDate	SMALLDATETIME
	,@ProductIds	VARCHAR(MAX)
AS
/*
	Created by: 20150601@Patrick
	Task: #36263 - Daily summary data 3rd product
	DB: DBTXN.bodb02

	Revisions:
		- 20171213@Sophia: Integrate CitiBet Exchange Products [Redmine: #86640]
		- 20180119@Sophia: Check data exchange have been existed before update the Flag
		- 20180223@Sophia: Change betform = 'd' for Exchange [Redmine: #91014]
		- 20181003@Percy: Integrate GoldDeluxe Tip [RedmineID: #70177]
		- 20200108@Percy: Support billing terms by product & currency instead of product only [RedmineID: #120005]
		- 20200407@Percy: Add @ProductIds to support input product list [RedmineID: #131885]
		- 20210219@Percy: Change code get MBBU date [RedmineID: #150327]
		- 20220721@Evan: Integrate new transid [Redmine: #175640]
		- 20220724@Evan: LAP - Scale out DBTrans phase 1 - classify data between SiteDB & CentralDB [Redmine: #175297]
		- 20221104@Sol: Deposit - AWS - Modify jobs of separated wallet - Move columns setting to new table - [RedmineID: #176479]

	Format for transdesc: 
		--AGC Betting - Transfer back to Sportsbook
		--AGC Adjustment - Date: 2015-05-26
	
*/ 
BEGIN
	SET NOCOUNT ON
	--@WinlostDate > CurrentDate
	IF @WinlostDate > GETDATE()
	BEGIN
		--PRINT('Can''t process data.')
		RETURN
	END

	CREATE TABLE #LicenseeProductTable (RowId INT IDENTITY(1,1), LicenseeId INT, LicenseeName VARCHAR(50), CurrencyId TINYINT, ProductId TINYINT)
	CREATE TABLE #3rdData (WinlostDate SMALLDATETIME, Stake MONEY, Actual_Stake MONEY, Winlost MONEY, CurrencyId TINYINT, Bettype SMALLINT, PlayerComm MONEY DEFAULT (0), Comm MONEY DEFAULT (0))
	CREATE TABLE #ChargeRate (ChargeId INT, PartyId INT, LicenseeId INT, ProductId INT, ChargeType TINYINT, Rate MONEY, FromDate SMALLDATETIME, ToDate SMALLDATETIME)
	CREATE TABLE #ChargeRateByCurrency (ChargeId INT, CurrencyId INT, Rate MONEY)

	DECLARE @LicenseeTable TABLE (RowId INT IDENTITY(1,1), LicenseeId INT, LicenseeName VARCHAR(50), CurrencyId TINYINT)
	DECLARE @DataTmp TABLE (RowId INT, CurrencyId TINYINT, Bettype SMALLINT)
	DECLARE @BalanceUpTable TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	DECLARE @Party TABLE (PartyId INT)

	DECLARE @RowId INT, @LicenseeName VARCHAR(50), @CurrencyId TINYINT, @ProductId TINYINT
		, @SqlQueryFor3rd VARCHAR(8000), @CustDummyId INT, @SqlQueryChargeRate VARCHAR(8000)
		, @RefNo BIGINT, @SqlQuery VARCHAR(8000), @ExchangeRate FLOAT
		, @LicenseeId INT, @PartyList VARCHAR(4000), @BettingIndicator VARCHAR(125), @ProductCodeList VARCHAR(1000)
		, @MoveBetsDay SMALLDATETIME, @TransId BIGINT
	
	--check @WinlostDate less than @MoveBetDay
	INSERT INTO @BalanceUpTable(BalanceUpDay, MoveBetsDay)
	EXEC dbo.Age_SelBalanceUpDay 
	
	SELECT @MoveBetsDay = MoveBetsDay
	FROM @BalanceUpTable

	IF @MoveBetsDay >= @WinlostDate
	BEGIN
		--PRINT('Can''t process data.')
		DROP TABLE #LicenseeProductTable
		DROP TABLE #3rdData
		DROP TABLE #ChargeRate
		DROP TABLE #ChargeRateByCurrency
		RETURN
	END
	
	SELECT @RowId = 1
	SELECT @BettingIndicator = ' Betting - '
		--, @AdjustmentIndicator = ' Adjustment - Date: '

	--get licensee list
	SET @SqlQuery = ''
	SELECT @SqlQuery = 'SELECT LicenseeId, LicenseeName, Currency, ProductId
			FROM OPENQUERY(DBLIC, ''SELECT l.LicenseeId, l.LicenseeName, c.Currency, p.ProductId
			FROM bodb_licensee.dbo.LicenseeCust c WITH(NOLOCK)
				INNER JOIN bodb_licensee.dbo.Licensees l WITH(NOLOCK) ON c.LicenseeId = l.LicenseeId
				INNER JOIN bodb_licensee.dbo.LicenseeProduct3rd p WITH(NOLOCK) ON c.LicenseeId = p.LicenseeId
			WHERE p.ProductId IN (' + @ProductIds + ')
			GROUP BY l.LicenseeId, l.LicenseeName, c.Currency, p.ProductId
			'')'
	
	INSERT INTO #LicenseeProductTable(LicenseeId, LicenseeName, CurrencyId, ProductId)
	EXEC (@SqlQuery)

	IF NOT EXISTS (SELECT 1 FROM #LicenseeProductTable)
	BEGIN
		--PRINT('licensee cust does not exist')
		DROP TABLE #LicenseeProductTable
		DROP TABLE #3rdData
		DROP TABLE #ChargeRate
		DROP TABLE #ChargeRateByCurrency
		RETURN
	END
	
	--- get SiteDBGroupID
	DECLARE @SiteDBGroupID SMALLINT;
	SELECT @SiteDBGroupID = dbo.f_Get_SiteDBGroupID()

	INSERT INTO @LicenseeTable(LicenseeId, LicenseeName, CurrencyId)
	SELECT DISTINCT l.LicenseeId, l.LicenseeName, l.CurrencyId
	FROM #LicenseeProductTable l 
		INNER JOIN DBCUST.CUSTDB.dbo.site s WITH (NOLOCK) ON l.LicenseeName = s.Site 
	WHERE s.SiteDBGroupID = @SiteDBGroupID
	GROUP BY l.LicenseeId, l.LicenseeName, l.CurrencyId

	--get party list
	SET @SqlQuery = ''
	SELECT @SqlQuery = 'SELECT FromParty
			FROM OPENQUERY(DBLIC, ''SELECT DISTINCT FromParty
									FROM bodb_licensee.dbo.OAS_ChargeInfo WITH (NOLOCK)
									WHERE ProductId IN (' + @ProductIds + ')
									'')'
	
	INSERT INTO @Party(PartyId)
	EXEC (@SqlQuery)

	SELECT @PartyList = COALESCE(@PartyList + ',' + CAST(PartyId AS VARCHAR), CAST(PartyId AS VARCHAR))
	FROM @Party
	
	--get charge rate
	SET @ProductCodeList = NULL

	IF CHARINDEX('10', @ProductIds, 0) > 0 --AG Casino
		SELECT @ProductCodeList = COALESCE(@ProductCodeList + ',AGC', 'AGC')

	IF CHARINDEX('11', @ProductIds, 0) > 0 --Gold Deluxe
		SELECT @ProductCodeList = COALESCE(@ProductCodeList + ',GD', 'GD')

	IF CHARINDEX('31', @ProductIds, 0) > 0 --Exchange
		SELECT @ProductCodeList = COALESCE(@ProductCodeList + ',BX', 'BX')

	SET @SqlQueryChargeRate = ''
	SELECT @SqlQueryChargeRate = 'SELECT ChargeId, PartyId, LicenseeId, ProductId, ChargeType, DI_Rate, Fromdate, Todate
			FROM OPENQUERY(DBLIC, ''SELECT ChargeId, PartyId, LicenseeId, ProductId, ChargeType, DI_Rate, FromDate, ToDate
			FROM bodb_licensee.dbo.LA_f_ChargeInfo(''''' + @PartyList + ''''', ''''' + CONVERT(VARCHAR(10), @WinlostDate, 112) + '''''
												 , ''''' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ''''', ''''' + @ProductCodeList + ''''', ''''OA'''', 1)
			WHERE DI_Rate > 0 AND ChargeType IN (1,12) '')'
	
	INSERT INTO #ChargeRate(ChargeId, PartyId, LicenseeId, ProductId, ChargeType, Rate, FromDate, ToDate)
	EXEC (@SqlQueryChargeRate)

	--get more charge rate for trial time
	SET @SqlQueryChargeRate = ''
	SELECT @SqlQueryChargeRate = 'SELECT ChargeId, PartyId, LicenseeId, ProductId, ChargeType, DI_Rate, Fromdate, Todate
			FROM OPENQUERY(DBLIC, ''SELECT ChargeId, PartyId, LicenseeId, ProductId, ChargeType, DI_Rate, FromDate, ToDate
			FROM bodb_licensee.dbo.LA_f_GetChargeInfoWithTrialTime(''''' + @PartyList + ''''', ''''' + CONVERT(VARCHAR(10), @WinlostDate, 112) + '''''
												 , ''''' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ''''', ''''' + @ProductCodeList + ''''', ''''OA'''', 1)
			WHERE DI_Rate > 0 AND ChargeType IN (1,12) '')'
	
	INSERT INTO #ChargeRate(ChargeId, PartyId, LicenseeId, ProductId, ChargeType, Rate, FromDate, ToDate)
	EXEC (@SqlQueryChargeRate)

	IF NOT EXISTS (SELECT TOP 1 1 FROM #ChargeRate)
	BEGIN
		--PRINT('Charge rate does not exist')
		DROP TABLE #LicenseeProductTable
		DROP TABLE #3rdData
		DROP TABLE #ChargeRate
		DROP TABLE #ChargeRateByCurrency
		RETURN
	END

	DECLARE @ChargeIdList NVARCHAR(MAX)
	SELECT  @ChargeIdList = COALESCE(@ChargeIdList + ',', '') + CONVERT(VARCHAR(20), ChargeId)
	FROM #ChargeRate

	SET @SqlQueryChargeRate = ''
	SELECT @SqlQueryChargeRate = 'SELECT ChargeId, CurrencyId, Rate
			FROM OPENQUERY(DBLIC, ''SELECT ChargeId, CurrencyId, Rate FROM bodb_Licensee.dbo.LA_ChargeRateByCurrency WITH (NOLOCK)
									WHERE ChargeId IN (' + @ChargeIdList + ')'')'

	INSERT INTO #ChargeRateByCurrency (ChargeId, CurrencyId, Rate)
	EXEC (@SqlQueryChargeRate)

	DECLARE @FinalData TABLE (TransId BIGINT, CustId INT, WinlostDate SMALLDATETIME, Stake MONEY, Actual_stake MONEY, Winlost MONEY, TransDesc VARCHAR(300)
			, StatusId TINYINT, Status VARCHAR(10), apositiontaking MONEY, awinlost MONEY, RefNo BIGINT, actualrate FLOAT
			, CurrencyId TINYINT, Bettype SMALLINT, CurrencyName VARCHAR(10), srecommend INT, mrecommend INT, recommend INT, UserName VARCHAR(50)
			, PlayerComm MONEY, Comm MONEY, betfrom NVARCHAR(1))

	WHILE EXISTS (SELECT 1 FROM @LicenseeTable WHERE RowId = @RowId)
	BEGIN
		--clean data
		DELETE @FinalData
		DELETE @DataTmp
		DELETE #3rdData

		SELECT @LicenseeId = ISNULL(LicenseeId, 0), @LicenseeName = ISNULL(LicenseeName, ''), @CurrencyId = ISNULL(CurrencyId, 0)
		FROM @LicenseeTable WHERE RowId = @RowId
		
		SELECT @RowId = @RowId + 1, @RefNo = 0
			, @ProductIds = NULL, @CustDummyId = NULL
			
		--get product list by @licensee & @currency
		SELECT @ProductIds = COALESCE(@ProductIds + ',' + CAST(ProductId AS VARCHAR), CAST(ProductId AS VARCHAR))
		FROM #LicenseeProductTable
		WHERE CurrencyId = @CurrencyId AND LicenseeName = @LicenseeName

		EXEC dbo.Lrf_Get_DummyAccount3rd @LicenseeName = @LicenseeName
			, @CurrencyId = @CurrencyId
			, @CustId = @CustDummyId OUTPUT
		
		IF ISNULL(@CustDummyId, 0) = 0 OR ISNULL(@ProductIds, '') = ''
			CONTINUE
		
		IF CHARINDEX('10', @ProductIds, 0) > 0 --AG Casino
		BEGIN
			--print ('AG Casino')
			SELECT @SqlQueryFor3rd = ''
			SELECT @SqlQueryFor3rd = 'SELECT WinlostDate, Currency, 1800 AS Bettype, Stake, Actual_stake, Winlost
				FROM OPENQUERY(DBLIC, ''SELECT WinlostDate, b.Currency, SUM(ABS(Stake)) AS Stake, SUM(ABS(Actual_stake)) AS Actual_stake, SUM(ABS(Winlost)) AS Winlost
				FROM bodb_PlaytechCS.dbo.bettrans_AGCasino b WITH (NOLOCK)
					INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(' + CAST(@LicenseeId AS VARCHAR) + ') f ON b.recommend = f.custid AND b.currency = f.currency 
				WHERE 1 = 1'
					+ ' AND WinlostDate BETWEEN ''''' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ''''' AND ''''' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ''''''
					+ ' AND b.Currency = ' + CAST(@CurrencyId AS VARCHAR)
					+ ' AND StatusId IN (112,113,111)'
				+ ' GROUP BY WinlostDate, b.Currency'
				+ ''' )'
			--select @SqlQueryFor3rd as '@SqlQueryFor3rd'
			INSERT INTO #3rdData(WinlostDate, CurrencyId, Bettype, Stake, Actual_stake, Winlost)
			EXEC (@SqlQueryFor3rd)
		END
		
		IF CHARINDEX('11', @ProductIds, 0) > 0 --Gold Deluxe
		BEGIN
			--print ('Gold Deluxe')
			
			-- bettrans_GoldDeluxe
			SELECT @SqlQueryFor3rd = ''
			SELECT @SqlQueryFor3rd = 'SELECT WinlostDate, Currency, 1700 AS Bettype, Stake, Actual_stake, Winlost
				FROM OPENQUERY(DBLIC, ''SELECT WinlostDate, b.Currency, SUM(ABS(Stake)) AS Stake, SUM(ABS(Stake)) AS Actual_stake, SUM(ABS(Winlost)) AS Winlost
				FROM bodb_PlaytechCS.dbo.bettrans_GoldDeluxe b WITH (NOLOCK)
					INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(' + CAST(@LicenseeId AS VARCHAR) + ') f ON b.recommend = f.custid AND b.currency = f.currency 
				WHERE 1 = 1'
					+ ' AND WinlostDate BETWEEN ''''' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ''''' AND ''''' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ''''''
					+ ' AND b.Currency = ' + CAST(@CurrencyId AS VARCHAR)
					+ ' AND StatusId IN (112,113,111)'
				+ ' GROUP BY WinlostDate, b.Currency'
				+ ''' )'
			
			INSERT INTO #3rdData(WinlostDate, CurrencyId, Bettype, Stake, Actual_stake, Winlost)
			EXEC (@SqlQueryFor3rd)

			-- GoldDeluxe_Tip
			SELECT @SqlQueryFor3rd = ''
			SELECT @SqlQueryFor3rd = 'SELECT WinlostDate, Currency, 1706 AS Bettype, Stake, Actual_stake, Winlost
				FROM OPENQUERY(DBLIC, ''SELECT b.WinlostDate, b.Currency, 0 AS Stake, SUM(ABS(b.Amount)) AS Actual_stake, 0 AS Winlost
				FROM bodb_PlaytechCS.dbo.GoldDeluxe_Tip b WITH (NOLOCK)
					INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(' + CAST(@LicenseeId AS VARCHAR) + ') f ON b.recommend = f.custid AND b.currency = f.currency 
				WHERE 1 = 1'
					+ ' AND b.WinlostDate BETWEEN ''''' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ''''' AND ''''' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ''''''
					+ ' AND b.Currency = ' + CAST(@CurrencyId AS VARCHAR)
				+ ' GROUP BY b.WinlostDate, b.Currency'
				+ ''' )'
			
			INSERT INTO #3rdData(WinlostDate, CurrencyId, Bettype, Stake, Actual_stake, Winlost)
			EXEC (@SqlQueryFor3rd)
		END

		IF CHARINDEX('31', @ProductIds, 0) > 0 --Exchange
		BEGIN
			--print ('Exchange')
			SELECT @SqlQueryFor3rd = ''
			SELECT @SqlQueryFor3rd = 'SELECT WinlostDate, Currency, 8000 AS Bettype, Stake, Actual_stake, Winlost, PlayerComm, Comm
				FROM OPENQUERY(DBLIC, ''SELECT CONVERT(Date,b.SettledDate) as WinlostDate, b.Currency, SUM(b.stakeTotal/ExVirtualRate) AS Stake, SUM(b.stakeTotal/ExVirtualRate) AS Actual_stake, 
				SUM((b.marketTotal+b.stakeTotal)/ExVirtualRate) AS Winlost, SUM(b.commission/ExVirtualRate) AS PlayerComm, SUM((b.agentCommission+b.commission)/ExVirtualRate) AS Comm
				FROM bodb_3rdProduct.dbo.Sum_winloss_Exchange b WITH (NOLOCK)
					INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.CustID = b.CustID AND c.roleid = 1
					INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(' + CAST(@LicenseeId AS VARCHAR) + ') f ON c.recommend = f.custid AND b.currency = f.currency 
				WHERE 1 = 1'
					+ ' AND CONVERT(Date,b.SettledDate) BETWEEN ''''' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ''''' AND ''''' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ''''''
					+ ' AND b.Currency = ' + CAST(@CurrencyId AS VARCHAR)
					+ ' GROUP BY CONVERT(Date,b.SettledDate), b.Currency'
				+ ''' )'
			
			INSERT INTO #3rdData(WinlostDate, CurrencyId, Bettype, Stake, Actual_stake, Winlost, PlayerComm, Comm)
			EXEC (@SqlQueryFor3rd)
		END
		
		IF NOT EXISTS (SELECT TOP 1 1 FROM #3rdData)
		BEGIN
			--PRINT('No data on that day. - WinlostDate: ' + CONVERT(VARCHAR(10), @WinlostDate, 112))
			CONTINUE
		END

		--incase daily sum
		INSERT @DataTmp(RowId, CurrencyId, Bettype)
		SELECT ROW_NUMBER() OVER(ORDER BY CurrencyId) AS RowId, CurrencyId, Bettype
		FROM (
			SELECT CurrencyId, Bettype
			FROM #3rdData 
			WHERE WinlostDate = @WinlostDate 
			GROUP BY CurrencyId, Bettype
		)tmp
		
		DECLARE @RowIdTmp INT, @CurrencyIdTmp TINYINT, @BettypeTmp SMALLINT
		SELECT @RowIdTmp = 1
		WHILE EXISTS (SELECT 1 FROM @DataTmp WHERE RowId = @RowIdTmp)
		BEGIN
			SELECT @CurrencyIdTmp = 0, @BettypeTmp = 0
			SELECT @CurrencyIdTmp = CurrencyId, @BettypeTmp = Bettype
			FROM @DataTmp WHERE RowId = @RowIdTmp
			
			SET @RowIdTmp = @RowIdTmp + 1

			--generate refno
			SET @RefNo = 0
			EXEC dbo.Get_refno_transid @refNo = @RefNo OUTPUT
			---get new transid 
			SET @TransId = 0
			EXEC Get_Bettrans_TransID @TransID = @TransId OUTPUT	
			--get exchangerate
			SELECT @ExchangeRate = ActualRate
			FROM CustDB.dbo.ExchangeDailyOanda WITH(NOLOCK)
			WHERE ExchangeDate = @WinlostDate AND ExchangeId = @CurrencyIdTmp

			--data sum --> prevent case re-run
			IF NOT EXISTS (SELECT TOP 1 1 
							FROM #3rdData d
								INNER JOIN dbo.bettrans dd WITH(NOLOCK) ON @CustDummyId = dd.custid AND d.WinlostDate = dd.WinlostDate 
																			AND d.CurrencyId = dd.Currency AND d.Bettype = dd.Bettype
							WHERE d.WinlostDate = @WinlostDate AND d.CurrencyId = @CurrencyIdTmp AND d.Bettype = @BettypeTmp
								AND d.Stake = dd.Stake AND d.Actual_Stake = dd.Actual_stake AND d.Winlost = dd.Winlost)
			BEGIN
				INSERT INTO @FinalData(TransId, WinlostDate, CustId, Stake, Actual_Stake, Winlost, RefNo, actualrate, CurrencyId, Bettype, PlayerComm, Comm)
				SELECT @TransId, WinlostDate, @CustDummyId, Stake, Actual_Stake, Winlost, @RefNo, @ExchangeRate, @CurrencyIdTmp, @BettypeTmp, PlayerComm, Comm
				FROM #3rdData tmp
				WHERE WinlostDate = @WinlostDate AND tmp.CurrencyId = @CurrencyIdTmp AND tmp.Bettype = @BettypeTmp
			END
			
		END
		
		--update some info: transdesc, awinlost, apositiontaking, status, recommend, ...
		--AGC Adjustment - Date: 2015-05-26
		UPDATE tmp
		SET TransDesc = CASE WHEN tmp.Bettype = 1800 THEN 'AGC' 
							 WHEN tmp.Bettype IN (1700, 1706) THEN 'GD' 
							 WHEN tmp.Bettype = 8000 THEN 'BX' 
							 END + @BettingIndicator + 'Transfer back to Sportsbook'
			, awinlost = -(Winlost - Actual_stake) * (1 - ISNULL(rc.Rate, r.Rate))
			, apositiontaking = 1 - ISNULL(rc.Rate, r.Rate)
			, Status = CASE WHEN Winlost - Actual_stake > 0 THEN 'WON'
							WHEN Winlost - Actual_stake < 0 THEN 'LOSE'
							ELSE 'DRAW' END
			, StatusId = CASE WHEN Winlost - Actual_stake > 0 THEN 112
							  WHEN Winlost - Actual_stake < 0 THEN 113
						      ELSE 111 END
			, srecommend = c.srecommend
			, mrecommend = c.mrecommend
			, recommend = c.recommend
			, UserName = c.username
			, CurrencyName = ex.currency
			, Betfrom = CASE WHEN tmp.Bettype = 8000 THEN 'd' 
							 ELSE 'i'
						END
		FROM @FinalData tmp
			INNER JOIN (
				SELECT ChargeId, FromDate, ToDate, Rate
					, CASE WHEN ProductId = 10 THEN 1800
						WHEN ProductId = 11 THEN CASE WHEN ChargeType = 1 THEN 1700 WHEN ChargeType = 12 THEN 1706 END
						WHEN ProductId = 31 THEN 8000 
						END Bettype
				FROM #ChargeRate WHERE LicenseeId = @LicenseeId
			) r ON tmp.WinlostDate BETWEEN r.FromDate AND r.ToDate AND r.Bettype = tmp.Bettype
			LEFT JOIN #ChargeRateByCurrency rc ON r.ChargeId = rc.ChargeId AND tmp.CurrencyId = rc.CurrencyId
			INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON tmp.CustId = c.custid AND c.roleid = 1
			INNER JOIN CustDB.dbo.exchange ex WITH(NOLOCK) ON tmp.CurrencyId = ex.exchangeid
		
		--select * from @FinalData
		--delete data when charge rate did not config & avoid error a while insert into @bettrans
		DELETE @FinalData 
		WHERE awinlost IS NULL
			OR ISNULL(TransDesc, '') = ''
			OR ISNULL(RefNo, 0) = 0

		INSERT INTO dbo.bettrans(TransId
			, custid
			, transdate
			, oddsid
			, hdp1
			, hdp2
			, odds
			, stake
			, Status
			, winlost
			, awinlost
			, mwinlost
			, playercomm
			, comm
			, acomm
			, apositiontaking
			, mpositiontaking
			, tpositiontaking
			, playerdiscount
			, discount
			, adiscount
			, livehomescore
			, liveawayscore
			, liveindicator
			, betteam
			, creator
			, refno
			, comstatus
			, winlostdate
			, betfrom
			, betcheck
			, checktime
			, oddsspread
			, actualrate
			, matchid
			, recommend
			, mrecommend
			, ruben
			, betid
			, statuswinlost
			, modds
			, bettype
			, betdaqid
			--, tstamp
			, actual_stake
			, currency
			, ip
			, transdesc
			, sdiscount
			, scomm
			, spositiontaking
			, swinlost
			, srecommend
			, Username
			, CurrencyName
			, virtualrate
			, oddstype
			, statusID
			, currency2
			, balance
			, SecAcceptFlag
			, transid2
			, RecommDate
			, RepUpdateTime 
			, SiteDBGroupID)
		SELECT TransId
			, custid
			, GETDATE() transdate
			, 0 oddsid
			, 0 hdp1
			, 0 hdp2
			, 0 odds
			, stake
			, Status
			, winlost
			, awinlost
			, 0 mwinlost
			, playercomm
			, comm
			, comm AS acomm
			, apositiontaking
			, 0 mpositiontaking
			, apositiontaking tpositiontaking --apos + mpos + spos
			, 0 playerdiscount
			, 0 discount
			, 0 adiscount
			, 0 livehomescore
			, 0 liveawayscore
			, 0 liveindicator
			, 0 betteam
			, CustId creator
			, refno
			, 0 comstatus
			, @WinlostDate winlostdate
			, betfrom
			, 0 betcheck
			, NULL checktime
			, NULL oddsspread
			, actualrate
			, 0 matchid
			, recommend
			, mrecommend
			, 1 ruben
			, 0 betid
			, NULL statuswinlost
			, 1 modds --get default value
			, bettype
			, NULL betdaqid
			--, tstamp --not insert
			, actual_stake
			, CurrencyId
			, '' ip
			, transdesc
			, 0 sdiscount
			, comm AS scomm
			, 0 spositiontaking
			, 0 swinlost
			, srecommend
			, Username
			, CurrencyName
			, actualrate virtualrate
			, NULL oddstype
			, statusID
			, NULL currency2
			, NULL balance
			, NULL SecAcceptFlag
			, NULL transid2
			, NULL RecommDate
			, SYSDATETIME() RepUpdateTime
			, @SiteDBGroupID SiteDBGroupID
		FROM @FinalData

		
		WAITFOR DELAY '000:00:00.280'
		
	END
	
	----Update flag to indicate we have just done data for Exchange product:
	IF EXISTS (SELECT 1 FROM dbo.Bettrans WITH (NOLOCK) WHERE Bettype = 8000 and Winlostdate = @WinlostDate)
		UPDATE DBLIC.bodb_LicenseeReport.dbo.Product3rd_SummarizedDateHistory_Tracking
			SET SumToBettransDate = GETDATE()
		WHERE ID IN (
						SELECT ID 
						FROM DBLIC.bodb_3rdProduct.dbo.Product3rd_SummarizedDateHistory
						WHERE ProductID = 31 AND Winlostdate = @WinlostDate
					)
				
	DROP TABLE #LicenseeProductTable
	DROP TABLE #3rdData
	DROP TABLE #ChargeRate
	DROP TABLE #ChargeRateByCurrency
END
GO