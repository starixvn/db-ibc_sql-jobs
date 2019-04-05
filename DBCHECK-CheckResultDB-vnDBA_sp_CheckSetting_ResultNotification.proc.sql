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
*/
BEGIN;
	SET NOCOUNT ON;

	DECLARE	@subject			NVARCHAR(255)
		,	@html				NVARCHAR(MAX)
		,	@countPT			INT
		,	@countStatus		INT
		,	@countComm			INT
		,	@countBetLimit		INT
		,	@countStakeLevel	INT
		,	@rowLimited			INT
		,	@logDate			DATETIME
		,	@fullBackup			NVARCHAR(500)
		,	@diffBackup			NVARCHAR(500)
		,	@case				TINYINT
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

	SELECT	@countPT = SUM(Total)
	FROM	#CheckResultPTAgg;

	UPDATE	StarixDB.dbo.vnDBA_Restore_CheckCustDB_History
	SET		PTResult = ISNULL(@countPT, 0)
	WHERE	LogDate = @LogDate;

	IF	@countPT <= @rowLimited
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
	
	SELECT	@countStatus = SUM(Total)
	FROM	#CheckResultStatusAgg;

	UPDATE	StarixDB.dbo.vnDBA_Restore_CheckCustDB_History
	SET		StatusResult = ISNULL(@countStatus, 0)
	WHERE	LogDate = @LogDate;

	IF	@countStatus <= @rowLimited
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

	SELECT	@countComm = SUM(Total)
	FROM	#CheckResultCommAgg;

	UPDATE	StarixDB.dbo.vnDBA_Restore_CheckCustDB_History
	SET		CommResult = ISNULL(@countComm, 0)
	WHERE	LogDate = @LogDate;

	IF	@countComm <= @rowLimited
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
	
	SELECT	@countBetLimit = SUM(Total)
	FROM	#CheckResultBetLimitAgg;

	UPDATE	StarixDB.dbo.vnDBA_Restore_CheckCustDB_History
	SET		BetLimitResult = ISNULL(@countBetLimit, 0)
	WHERE	LogDate = @LogDate;

	IF	@countBetLimit <= @rowLimited
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
	
	SELECT	@countStakeLevel = SUM(Total)
	FROM	#CheckResultStakeLevelAgg;

	UPDATE	StarixDB.dbo.vnDBA_Restore_CheckCustDB_History
	SET		StakeLevelResult = ISNULL(@countStakeLevel, 0)
	WHERE	LogDate = @LogDate;

	IF	@countStatus <= @rowLimited
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
							,	[div/@style]	= N'background-color:' + CASE ISNULL(@countPT, 0) WHEN 0 THEN N'blue;' ELSE N'red;' END + s.style
							,	[div/h2]		= N'PT'
							,	[div/h3]		= CASE ISNULL(@countPT, 0) WHEN 0 THEN N'Success' ELSE CAST(@countPT AS NVARCHAR) END
							,	NULL
							,	[div/@style]	= N'background-color:' + CASE ISNULL(@countStatus, 0) WHEN 0 THEN N'blue;' ELSE N'red;' END + s.style
							,	[div/h2]		= N'Status'
							,	[div/h3]		= CASE ISNULL(@countStatus, 0) WHEN 0 THEN N'Success' ELSE CAST(@countStatus AS NVARCHAR) END
							,	NULL
							,	[div/@style]	= N'background-color:' + CASE ISNULL(@countComm, 0) WHEN 0 THEN N'blue;' ELSE N'red;' END + s.style
							,	[div/h2]		= N'Commission'
							,	[div/h3]		= CASE ISNULL(@countComm, 0) WHEN 0 THEN N'Success' ELSE CAST(@countComm AS NVARCHAR) END
							,	NULL
							,	[div/@style]	= N'background-color:' + CASE ISNULL(@countBetLimit, 0) WHEN 0 THEN N'blue;' ELSE N'red;' END + s.style
							,	[div/h2]		= N'Bet Limit'
							,	[div/h3]		= CASE ISNULL(@countBetLimit, 0) WHEN 0 THEN N'Success' ELSE CAST(@countBetLimit AS NVARCHAR) END
							,	NULL
							,	[div/@style]	= N'background-color:' + CASE ISNULL(@countStakeLevel, 0) WHEN 0 THEN N'blue;' ELSE N'red;' END + s.style
							,	[div/h2]		= N'Stake Level'
							,	[div/h3]		= CASE ISNULL(@countStakeLevel, 0) WHEN 0 THEN N'Success' ELSE CAST(@countStakeLevel AS NVARCHAR) END
						FROM	(
							SELECT	[style]			= N'color:white;text-align:center;width:20%;display:table-cell;'
						) s
						FOR XML PATH ('div')
						,	TYPE
					)
				,	[br]		= ''

				-- PT Result --
				,	[br]		= CASE WHEN @countPT IS NOT NULL THEN '' ELSE NULL END
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
						WHERE	@countPT > @rowLimited
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
						WHERE	@countPT <= @rowLimited
						FOR XML PATH ('table')
						,	TYPE
					)

				-- Status Result --
				,	[br]		= CASE WHEN @countStatus IS NOT NULL THEN '' ELSE NULL END
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
						WHERE	@countStatus > @rowLimited
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
						WHERE	@countStatus <= @rowLimited
						FOR XML PATH ('table')
						,	TYPE
					)

				-- Commission Result --
				,	[br]		= CASE WHEN @countComm IS NOT NULL THEN '' ELSE NULL END
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
						WHERE	@countComm > @rowLimited
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
						WHERE	@countComm <= @rowLimited
						FOR XML PATH ('table')
						,	TYPE
					)

				-- Bet Limit Result --
				,	[br]		= CASE WHEN @countBetLimit IS NOT NULL THEN '' ELSE NULL END
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
						WHERE	@countBetLimit > @rowLimited
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
						WHERE	@countBetLimit <= @rowLimited
						FOR XML PATH ('table')
						,	TYPE
					)

				-- Stake Level Result --
				,	[br]		= CASE WHEN @countStakeLevel IS NOT NULL THEN '' ELSE NULL END
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
						WHERE	@countStakeLevel > @rowLimited
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
						WHERE	@countStakeLevel <= @rowLimited
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

