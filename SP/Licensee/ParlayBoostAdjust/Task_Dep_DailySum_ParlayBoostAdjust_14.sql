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
		, SiteID VARCHAR(20)
		, SuperId INT
		, MemberId INT
		, CurrencyId INT
		, CurrencyName NVARCHAR(50)
		, IsSum BIT
	);
	 
	CREATE TABLE #tmp_TransInsertUpdate (
		  awinlost MONEY
		, betid BIGINT
		, srecommend INT
		, oddsspread MONEY
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
		FROM CustDB.dbo.Dep_CustSuper dcs WITH (NOLOCK)
			INNER JOIN DBCUST.bodb_licensee.dbo.licensees l WITH(NOLOCK) ON l.licenseeName = dcs.site
			INNER JOIN @tmpSuper ts ON dcs.custid = ts.srecommend
			INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON e.ExchangeId = dcs.currency
			INNER JOIN CustDB.dbo.ExchangeDailyOanda eo WITH (NOLOCK) ON eo.ExchangeId = e.ExchangeId
				AND eo.ExchangeDate = @WLDate
	)
	INSERT INTO #tmp_DummyMember (LicenseeID, SiteID, SuperId, MemberId, CurrencyId, CurrencyName, IsSum)
	SELECT rs.LicenseeID
		 , rs.site
		 , rs.custid AS superId
		 , c.custid AS memberId
		 , rs.CurrencyId
		 , rs.CurrencyName
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
	DROP TABLE IF EXISTS #tmp_ParlayBoostAdjust;

	CREATE TABLE #tmp_RealAgent (
		  SuperId INT
		, AgentId INT
	);

	CREATE TABLE #tmp_BoostParlayTrans (
		  Recommend INT
		, Apositiontaking SMALLMONEY
		, lbbs DECIMAL(9,8)
		, bba MONEY
	);

	CREATE TABLE #tmp_ParlayBoostAdjust (
		  TransactionId BIGINT
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
			WHERE lc.LicenseeID = t.SiteID
				AND lc.CustID = c.recommend
		);
	
	INSERT INTO #tmp_BoostParlayTrans (Recommend, Apositiontaking, lbbs, bba)
	SELECT b.recommend
		 , Apositiontaking
		 , ISNULL(TRY_CAST(CAST(ExtraInfo AS XML).value('(/p1/@lbbs)[1]', 'VARCHAR(50)') AS MONEY),0) lbbs
		 , ISNULL(TRY_CAST(CAST(ExtraInfo AS XML).value('(/p1/@bba)[1]', 'VARCHAR(50)') AS MONEY),0) bba
	FROM bettrans14 b WITH (NOLOCK)
	WHERE b.winlostdate = @WLDate
		AND b.statusID = 112 	-- Ticket Won
		AND b.bettype = 29 		-- Parlay
		AND b.oddsspread = 2; 	-- Flag detect ticket offer Boost Bonus
		
	-- generate new tranid for member dummy
	INSERT INTO #tmp_TransInsertUpdate (srecommend, awinlost, oddsspread, betid)
	SELECT t.SuperId srecommend
		 , SUM((b.apositiontaking - ISNULL(lbbs, 0)) * ISNULL(bba, 0)) -- awinlost
		 , SUM(ISNULL(bba, 0)) oddsspread -- Boost bonus amount
		 , SUM((ISNULL(bba,0) * ISNULL(lbbs, 0)) * 100000000) betid -- Licensee Sharing Boost bonus amount
	FROM #tmp_BoostParlayTrans b WITH (NOLOCK)
		INNER JOIN #tmp_RealAgent t ON t.AgentId = b.Recommend
	GROUP BY t.SuperId;
	
	-- update info to temp table
	UPDATE t
	SET t.CustID = td.MemberId
	FROM #tmp_TransInsertUpdate t
		INNER JOIN #tmp_DummyMember td ON t.srecommend = td.SuperId AND td.IsSum = 1;

	-- get existing parlay boost adjustment trans
	INSERT INTO #tmp_ParlayBoostAdjust (TransactionId)
	SELECT b.transid
	FROM bettrans14 b WITH (NOLOCK)
	WHERE b.winlostdate = @WLDate
		AND b.matchid = 998
		AND b.bettype = 998;
	
	-- update exists trans 
	UPDATE b WITH (ROWLOCK)
	SET b.awinlost = t.awinlost
	  , b.oddsspread = t.oddsspread
	  , b.betid = t.betid
	FROM bettrans14 b
		INNER JOIN #tmp_ParlayBoostAdjust soa ON b.transid = soa.TransactionId
		INNER JOIN #tmp_TransInsertUpdate t ON b.srecommend = t.srecommend
			AND b.CustID = t.MemberId;

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
								ELSE 'harmony.huynh@starixsoft.com,evan.trinh@nexcel.com'
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