/*<info serverAlias="DBTXN-bodb02" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Dep_DailySum_OddsAdjustment_14]
(
	@WinlostDate SMALLDATETIME,
	@CustIds VARCHAR(MAX) = ''
)
AS
/*
	Created: 20201005@Sol
	DB: DBTXN.bodb02
	Task: LAP - Licensee Spread Setting - Generate new trans for bettype 999 (odds adjusted)

	Revisions:
		- 20201005@Sol: Initialize SP - [RedmineID: #142532]
*/
BEGIN
	
	SET NOCOUNT ON;

	--- #declare section
	--- mail info
	DECLARE	@Subject NVARCHAR(1000)
			, @bodymsg NVARCHAR(MAX)
			, @recipients VARCHAR(1000)
			, @WLDate SMALLDATETIME

	SET @WLDate = @WinlostDate

	-- check test version
	DECLARE @isTest BIT = 0  
	SELECT @isTest = dbo.f_CheckSPVersion(@@PROCID);

	--- temp table 
	DECLARE @tblSiteSupported TABLE(SiteName VARCHAR(50))
	DECLARE @tblDummyMember TABLE(SiteId VARCHAR(20), UserName NVARCHAR(50), MemberId INT, SuperId INT, MasterId INT, AgentId INT, CurrencyId INT, CurrencyName NVARCHAR(50), ActualRate FLOAT, IsSum BIT)
	DECLARE @tmpSuper TABLE (srecommend INT)

	CREATE TABLE #__tblSumOddsAdjustment (TransactionId BIGINT, MemberId INT, SuperId INT)
	CREATE TABLE #__tmpTransInsertUpdate 
	(
		CustId INT, transdate DATETIME, oddsid INT, hdp1 SMALLMONEY, hdp2 SMALLMONEY, odds SMALLMONEY, stake MONEY, Status NVARCHAR(10), winlost MONEY,
		awinlost MONEY, mwinlost MONEY, playercomm MONEY, comm MONEY, acomm MONEY, apositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, tpositiontaking SMALLMONEY,
		playerdiscount DECIMAL(9,8), discount DECIMAL(9,8), adiscount DECIMAL(9,8), livehomescore SMALLINT, liveawayscore SMALLINT, liveindicator BIT, betteam NVARCHAR(10),
		creator INT, refno BIGINT, comstatus NVARCHAR(20), winlostdate SMALLDATETIME, betfrom NVARCHAR(1), betcheck NVARCHAR(50), checktime DATETIME, oddsspread MONEY,
		actualrate FLOAT, matchid INT, recommend INT, mrecommend INT, ruben TINYINT, betid BIGINT, statuswinlost TINYINT, modds SMALLMONEY, bettype SMALLINT,
		betdaqid BIGINT, actual_stake MONEY, currency TINYINT, ip NVARCHAR(15), transdesc NVARCHAR(1000), sdiscount DECIMAL(9,8), scomm MONEY, spositiontaking SMALLMONEY,
		swinlost MONEY, srecommend INT, Username NVARCHAR(50), CurrencyName NVARCHAR(50), virtualrate FLOAT, oddstype TINYINT, statusID TINYINT, currency2 TINYINT,
		balance MONEY, SecAcceptFlag BIT, transid2 BIGINT, RecommDate DATETIME
	)

	--- get all licensees that support odds adjustment
	INSERT INTO @tblSiteSupported(SiteName)
	SELECT vp.SiteName
	FROM 
		DBPRO.bodb02.dbo.LicSiteSetting ss WITH(NOLOCK)
		INNER JOIN DBCUST.SiteConfig.dbo.LicVendorProfile vp WITH(NOLOCK)
			ON ss.SiteId = vp.SiteId
	WHERE ss.ApplySpreadAdjustment = 1

	--- get list super
	INSERT INTO @tmpSuper (srecommend)
	SELECT DISTINCT c.srecommend
	FROM CustDB.dbo.Customer c WITH (NOLOCK)
		CROSS APPLY 
		(
			SELECT val FROM bodb02.dbo.f_SplitString(@CustIds, ',') f WHERE c.custid = f.val
		) AS tmp
	WHERE c.roleid = 1
	OPTION (MAXRECURSION 0)

	--- get dummies member acc 
	;WITH rs AS
	(
		SELECT
			dcs.site
			,dcs.custid
			,dcs.site + e.currency + '01OddsAdj' AS UserName
			,e.ExchangeId AS CurrencyId
			,e.currency AS CurrencyName
			,e.actualrate
		FROM 
			CustDB.dbo.dep_custsuper dcs WITH (NOLOCK)
			INNER JOIN @tmpSuper ts 
				ON dcs.custid = ts.srecommend
			INNER JOIN @tblSiteSupported sp
				ON sp.SiteName = dcs.site
			INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK)
				ON e.ExchangeId = dcs.currency
	)
	INSERT INTO @tblDummyMember(SiteId, UserName, memberid, SuperId, MasterId, AgentId, CurrencyId, CurrencyName, ActualRate, IsSum)	
	SELECT
		rs.site
		,rs.UserName
		,c.custid AS memberId
		,rs.custid AS superId
		,c.mrecommend AS masterid
		,c.recommend AS agentid
		,rs.CurrencyId
		,rs.CurrencyName
		,rs.actualrate
        ,CASE WHEN c.username IS NULL THEN 0 ELSE 1 END IsSum
	FROM 
		rs
		LEFT JOIN CustDB.dbo.customer c WITH (NOLOCK)
			ON c.username = rs.UserName AND rs.custid = c.srecommend AND c.roleid = 1

	IF NOT EXISTS (SELECT TOP 1 1 FROM @tblDummyMember)
	BEGIN
		--- do nothing
		RETURN
	END

	-- get list agent to use index in bettrans
	CREATE TABLE #__tblLicenseeAgent(AgentId INT)

	INSERT INTO #__tblLicenseeAgent (AgentId)
	SELECT lc.custid 
	FROM @tblSiteSupported t 
		INNER JOIN DBCUST.bodb_licensee.dbo.licensees l WITH(NOLOCK)
			ON l.licenseeName = t.SiteName
		INNER JOIN DBCUST.bodb_licensee.dbo.LicenseeCust lc WITH(NOLOCK)
			ON l.licenseeid = lc.licenseeid
	
	CREATE TABLE #__tblRealAgent(SuperId INT, MasterId INT, AgentId INT, CurrencyId INT, CurrencyName NVARCHAR(50))

	INSERT INTO #__tblRealAgent(SuperId , MasterId , AgentId , CurrencyId , CurrencyName )
	SELECT t.SuperId, t.MasterId, c.recommend, t.CurrencyId, t.CurrencyName 
	FROM @tblDummyMember t
		INNER JOIN CUSTDB.dbo.Customer c WITH(NOLOCK)
			ON t.SuperId = c.srecommend AND c.roleid = 2
	WHERE 
		t.IsSum = 1 
		AND EXISTS (SELECT TOP 1 1 FROM #__tblLicenseeAgent t WHERE t.AgentID = c.recommend)

	--- generate new trans for summary data
	INSERT INTO #__tmpTransInsertUpdate
	(
		transdate,oddsid,bettype,hdp1,hdp2,betteam,betid ,odds,stake,status,winlost,awinlost,mwinlost,playercomm,comm,acomm,apositiontaking,mpositiontaking,tpositiontaking
		,playerdiscount,discount,adiscount,refno,winlostdate,matchid, actual_stake,currency,sdiscount,scomm,spositiontaking,swinlost,srecommend,CurrencyName,oddstype 
		,statusID ,comstatus,oddsspread,betdaqid ,liveindicator,livehomescore,liveawayscore,SecAcceptFlag,checktime,betfrom,betcheck,ruben,statuswinlost, modds,ip
		,transdesc,currency2,balance ,transid2 ,RecommDate
	)
	SELECT
		--new tranid for member dummy
		--t.memberid AS custid
	   
       GETDATE() transdate
	   ,0 oddsid
	   ,999 AS bettype
	   ,0 hdp1
	   ,0 hdp2
	   ,NULL betteam
	   ,0 betid -- ask?
	   ,0 odds
	   ,0 stake
	   ,'DRAW' status
	   ,0 winlost
	   ,-1*((-1*SUM(fMember.oriWL + fAgent.oriWL + fMaster.oriWL + fSuper.oriWL + b.scomm)) - SUM(tblTemp.AdjCompanyWL)) awinlost
	   ,0 mwinlost
	   ,0 playercomm
	   ,0 comm
	   ,0 acomm
	   ,0 apositiontaking
	   ,0 mpositiontaking
	   ,0 tpositiontaking
	   ,0 playerdiscount
	   ,0 discount
	   ,0 adiscount
	   ,100000000000 refno
	   ,@WLDate winlostdate
	   ,999 matchid
	   --,t.AgentId recommend
	   --,t.MasterId mrecommend
	   ,0 actual_stake
	   ,t.CurrencyId currency
	   ,0 sdiscount -- ask
	   ,0 scomm
	   ,0 spositiontaking
	   ,0 swinlost
	   ,t.SuperId srecommend
	   --,t.UserName Username
	   ,t.CurrencyName CurrencyName
	   ,1 oddstype --ask , -- decimal odd only -> ask
	   ,111 statusID -- gdoc = 0 -> ask
	   ,0 comstatus -- null or 0 ---ask
	   ,0 oddsspread
	   ,-1 betdaqid 
	   ,0 liveindicator
	   ,0 livehomescore
	   ,0 liveawayscore
	   ,0 SecAcceptFlag
	   ,GETDATE() checktime  -- ask 
	   --,t.ActualRate --ask 'value in table exchange' actualrate -- ask about this bc the job runs for yesterday
	   --,t.MemberId AS creator -- ask
	   ,'d' betfrom -- ask d:deposit
	   ,'' betcheck -- ask
	   ,1 ruben
	   ,NULL statuswinlost --ask
	   ,0 modds
	   ,'' ip -- ask '' or ...
	   ,'Odds Spread Adjustment' transdesc -- ask 
	   --,t.ActualRate virtualrate -- -- ask about this bc the job runs for yesterday 
	   ,NULL currency2
	   ,0 balance 
	   ,0 transid2 
	   ,NULL RecommDate

	FROM 
		bettrans14 b WITH (NOLOCK)
		INNER JOIN BettransInfo14 bi WITH (NOLOCK)
			ON b.transid = bi.transid
		INNER JOIN #__tblRealAgent t
			ON t.AgentId = b.recommend
		LEFT JOIN f_Set_OddsTypeBettypes() fdec -- check for decimal odds only
			ON b.bettype = fdec.BetType
		CROSS APPLY
		(
			VALUES (-1*(b.swinlost + b.awinlost + b.mwinlost + b.scomm + (b.winlost - b.actual_stake)))
		) AS tblTemp(AdjCompanyWL)
		CROSS APPLY dbo.f_Set_CalOriginalLicenseeWL(bi.OriginalOdds, b.odds, 0, (b.winlost - b.actual_stake), b.actual_stake, b.statusID, b.statuswinlost, b.apositiontaking, b.mpositiontaking, b.spositiontaking, 1, fdec.OddsType) fMember
		CROSS APPLY dbo.f_Set_CalOriginalLicenseeWL(bi.OriginalOdds, b.odds, -1 * fMember.oriWL, b.awinlost, b.actual_stake, b.statusID, b.statuswinlost, b.apositiontaking, b.mpositiontaking, b.spositiontaking, 2, fdec.OddsType) fAgent
		CROSS APPLY dbo.f_Set_CalOriginalLicenseeWL(bi.OriginalOdds, b.odds, -1 * fMember.oriWL, b.mwinlost, b.actual_stake, b.statusID, b.statuswinlost, b.apositiontaking, b.mpositiontaking, b.spositiontaking, 3, fdec.OddsType) fMaster
		CROSS APPLY dbo.f_Set_CalOriginalLicenseeWL(bi.OriginalOdds, b.odds, -1 * fMember.oriWL, b.swinlost, b.actual_stake, b.statusID, b.statuswinlost, b.apositiontaking, b.mpositiontaking, b.spositiontaking, 4, fdec.OddsType) fSuper
	WHERE
		b.winlostdate = @WLDate
		AND bi.OriginalOdds IS NOT NULL
		AND b.statusID IN (101, 102, 103, 111, 112, 113) -- reject, void, refund, draw, won, lose
	
	GROUP BY b.winlostdate
			,t.SuperId
			,t.CurrencyId
			,t.CurrencyName

	-- update info to temp table
	UPDATE t
		SET Username = td.UserName,
			Custid = td.MemberId,
			Recommend = td.AgentId,
			mrecommend = td.MasterId,
			ActualRate = td.ActualRate,
			VirtualRate = td.ActualRate,
			Creator = td.MemberId
	FROM #__tmpTransInsertUpdate t
		INNER JOIN @tblDummyMember td
			ON t.srecommend = td.SuperId AND td.IsSum = 1

	--- end

	---- get existing odds adjustment trans
	INSERT INTO #__tblSumOddsAdjustment(TransactionId, MemberId, SuperId)
	SELECT b.transid, b.custid, b.srecommend
	FROM bettrans14 b WITH(NOLOCK)
	WHERE 
		b.winlostdate = @WLDate
		AND b.matchid = 999
		AND b.bettype = 999

	----- update existing ones
	UPDATE b WITH(ROWLOCK)
		SET b.awinlost = t.awinlost
	FROM bettrans14 b
		INNER JOIN #__tblSumOddsAdjustment soa
			ON b.transid = soa.TransactionId
		INNER JOIN #__tmpTransInsertUpdate t
			ON b.srecommend = t.srecommend AND b.custid = t.custid

	--- get licensees that support odds adjustment but do not have dummy member account and send email notification
	IF EXISTS (SELECT TOP 1 1 FROM @tblDummyMember d WHERE d.IsSum = 0)
	BEGIN

		SELECT @Subject = 'Missing dummy account notification'
			, @bodymsg = ''
			, @recipients = CASE WHEN @isTest = 0 AND @@SERVERNAME = 'DBTRANS' THEN 'it@starixvn.com;ben.nguyen@starixvn.com' ELSE 'dba_local@starixvn.com' END

		SELECT lc.CustID, Currency INTO #__tblRealLicensee
		FROM DBCUST.bodb_licensee.dbo.LicenseeCust lc WITH(NOLOCK)

		;WITH rs AS
		(
			SELECT td.SiteId, td.SuperId, c.recommend, c.username, c.currency , td.CurrencyName
			FROM @tblDummyMember td
				INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK)
					ON td.SiteId = c.site AND td.CurrencyId = c.currency AND td.SuperId = c.srecommend
			WHERE td.IsSum = 0
				AND c.roleid = 2
				AND c.username LIKE '%' + td.CurrencyName + '01'
				AND EXISTS (SELECT TOP 1 1 FROM	#__tblRealLicensee t WHERE t.CustID = c.recommend AND t.Currency = td.CurrencyId)
		)
		SELECT
			@bodymsg = N'\
					Dear All,</br></br>
					Missing dummy account for licensees.</br>
					Please take a look at the table below:</br></br> '
			+ '<table border="1"> '
			+ '<tr>'
			+ '<th>Licensee Name</th>'
			+ '<th>Currency</th>'
			+ '<th>Agent Username</th>'
			+ '<th>Dummy Username</th>'
			+ '</tr>'
			+ CAST((SELECT
					td = rs.SiteId
				   ,''
				   ,td = rs.CurrencyName
				   ,''
				   ,td = rs.username
				   ,''
				   ,td = rs.username + 'OddsAdj'
				   ,''
				FROM rs
				FOR XML PATH ('tr'), TYPE)
			AS NVARCHAR(MAX)) + N'</table></br>'

			+ 'Best regards, </br> 
					This is an auto-mail from the Internal System. Please do not reply.';

		-- SEND mail
		EXECUTE msdb.dbo.sp_send_dbmail @recipients = @recipients
										,@copy_recipients = ''
										,@blind_copy_recipients = ''
										,@subject = @Subject
										,@body = @bodymsg
										,@body_format = 'HTML'

	END

	IF OBJECT_ID('tempdb..#__tblSumOddsAdjustment') IS NOT NULL DROP TABLE #__tblSumOddsAdjustment
	IF OBJECT_ID('tempdb..#__tmpTransInsertUpdate') IS NOT NULL DROP TABLE #__tmpTransInsertUpdate
	IF OBJECT_ID('tempdb..#__tblRealLicensee') IS NOT NULL DROP TABLE #__tblRealLicensee
	IF OBJECT_ID('tempdb..#__tblLicenseeAgent') IS NOT NULL DROP TABLE #__tblLicenseeAgent
	IF OBJECT_ID('tempdb..#__tblRealAgent') IS NOT NULL DROP TABLE #__tblRealAgent

END
GO