- PT:' + xpt.xml.value('.[1]', 'NVARCHAR(MAX)'), N'') + ISNULL(N'

- Status:' + xst.xml.value('.[1]', 'NVARCHAR(MAX)'), N'') + ISNULL(N'

- Commission:' + xcm.xml.value('.[1]', 'NVARCHAR(MAX)'), N'') + ISNULL(N'

- Bet Limit:' + xbl.xml.value('.[1]', 'NVARCHAR(MAX)'), N'') + ISNULL(N'

- Stake Level:' + xsl.xml.value('.[1]', 'NVARCHAR(MAX)'), N'')
		FROM	(
			SELECT	N'
    ' + CASE pt.IsDeposit WHEN 0 THEN N'Cre - ' WHEN 1 THEN N'Dep - ' ELSE N'' END + CAST(SUM(pt.Total) AS NVARCHAR)
			FROM	#CheckResultPTAgg AS pt WITH (NOLOCK)
			GROUP BY pt.IsDeposit
			ORDER BY pt.IsDeposit
			FOR XML PATH ('')
			,	TYPE
		) AS xpt(xml)
		CROSS APPLY	(
			SELECT	N'
    ' + CASE st.IsDeposit WHEN 0 THEN N'Cre - ' WHEN 1 THEN N'Dep - ' ELSE N'' END + CAST(SUM(st.Total) AS NVARCHAR)
			FROM	#CheckResultStatusAgg AS st WITH (NOLOCK)
			GROUP BY st.IsDeposit
			ORDER BY st.IsDeposit
			FOR XML PATH ('')
			,	TYPE
		) AS xst(xml)
		CROSS APPLY	(
			SELECT	N'
    ' + CASE cm.IsDeposit WHEN 0 THEN N'Cre - ' WHEN 1 THEN N'Dep - ' ELSE N'' END + CAST(SUM(cm.Total) AS NVARCHAR)
			FROM	#CheckResultCommAgg AS cm WITH (NOLOCK)
			GROUP BY cm.IsDeposit
			ORDER BY cm.IsDeposit
			FOR XML PATH ('')
			,	TYPE
		) AS xcm(xml)
		CROSS APPLY	(
			SELECT	N'
    ' + CASE bl.IsDeposit WHEN 0 THEN N'Cre - ' WHEN 1 THEN N'Dep - ' ELSE N'' END + CAST(SUM(bl.Total) AS NVARCHAR)
			FROM	#CheckResultBetLimitAgg AS bl WITH (NOLOCK)
			GROUP BY bl.IsDeposit
			ORDER BY bl.IsDeposit
			FOR XML PATH ('')
			,	TYPE
		) AS xbl(xml)
		CROSS APPLY	(
			SELECT	N'
    ' + CASE sl.IsDeposit WHEN 0 THEN N'Cre - ' WHEN 1 THEN N'Dep - ' ELSE N'' END + CAST(SUM(sl.Total) AS NVARCHAR)
			FROM	#CheckResultStakeLevelAgg AS sl WITH (NOLOCK)
			GROUP BY sl.IsDeposit
			ORDER BY sl.IsDeposit
			FOR XML PATH ('')
			,	TYPE
		) AS xsl(xml);

		SELECT	@subject	= N'vnDBA : Automation Check CustDB'
			,	@case		= CASE WHEN ISNULL(@countPT, 0) + ISNULL(@countStatus, 0) + ISNULL(@countComm, 0) + ISNULL(@countBetLimit, 0) + ISNULL(@countStakeLevel, 0) = 0 THEN 1 ELSE 2 END
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