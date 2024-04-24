/*<info serverAlias="DBTXN-bodb02" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Dep_DailySum_ParlayBoostAdjust_14]
(
	@WinlostDate SMALLDATETIME,
	@CustIds VARCHAR(MAX) = ''
)
AS
/*
	Created: 20230822@Evan
	DB: DBTXN.bodb02
	Task: LAP - Licensee Parlay Boost - Correct tickets bettype 998 (Parlay Boost Adjustment)

	Revisions:
		- 20230822@Evan: Initialize SP (Integrate Parlay Boost) - [RedmineID: #192238]

*/
BEGIN

	SET NOCOUNT ON;

	--- mail info
	DECLARE @Subject NVARCHAR(1000)
		  , @bodymsg NVARCHAR(MAX)
		  , @recipients VARCHAR(1000)
		  , @WLDate SMALLDATETIME
	
	-- check test version
	DECLARE @isTest BIT = 0  
	SELECT @isTest = dbo.f_CheckSPVersion(@@PROCID);

	DECLARE @tmpSuper TABLE (
		  srecommend INT
	);

	SET @WLDate = @WinlostDate;

	--- temp table 
	DROP TABLE IF EXISTS #tmp_DummyMember;
	DROP TABLE IF EXISTS #tmp_TransInsertUpdate;

	CREATE TABLE #tmp_DummyMember(
		  LicenseeID INT
		, SiteId VARCHAR(20)
		, UserName NVARCHAR(50)
		, MemberId INT
		, SuperId INT
		, MasterId INT
		, AgentId INT
		, CurrencyId INT
		, CurrencyName NVARCHAR(50)
		, ActualRate FLOAT
		, IsSum BIT
		, SiteDBGroupID SMALLINT
	);
	 
	CREATE TABLE #tmp_TransInsertUpdate (
		  RowID INT IDENTITY (1, 1) PRIMARY KEY
		, CustId INT
		, transdate DATETIME
		, oddsid INT
		, hdp1 SMALLMONEY
		, hdp2 SMALLMONEY
		, odds SMALLMONEY
		, stake MONEY
		, Status NVARCHAR(10)
		, winlost MONEY
		, awinlost MONEY
		, mwinlost MONEY
		, playercomm MONEY
		, comm MONEY
		, acomm MONEY
		, apositiontaking SMALLMONEY
		, mpositiontaking SMALLMONEY
		, tpositiontaking SMALLMONEY
		, playerdiscount DECIMAL(9, 8)
		, discount DECIMAL(9, 8)
		, adiscount DECIMAL(9, 8)
		, livehomescore SMALLINT
		, liveawayscore SMALLINT
		, liveindicator BIT
		, betteam NVARCHAR(10)
		, creator INT
		, refno BIGINT
		, comstatus NVARCHAR(20)
		, winlostdate SMALLDATETIME
		, betfrom NVARCHAR(4)
		, betcheck NVARCHAR(50)
		, checktime DATETIME
		, oddsspread MONEY
		, actualrate FLOAT
		, matchid INT
		, recommend INT
		, mrecommend INT
		, ruben TINYINT
		, betid BIGINT
		, statuswinlost TINYINT
		, modds SMALLMONEY
		, bettype SMALLINT
		, betdaqid BIGINT
		, actual_stake MONEY
		, currency TINYINT
		, ip VARCHAR(45)
		, transdesc NVARCHAR(1000)
		, sdiscount DECIMAL(9, 8)
		, scomm MONEY
		, spositiontaking SMALLMONEY
		, swinlost MONEY
		, srecommend INT
		, Username NVARCHAR(50)
		, CurrencyName NVARCHAR(50)
		, virtualrate FLOAT
		, oddstype TINYINT
		, statusID TINYINT
		, currency2 TINYINT
		, balance MONEY
		, SecAcceptFlag BIT
		, transid2 BIGINT
		, RecommDate DATETIME
		, SiteDBGroupID SMALLINT
	);

	--- get list supers
	INSERT INTO @tmpSuper (srecommend)
	SELECT DISTINCT c.srecommend
	FROM CustDB.dbo.Customer c WITH (NOLOCK)
		CROSS APPLY (
			SELECT value
			FROM STRING_SPLIT(@CustIds, ',') f
			WHERE c.custid = f.value
		) AS tmp
	WHERE c.RoleID = 1

	--- get dummies member acc 
	;
	WITH rs AS
	( 
		SELECT l.LicenseeID
			 , dcs.site
			 , dcs.custid
			 , dcs.site + 'ParlayBoostAdj' + e.currency AS UserName
			 , e.ExchangeId AS CurrencyId
			 , e.currency AS CurrencyName
			 , dcs.SiteDBGroupID
			 , eo.actualrate
		FROM CustDB.dbo.Dep_CustSuper dcs WITH (NOLOCK)
			INNER JOIN DBCUST.bodb_Licensee.dbo.licensees l WITH(NOLOCK) ON l.LicenseeName = dcs.site
			INNER JOIN @tmpSuper ts ON dcs.custid = ts.srecommend
			INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON e.ExchangeId = dcs.currency
			INNER JOIN CustDB.dbo.ExchangeDailyOanda eo WITH (NOLOCK) ON eo.ExchangeId = e.ExchangeId
				AND eo.ExchangeDate = @WLDate
	)
	INSERT INTO #tmp_DummyMember (LicenseeID, SiteID, UserName, MemberId, SuperId, MasterId, AgentId, CurrencyId, CurrencyName, ActualRate, SiteDBGroupID, IsSum)
	SELECT rs.LicenseeID
		 , rs.site
		 , rs.UserName
		 , c.custid AS memberId
		 , rs.custid AS superId
		 , c.mrecommend AS masterid
		 , c.recommend AS agentid
		 , rs.CurrencyId
		 , rs.CurrencyName
		 , rs.actualrate
		 , rs.SiteDBGroupID
		 , CASE WHEN c.username IS NULL THEN 0 ELSE 1 END IsSum
	FROM rs
		LEFT JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.username = rs.UserName
			AND rs.custid = c.srecommend
			AND c.roleid = 1;

	IF NOT EXISTS (SELECT TOP 1 1 FROM #tmp_DummyMember)
	BEGIN
		--- do nothing
		RETURN
	END

	DROP TABLE IF EXISTS #tmp_RealAgent;
	DROP TABLE IF EXISTS #tmp_BoostParlayTrans;
	DROP TABLE IF EXISTS #tmp_BoostParlayExists;

	CREATE TABLE #tmp_RealAgent (
		  SuperId INT
		, AgentId INT
	);

	CREATE TABLE #tmp_BoostParlayTrans (
		  Recommend INT
		, Apositiontaking SMALLMONEY
		, lbbs MONEY -- licensee boost bonus sharing
		, bba MONEY -- boost bonus amount
	);

	CREATE TABLE #tmp_BoostParlayExists (
		  TransactionId BIGINT
		, MemberId INT
		, SuperId INT
	);
	
	INSERT INTO #tmp_RealAgent (SuperId, AgentId)
	SELECT t.SuperId
		 , c.recommend
	FROM #tmp_DummyMember t
		INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON t.SuperId = c.srecommend
			AND c.RoleID = 2
	WHERE t.IsSum = 1
		AND EXISTS (
			SELECT TOP 1 1
			FROM DBCUST.bodb_licensee.dbo.LicenseeCust lc WITH (NOLOCK)
			WHERE lc.LicenseeID = t.LicenseeID
				AND lc.CustID = c.recommend
		);
	
	-- get ticket offer Boost Bonus on bettrans14
	INSERT INTO #tmp_BoostParlayTrans (Recommend, Apositiontaking, lbbs, bba)
	SELECT b.recommend
		 , Apositiontaking
		 , ISNULL(TRY_CAST(TRY_CAST(ExtraInfo AS XML).value('(/p1/@lbbs)[1]', 'VARCHAR(50)') AS MONEY),0) lbbs
		 , ISNULL(TRY_CAST(TRY_CAST(ExtraInfo AS XML).value('(/p1/@bba)[1]', 'VARCHAR(50)') AS MONEY),0) bba
	FROM bettrans14 b WITH (NOLOCK)
	WHERE b.winlostdate = @WLDate
		AND b.statusID = 112 	-- Ticket Won
		AND b.bettype = 29 		-- Parlay
		AND b.oddsspread = 2; 	-- Flag detect ticket offer Boost Bonus
		
	--- generate new tranid for member dummy
	INSERT INTO #tmp_TransInsertUpdate (transdate, oddsid, bettype, hdp1, hdp2, betteam, betid, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, refno, winlostdate, matchid, actual_stake, currency, sdiscount, scomm, spositiontaking, swinlost, srecommend, CurrencyName, oddstype, statusID, comstatus, oddsspread, betdaqid, liveindicator, livehomescore, liveawayscore, SecAcceptFlag, checktime, betfrom, betcheck, ruben, statuswinlost, modds, ip, transdesc, currency2, balance, transid2, RecommDate)
	SELECT
		GETDATE() AS transdate
	  , 0 AS oddsid
	  , 998 AS bettype
	  , 0 AS hdp1
	  , 0 AS hdp2
	  , NULL AS betteam
	  , SUM((ISNULL(bba,0) * ISNULL(lbbs, 0)) * 100000000) AS betid -- Licensee Sharing Boost bonus amount
	  , 0 AS odds
	  , 0 AS stake
	  , 'DRAW' AS status
	  , 0 AS winlost
	  , SUM((b.apositiontaking - ISNULL(lbbs,0)) *  ISNULL(bba,0)) AS awinlost 
	  , 0 AS mwinlost
	  , 0 AS playercomm
	  , 0 AS comm
	  , 0 AS acomm
	  , 0 AS apositiontaking
	  , 0 AS mpositiontaking
	  , 0 AS tpositiontaking
	  , 0 AS playerdiscount
	  , 0 AS discount
	  , 0 AS adiscount
	  , 100000000000 AS refno
	  , @WLDate AS winlostdate
	  , 998 AS matchid
	  , 0 AS actual_stake
	  , 0 AS currency
	  , 0 AS sdiscount
	  , 0 AS scomm
	  , 0 AS spositiontaking
	  , 0 AS swinlost
	  , t.SuperId AS srecommend
	  , '' AS CurrencyName
	  , 1 AS oddstype
	  , 111 AS statusID
	  , 0 AS comstatus
	  , SUM(ISNULL(bba,0)) AS oddsspread -- Boost bonus amount
	  , -1 AS betdaqid
	  , 0 AS liveindicator
	  , 0 AS livehomescore
	  , 0 AS liveawayscore
	  , 0 AS SecAcceptFlag
	  , GETDATE() AS checktime
	  , 'd' AS betfrom
	  , '' AS betcheck
	  , 1 AS ruben
	  , NULL AS statuswinlost
	  , 0 AS modds
	  , '' AS ip
	  , 'Parlay Boost Adjustment' AS transdesc
	  , NULL AS currency2
	  , 0 AS balance
	  , 0 AS transid2
	  , NULL AS RecommDate
	FROM #tmp_BoostParlayTrans b WITH (NOLOCK)
		INNER JOIN #tmp_RealAgent t ON t.AgentId = b.Recommend
	GROUP BY
		t.SuperId;
	
	-- update info Dummy Acc to temp table
	UPDATE t
	SET Username = td.UserName
	  , Custid = td.MemberId
	  , recommend = td.AgentId
	  , mrecommend = td.MasterId
	  , ActualRate = td.ActualRate
	  , virtualrate = td.ActualRate
	  , creator = td.MemberId
	  , currency = td.CurrencyId
	  , CurrencyName = td.CurrencyName
	  , SiteDBGroupID = td.SiteDBGroupID
	FROM #tmp_TransInsertUpdate t
		INNER JOIN #tmp_DummyMember td ON t.srecommend = td.SuperId AND td.IsSum = 1;

	-- get existing parlay boost adjustment trans
	INSERT INTO #tmp_BoostParlayExists (TransactionId, MemberId, SuperId)
	SELECT b.transid
		 , b.custid
		 , b.srecommend
	FROM bettrans14 b WITH (NOLOCK)
	WHERE b.winlostdate = @WLDate
		AND b.matchid = 998
		AND b.bettype = 998
		AND b.custid <> 0;
	
	DECLARE @TransIDs TABLE (
		  RowID INT IDENTITY (1, 1) PRIMARY KEY
		, TransID BIGINT
		, seq TINYINT
	);
	DECLARE @MaxGenTransId INT
		  , @total_transid INT;

	SELECT @MaxGenTransId = MAX(RowID)
	FROM #tmp_TransInsertUpdate;

	WHILE (@MaxGenTransId > 0)
	BEGIN
		IF (@MaxGenTransId > 255)
			SET @total_transid = 255
		ELSE
			SET @total_transid = @MaxGenTransId;

		INSERT INTO @TransIDs (seq, TransID)
		EXEC Get_bettrans_transid_Range @total_transid = @total_transid;

		SET @MaxGenTransId = @MaxGenTransId - @total_transid;
	END;

	--- insert new trans 
	INSERT INTO dbo.bettrans14 (transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, Status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, RecommDate, SiteDBGroupID)
	SELECT tr.TransID
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
		 , SiteDBGroupID
	FROM #tmp_TransInsertUpdate t
		INNER JOIN @TransIDs tr ON tr.RowID = t.RowID
	WHERE NOT EXISTS (
			SELECT TOP 1 1
			FROM #tmp_BoostParlayExists bp
			WHERE bp.SuperId = t.srecommend
				AND bp.MemberId = t.custid
		);

	IF EXISTS (SELECT TOP 1 1 FROM #tmp_BoostParlayExists)
	BEGIN
    	----- update exists trans 
		UPDATE b 
		SET b.awinlost = CASE WHEN t.CustId IS NULL THEN 0 ELSE t.awinlost END
		  , b.oddsspread = CASE WHEN t.CustId IS NULL THEN 0 ELSE t.oddsspread END
		  , b.betid = CASE WHEN t.CustId IS NULL THEN 0 ELSE t.betid END
		  , b.custid =	CASE WHEN t.CustId IS NULL THEN 0 ELSE b.custid END
		  , b.Recommend = CASE WHEN t.CustId IS NULL THEN 0 ELSE b.Recommend END
		  , b.mrecommend = CASE WHEN t.CustId IS NULL THEN 0 ELSE b.mrecommend END
		  , b.srecommend = CASE WHEN t.CustId IS NULL THEN 0 ELSE b.srecommend END
		FROM dbo.bettrans14 b WITH (ROWLOCK)
			INNER JOIN #tmp_BoostParlayExists bp ON b.TransId = bp.TransactionId
			LEFT JOIN #tmp_TransInsertUpdate t ON b.srecommend = t.srecommend AND b.custid = t.custid;
    END

	--- get licensees that support odds adjustment but do not have dummy member account and send email notification
	IF EXISTS (
			SELECT TOP 1 1
			FROM #tmp_DummyMember d
			WHERE d.IsSum = 0
				AND d.SiteID NOT IN ('Saba789', 'SEAL888')
		)
	BEGIN
		
		SELECT @Subject = 'Missing dummy account notification'
			 , @bodymsg = ''
			 , @recipients =
							CASE
								WHEN @isTest = 0 AND
									@@servername IN ('DBTRANS', 'DBGRP01N1', 'DBGRP02N1', 'DBGRP01N2', 'DBGRP02N2') THEN 'it@starixsoft.com;ben.nguyen@starixsoft.com'
								ELSE 'dba_local@starixsoft.com'
							END
		;
		WITH rs AS
		(
			SELECT td.SiteID 
				 , c.username
				 , td.CurrencyName
			FROM #tmp_DummyMember td
				INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON td.SiteID = c.site
					AND td.CurrencyId = c.currency
					AND td.SuperId = c.srecommend
			WHERE td.IsSum = 0
				AND c.roleid = 2
				AND c.username = td.SiteId + 'ACC' + td.CurrencyName + '01'
				AND td.SiteID NOT IN ('Saba789', 'SEAL888')
		)
		SELECT @bodymsg = N'\
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
			+ CAST((
				SELECT td = rs.SiteID
					 , ''
					 , td = rs.CurrencyName
					 , ''
					 , td = rs.username
					 , ''
					 , td = rs.SiteID + 'ParlayBoostAdj' + rs.CurrencyName
					 , ''
				FROM rs
				FOR XML PATH ('tr'), TYPE
			) AS NVARCHAR(MAX)) + N'</table></br>'

			+ 'Best regards, </br> 
					This is an auto-mail from the Internal System. Please do not reply.';

		-- SEND mail
		EXECUTE msdb.dbo.sp_send_dbmail @recipients = @recipients
									  , @copy_recipients = ''
									  , @blind_copy_recipients = ''
									  , @subject = @Subject
									  , @body = @bodymsg
									  , @body_format = 'HTML'

	END
END
GO