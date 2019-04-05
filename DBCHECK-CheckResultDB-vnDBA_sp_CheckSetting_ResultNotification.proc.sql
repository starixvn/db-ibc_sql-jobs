SET ANSI_NULLS ON;
SET	QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE	dbo.vnDBA_sp_CheckSetting_ResultNotification
					@to					VARCHAR(MAX)	= 'pontus@starixsoft.com'
				,	@cc					VARCHAR(MAX)	= ''
				,	@bcc				VARCHAR(MAX)	= ''
				,	@mode				INT				= 3
AS
/*
	Creator:	20170411@Billy
	Task:		Notify Auto Check Settings is finished - [Redmine: #74664]
	Database:	DBCHECK.CheckResultDB
	
	Revisions:	
		- 20170620@Billy:	Add check status result - [Redmine: #00000]
		- 20170914@Billy:	Add log history and backup path in email - [Redmine: #00000]
		- 20180102@Billy:	Send failed checksum to 「DB JOB MONITOR」 room - [Redmine: #88932]
		- 20180202@Billy:	Get SportName from DBPRO - [Redmine: #00000]
		- 20180720@Billy:	Integrate check commission - [Redmine: #00000]
		- 20180801@Elodie:	Update filter of commission result - [Redmine: #99249]
		- 20180806@Elodie:	Exclude ignored cust from table result - [Redmine: #73556]
		- 20180807@Billy:	Fix bug of rendering result - [Redmine: #99249]
		- 20180816@Billy:	Integrate Bet Limit & Stake Level checking - [Redmine: #99249]
		- 20190405@Billy:	Update mail format - [Redmine: #111478]
*/
BEGIN;
	SET NOCOUNT ON;

	DECLARE	@subject				NVARCHAR(255)
		,	@html					NVARCHAR(MAX)
		,	@countPTCredit			INT
		,	@countPTDeposit			INT
		,	@countStatusCredit		INT
		,	@countStatusDeposit		INT
		,	@countCommCredit		INT
		,	@countCommDeposit		INT
		,	@countBetLimitCredit	INT
		,	@countBetLimitDeposit	INT
		,	@countStakeLevelCredit	INT
		,	@countStakeLevelDeposit	INT
		,	@rowLimited				INT
		,	@logDate				DATETIME
		,	@fullBackup				NVARCHAR(500)
		,	@diffBackup				NVARCHAR(500)
		,	@case					TINYINT
		;

	WHILE	NOT EXISTS (SELECT 1 FROM dbo.vnDBA_Service_Variables WITH (NOLOCK) WHERE VarKey = 'CheckSettingThreadCount' AND CAST(VarValue AS SMALLINT) = 0)
	BEGIN;
		WAITFOR DELAY '00:00:05';
	END;

	CREATE TABLE	#CheckResultPT (
						RuleName		VARCHAR(100)
					,	RuleId			SMALLINT
					,	SportName		VARCHAR(500)
					,	SportType		SMALLINT
					,	BetType			SMALLINT
					,	CustId_A		INT
					,	Username_A		NVARCHAR(50)
					,	CustId_B		INT
					,	Value_A			SMALLMONEY
					,	Value_B			SMALLMONEY
					,	CreatedDate		DATETIME
					,	IsLive			BIT
					,	IsDeposit		BIT
					);

	CREATE TABLE	#CheckResultPTAgg (
						RuleName		VARCHAR(100)
					,	RuleId			SMALLINT
					,	SportName		VARCHAR(500)
					,	SportType		SMALLINT
					,	BetType			SMALLINT
					,	IsLive			BIT
					,	IsDeposit		BIT
					,	Total			INT
					);

	CREATE TABLE	#CheckResultStatus (
						RuleName		VARCHAR(500)
					,	RuleId			INT
					,	SportName		VARCHAR(500)
					,	SportType		SMALLINT
					,	BetType			SMALLINT
					,	CustId_A		INT
					,	Username_A		NVARCHAR(50)
					,	CustId_B		INT
					,	Value_A			BIT
					,	Value_B			BIT
					,	CreatedDate		DATETIME
					,	IsDCS			BIT
					,	IsDeposit		BIT
					);

	CREATE TABLE	#CheckResultStatusAgg (
						RuleName		VARCHAR(500)
					,	RuleId			INT
					,	SportName		VARCHAR(500)
					,	SportType		SMALLINT
					,	BetType			SMALLINT
					,	IsDCS			BIT
					,	IsDeposit		BIT
					,	Total			INT
					);
	
	CREATE TABLE	#CheckResultComm (
						RuleName		VARCHAR(100)
					,	RuleId			SMALLINT
					,	SportName		VARCHAR(500)
					,	SportType		SMALLINT
					,	BetType			SMALLINT
					,	CustId_A		INT
					,	Username_A		NVARCHAR(50)
					,	CustId_B		INT
					,	Value_A			SMALLMONEY
					,	Value_B			SMALLMONEY
					,	CreatedDate		DATETIME
					,	IsDeposit		BIT
					);

	CREATE TABLE	#CheckResultCommAgg (
						RuleName		VARCHAR(100)
					,	RuleId			SMALLINT
					,	SportName		VARCHAR(500)
					,	SportType		SMALLINT
					,	BetType			SMALLINT
					,	Total			INT
					,	IsDeposit		BIT
					);

	CREATE TABLE	#CheckResultBetLimit (
						RuleName		VARCHAR(100)
					,	RuleId			SMALLINT
					,	SportName		VARCHAR(500)
					,	SportType		SMALLINT
					,	BetType			SMALLINT
					,	CustId_A		INT
					,	Username_A		NVARCHAR(50)
					,	CustId_B		INT
					,	Value_A			SMALLMONEY
					,	Value_B			SMALLMONEY
					,	CreatedDate		DATETIME
					,	IsDCS			BIT
					,	IsDeposit		BIT
					);

	CREATE TABLE	#CheckResultBetLimitAgg (
						RuleName		VARCHAR(100)
					,	RuleId			SMALLINT
					,	SportName		VARCHAR(500)
					,	SportType		SMALLINT
					,	BetType			SMALLINT
					,	Total			INT
					,	IsDCS			BIT
					,	IsDeposit		BIT
					);
	
	CREATE TABLE	#CheckResultStakeLevel (
						RuleName		VARCHAR(100)
					,	RuleId			SMALLINT
					,	SportName		VARCHAR(500)
					,	SportType		SMALLINT
					,	BetType			SMALLINT
					,	CustId_A		INT
					,	Username_A		NVARCHAR(50)
					,	CustId_B		INT
					,	Value_A			SMALLMONEY
					,	Value_B			SMALLMONEY
					,	CreatedDate		DATETIME
					,	IsDeposit		BIT
					);

	CREATE TABLE	#CheckResultStakeLevelAgg (
						RuleName		VARCHAR(100)
					,	RuleId			SMALLINT
					,	SportName		VARCHAR(500)
					,	SportType		SMALLINT
					,	BetType			SMALLINT
					,	Total			INT
					,	IsDeposit		BIT
					);

	DECLARE	@Sports AS TABLE (
				SportType		SMALLINT
			,	SportName		NVARCHAR(50)
			,	PRIMARY KEY CLUSTERED (SportType)
			);

	INSERT INTO	@Sports (SportType, SportName)
	SELECT	SportType, SportName
	FROM	OPENQUERY(DB02KBT, '
SELECT	SportType, SportName
FROM	bodb02.dbo.Sports WITH (NOLOCK);
');

	SELECT	@rowLimited = 30;

	SELECT	TOP(1)
			@LogDate = LogDate
		,	@fullBackup = FullBackup
		,	@diffBackup = DiffBackup
	FROM	StarixDB.dbo.vnDBA_Restore_CheckCustDB_History WITH (NOLOCK)
	WHERE	ISNULL(FullBackup, DiffBackup) IS NOT NULL
	ORDER BY LogDate DESC;

	IF	@LogDate IS NULL
	BEGIN;
		SELECT	@LogDate = GETDATE();

		INSERT INTO	StarixDB.dbo.vnDBA_Restore_CheckCustDB_History (LogDate, FullBackup, DiffBackup)
		VALUES	(@LogDate, 'N/A', 'N/A');
	END;


	--	BEGIN STEP :
	--		Cleanup ignored results
	----------------------------------------------------------------------------------------------------

	DELETE	r WITH (TABLOCK)
	FROM		dbo.CheckPTResult_Credit AS r
	INNER JOIN	CheckCustDB.dbo.custInfo AS cus WITH (NOLOCK)
			ON	r.CustIdA = cus.CustId
	INNER JOIN	dbo.IgnoredCust ic WITH (NOLOCK)
			ON	ic.custid = CASE	WHEN ic.Allline = 0 THEN cus.CustId 
									ELSE CASE	WHEN ic.RoleID = 4 THEN cus.srecommend 
												WHEN ic.RoleID = 3 THEN cus.mrecommend
												WHEN ic.RoleID = 2 THEN cus.recommend
												ELSE cus.CustId
											END
							END
			AND ic.RuleId = CASE WHEN ic.RuleId = 0 THEN ic.RuleId ELSE r.ruleid END
			AND	ic.sporttype = CASE WHEN ic.sporttype = 0 THEN ic.sporttype ELSE r.sporttype END;

	DELETE	r WITH (TABLOCK)
	FROM		dbo.CheckStatusResult AS r
	INNER JOIN	CheckCustDB.dbo.custInfo AS cus WITH (NOLOCK)
			ON	r.CustIdA = cus.CustId
	INNER JOIN	dbo.IgnoredCust AS ic WITH (NOLOCK)
			ON	ic.custid = CASE	WHEN ic.Allline = 0 THEN cus.CustId 
									ELSE CASE	WHEN ic.RoleID = 4 THEN cus.srecommend 
												WHEN ic.RoleID = 3 THEN cus.mrecommend
												WHEN ic.RoleID = 2 THEN cus.recommend
												ELSE cus.CustId
											END
							END
			AND ic.RuleId = CASE WHEN ic.RuleId = 0 THEN ic.RuleId ELSE r.ruleid END
			AND	ic.sporttype = CASE WHEN ic.sporttype = 0 THEN ic.sporttype ELSE r.sporttype END;

	DELETE	r WITH (TABLOCK)
	FROM		dbo.CheckStatusResult_DCS r
	INNER JOIN	CheckCustDB.dbo.custInfo AS cus WITH (NOLOCK) ON r.CustIdA = cus.CustId
	INNER JOIN	dbo.IgnoredCust ic WITH (NOLOCK)
			ON	ic.custid = CASE	WHEN ic.Allline = 0 THEN cus.CustId 
									ELSE CASE	WHEN ic.RoleID = 4 THEN cus.srecommend 
												WHEN ic.RoleID = 3 THEN cus.mrecommend
												WHEN ic.RoleID = 2 THEN cus.recommend
												ELSE cus.CustId
											END
							END
			AND ic.RuleId = CASE WHEN ic.RuleId = 0 THEN ic.RuleId ELSE r.ruleid END
			AND	ic.sporttype = CASE WHEN ic.sporttype = 0 THEN ic.sporttype ELSE r.sporttype END;


	DELETE	r WITH (TABLOCK)
	FROM		dbo.CheckCommResult_Credit AS r
	INNER JOIN	CheckCustDB.dbo.custInfo AS cus WITH (NOLOCK)
			ON	r.CustIdA = cus.CustId
	INNER JOIN	dbo.IgnoredCust ic WITH (NOLOCK)
			ON	ic.custid = CASE	WHEN ic.Allline = 0 THEN cus.CustId 
									ELSE CASE	WHEN ic.RoleID = 4 THEN cus.srecommend 
												WHEN ic.RoleID = 3 THEN cus.mrecommend
												WHEN ic.RoleID = 2 THEN cus.recommend
												ELSE cus.CustId
											END
							END
			AND ic.RuleId = CASE WHEN ic.RuleId = 0 THEN ic.RuleId ELSE r.ruleid END
			AND	ic.sporttype = CASE WHEN ic.sporttype = 0 THEN ic.sporttype ELSE r.sporttype END;

	DELETE	r WITH (TABLOCK)
	FROM		dbo.CheckCommResult_Credit AS r
	INNER JOIN	CheckCustDB.dbo.custInfo AS cus WITH (NOLOCK)
			ON	r.CustIdA = cus.CustId
	INNER JOIN	CheckCustDB.dbo.custInfo AS cus1 WITH (NOLOCK)
			ON	r.CustIdB = cus1.CustId
	WHERE	EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustNoComm AS cnc WITH (NOLOCK) WHERE cus.srecommend = cnc.CustID)
		OR	EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustNoComm AS cnc WITH (NOLOCK) WHERE cus.mrecommend = cnc.CustID)
		OR	EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustNoComm AS cnc WITH (NOLOCK) WHERE cus.recommend = cnc.CustID)
		OR	EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustNoComm AS cnc WITH (NOLOCK) WHERE cus.custid = cnc.CustID)
		OR	EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustNoComm AS cnc WITH (NOLOCK) WHERE cus1.srecommend = cnc.CustID)
		OR	EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustNoComm AS cnc WITH (NOLOCK) WHERE cus1.mrecommend = cnc.CustID)
		OR	EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustNoComm AS cnc WITH (NOLOCK) WHERE cus1.recommend = cnc.CustID)
		OR	EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustNoComm AS cnc WITH (NOLOCK) WHERE cus1.custid = cnc.CustID)
		OR	EXISTS (SELECT 1 FROM CheckCustDB.dbo.PhoneBettingCustomerList AS pbc WITH (NOLOCK) WHERE cus.username = pbc.username)
		OR	EXISTS (SELECT 1 FROM CheckCustDB.dbo.PhoneBettingCustomerList AS pbc WITH (NOLOCK) WHERE cus1.username = pbc.username);

	DELETE	r WITH (TABLOCK)
	FROM		dbo.CheckBetLimitResult AS r
	INNER JOIN	CheckCustDB.dbo.custInfo AS cus WITH (NOLOCK)
			ON	r.CustIdA = cus.CustId
	INNER JOIN	dbo.IgnoredCust ic WITH (NOLOCK)
			ON	ic.custid = CASE	WHEN ic.Allline = 0 THEN cus.CustId 
									ELSE CASE	WHEN ic.RoleID = 4 THEN cus.srecommend 
												WHEN ic.RoleID = 3 THEN cus.mrecommend
												WHEN ic.RoleID = 2 THEN cus.recommend
												ELSE cus.CustId
											END
							END
			AND ic.RuleId = CASE WHEN ic.RuleId = 0 THEN ic.RuleId ELSE r.ruleid END
			AND	ic.sporttype = CASE WHEN ic.sporttype = 0 THEN ic.sporttype ELSE r.sporttype END;

	DELETE	r WITH (TABLOCK)
	FROM		dbo.CheckBetLimitResult_DCS AS r
	INNER JOIN	CheckCustDB.dbo.custInfo AS cus WITH (NOLOCK)
			ON	r.CustIdA = cus.CustId
	INNER JOIN	dbo.IgnoredCust ic WITH (NOLOCK)
			ON	ic.custid = CASE	WHEN ic.Allline = 0 THEN cus.CustId 
									ELSE CASE	WHEN ic.RoleID = 4 THEN cus.srecommend 
												WHEN ic.RoleID = 3 THEN cus.mrecommend
												WHEN ic.RoleID = 2 THEN cus.recommend
												ELSE cus.CustId
											END
							END
			AND ic.RuleId = CASE WHEN ic.RuleId = 0 THEN ic.RuleId ELSE r.ruleid END
			AND	ic.sporttype = CASE WHEN ic.sporttype = 0 THEN ic.sporttype ELSE r.sporttype END;

	DELETE	r WITH (TABLOCK)
	FROM		dbo.CheckResultStakeLevel_Credit AS r
	INNER JOIN	CheckCustDB.dbo.custInfo AS cus WITH (NOLOCK)
			ON	r.CustIdA = cus.CustId
	INNER JOIN	dbo.IgnoredCust ic WITH (NOLOCK)
			ON	ic.custid = CASE	WHEN ic.Allline = 0 THEN cus.CustId 
									ELSE CASE	WHEN ic.RoleID = 4 THEN cus.srecommend 
												WHEN ic.RoleID = 3 THEN cus.mrecommend
												WHEN ic.RoleID = 2 THEN cus.recommend
												ELSE cus.CustId
											END
							END
			AND ic.RuleId = CASE WHEN ic.RuleId = 0 THEN ic.RuleId ELSE r.ruleid END
			AND	ic.sporttype = CASE WHEN ic.sporttype = 0 THEN ic.sporttype ELSE r.sporttype END;

	DELETE	r WITH (TABLOCK)
	FROM		dbo.CheckResultStakeLevel_Deposit AS r
	INNER JOIN	CheckCustDB.dbo.custInfo AS cus WITH (NOLOCK)
			ON	r.CustIdA = cus.CustId
	INNER JOIN	dbo.IgnoredCust ic WITH (NOLOCK)
			ON	ic.custid = CASE	WHEN ic.Allline = 0 THEN cus.CustId 
									ELSE CASE	WHEN ic.RoleID = 4 THEN cus.srecommend 
												WHEN ic.RoleID = 3 THEN cus.mrecommend
												WHEN ic.RoleID = 2 THEN cus.recommend
												ELSE cus.CustId
											END
							END
			AND ic.RuleId = CASE WHEN ic.RuleId = 0 THEN ic.RuleId ELSE r.ruleid END
			AND	ic.sporttype = CASE WHEN ic.sporttype = 0 THEN ic.sporttype ELSE r.sporttype END;


	--	BEGIN STEP :
	--		Get PT result
	----------------------------------------------------------------------------------------------------

	INSERT INTO	#CheckResultPTAgg (RuleName, RuleId, SportName, SportType, BetType, IsLive, IsDeposit, Total)
	SELECT	ISNULL(r.RuleName, 'N/A'), c.RuleId, ISNULL(s.SportName, 'N/A'), c.SportType, c.BetType, c.IsLive, 0, COUNT(1)
	FROM		dbo.CheckPTResult_Credit AS c WITH (NOLOCK)
	LEFT JOIN	dbo.Rule_Credit AS r WITH (NOLOCK)
			ON	c.RuleId = r.RuleId
	INNER JOIN	CheckCustDB.dbo.custInfo AS cus WITH (NOLOCK)
			ON	c.CustIdA = cus.CustId
	INNER JOIN	CheckCustDB.dbo.custInfo AS cus1 WITH (NOLOCK)
			ON	c.CustIdB = cus1.CustId
	LEFT JOIN	@Sports AS s
			ON	c.SportType = s.SportType
	GROUP BY r.RuleName, c.RuleId, s.SportName, c.SportType, c.BetType, c.IsLive;

	SELECT	@countPTCredit = ISNULL(SUM(Total), 0)
	FROM	#CheckResultPTAgg WITH (NOLOCK)
	WHERE	IsDeposit = 0;

	SELECT	@countPTDeposit = ISNULL(SUM(Total), 0)
	FROM	#CheckResultPTAgg WITH (NOLOCK)
	WHERE	IsDeposit = 1;

	UPDATE	StarixDB.dbo.vnDBA_Restore_CheckCustDB_History
	SET		PTResult = @countPTCredit + @countPTDeposit
	WHERE	LogDate = @LogDate;

	IF	@countPTCredit + @countPTDeposit <= @rowLimited
	BEGIN
		INSERT INTO	#CheckResultPT (RuleName, RuleId, SportName, SportType, BetType, CustId_A, Username_A, CustId_B, Value_A, Value_B, CreatedDate, IsLive, IsDeposit)
		SELECT	ISNULL(r.RuleName, 'N/A'), c.RuleId, ISNULL(s.SportName, 'N/A'), c.SportType, c.BetType, c.CustIdA, cus.username, c.CustIdB, c.ValueA, c.ValueB, c.CreatedDate, c.IsLive, 0
		FROM		dbo.CheckPTResult_Credit AS c WITH (NOLOCK)
		LEFT JOIN	dbo.Rule_Credit AS r WITH (NOLOCK)
				ON	c.RuleId = r.RuleId
		INNER JOIN	CheckCustDB.dbo.custInfo AS cus WITH (NOLOCK)
				ON	c.CustIdA = cus.CustId
		INNER JOIN	CheckCustDB.dbo.custInfo AS cus1 WITH (NOLOCK)
				ON	c.CustIdB = cus1.CustId
		LEFT JOIN	@Sports AS s
				ON	c.SportType = s.SportType;
	END;


	--	BEGIN STEP :
	--		Get status result
	----------------------------------------------------------------------------------------------------

	INSERT INTO	#CheckResultStatusAgg (RuleName, RuleId, SportName, SportType, BetType, IsDCS, IsDeposit, Total)
	SELECT	ISNULL(sr.RuleName, 'N/A'), rd.RuleId, ISNULL(s.SportName, 'N/A'), rd.SportType, rd.BetType, 1, rd.IsDeposit, COUNT(1)
	FROM		dbo.CheckStatusResult_DCS AS rd WITH (NOLOCK)
	LEFT JOIN	dbo.DBA_CheckSetting_ProductStatusRule AS sr WITH (NOLOCK)
			ON	rd.RuleId = sr.RuleID
	LEFT JOIN	@Sports AS s
			ON	rd.SportType = s.SportType
	GROUP BY sr.RuleName, rd.RuleId, s.SportName, rd.SportType, rd.BetType, rd.IsDeposit
	UNION ALL
	SELECT	ISNULL(sr.RuleName, 'N/A'), r.RuleId, ISNULL(s.SportName, 'N/A'), r.SportType, r.BetType, 0, r.IsDeposit, COUNT(1)
	FROM		dbo.CheckStatusResult AS r WITH (NOLOCK)
	LEFT JOIN	dbo.DBA_CheckSetting_ProductStatusRule AS sr WITH (NOLOCK)
			ON	r.RuleId = sr.RuleID
	LEFT JOIN	@Sports AS s
			ON	r.SportType = s.SportType
	GROUP BY sr.RuleName, r.RuleId, s.SportName, r.SportType, r.BetType, r.IsDeposit;

	SELECT	@countStatusCredit = ISNULL(SUM(Total), 0)
	FROM	#CheckResultStatusAgg WITH (NOLOCK)
	WHERE	IsDeposit = 0;

	SELECT	@countStatusDeposit = ISNULL(SUM(Total), 0)
	FROM	#CheckResultStatusAgg WITH (NOLOCK)
	WHERE	IsDeposit = 1;

	UPDATE	StarixDB.dbo.vnDBA_Restore_CheckCustDB_History
	SET		StatusResult = @countStatusCredit + @countStatusDeposit
	WHERE	LogDate = @LogDate;

	IF	@countStatusCredit + @countStatusDeposit <= @rowLimited
	BEGIN
		INSERT INTO	#CheckResultStatus (RuleName, RuleId, SportName, SportType, BetType, CustId_A, Username_A, CustId_B, Value_A, Value_B, CreatedDate, IsDCS, IsDeposit)
		SELECT	ISNULL(sr.RuleName, 'N/A'), rd.RuleId, ISNULL(s.SportName, 'N/A'), rd.SportType, rd.BetType, rd.CustIdA, ci.username, rd.CustIdB, rd.ValueA, rd.ValueB, rd.CreatedDate, 1, rd.IsDeposit
		FROM		dbo.CheckStatusResult_DCS AS rd WITH (NOLOCK)
		LEFT JOIN	CheckCustDB.dbo.custInfo AS ci WITH (NOLOCK)
				ON	rd.CustIdA = ci.custid
		LEFT JOIN	dbo.DBA_CheckSetting_ProductStatusRule AS sr WITH (NOLOCK)
				ON	rd.RuleId = sr.RuleID
		LEFT JOIN	@Sports AS s
				ON	rd.SportType = s.SportType
		UNION ALL
		SELECT	ISNULL(sr.RuleName, 'N/A'), r.RuleId, ISNULL(s.SportName, 'N/A'), r.SportType, r.BetType, r.CustIdA, ci.username, r.CustIdB, r.ValueA, r.ValueB, r.CreatedDate, 0, r.IsDeposit
		FROM		dbo.CheckStatusResult AS r WITH (NOLOCK)
		LEFT JOIN	CheckCustDB.dbo.custInfo AS ci WITH (NOLOCK)
				ON	r.CustIdA = ci.custid
		LEFT JOIN	dbo.DBA_CheckSetting_ProductStatusRule AS sr WITH (NOLOCK)
				ON	r.RuleId = sr.RuleID
		LEFT JOIN	@Sports AS s
				ON	r.SportType = s.SportType;
	END;


	--	BEGIN STEP :
	--		Get comm result
	----------------------------------------------------------------------------------------------------

	INSERT INTO	#CheckResultCommAgg (RuleName, RuleId, SportName, SportType, BetType, Total, IsDeposit)
	SELECT	ISNULL(r.RuleName, 'N/A'), c.RuleId, ISNULL(s.SportName, 'N/A'), c.SportType, c.BetType, COUNT(1), 0
	FROM		dbo.CheckCommResult_Credit AS c WITH (NOLOCK)
	LEFT JOIN	dbo.Rule_Credit AS r WITH (NOLOCK)
			ON	c.RuleId = r.RuleId
	INNER JOIN	CheckCustDB.dbo.custInfo AS cus WITH (NOLOCK)
			ON	c.CustIdA = cus.CustId
	INNER JOIN	CheckCustDB.dbo.custInfo AS cus1 WITH (NOLOCK)
			ON	c.CustIdB = cus1.CustId
	LEFT JOIN	@Sports AS s
			ON	c.SportType = s.SportType
	GROUP BY r.RuleName, c.RuleId, s.SportName, c.SportType, c.BetType;

	SELECT	@countCommCredit = ISNULL(SUM(Total), 0)
	FROM	#CheckResultCommAgg WITH (NOLOCK)
	WHERE	IsDeposit = 0;

	SELECT	@countCommDeposit = ISNULL(SUM(Total), 0)
	FROM	#CheckResultCommAgg WITH (NOLOCK)
	WHERE	IsDeposit = 1;

	UPDATE	StarixDB.dbo.vnDBA_Restore_CheckCustDB_History
	SET		CommResult = @countCommCredit + @countCommDeposit
	WHERE	LogDate = @LogDate;

	IF	@countCommCredit + @countCommDeposit <= @rowLimited
	BEGIN
		INSERT INTO	#CheckResultComm (RuleName, RuleId, SportName, SportType, BetType, CustId_A, Username_A, CustId_B, Value_A, Value_B, CreatedDate, IsDeposit)
		SELECT	ISNULL(r.RuleName, 'N/A'), c.RuleId, ISNULL(s.SportName, 'N/A'), c.SportType, c.BetType, c.CustIdA, cus.username, c.CustIdB, c.ValueA, c.ValueB, c.CreatedDate, 0
		FROM		dbo.CheckCommResult_Credit AS c WITH (NOLOCK)
		LEFT JOIN	dbo.Rule_Credit AS r WITH (NOLOCK)
				ON	c.RuleId = r.RuleId
		INNER JOIN	CheckCustDB.dbo.custInfo AS cus WITH (NOLOCK)
				ON	c.CustIdA = cus.CustId
		INNER JOIN	CheckCustDB.dbo.custInfo AS cus1 WITH (NOLOCK)
				ON	c.CustIdB = cus1.CustId
		LEFT JOIN	@Sports s
				ON	c.SportType = s.SportType;
	END;


	--	BEGIN STEP :
	--		Get bet limit result
	----------------------------------------------------------------------------------------------------

	INSERT INTO	#CheckResultBetLimitAgg (RuleName, RuleId, SportName, SportType, BetType, IsDCS, IsDeposit, Total)
	SELECT	ISNULL(rc.RuleName, 'N/A'), rd.RuleId, ISNULL(s.SportName, 'N/A'), rd.SportType, rd.BetType, 1, rd.IsDeposit, COUNT(1)
	FROM		dbo.CheckBetLimitResult_DCS AS rd WITH (NOLOCK)
	LEFT JOIN	dbo.Rule_Credit AS rc WITH (NOLOCK)
			ON	rd.RuleId = rc.RuleID
	LEFT JOIN	@Sports AS s
			ON	rd.SportType = s.SportType
	GROUP BY rc.RuleName, rd.RuleId, s.SportName, rd.SportType, rd.BetType, rd.IsDeposit
	UNION ALL
	SELECT	ISNULL(rc.RuleName, 'N/A'), r.RuleId, ISNULL(s.SportName, 'N/A'), r.SportType, r.BetType, 0, r.IsDeposit, COUNT(1)
	FROM		dbo.CheckBetLimitResult AS r WITH (NOLOCK)
	LEFT JOIN	dbo.Rule_Credit AS rc WITH (NOLOCK)
			ON	r.RuleId = rc.RuleID
	LEFT JOIN	@Sports AS s
			ON	r.SportType = s.SportType
	GROUP BY rc.RuleName, r.RuleId, s.SportName, r.SportType, r.BetType, r.IsDeposit;

	SELECT	@countBetLimitCredit = ISNULL(SUM(Total), 0)
	FROM	#CheckResultBetLimitAgg WITH (NOLOCK)
	WHERE	IsDeposit = 0;

	SELECT	@countBetLimitDeposit = ISNULL(SUM(Total), 0)
	FROM	#CheckResultBetLimitAgg WITH (NOLOCK)
	WHERE	IsDeposit = 1;

	UPDATE	StarixDB.dbo.vnDBA_Restore_CheckCustDB_History
	SET		BetLimitResult = @countBetLimitCredit + @countBetLimitDeposit
	WHERE	LogDate = @LogDate;

	IF	@countBetLimitCredit + @countBetLimitDeposit <= @rowLimited
	BEGIN
		INSERT INTO	#CheckResultBetLimit (RuleName, RuleId, SportName, SportType, BetType, CustId_A, Username_A, CustId_B, Value_A, Value_B, CreatedDate, IsDCS, IsDeposit)
		SELECT	ISNULL(rc.RuleName, 'N/A'), rd.RuleId, ISNULL(s.SportName, 'N/A'), rd.SportType, rd.BetType, rd.CustIdA, ci.username, rd.CustIdB, rd.ValueA, rd.ValueB, rd.CreatedDate, 1, rd.IsDeposit
		FROM		dbo.CheckBetLimitResult_DCS AS rd WITH (NOLOCK)
		LEFT JOIN	CheckCustDB.dbo.custInfo AS ci WITH (NOLOCK)
				ON	rd.CustIdA = ci.custid
		LEFT JOIN	dbo.Rule_Credit AS rc WITH (NOLOCK)
				ON	rd.RuleId = rc.RuleID
		LEFT JOIN	@Sports AS s
				ON	rd.SportType = s.SportType
		UNION ALL
		SELECT	ISNULL(rc.RuleName, 'N/A'), r.RuleId, ISNULL(s.SportName, 'N/A'), r.SportType, r.BetType, r.CustIdA, ci.username, r.CustIdB, r.ValueA, r.ValueB, r.CreatedDate, 0, r.IsDeposit
		FROM		dbo.CheckBetLimitResult AS r WITH (NOLOCK)
		LEFT JOIN	CheckCustDB.dbo.custInfo AS ci WITH (NOLOCK)
				ON	r.CustIdA = ci.custid
		LEFT JOIN	dbo.Rule_Credit AS rc WITH (NOLOCK)
				ON	r.RuleId = rc.RuleID
		LEFT JOIN	@Sports AS s
				ON	r.SportType = s.SportType;
	END;


	--	BEGIN STEP :
	--		Get stake level result
	----------------------------------------------------------------------------------------------------

	INSERT INTO	#CheckResultStakeLevelAgg (RuleName, RuleId, SportName, SportType, BetType, IsDeposit, Total)
	SELECT	ISNULL(rc.RuleName, 'N/A'), r.RuleId, ISNULL(s.SportName, 'N/A'), r.SportType, r.BetType, 0, COUNT(1)
	FROM		dbo.CheckResultStakeLevel_Credit AS r WITH (NOLOCK)
	LEFT JOIN	dbo.Rule_Credit AS rc WITH (NOLOCK)
			ON	r.RuleId = rc.RuleID
	LEFT JOIN	@Sports AS s
			ON	r.SportType = s.SportType
	GROUP BY rc.RuleName, r.RuleId, s.SportName, r.SportType, r.BetType
	UNION ALL
	SELECT	ISNULL(rc.RuleName, 'N/A'), r.RuleId, ISNULL(s.SportName, 'N/A'), r.SportType, r.BetType, 1, COUNT(1)
	FROM		dbo.CheckResultStakeLevel_Deposit AS r WITH (NOLOCK)
	LEFT JOIN	dbo.Rule_Credit AS rc WITH (NOLOCK)
			ON	r.RuleId = rc.RuleID
	LEFT JOIN	@Sports AS s
			ON	r.SportType = s.SportType
	GROUP BY rc.RuleName, r.RuleId, s.SportName, r.SportType, r.BetType;

	SELECT	@countStakeLevelCredit = ISNULL(SUM(Total), 0)
	FROM	#CheckResultStakeLevelAgg WITH (NOLOCK)
	WHERE	IsDeposit = 0;

	SELECT	@countStakeLevelDeposit = ISNULL(SUM(Total), 0)
	FROM	#CheckResultStakeLevelAgg WITH (NOLOCK)
	WHERE	IsDeposit = 1;

	UPDATE	StarixDB.dbo.vnDBA_Restore_CheckCustDB_History
	SET		StakeLevelResult = @countStakeLevelCredit + @countStakeLevelDeposit
	WHERE	LogDate = @LogDate;

	IF	@countStakeLevelCredit + @countStakeLevelDeposit <= @rowLimited
	BEGIN
		INSERT INTO	#CheckResultStakeLevel (RuleName, RuleId, SportName, SportType, BetType, CustId_A, Username_A, CustId_B, Value_A, Value_B, CreatedDate, IsDeposit)
		SELECT	ISNULL(rc.RuleName, 'N/A'), r.RuleId, ISNULL(s.SportName, 'N/A'), r.SportType, r.BetType, r.CustIdA, ci.username, r.CustIdB, r.ValueA, r.ValueB, r.CreatedDate, 0
		FROM		dbo.CheckResultStakeLevel_Credit AS r WITH (NOLOCK)
		LEFT JOIN	CheckCustDB.dbo.custInfo AS ci WITH (NOLOCK)
				ON	r.CustIdA = ci.custid
		LEFT JOIN	dbo.Rule_Credit AS rc WITH (NOLOCK)
				ON	r.RuleId = rc.RuleID
		LEFT JOIN	@Sports AS s
				ON	r.SportType = s.SportType
		UNION ALL
		SELECT	ISNULL(rc.RuleName, 'N/A'), r.RuleId, ISNULL(s.SportName, 'N/A'), r.SportType, r.BetType, r.CustIdA, ci.username, r.CustIdB, r.ValueA, r.ValueB, r.CreatedDate, 1
		FROM		dbo.CheckResultStakeLevel_Deposit AS r WITH (NOLOCK)
		LEFT JOIN	CheckCustDB.dbo.custInfo AS ci WITH (NOLOCK)
				ON	r.CustIdA = ci.custid
		LEFT JOIN	dbo.Rule_Credit AS rc WITH (NOLOCK)
				ON	r.RuleId = rc.RuleID
		LEFT JOIN	@Sports AS s
				ON	r.SportType = s.SportType;
	END;


	--	BEGIN STEP :
	--		Send email -- Mode: 1
	----------------------------------------------------------------------------------------------------

	IF	@mode & 1 <> 0
	BEGIN
		SELECT	@subject	= N'Auto Restore DB CheckCustDB'
			,	@to			= CASE	WHEN	@to LIKE '%dbaadmin@starixsoft.com%'
										OR	@to LIKE '%DBAAdmin@onelab.tw%'
										OR	@to LIKE '%billy.bui@starixsoft.com%'
										OR	@to LIKE '%pontus@starixsoft.com%'
										THEN ''
									ELSE 'billy.bui@starixsoft.com;'
							  END
							+ ISNULL(@to, '')
			;

		SELECT	@html = (
			SELECT	TOP(1)
					[@style]	= N'width: 100%;'
				,	[h1/@align]	= N'center'
				,	[h1]		= N'Auto Check CustDB'
				,	[p]			= ISNULL(N'Full backup path: ' + @fullBackup, N'')
				,	NULL
				,	[p]			= ISNULL(N'Diff backup path: ' + @diffBackup, N'')
				,	[br]		= ''
				,	(	SELECT	[@style]		= N'display:table;width:95%;border-spacing:10px;margin:0 auto;'
							,	[div/@style]	= N'background-color:' + CASE @countPTCredit WHEN 0 THEN N'blue;' ELSE N'red;' END + s.style
							,	[div/h2]		= N'PT Credit'
							,	[div/h3]		= CASE @countPTCredit WHEN 0 THEN N'Success' ELSE CAST(@countPTCredit AS NVARCHAR) END
							,	NULL
							,	[div/@style]	= N'background-color:' + CASE @countStatusCredit WHEN 0 THEN N'blue;' ELSE N'red;' END + s.style
							,	[div/h2]		= N'Status Credit'
							,	[div/h3]		= CASE @countStatusCredit WHEN 0 THEN N'Success' ELSE CAST(@countStatusCredit AS NVARCHAR) END
							,	NULL
							,	[div/@style]	= N'background-color:' + CASE @countCommCredit WHEN 0 THEN N'blue;' ELSE N'red;' END + s.style
							,	[div/h2]		= N'Commission Credit'
							,	[div/h3]		= CASE @countCommCredit WHEN 0 THEN N'Success' ELSE CAST(@countCommCredit AS NVARCHAR) END
							,	NULL
							,	[div/@style]	= N'background-color:' + CASE @countBetLimitCredit WHEN 0 THEN N'blue;' ELSE N'red;' END + s.style
							,	[div/h2]		= N'Bet Limit Credit'
							,	[div/h3]		= CASE @countBetLimitCredit WHEN 0 THEN N'Success' ELSE CAST(@countBetLimitCredit AS NVARCHAR) END
							,	NULL
							,	[div/@style]	= N'background-color:' + CASE @countStakeLevelCredit WHEN 0 THEN N'blue;' ELSE N'red;' END + s.style
							,	[div/h2]		= N'Stake Level Credit'
							,	[div/h3]		= CASE @countStakeLevelCredit WHEN 0 THEN N'Success' ELSE CAST(@countStakeLevelCredit AS NVARCHAR) END
						FROM	(
							SELECT	[style]			= N'color:white;text-align:center;width:20%;display:table-cell;'
						) s
						FOR XML PATH ('div')
						,	TYPE
					)
				,	[br]		= ''
				,	(	SELECT	[@style]		= N'display:table;width:95%;border-spacing:10px;margin:0 auto;'
							,	[div/@style]	= N'background-color:' + CASE @countPTDeposit WHEN 0 THEN N'blue;' ELSE N'red;' END + s.style
							,	[div/h2]		= N'PT Deposit'
							,	[div/h3]		= CASE @countPTDeposit WHEN 0 THEN N'Success' ELSE CAST(@countPTDeposit AS NVARCHAR) END
							,	NULL
							,	[div/@style]	= N'background-color:' + CASE @countStatusDeposit WHEN 0 THEN N'blue;' ELSE N'red;' END + s.style
							,	[div/h2]		= N'Status Deposit'
							,	[div/h3]		= CASE @countStatusDeposit WHEN 0 THEN N'Success' ELSE CAST(@countStatusDeposit AS NVARCHAR) END
							,	NULL
							,	[div/@style]	= N'background-color:' + CASE @countCommDeposit WHEN 0 THEN N'blue;' ELSE N'red;' END + s.style
							,	[div/h2]		= N'Commission Deposit'
							,	[div/h3]		= CASE @countCommDeposit WHEN 0 THEN N'Success' ELSE CAST(@countCommDeposit AS NVARCHAR) END
							,	NULL
							,	[div/@style]	= N'background-color:' + CASE @countBetLimitDeposit WHEN 0 THEN N'blue;' ELSE N'red;' END + s.style
							,	[div/h2]		= N'Bet Limit Deposit'
							,	[div/h3]		= CASE @countBetLimitDeposit WHEN 0 THEN N'Success' ELSE CAST(@countBetLimitDeposit AS NVARCHAR) END
							,	NULL
							,	[div/@style]	= N'background-color:' + CASE @countStakeLevelDeposit WHEN 0 THEN N'blue;' ELSE N'red;' END + s.style
							,	[div/h2]		= N'Stake Level Deposit'
							,	[div/h3]		= CASE @countStakeLevelDeposit WHEN 0 THEN N'Success' ELSE CAST(@countStakeLevelDeposit AS NVARCHAR) END
						FROM	(
							SELECT	[style]			= N'color:white;text-align:center;width:20%;display:table-cell;'
						) s
						FOR XML PATH ('div')
						,	TYPE
					)
				,	[br]		= ''

				-- PT Result --
				,	[br]		= CASE WHEN @countPTCredit + @countPTDeposit > 0 THEN '' ELSE NULL END
				,	(	SELECT	[@style]		= N'margin-left:3%'
							,	[node()]		= N'Check PT Result'
						FROM	(
							SELECT	TOP(1) x = 1
							FROM	#CheckResultPTAgg
						) tbl
						FOR XML PATH ('h3')
						,	TYPE
					)
				,	(	SELECT	[@border]		= 1
							,	[@cellpadding]	= 5
							,	[@width]		= N'95%'
							,	[@style]		= N'margin:0 auto;white-space:nowrap;'
							,	(	SELECT	[th]		= N'No.'
										,	NULL
										,	[th]		= N'Rule'
										,	NULL
										,	[th]		= N'ID'
										,	NULL
										,	[th]		= N'SportName'
										,	NULL
										,	[th]		= N'SportType'
										,	NULL
										,	[th]		= N'BetType'
										,	NULL
										,	[th]		= N'IsLive'
										,	NULL
										,	[th]		= N'Total'
										,	NULL
										,	[th]		= N''
									FOR XML PATH ('tr')
									,	TYPE
								)
							,	NULL
							,	(	SELECT	[td]		= ROW_NUMBER() OVER(ORDER BY RuleId, IsDeposit, SportType, BetType, IsLive)
										,	NULL
										,	[td]		= RuleName
										,	NULL
										,	[td]		= RuleID
										,	NULL
										,	[td]		= SportName
										,	NULL
										,	[td]		= SportType
										,	NULL
										,	[td]		= BetType
										,	NULL
										,	[td]		= IsLive
										,	NULL
										,	[td]		= Total
										,	NULL
										,	[td]		= CASE IsDeposit WHEN 1 THEN 'Deposit' ELSE 'Credit' END
									FROM	#CheckResultPTAgg
									ORDER BY RuleId, IsDeposit, SportType, BetType, IsLive
									FOR XML PATH ('tr')
									,	TYPE
								)
						WHERE	@countPTCredit + @countPTDeposit > @rowLimited
						FOR XML PATH ('table')
						,	TYPE
					)
				,	(	SELECT	[@border]		= 1
							,	[@cellpadding]	= 5
							,	[@width]		= N'95%'
							,	[@style]		= N'margin:0 auto;white-space:nowrap;'
							,	(	SELECT	[th]		= N'No.'
										,	NULL
										,	[th]		= N'Rule'
										,	NULL
										,	[th]		= N'ID'
										,	NULL
										,	[th]		= N'SportName'
										,	NULL
										,	[th]		= N'SportType'
										,	NULL
										,	[th]		= N'BetType'
										,	NULL
										,	[th]		= N'CustId A'
										,	NULL
										,	[th]		= N'Username A'
										,	NULL
										,	[th]		= N'CustId B'
										,	NULL
										,	[th]		= N'Value A'
										,	NULL
										,	[th]		= N'Value B'
										,	NULL
										,	[th]		= N'IsLive'
										,	NULL
										,	[th]		= N''
									FOR XML PATH ('tr')
									,	TYPE
								)
							,	NULL
							,	(	SELECT	[td]		= ROW_NUMBER() OVER(ORDER BY RuleId, IsDeposit, CustId_A, SportType, BetType, IsLive)
										,	NULL
										,	[td]		= RuleName
										,	NULL
										,	[td]		= RuleID
										,	NULL
										,	[td]		= SportName
										,	NULL
										,	[td]		= SportType
										,	NULL
										,	[td]		= BetType
										,	NULL
										,	[td]		= CustId_A
										,	NULL
										,	[td]		= Username_A
										,	NULL
										,	[td]		= CustId_B
										,	NULL
										,	[td]		= Value_A
										,	NULL
										,	[td]		= Value_B
										,	NULL
										,	[td]		= IsLive
										,	NULL
										,	[td]		= CASE IsDeposit WHEN 1 THEN 'Deposit' ELSE 'Credit' END
									FROM	#CheckResultPT
									ORDER BY RuleId, IsDeposit, CustId_A, SportType, BetType, IsLive
									FOR XML PATH ('tr')
									,	TYPE
								)
						WHERE	@countPTCredit + @countPTDeposit <= @rowLimited
						FOR XML PATH ('table')
						,	TYPE
					)

				-- Status Result --
				,	[br]		= CASE WHEN @countStatusCredit + @countStatusDeposit = 0 THEN '' ELSE NULL END
				,	(	SELECT	[@style]		= N'margin-left:3%'
							,	[node()]		= 'Check Status Result'
						FROM	(
							SELECT	TOP(1) x = 1
							FROM	#CheckResultStatusAgg
						) tbl
						FOR XML PATH ('h3')
						,	TYPE
					)
				,	(	SELECT	[@border]		= 1
							,	[@cellpadding]	= 5
							,	[@width]		= N'95%'
							,	[@style]		= N'margin:0 auto;white-space:nowrap;'
							,	(	SELECT	[th]		= N'No.'
										,	NULL
										,	[th]		= N'Rule'
										,	NULL
										,	[th]		= N'ID'
										,	NULL
										,	[th]		= N'SportName'
										,	NULL
										,	[th]		= N'SportType'
										,	NULL
										,	[th]		= N'BetType'
										,	NULL
										,	[th]		= N'IsDCS'
										,	NULL
										,	[th]		= N'Total'
										,	NULL
										,	[th]		= N''
									FOR XML PATH ('tr')
									,	TYPE
								)
							,	NULL
							,	(	SELECT	[td]		= ROW_NUMBER() OVER(ORDER BY RuleId, IsDeposit, IsDCS, SportType, BetType)
										,	NULL
										,	[td]		= RuleName
										,	NULL
										,	[td]		= RuleID
										,	NULL
										,	[td]		= SportName
										,	NULL
										,	[td]		= ISNULL(CAST(SportType AS NVARCHAR), N'')
										,	NULL
										,	[td]		= ISNULL(CAST(BetType AS NVARCHAR), N'')
										,	NULL
										,	[td]		= IsDCS
										,	NULL
										,	[td]		= Total
										,	NULL
										,	[td]		= CASE IsDeposit WHEN 1 THEN 'Deposit' ELSE 'Credit' END
									FROM	#CheckResultStatusAgg
									ORDER BY RuleId, IsDeposit, IsDCS, SportType, BetType
									FOR XML PATH ('tr')
									,	TYPE
								)
						WHERE	@countStatusCredit + @countStatusDeposit > @rowLimited
						FOR XML PATH ('table')
						,	TYPE
					)
				,	(	SELECT	[@border]		= 1
							,	[@cellpadding]	= 5
							,	[@width]		= N'95%'
							,	[@style]		= N'margin:0 auto;white-space:nowrap;'
							,	(	SELECT	[th]		= N'No.'
										,	NULL
										,	[th]		= N'Rule'
										,	NULL
										,	[th]		= N'ID'
										,	NULL
										,	[th]		= N'SportName'
										,	NULL
										,	[th]		= N'SportType'
										,	NULL
										,	[th]		= N'BetType'
										,	NULL
										,	[th]		= N'CustId A'
										,	NULL
										,	[th]		= N'Username A'
										,	NULL
										,	[th]		= N'CustId B'
										,	NULL
										,	[th]		= N'Value A'
										,	NULL
										,	[th]		= N'Value B'
										,	NULL
										,	[th]		= N'IsDCS'
										,	NULL
										,	[th]		= N''
									FOR XML PATH ('tr')
									,	TYPE
								)
							,	NULL
							,	(	SELECT	[td]		= ROW_NUMBER() OVER(ORDER BY RuleId, IsDeposit, IsDCS, CustId_A, SportType, BetType)
										,	NULL
										,	[td]		= RuleName
										,	NULL
										,	[td]		= RuleID
										,	NULL
										,	[td]		= SportName
										,	NULL
										,	[td]		= ISNULL(CAST(SportType AS NVARCHAR), N'')
										,	NULL
										,	[td]		= ISNULL(CAST(BetType AS NVARCHAR), N'')
										,	NULL
										,	[td]		= CustId_A
										,	NULL
										,	[td]		= Username_A
										,	NULL
										,	[td]		= CustId_B
										,	NULL
										,	[td]		= Value_A
										,	NULL
										,	[td]		= Value_B
										,	NULL
										,	[td]		= IsDCS
										,	NULL
										,	[td]		= CASE IsDeposit WHEN 1 THEN 'Deposit' ELSE 'Credit' END
									FROM	#CheckResultStatus
									ORDER BY RuleId, IsDeposit, IsDCS, CustId_A, SportType, BetType
									FOR XML PATH ('tr')
									,	TYPE
								)
						WHERE	@countStatusCredit + @countStatusDeposit <= @rowLimited
						FOR XML PATH ('table')
						,	TYPE
					)

				-- Commission Result --
				,	[br]		= CASE WHEN @countCommCredit + @countCommDeposit = 0 THEN '' ELSE NULL END
				,	(	SELECT	[@style]		= N'margin-left:3%'
							,	[node()]		= 'Check Commission Result'
						FROM	(
							SELECT	TOP(1) x = 1
							FROM	#CheckResultCommAgg
						) tbl
						FOR XML PATH ('h3')
						,	TYPE
					)
				,	(	SELECT	[@border]		= 1
							,	[@cellpadding]	= 5
							,	[@width]		= N'95%'
							,	[@style]		= N'margin:0 auto;white-space:nowrap;'
							,	(	SELECT	[th]		= N'No.'
										,	NULL
										,	[th]		= N'Rule'
										,	NULL
										,	[th]		= N'ID'
										,	NULL
										,	[th]		= N'SportName'
										,	NULL
										,	[th]		= N'SportType'
										,	NULL
										,	[th]		= N'BetType'
										,	NULL
										,	[th]		= N'Total'
										,	NULL
										,	[th]		= N''
									FOR XML PATH ('tr')
									,	TYPE
								)
							,	NULL
							,	(	SELECT	[td]		= ROW_NUMBER() OVER(ORDER BY RuleId, IsDeposit, SportType, BetType)
										,	NULL
										,	[td]		= RuleName
										,	NULL
										,	[td]		= RuleID
										,	NULL
										,	[td]		= SportName
										,	NULL
										,	[td]		= SportType
										,	NULL
										,	[td]		= BetType
										,	NULL
										,	[td]		= Total
										,	NULL
										,	[td]		= CASE IsDeposit WHEN 1 THEN 'Deposit' ELSE 'Credit' END
									FROM	#CheckResultCommAgg
									ORDER BY RuleId, IsDeposit, SportType, BetType
									FOR XML PATH ('tr')
									,	TYPE
								)
						WHERE	@countCommCredit + @countCommDeposit > @rowLimited
						FOR XML PATH ('table')
						,	TYPE
					)
				,	(	SELECT	[@border]		= 1
							,	[@cellpadding]	= 5
							,	[@width]		= N'95%'
							,	[@style]		= N'margin:0 auto;white-space:nowrap;'
							,	(	SELECT	[th]		= N'No.'
										,	NULL
										,	[th]		= N'Rule'
										,	NULL
										,	[th]		= N'ID'
										,	NULL
										,	[th]		= N'SportName'
										,	NULL
										,	[th]		= N'SportType'
										,	NULL
										,	[th]		= N'BetType'
										,	NULL
										,	[th]		= N'CustId A'
										,	NULL
										,	[th]		= N'Username A'
										,	NULL
										,	[th]		= N'CustId B'
										,	NULL
										,	[th]		= N'Value A'
										,	NULL
										,	[th]		= N'Value B'
										,	NULL
										,	[th]		= N''
									FOR XML PATH ('tr')
									,	TYPE
								)
							,	NULL
							,	(	SELECT	[td]		= ROW_NUMBER() OVER(ORDER BY RuleId, IsDeposit, CustId_A, SportType, BetType)
										,	NULL
										,	[td]		= RuleName
										,	NULL
										,	[td]		= RuleID
										,	NULL
										,	[td]		= SportName
										,	NULL
										,	[td]		= SportType
										,	NULL
										,	[td]		= BetType
										,	NULL
										,	[td]		= CustId_A
										,	NULL
										,	[td]		= Username_A
										,	NULL
										,	[td]		= CustId_B
										,	NULL
										,	[td]		= Value_A
										,	NULL
										,	[td]		= Value_B
										,	NULL
										,	[td]		= CASE IsDeposit WHEN 1 THEN 'Deposit' ELSE 'Credit' END
									FROM	#CheckResultComm
									ORDER BY RuleId, IsDeposit, CustId_A, SportType, BetType
									FOR XML PATH ('tr')
									,	TYPE
								)
						WHERE	@countCommCredit + @countCommDeposit <= @rowLimited
						FOR XML PATH ('table')
						,	TYPE
					)

				-- Bet Limit Result --
				,	[br]		= CASE WHEN @countBetLimitCredit + @countBetLimitDeposit = 0 THEN '' ELSE NULL END
				,	(	SELECT	[@style]		= N'margin-left:3%'
							,	[node()]		= 'Check Bet Limit Result'
						FROM	(
							SELECT	TOP(1) x = 1
							FROM	#CheckResultBetLimitAgg
						) tbl
						FOR XML PATH ('h3')
						,	TYPE
					)
				,	(	SELECT	[@border]		= 1
							,	[@cellpadding]	= 5
							,	[@width]		= N'95%'
							,	[@style]		= N'margin:0 auto;white-space:nowrap;'
							,	(	SELECT	[th]		= N'No.'
										,	NULL
										,	[th]		= N'Rule'
										,	NULL
										,	[th]		= N'ID'
										,	NULL
										,	[th]		= N'SportName'
										,	NULL
										,	[th]		= N'SportType'
										,	NULL
										,	[th]		= N'BetType'
										,	NULL
										,	[th]		= N'IsDCS'
										,	NULL
										,	[th]		= N'Total'
										,	NULL
										,	[th]		= N''
									FOR XML PATH ('tr')
									,	TYPE
								)
							,	NULL
							,	(	SELECT	[td]		= ROW_NUMBER() OVER(ORDER BY RuleId, IsDeposit, IsDCS, SportType, BetType)
										,	NULL
										,	[td]		= RuleName
										,	NULL
										,	[td]		= RuleID
										,	NULL
										,	[td]		= SportName
										,	NULL
										,	[td]		= ISNULL(CAST(SportType AS NVARCHAR), N'')
										,	NULL
										,	[td]		= ISNULL(CAST(BetType AS NVARCHAR), N'')
										,	NULL
										,	[td]		= IsDCS
										,	NULL
										,	[td]		= Total
										,	NULL
										,	[td]		= CASE IsDeposit WHEN 1 THEN 'Deposit' ELSE 'Credit' END
									FROM	#CheckResultBetLimitAgg
									ORDER BY RuleId, IsDeposit, IsDCS, SportType, BetType
									FOR XML PATH ('tr')
									,	TYPE
								)
						WHERE	@countBetLimitCredit + @countBetLimitDeposit > @rowLimited
						FOR XML PATH ('table')
						,	TYPE
					)
				,	(	SELECT	[@border]		= 1
							,	[@cellpadding]	= 5
							,	[@width]		= N'95%'
							,	[@style]		= N'margin:0 auto;white-space:nowrap;'
							,	(	SELECT	[th]		= N'No.'
										,	NULL
										,	[th]		= N'Rule'
										,	NULL
										,	[th]		= N'ID'
										,	NULL
										,	[th]		= N'SportName'
										,	NULL
										,	[th]		= N'SportType'
										,	NULL
										,	[th]		= N'BetType'
										,	NULL
										,	[th]		= N'CustId A'
										,	NULL
										,	[th]		= N'Username A'
										,	NULL
										,	[th]		= N'CustId B'
										,	NULL
										,	[th]		= N'Value A'
										,	NULL
										,	[th]		= N'Value B'
										,	NULL
										,	[th]		= N'IsDCS'
										,	NULL
										,	[th]		= N''
									FOR XML PATH ('tr')
									,	TYPE
								)
							,	NULL
							,	(	SELECT	[td]		= ROW_NUMBER() OVER(ORDER BY RuleId, IsDeposit, IsDCS, CustId_A, SportType, BetType)
										,	NULL
										,	[td]		= RuleName
										,	NULL
										,	[td]		= RuleID
										,	NULL
										,	[td]		= SportName
										,	NULL
										,	[td]		= ISNULL(CAST(SportType AS NVARCHAR), N'')
										,	NULL
										,	[td]		= ISNULL(CAST(BetType AS NVARCHAR), N'')
										,	NULL
										,	[td]		= CustId_A
										,	NULL
										,	[td]		= Username_A
										,	NULL
										,	[td]		= CustId_B
										,	NULL
										,	[td]		= Value_A
										,	NULL
										,	[td]		= Value_B
										,	NULL
										,	[td]		= IsDCS
										,	NULL
										,	[td]		= CASE IsDeposit WHEN 1 THEN 'Deposit' ELSE 'Credit' END
									FROM	#CheckResultBetLimit
									ORDER BY RuleId, IsDeposit, IsDCS, CustId_A, SportType, BetType
									FOR XML PATH ('tr')
									,	TYPE
								)
						WHERE	@countBetLimitCredit + @countBetLimitDeposit <= @rowLimited
						FOR XML PATH ('table')
						,	TYPE
					)

				-- Stake Level Result --
				,	[br]		= CASE WHEN @countStakeLevelCredit + @countStakeLevelDeposit = 0 THEN '' ELSE NULL END
				,	(	SELECT	[@style]		= N'margin-left:3%'
							,	[node()]		= 'Check Stake Level Result'
						FROM	(
							SELECT	TOP(1) x = 1
							FROM	#CheckResultStakeLevelAgg
						) tbl
						FOR XML PATH ('h3')
						,	TYPE
					)
				,	(	SELECT	[@border]		= 1
							,	[@cellpadding]	= 5
							,	[@width]		= N'95%'
							,	[@style]		= N'margin:0 auto;white-space:nowrap;'
							,	(	SELECT	[th]		= N'No.'
										,	NULL
										,	[th]		= N'Rule'
										,	NULL
										,	[th]		= N'ID'
										,	NULL
										,	[th]		= N'SportName'
										,	NULL
										,	[th]		= N'SportType'
										,	NULL
										,	[th]		= N'BetType'
										,	NULL
										,	[th]		= N'Total'
										,	NULL
										,	[th]		= N''
									FOR XML PATH ('tr')
									,	TYPE
								)
							,	NULL
							,	(	SELECT	[td]		= ROW_NUMBER() OVER(ORDER BY RuleId, IsDeposit, SportType, BetType)
										,	NULL
										,	[td]		= RuleName
										,	NULL
										,	[td]		= RuleID
										,	NULL
										,	[td]		= SportName
										,	NULL
										,	[td]		= ISNULL(CAST(SportType AS NVARCHAR), N'')
										,	NULL
										,	[td]		= ISNULL(CAST(BetType AS NVARCHAR), N'')
										,	NULL
										,	[td]		= Total
										,	NULL
										,	[td]		= CASE IsDeposit WHEN 1 THEN 'Deposit' ELSE 'Credit' END
									FROM	#CheckResultStakeLevelAgg
									ORDER BY RuleId, IsDeposit, SportType, BetType
									FOR XML PATH ('tr')
									,	TYPE
								)
						WHERE	@countStakeLevelCredit + @countStakeLevelDeposit > @rowLimited
						FOR XML PATH ('table')
						,	TYPE
					)
				,	(	SELECT	[@border]		= 1
							,	[@cellpadding]	= 5
							,	[@width]		= N'95%'
							,	[@style]		= N'margin:0 auto;white-space:nowrap;'
							,	(	SELECT	[th]		= N'No.'
										,	NULL
										,	[th]		= N'Rule'
										,	NULL
										,	[th]		= N'ID'
										,	NULL
										,	[th]		= N'SportName'
										,	NULL
										,	[th]		= N'SportType'
										,	NULL
										,	[th]		= N'BetType'
										,	NULL
										,	[th]		= N'CustId A'
										,	NULL
										,	[th]		= N'Username A'
										,	NULL
										,	[th]		= N'CustId B'
										,	NULL
										,	[th]		= N'Value A'
										,	NULL
										,	[th]		= N'Value B'
										,	NULL
										,	[th]		= N''
									FOR XML PATH ('tr')
									,	TYPE
								)
							,	NULL
							,	(	SELECT	[td]		= ROW_NUMBER() OVER(ORDER BY RuleId, IsDeposit, CustId_A, SportType, BetType)
										,	NULL
										,	[td]		= RuleName
										,	NULL
										,	[td]		= RuleID
										,	NULL
										,	[td]		= SportName
										,	NULL
										,	[td]		= ISNULL(CAST(SportType AS NVARCHAR), N'')
										,	NULL
										,	[td]		= ISNULL(CAST(BetType AS NVARCHAR), N'')
										,	NULL
										,	[td]		= CustId_A
										,	NULL
										,	[td]		= Username_A
										,	NULL
										,	[td]		= CustId_B
										,	NULL
										,	[td]		= Value_A
										,	NULL
										,	[td]		= Value_B
										,	NULL
										,	[td]		= CASE IsDeposit WHEN 1 THEN 'Deposit' ELSE 'Credit' END
									FROM	#CheckResultStakeLevel
									ORDER BY RuleId, IsDeposit, CustId_A, SportType, BetType
									FOR XML PATH ('tr')
									,	TYPE
								)
						WHERE	@countStakeLevelCredit + @countStakeLevelDeposit <= @rowLimited
						FOR XML PATH ('table')
						,	TYPE
					)

			FOR XML PATH ('body')
			,	ROOT ('html')
		);
		
		EXECUTE	msdb.dbo.sp_send_dbmail
					@profile_name			= DEFAULT
				,	@recipients				= @to
				,	@copy_recipients		= @cc
				,	@blind_copy_recipients	= @bcc
				,	@subject				= @subject
				,	@body					= @html
				,	@body_format			= 'HTML'
				;
	END;


	--	BEGIN STEP :
	--		Send letstalk -- Mode: 2
	----------------------------------------------------------------------------------------------------

	IF	@mode & 2 <> 0
	BEGIN
		SELECT	@html = N'';
		SELECT	@html = @html + N'
