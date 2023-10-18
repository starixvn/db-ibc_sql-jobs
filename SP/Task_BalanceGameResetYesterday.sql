/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_BalanceGameResetYesterday] 
	@sporttype SMALLINT = -1
	, @bettype SMALLINT = 1101
	, @SettingStatus TINYINT = 0
AS
/*
		Created: Dan	
		Date: 20121009
		Task: reset yesterday balance for live casino
		DB: DBTRANS.BODB02
		
		Revisions:
			- 20131108@Elodie: Splitting bodb02 into CustDB (call CustInfo by link database)
			- 20150710@Patrick: Remove insert default balance value & remove deposit account & support Gold deluxe
			- 20150910@Patrick: Re-arrange code to reduce time & CPU cost
			- 20160201@Elodie: Apply new rule for auto reset of OneRNG 
			- 20160204@Elodie: Add WinLossLimit setting type for DCS [Redmine: #49606]
			- 20160718@Elodie: Reset data from yesterday backward [Redmine: #60993]
			- 20191216@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
			- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
			- 20221121@Eden: Unify RNG Lottery Customer Settings [RedmineID: #180640]
			- 20230414@Eden: Scale out DBTRANS for Credit [Redmine: #181595]
			- 20230804@Eden: Win loss limit - Change SP to allow dynamic seting [RedmineID: #180640]
			- 20230928@Luke: Modify SPs to adapt in-house replication setup [Redmine: #194414]

		Parameters Explanation:	
*/
SET NOCOUNT ON	
CREATE TABLE #WeeklyResetCustomer(custid INT, srecommend INT)

DECLARE @SporttypeRefWinlossLimit SMALLINT
	, @BettypeRefWinlossLimit SMALLINT

DECLARE @SiteDBGroupID smallint
SELECT @SiteDBGroupID = dbo.f_Get_SiteDBGroupID()

SELECT @SporttypeRefWinlossLimit = SporttypeRefWinlossLimit, 
		@BettypeRefWinlossLimit = BettypeRefWinlossLimit
FROM DBCUST.CustDB.dbo.SportBettypeSettingMatrix st WITH(NOLOCK) 
	INNER JOIN CustDB.dbo.f_CustSetting_SportBetTypeSettingSelect(NULL, 22, @SettingStatus) AS s
			ON st.SporttypeRefWinlossLimit = s.SportType 
			AND st.BettypeRefWinlossLimit = s.Bettype
			AND st.isLicensee = 0 AND st.Site = 'ALL'
WHERE st.SportType = @SportType
	AND st.bettype = @BetType
	AND st.isDeleted = 0

SELECT @SporttypeRefWinlossLimit = ISNULL(@SporttypeRefWinlossLimit,@SportType), 
		@BettypeRefWinlossLimit = ISNULL(@BettypeRefWinlossLimit,@BetType)

IF @bettype = 1101 --LiveCS
BEGIN
	RETURN
END
ELSE --others DCS products
BEGIN
	INSERT INTO #WeeklyResetCustomer(custid, srecommend)
	SELECT c.custid, srecommend
	FROM CustDB.dbo.customer c WITH (NOLOCK)
		INNER JOIN CustDB.dbo.Site s WITH(NOLOCK) 
			ON c.site = s.Site
		INNER JOIN DBCUST.CustDB.dbo.CustWinLossLimit_Member cwl WITH (NOLOCK) 
			ON cwl.CustId = c.custid 
			AND cwl.sporttype = @SporttypeRefWinlossLimit 
			AND cwl.bettype = @BettypeRefWinlossLimit
	WHERE c.roleid = 1 
		AND IsAutoReset = 0
		AND s.SiteDBGroupID = @SiteDBGroupID
END

DECLARE @Yesterday SMALLDATETIME
SET @Yesterday = DATEADD(dd, -1, CAST(GETDATE() AS DATE))

--delete yesterday balance for daily reset and unlimited balance
WHILE 1 = 1
BEGIN
	DELETE TOP (50000) bal
	FROM dbo.BalanceCreditGame bal WITH (ROWLOCK)
		LEFT JOIN #WeeklyResetCustomer t ON bal.CustId = t.CustId
	WHERE winlostdate <= @Yesterday AND bettype = @bettype
		 AND t.CustId IS NULL
	OPTION (MAXDOP 4,RECOMPILE)
		
	IF @@ROWCOUNT < 50000
		BREAK
			
	WAITFOR DELAY '00:00:00.280'
END

WHILE 1 = 1
BEGIN
	DELETE TOP (50000) bal
	FROM dbo.BalanceDebitGame bal WITH (ROWLOCK)
		LEFT JOIN #WeeklyResetCustomer t ON bal.CustId = t.CustId
	WHERE winlostdate <= @Yesterday AND bettype = @bettype
		 AND t.CustId IS NULL
	OPTION (MAXDOP 4,RECOMPILE)
		
	IF @@ROWCOUNT < 50000
		BREAK
			
	WAITFOR DELAY '00:00:00.280'
END

--remove credit account
DELETE t
FROM #WeeklyResetCustomer t
	LEFT JOIN CustDB.dbo.Dep_CustSuper s WITH(NOLOCK) ON t.srecommend = s.custid
WHERE s.custid IS NULL

IF NOT EXISTS (SELECT TOP 1 1 FROM #WeeklyResetCustomer)
BEGIN
	DROP TABLE #WeeklyResetCustomer
	RETURN
END

--remove deposit account
IF EXISTS (	SELECT TOP 1 1 FROM dbo.BalanceCreditGame bal WITH(NOLOCK)
				INNER JOIN #WeeklyResetCustomer t ON bal.CustId = t.custid AND bal.bettype = @bettype 
			WHERE winlostdate <= @Yesterday
		)
BEGIN
	WHILE 1 = 1
	BEGIN
		DELETE TOP (50000) bal
		FROM dbo.BalanceCreditGame bal WITH (ROWLOCK)
			INNER JOIN #WeeklyResetCustomer t ON bal.CustId = t.custid AND bal.bettype = @bettype 
		WHERE winlostdate <= @Yesterday
		
		IF @@ROWCOUNT < 50000
			BREAK
			
		WAITFOR DELAY '00:00:00.280'
	END
END

IF EXISTS (	SELECT TOP 1 1 FROM dbo.BalanceDebitGame bal WITH(NOLOCK)
				INNER JOIN #WeeklyResetCustomer t ON bal.CustId = t.custid AND bal.bettype = @bettype 
			WHERE winlostdate <= @Yesterday
		)
BEGIN
	WHILE 1 = 1
	BEGIN
		DELETE TOP (50000) bal
		FROM dbo.BalanceDebitGame bal WITH (ROWLOCK)
			INNER JOIN #WeeklyResetCustomer t ON bal.CustId = t.custid AND bal.bettype = @bettype 
		WHERE winlostdate <= @Yesterday
		
		IF @@ROWCOUNT < 50000
			BREAK
			
		WAITFOR DELAY '00:00:00.280'
	END
END	
DROP TABLE #WeeklyResetCustomer
