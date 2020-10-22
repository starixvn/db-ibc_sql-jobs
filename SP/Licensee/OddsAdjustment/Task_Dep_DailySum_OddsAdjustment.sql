/*<info serverAlias="DBTXN-bodb02" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Dep_DailySum_OddsAdjustment]
(
	@WinlostDate SMALLDATETIME
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

	--- temp table 
	DECLARE @tblSiteSupported TABLE(SiteName VARCHAR(50))
	DECLARE @tblDummyMember TABLE(SiteId VARCHAR(20), UserName NVARCHAR(50), MemberId INT, SuperId INT, MasterId INT, AgentId INT, CurrencyId INT, CurrencyName NVARCHAR(50), ActualRate FLOAT)
	CREATE TABLE #__tblSumOddsAdjustment (TransactionId BIGINT, MemberId INT, SuperId INT)

	--- get all licensees that support odds adjustment
	INSERT INTO @tblSiteSupported(SiteName)
	SELECT vp.SiteName
	FROM 
		DBPRO.bodb02.dbo.LicSiteSetting ss WITH(NOLOCK)
		INNER JOIN DBCUST.SiteConfig.dbo.LicVendorProfile vp WITH(NOLOCK)
			ON ss.SiteId = vp.SiteId
	WHERE ss.ApplyDeductedSpread = 1

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
			INNER JOIN @tblSiteSupported sp
				ON sp.SiteName = dcs.site
			INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK)
				ON e.ExchangeId = dcs.currency
	)
	INSERT INTO @tblDummyMember(SiteId, UserName, memberid, SuperId, MasterId, AgentId, CurrencyId, CurrencyName, ActualRate)	
	SELECT
		rs.site
		,c.username
		,c.custid AS memberId
		,c.srecommend AS superId
		,c.mrecommend AS masterid
		,c.recommend AS agentid
		,rs.CurrencyId
		,rs.CurrencyName
		,rs.actualrate
	FROM 
		rs
		LEFT JOIN CustDB.dbo.customer c WITH (NOLOCK)
			ON c.srecommend = rs.custid
	WHERE 
		c.roleid = 1
		AND c.username = rs.UserName

	SELECT * FROM @tblDummyMember

	IF NOT EXISTS (SELECT TOP 1 1 FROM @tblDummyMember)
	BEGIN
		--- do nothing
		RETURN
	END

	--- generate new trans for summary data
	SELECT
		--new tranid for member dummy
		t.memberid AS custid
	   ,GETDATE() transdate
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
	   ,-1*SUM(fMember.oriWL + fAgent.oriWL + fMaster.oriWL + fSuper.oriWL + b.scomm) - SUM(tblTemp.AdjCompanyWL) awinlost
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
	   ,@winlostdate winlostdate
	   ,999 matchid
	   ,t.AgentId recommend
	   ,t.MasterId mrecommend
	   ,0 actual_stake
	   ,t.CurrencyId currency
	   ,0 sdiscount -- ask
	   ,0 scomm
	   ,0 spositiontaking
	   ,0 swinlost
	   ,t.SuperId srecommend
	   ,t.UserName Username
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
	   ,t.ActualRate --ask 'value in table exchange' actualrate -- ask about this bc the job runs for yesterday
	   ,t.MemberId AS creator -- ask
	   ,'d' betfrom -- ask d:deposit
	   ,'' betcheck -- ask
	   ,1 ruben
	   ,NULL statuswinlost --ask
	   ,0 modds
	   ,'' ip -- ask '' or ...
	   ,'Odds Spread Adjustment' transdesc -- ask 
	   ,t.ActualRate virtualrate -- -- ask about this bc the job runs for yesterday 
	   ,NULL currency2
	   ,0 balance 
	   ,0 transid2 
	   ,NULL RecommDate
	   ,SUM(tblTemp.AdjCompanyWL) AS AdjAmount
	   ,-1*SUM(fMember.oriWL + fAgent.oriWL + fMaster.oriWL + fSuper.oriWL + b.scomm) AS OriAmount
	   ,-1*SUM(fMember.oriWL + fAgent.oriWL + fMaster.oriWL + fSuper.oriWL + b.scomm) - SUM(tblTemp.AdjCompanyWL) AS DeductedOddSpreadCost

	INTO #__tmpTransInsertUpdate
	FROM 
		bettrans b WITH (NOLOCK)
		INNER JOIN BettransInfo bi WITH (NOLOCK)
			ON b.transid = bi.transid
		INNER JOIN @tblDummyMember t
			ON t.SuperId = b.srecommend
		LEFT JOIN f_Set_OddsTypeBettypes() fdec -- check for decimal odds only
			ON b.bettype = fdec.BetType
		CROSS APPLY
		(
			VALUES (-1*(b.swinlost + b.awinlost + b.mwinlost + b.scomm + (b.winlost - b.actual_stake)))
		) AS tblTemp(AdjCompanyWL)
		CROSS APPLY dbo.f_Set_CalOriginalLicenseeWL(bi.OriginalOdds, b.odds, (b.winlost - b.actual_stake), b.statuswinlost, fdec.OddsType) fMember
		CROSS APPLY dbo.f_Set_CalOriginalLicenseeWL(bi.OriginalOdds, b.odds, b.awinlost, b.statuswinlost, fdec.OddsType) fAgent
		CROSS APPLY dbo.f_Set_CalOriginalLicenseeWL(bi.OriginalOdds, b.odds, b.mwinlost, b.statuswinlost, fdec.OddsType) fMaster
		CROSS APPLY dbo.f_Set_CalOriginalLicenseeWL(bi.OriginalOdds, b.odds, b.swinlost, b.statuswinlost, fdec.OddsType) fSuper
	WHERE
		b.winlostdate = @WinlostDate
		AND bi.OriginalOdds IS NOT NULL
		AND b.statusid IN (112, 113) -- win/losed
	
	GROUP BY b.winlostdate
			,t.UserName
			,t.MemberId
			,t.SuperId
			,t.MasterId
			,t.AgentId
			,t.CurrencyId
			,t.CurrencyName
			,t.ActualRate

	---- get existing odds adjustment trans
	INSERT INTO #__tblSumOddsAdjustment(TransactionId, MemberId, SuperId)
	SELECT b.transid, b.custid, b.srecommend
	FROM bettrans b WITH(NOLOCK)
	WHERE 
		b.winlostdate = @WinlostDate
		AND b.matchid = 999
		AND b.bettype = 999

	--- insert new trans 
	INSERT INTO dbo.bettrans
	(
		custid, transdate, oddsid, hdp1, hdp2, odds, stake, Status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking
		, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate
		, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid
		, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype
		, statusID, currency2, balance, SecAcceptFlag, transid2, RecommDate
	)
	SELECT custid, transdate, oddsid, hdp1, hdp2, odds, stake, Status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking
		, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate
		, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid
		, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype
		, statusID, currency2, balance, SecAcceptFlag, transid2, RecommDate
	FROM #__tmpTransInsertUpdate t
	WHERE 
		NOT EXISTS 
		(
			SELECT TOP 1 1 
			FROM #__tblSumOddsAdjustment soa 
			WHERE soa.SuperId = t.srecommend AND soa.MemberId = t.custid
		)

	----- update existing ones
	UPDATE b WITH(ROWLOCK)
		SET b.awinlost = ISNULL(t.awinlost, 0)
	FROM bettrans b
		INNER JOIN #__tblSumOddsAdjustment soa
			ON b.transid = soa.TransactionId
		LEFT JOIN #__tmpTransInsertUpdate t
			ON b.srecommend = t.srecommend AND b.custid = t.custid

	--- get licensees that support odds adjustment but do not have dummy member account and send email notification
	IF EXISTS (SELECT TOP 1 1 FROM @tblDummyMember d WHERE d.MemberId IS NULL)
	BEGIN

		SELECT @Subject = 'Missing dummy account notification'
			, @bodymsg = ''
			, @recipients = CASE WHEN @@SERVERNAME = 'DB206' THEN 'sol.le@starixvn.com;' ELSE 'sol.le@starixvn.com;' END

		SELECT
			@bodymsg = N'\
					Dear All,</br></br>
					Missing dummy account for licensees.</br>
					Please take a look at the table below:</br></br> '
			+ '<table border="1"> '
			+ '<tr><th>Licensee</th>'
			+ '</tr>'
			+ CAST((SELECT
					td = d.SiteId
				   ,''
				FROM @tblDummyMember d 
				WHERE d.MemberId IS NULL
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

	DROP TABLE #__tmpTransInsertUpdate
	DROP TABLE #__tblSumOddsAdjustment

END
GO