Check Setting Result:' + ISNULL(N'

- PT:' + NULLIF(ISNULL(N'
    Cre - ' + CAST(NULLIF(@countPTCredit, 0) AS NVARCHAR), N'') + ISNULL(N'
    Dep - ' + CAST(NULLIF(@countPTDeposit, 0) AS NVARCHAR), N''), N''), N'') + ISNULL(N'

- Status:' + NULLIF(ISNULL(N'
    Cre - ' + CAST(NULLIF(@countStatusCredit, 0) AS NVARCHAR), N'') + ISNULL(N'
    Dep - ' + CAST(NULLIF(@countStatusDeposit, 0) AS NVARCHAR), N''), N''), N'') + ISNULL(N'

- Commission:' + NULLIF(ISNULL(N'
    Cre - ' + CAST(NULLIF(@countCommCredit, 0) AS NVARCHAR), N'') + ISNULL(N'
    Dep - ' + CAST(NULLIF(@countCommDeposit, 0) AS NVARCHAR), N''), N''), N'') + ISNULL(N'

- Bet Limit:' + NULLIF(ISNULL(N'
    Cre - ' + CAST(NULLIF(@countBetLimitCredit, 0) AS NVARCHAR), N'') + ISNULL(N'
    Dep - ' + CAST(NULLIF(@countBetLimitDeposit, 0) AS NVARCHAR), N''), N''), N'') + ISNULL(N'

