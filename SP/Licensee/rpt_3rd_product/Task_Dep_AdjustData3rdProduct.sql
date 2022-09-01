/*<info serverAlias="DBTXN-bodb02" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Dep_AdjustData3rdProduct]
	@WinlostDate		SMALLDATETIME
	,@ProductIds		VARCHAR(MAX)
	,@DayForAdjustment	VARCHAR(125) = '1,2,3,4,5,6,7'
AS
/*
	Created by: 20150601@Patrick
	Task: #36263 - Adjust data for 3rd product
	DB: DBTRANS.bodb02
	Revisions: 
		- 20150702@Patrick: Fix bug multiple rate, use to index hint to get data from bettrans_bk
		- 20150703@Patrick: Filter data by range balanceup & movebet
		- 20150824@Patrick: Call sp: Lrf_SelBalanceUpDay via link server
		- 20171213@Sophia: Integrate CitiBet Exchange Products [Redmine: #86640]
		- 20181003@Percy: Integrate GoldDeluxe Tip [RedmineID: #70177]
		- 20200108@Percy: Support billing terms by product & currency instead of product only [RedmineID: #120005]
		- 20200407@Percy: Add @ProductIds to support input product list [RedmineID: #131885]
		- 20200501@Sophia: Fix bug @bettypeIds [Redmine: #131885]
		- 20220315@Evan: SQL Server Upgrade STRING_SPLIT [Redmine: #168783]
		- 20220721@Evan: Integrate new transid [Redmine: #175640]
		- 20220724@Evan: LAP - Scale out DBTrans phase 1 - classify data between SiteDB & CentralDB [Redmine: #175297]
		- 20220724@Evan: Fix bug @transid null when existed refno  [Redmine: #175640]
	Format for transdesc: 
		--AGC Betting - Transfer back to Sportsbook
		--AGC Adjustment - Date: 2015-05-26
	
*/
BEGIN
	SET NOCOUNT ON

	IF @WinlostDate > GETDATE()
	BEGIN
		RETURN
	END

	DECLARE @Today DATE
	SELECT  @Today = DATEADD(DAY, 1, @WinlostDate)

	--Only run on that date @DayForAdjustment
	IF CHARINDEX(CAST(DATEPART(DAY, @Today) AS VARCHAR), @DayForAdjustment, 0) <= 0 --DATEPART(DD, @Today) NOT IN (1,2,3,4,5,6,7)
	BEGIN
		RETURN
	END

	CREATE TABLE #LicenseeProductTable (RowId INT IDENTITY(1,1), LicenseeId INT, LicenseeName VARCHAR(50), CurrencyId TINYINT, ProductId TINYINT)
	CREATE TABLE #3rdData (WinlostDate SMALLDATETIME, Stake MONEY, Actual_Stake MONEY, Winlost MONEY, CurrencyId TINYINT, Bettype SMALLINT, PlayerComm MONEY DEFAULT (0), Comm MONEY DEFAULT (0))
	CREATE TABLE #3rdDummnyData (CustId INT, WinlostDate SMALLDATETIME, Stake MONEY, Actual_stake MONEY, Winlost MONEY, TransDesc VARCHAR(300), RefNo BIGINT
		, Apositiontaking SMALLMONEY, actualrate FLOAT, CurrencyId TINYINT, Bettype SMALLINT, PlayerComm MONEY DEFAULT (0), Comm MONEY DEFAULT (0))
	CREATE TABLE #ChargeRate (ChargeId INT, PartyId INT, LicenseeId INT, ProductId INT, ChargeType TINYINT, Rate MONEY, FromDate SMALLDATETIME, ToDate SMALLDATETIME)
	CREATE TABLE #ChargeRateByCurrency (ChargeId INT, CurrencyId INT, Rate MONEY)

	DECLARE @LicenseeTable TABLE (RowId INT IDENTITY(1,1), LicenseeId INT, LicenseeName VARCHAR(50), CurrencyId TINYINT)
	DECLARE @BalanceUpTable TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	DECLARE @Party TABLE (PartyId INT)
	
	DECLARE @RowId INT, @LicenseeName VARCHAR(50), @CurrencyId TINYINT, @ProductId TINYINT
		, @SqlQueryForDummny VARCHAR(8000), @SqlQueryFor3rd VARCHAR(8000), @CustDummyId INT
		, @SqlQueryChargeRate VARCHAR(8000), @PartyList VARCHAR(4000), @ProductCodeList VARCHAR(1000)
		, @RefNo BIGINT, @SqlQuery VARCHAR(8000), @ExchangeRate FLOAT
		, @LicenseeId INT, @BettypeIds VARCHAR(512), @FirstDateOfLastMonth SMALLDATETIME, @LastDateOfLastMonth SMALLDATETIME
		, @AdjustmentIndicator VARCHAR(125), @BettingIndicator VARCHAR(125), @BalanceUpDay SMALLDATETIME, @MoveBetsDay SMALLDATETIME
		, @TransId BIGINT
		
	SELECT @RowId = 1
	SELECT @FirstDateOfLastMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today) -1, 0) --First day of last month
		, @LastDateOfLastMonth = DATEADD(MONTH, DATEDIFF(MONTH, -1, @Today) -1, -1) --Last day of last month
		, @BettingIndicator = ' Betting - '
		, @AdjustmentIndicator = ' Adjustment - Date: '

	--check @WinlostDate less than @MoveBetDay
	INSERT INTO @BalanceUpTable(BalanceUpDay, MoveBetsDay)
	EXEC dbo.Age_SelBalanceUpDay
	
	SELECT @MoveBetsDay = MoveBetsDay, @BalanceUpDay = BalanceUpDay
	FROM @BalanceUpTable
	
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
		DROP TABLE #3rdDummnyData
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
			FROM bodb_licensee.dbo.LA_f_ChargeInfo(''''' + @PartyList + ''''', ''''' + CONVERT(VARCHAR(10), @FirstDateOfLastMonth, 112) + '''''
												 , ''''' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ''''', ''''' + @ProductCodeList + ''''', ''''OA'''', 1)
			WHERE DI_Rate > 0 AND ChargeType IN (1,12) '')'
	
	INSERT INTO #ChargeRate(ChargeId, PartyId, LicenseeId, ProductId, ChargeType, Rate, FromDate, ToDate)
	EXEC (@SqlQueryChargeRate)

	--get more charge rate for trial time
	SET @SqlQueryChargeRate = ''
	SELECT @SqlQueryChargeRate = 'SELECT ChargeId, PartyId, LicenseeId, ProductId, ChargeType, DI_Rate, Fromdate, Todate
			FROM OPENQUERY(DBLIC, ''SELECT ChargeId, PartyId, LicenseeId, ProductId, ChargeType, DI_Rate, FromDate, ToDate
			FROM bodb_licensee.dbo.LA_f_GetChargeInfoWithTrialTime(''''' + @PartyList + ''''', ''''' + CONVERT(VARCHAR(10), @FirstDateOfLastMonth, 112) + '''''
												 , ''''' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ''''', ''''' + @ProductCodeList + ''''', ''''OA'''', 1)
			WHERE DI_Rate > 0 AND ChargeType IN (1,12) '')'
	
	INSERT INTO #ChargeRate(ChargeId, PartyId, LicenseeId, ProductId, ChargeType, Rate, FromDate, ToDate)
	EXEC (@SqlQueryChargeRate)

	IF NOT EXISTS (SELECT TOP 1 1 FROM #ChargeRate)
	BEGIN
		--PRINT('Charge rate does not exist')
		DROP TABLE #LicenseeProductTable
		DROP TABLE #3rdData
		DROP TABLE #3rdDummnyData
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

	DECLARE @FinalData TABLE (RowID INT IDENTITY(1,1) PRIMARY KEY,CustId INT, WinlostDate SMALLDATETIME, Stake MONEY, Actual_stake MONEY, Winlost MONEY, TransDesc VARCHAR(300)
			, StatusId TINYINT, Status VARCHAR(10), apositiontaking MONEY, awinlost MONEY, RefNo BIGINT, actualrate FLOAT
			, CurrencyId TINYINT, Bettype SMALLINT, CurrencyName VARCHAR(10), srecommend INT, mrecommend INT, recommend INT, UserName VARCHAR(50)
			, PlayerComm MONEY, Comm MONEY, betfrom NVARCHAR(1))

	WHILE EXISTS (SELECT 1 FROM @LicenseeTable WHERE RowId = @RowId)
	BEGIN
		--clean data
		DELETE @FinalData
		DELETE #3rdData
		DELETE #3rdDummnyData

		SELECT @LicenseeId = ISNULL(LicenseeId, 0), @LicenseeName = ISNULL(LicenseeName, ''), @CurrencyId = ISNULL(CurrencyId, 0)
		FROM @LicenseeTable WHERE RowId = @RowId
		
		SELECT @RowId = @RowId + 1, @RefNo = 0
			, @ProductIds = NULL, @CustDummyId = NULL, @BettypeIds = NULL
			
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
			SELECT @BettypeIds = COALESCE(@BettypeIds + ',1800', '1800')

		IF CHARINDEX('11', @ProductIds, 0) > 0 --Gold Deluxe
			SELECT @BettypeIds = COALESCE(@BettypeIds + ',1700,1706', '1700,1706')

		IF CHARINDEX('31', @ProductIds, 0) > 0 --Exchange
			SELECT @BettypeIds = COALESCE(@BettypeIds + ',8000', '8000')

		--print('get data from bk, 14 & bettrans to data adjustment')
		-- get data from bk
		SELECT @SqlQueryForDummny = ''
		SELECT @SqlQueryForDummny = 'SELECT CustId, WinlostDate, Stake, Actual_stake, Winlost, TransDesc, RefNo, Apositiontaking, actualrate, Currency, Bettype, PlayerComm, Comm
			FROM OPENQUERY(DBARC, ''SELECT CustId, WinlostDate, Stake, Actual_stake, Winlost, TransDesc, RefNo, Apositiontaking, actualrate, Currency, Bettype, PlayerComm, Comm
			FROM bodb_archive.dbo.bettrans_bk WITH (NOLOCK, INDEX = IX_custid) WHERE CustId IN (' + CAST(@CustDummyId AS VARCHAR) + ')'
																+ ' AND WinlostDate BETWEEN ''''' + CONVERT(VARCHAR(10), @FirstDateOfLastMonth, 112) + ''''''
																+ ' AND ''''' + CONVERT(VARCHAR(10), @BalanceUpDay - 1, 112) + ''''''
																+ ' AND bettype IN (' + CAST(@BettypeIds AS VARCHAR) + ')'
																+ ''' )'
		--select @SqlQueryForDummny as '@SqlQueryForDummny'
		INSERT INTO #3rdDummnyData (CustId, WinlostDate, Stake, Actual_Stake, Winlost, TransDesc, RefNo, Apositiontaking, actualrate, CurrencyId, Bettype, PlayerComm, Comm)
		EXEC (@SqlQueryForDummny)
			
		-- get data from 14
		INSERT INTO #3rdDummnyData (CustId, WinlostDate, Stake, Actual_stake, Winlost, TransDesc, RefNo, Apositiontaking, actualrate, CurrencyId, Bettype, PlayerComm, Comm)
		SELECT CustId, WinlostDate, Stake, Actual_stake, Winlost, TransDesc, RefNo, Apositiontaking, actualrate, currency, Bettype, PlayerComm, Comm
		FROM dbo.bettrans14 WITH(NOLOCK)
		WHERE custid = @CustDummyId-- custid IN (SELECT val FROM dbo.strSplit(@CustDummyIds, ','))
			AND bettype IN (SELECT value FROM STRING_SPLIT(@BettypeIds, ','))
			AND winlostdate BETWEEN @BalanceUpDay AND @MoveBetsDay
			
		-- get data from bettrans
		INSERT INTO #3rdDummnyData (CustId, WinlostDate, Stake, Actual_stake, Winlost, TransDesc, RefNo, Apositiontaking, actualrate, CurrencyId, Bettype, PlayerComm, Comm)
		SELECT CustId, WinlostDate, Stake, Actual_stake, Winlost, TransDesc, RefNo, Apositiontaking, actualrate, currency, Bettype, PlayerComm, Comm
		FROM dbo.bettrans WITH(NOLOCK)
		WHERE custid = @CustDummyId--custid IN (SELECT val FROM dbo.strSplit(@CustDummyIds, ','))
			AND bettype IN (SELECT value FROM STRING_SPLIT(@BettypeIds, ','))
			AND winlostdate BETWEEN @MoveBetsDay + 1 AND @WinlostDate
			
		--exclude ticket sum of current month
		DELETE #3rdDummnyData
		WHERE WinlostDate > @LastDateOfLastMonth
			AND TransDesc LIKE '%' + @BettingIndicator + '%'

		--delete ticket adjustment of others month
		DELETE #3rdDummnyData 
		WHERE TransDesc LIKE '%' + @AdjustmentIndicator + '%'
			AND TransDesc NOT LIKE '%' + CAST(YEAR(@LastDateOfLastMonth) AS VARCHAR) 
								    + '-' + RIGHT('0' + RTRIM(MONTH(@LastDateOfLastMonth)), 2) -- CAST(MONTH(@LastDateOfLastMonth) AS VARCHAR)
									+ '%'

		--update winlost date --AGC Adjustment - Date: 2015-05-26
		UPDATE #3rdDummnyData
		SET WinlostDate = SUBSTRING(TransDesc, CHARINDEX('Date: ', TransDesc, 0) + 6, 10)
		WHERE TransDesc LIKE '%' + @AdjustmentIndicator + '%'

		IF CHARINDEX('10', @ProductIds, 0) > 0 --AG Casino
		BEGIN
			--print ('AG Casino')
			SELECT @SqlQueryFor3rd = ''
			SELECT @SqlQueryFor3rd = 'SELECT WinlostDate, Currency, 1800 AS Bettype, Stake, Actual_stake, Winlost
				FROM OPENQUERY(DBLIC, ''SELECT WinlostDate, b.Currency, SUM(ABS(Stake)) AS Stake, SUM(ABS(Actual_stake)) AS Actual_stake, SUM(ABS(Winlost)) AS Winlost
				FROM bodb_PlaytechCS.dbo.bettrans_AGCasino b WITH (NOLOCK)
					INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(' + CAST(@LicenseeId AS VARCHAR) + ') f ON b.recommend = f.custid AND b.currency = f.currency 
				WHERE 1 = 1'
					+ ' AND WinlostDate BETWEEN ''''' + CONVERT(VARCHAR(10), @FirstDateOfLastMonth, 112) + ''''' AND ''''' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ''''''
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
					+ ' AND WinlostDate BETWEEN ''''' + CONVERT(VARCHAR(10), @FirstDateOfLastMonth, 112) + ''''' AND ''''' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ''''''
					+ ' AND b.Currency = ' + CAST(@CurrencyId AS VARCHAR)
					+ ' AND StatusId IN (112,113,111)'
				+ ' GROUP BY WinlostDate, b.Currency'
				+ ''' )'
			
			INSERT INTO #3rdData(WinlostDate, CurrencyId, Bettype, Stake, Actual_stake, Winlost)
			EXEC (@SqlQueryFor3rd)

			-- GoldDeluxe_Tip
			SELECT @SqlQueryFor3rd = ''
			SELECT @SqlQueryFor3rd = 'SELECT WinlostDate, Currency, 1706 AS Bettype, Stake, Actual_stake, Winlost
				FROM OPENQUERY(DBLIC, ''SELECT WinlostDate, b.Currency, 0 AS Stake, SUM(ABS(Amount)) AS Actual_stake, 0 AS Winlost
				FROM bodb_PlaytechCS.dbo.GoldDeluxe_Tip b WITH (NOLOCK)
					INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(' + CAST(@LicenseeId AS VARCHAR) + ') f ON b.recommend = f.custid AND b.currency = f.currency 
				WHERE 1 = 1'
					+ ' AND WinlostDate BETWEEN ''''' + CONVERT(VARCHAR(10), @FirstDateOfLastMonth, 112) + ''''' AND ''''' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ''''''
					+ ' AND b.Currency = ' + CAST(@CurrencyId AS VARCHAR)
				+ ' GROUP BY WinlostDate, b.Currency'
				+ ''' )'
			
			INSERT INTO #3rdData(WinlostDate, CurrencyId, Bettype, Stake, Actual_stake, Winlost)
			EXEC (@SqlQueryFor3rd)
		END

		IF CHARINDEX('31', @ProductIds, 0) > 0 --Exchange
		BEGIN
			--print ('Exchange')
			SELECT @SqlQueryFor3rd = ''
			SELECT @SqlQueryFor3rd = 'SELECT WinlostDate, Currency, 8000 AS Bettype, Stake, Actual_stake, Winlost, PlayerComm, Comm
				FROM OPENQUERY(DBLIC, ''SELECT CONVERT(Date,b.SettledDate) as WinlostDate, b.Currency, 
				SUM(b.stakeTotal/ExVirtualRate) AS Stake, SUM(b.stakeTotal/ExVirtualRate) AS Actual_stake, 
				SUM((b.marketTotal+b.stakeTotal)/ExVirtualRate) AS Winlost, SUM(b.commission/ExVirtualRate) AS PlayerComm, SUM((b.agentCommission+b.commission)/ExVirtualRate) AS Comm
				FROM bodb_3rdProduct.dbo.Sum_winloss_Exchange b WITH (NOLOCK)
					INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.CustID = b.CustID AND c.roleid = 1
					INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(' + CAST(@LicenseeId AS VARCHAR) + ') f ON c.recommend = f.custid AND b.currency = f.currency 					
				WHERE 1 = 1'
					+ ' AND CONVERT(Date,b.SettledDate) BETWEEN ''''' + CONVERT(VARCHAR(10), @FirstDateOfLastMonth, 112) + ''''' AND ''''' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ''''''
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

		--insert difference data
		INSERT INTO @FinalData(WinlostDate, CustId, Stake, Actual_Stake, Winlost, RefNo, actualrate, CurrencyId, Bettype, PlayerComm, Comm )
		SELECT tmp.WinlostDate
			, @CustDummyId
			, tmp.Stake - ISNULL(tmp2.Stake, 0) --Stake
			, tmp.Actual_stake - ISNULL(tmp2.Actual_stake, 0) --Actual_Stake
			, tmp.Winlost - ISNULL(tmp2.Winlost, 0) --Winlost
			, (SELECT TOP 1 RefNo FROM #3rdDummnyData WHERE WinlostDate = tmp2.WinlostDate AND bettype = tmp2.bettype)
			, (SELECT TOP 1 actualrate FROM #3rdDummnyData WHERE WinlostDate = tmp2.WinlostDate AND bettype = tmp2.bettype)
			, tmp.CurrencyId
			, tmp.Bettype
			, tmp.PlayerComm - ISNULL(tmp2.PlayerComm, 0) AS PlayerComm
			, tmp.Comm - ISNULL(tmp2.Comm, 0) AS Comm
		FROM (
			SELECT *
			FROM #3rdData
			WHERE WinlostDate <= @LastDateOfLastMonth
		) tmp
		LEFT JOIN (
			SELECT WinlostDate, CurrencyId, Bettype, SUM(Stake) AS Stake, SUM(Actual_stake) AS Actual_stake, SUM(Winlost) AS Winlost,  SUM (PlayerComm) AS PlayerComm, SUM (Comm) AS Comm
			FROM #3rdDummnyData
			GROUP BY WinlostDate, CurrencyId, Bettype
		) tmp2 ON tmp.WinlostDate = tmp2.WinlostDate AND tmp.CurrencyId = tmp2.CurrencyId AND tmp.Bettype = tmp2.Bettype
		WHERE tmp.Stake <> ISNULL(tmp2.Stake, 0)
			OR tmp.Actual_stake <> ISNULL(tmp2.Actual_stake, 0)
			OR tmp.Winlost <> ISNULL(tmp2.Winlost, 0)
			OR tmp.PlayerComm <> ISNULL(tmp2.PlayerComm, 0)
			OR tmp.Comm <> ISNULL(tmp2.Comm, 0)

		IF NOT EXISTS (SELECT TOP 1 1 FROM @FinalData)
		BEGIN
			--PRINT('No data on that day. - WinlostDate: ' + CONVERT(VARCHAR(10), @WinlostDate, 112))
			CONTINUE
		END

		--Incase missing all tickets on that date
		DECLARE @Count INT, @IndexId INT, @WinlostDateTmp SMALLDATETIME, @CurrencyIdTmp TINYINT, @BettypeTmp SMALLINT
		SELECT @Count = 0, @IndexId = 1
		--SELECT @Count = COUNT(1) FROM @FinalData WHERE RefNo IS NULL
		
		WHILE EXISTS (SELECT 1 FROM @FinalData WHERE RefNo IS NULL)
		BEGIN
			SELECT @WinlostDateTmp = NULL, @CurrencyIdTmp = 0, @BettypeTmp = 0
			SELECT TOP (1) @WinlostDateTmp = WinlostDate, @CurrencyIdTmp = CurrencyId, @BettypeTmp = Bettype
			FROM @FinalData WHERE RefNo IS NULL

			SET @RefNo = 0
			EXEC dbo.Get_refno_transid @refNo = @RefNo OUTPUT

			--get exchange rate
			SELECT @ExchangeRate = ActualRate
			FROM CustDB.dbo.ExchangeDailyOanda WITH(NOLOCK)
			WHERE ExchangeDate = @WinlostDateTmp AND ExchangeId = @CurrencyIdTmp

			UPDATE @FinalData
			SET RefNo = @RefNo
				, ActualRate = @ExchangeRate
			WHERE WinlostDate = @WinlostDateTmp AND CurrencyId = @CurrencyIdTmp AND Bettype = @BettypeTmp
		END
		
		---get new transid 

		DECLARE @TransIDs TABLE (RowID INT IDENTITY(1,1) PRIMARY KEY, TransID BIGINT, seq TINYINT)
		DECLARE @MaxGenTransId INT, @total_transid INT;

		SELECT @MaxGenTransId = MAX(RowID) FROM @FinalData
	
		WHILE (@MaxGenTransId > 0)
		BEGIN
			IF (@MaxGenTransId > 255)
				SET @total_transid = 255
			ELSE 
				SET @total_transid = @MaxGenTransId

			INSERT INTO @TransIDs (seq, TransID)
			EXEC Get_bettrans_transid_Range @total_transid = @total_transid

			SET @MaxGenTransId = @MaxGenTransId - @total_transid
		END

		--update some info: transdesc, awinlost, apositiontaking, status, recommend, ...
		--AGC Adjustment - Date: 2015-05-26
		UPDATE tmp
		SET TransDesc = CASE WHEN tmp.Bettype = 1800 THEN 'AGC' 
							 WHEN tmp.Bettype IN (1700, 1706) THEN 'GD' 
							 WHEN tmp.Bettype = 8000 THEN 'BX' END + @AdjustmentIndicator + CONVERT(VARCHAR(10), WinlostDate, 120) + ' - Ex.Rate: ' + CAST(tmp.ActualRate AS VARCHAR)
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
				SELECT FromDate, ToDate, Rate, ChargeId
					, CASE WHEN ProductId = 10 THEN 1800
						WHEN ProductId = 11 THEN CASE WHEN ChargeType = 1 THEN 1700 WHEN ChargeType = 12 THEN 1706 END
						WHEN ProductId = 31 THEN 8000 END Bettype
				FROM #ChargeRate WHERE LicenseeId = @LicenseeId
			) r ON tmp.WinlostDate BETWEEN r.FromDate AND r.ToDate AND r.Bettype = tmp.Bettype
			LEFT JOIN #ChargeRateByCurrency rc ON r.ChargeId = rc.ChargeId AND tmp.CurrencyId = rc.CurrencyId
			INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON tmp.CustId = c.custid AND c.roleid = 1
			INNER JOIN CustDB.dbo.exchange ex WITH(NOLOCK) ON tmp.CurrencyId = ex.exchangeid
		
		--get exchange rate:
		SELECT @ExchangeRate = ActualRate
		FROM CustDB.dbo.ExchangeDailyOanda WITH(NOLOCK)
		WHERE ExchangeDate = @WinlostDate AND ExchangeId = @CurrencyId

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
		SELECT tr.TransId
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
			, @ExchangeRate
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
			, @ExchangeRate virtualrate
			, NULL oddstype
			, statusID
			, NULL currency2
			, NULL balance
			, NULL SecAcceptFlag
			, NULL transid2
			, NULL RecommDate
			, SYSDATETIME() RepUpdateTime
			, @SiteDBGroupID SiteDBGroupID
		FROM @FinalData t
			INNER JOIN @TransIDs tr ON tr.RowID = t.RowID
		--WAITFOR DELAY '000:00:00.280'
		
	END
	
	DROP TABLE #LicenseeProductTable
	DROP TABLE #3rdData
	DROP TABLE #3rdDummnyData
	DROP TABLE #ChargeRate
	DROP TABLE #ChargeRateByCurrency
END
GO