- Stake Level:' + NULLIF(ISNULL(N'
    Cre - ' + CAST(NULLIF(@countStakeLevelCredit, 0) AS NVARCHAR), N'') + ISNULL(N'
    Dep - ' + CAST(NULLIF(@countStakeLevelDeposit, 0) AS NVARCHAR), N''), N''), N'');

		SELECT	@subject	= N'vnDBA : Automation Check CustDB'
			,	@case		= CASE	WHEN @countPTCredit + @countPTDeposit
									   + @countStatusCredit + @countStatusDeposit
									   + @countCommCredit + @countCommDeposit
									   + @countBetLimitCredit + @countBetLimitDeposit
									   + @countStakeLevelCredit + @countStakeLevelDeposit
									   = 0
									THEN 1 ELSE 2 END
			;

		EXECUTE DBMONDW.MonDBDW.dbo.DBA_Letstalk_NewJobMessage
					@ServerName	= @@SERVERNAME
				,	@JobId		= NULL
				,	@JobName	= @subject
				,	@Message	= @html
				,	@CaseId		= @case
				;
	END;

	DROP TABLE	#CheckResultPT
			,	#CheckResultPTAgg
			,	#CheckResultStatus
			,	#CheckResultStatusAgg
			,	#CheckResultComm
			,	#CheckResultCommAgg
			;
END;
GO
/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/