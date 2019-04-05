/*
	Creator:	20190405@Billy
	Task:		Description - [Redmine: #000000]
	Server:		DBCHECK.CheckResultDB
*/


--	BEGIN STEP :
--		Data
----------------------------------------------------------------------------------------------------

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'PT Sportbook Credit', N'CheckSettingThreadCount', 6, N'
SET NOCOUNT ON;

DECLARE @CustId INT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Credit_Supers
	SET @CustId = CustId
	, PTSportbook = 2
	WHERE PTSportbook = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckPT_Credit @srecommend = @CustId;

	UPDATE dbo.Credit_Supers
	SET PTSportbook = 1
	WHERE CustId = @CustId
	AND PTSportbook = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'PT 3rd Products Credit', N'CheckSettingThreadCount', 3, N'
SET NOCOUNT ON;

DECLARE @CustId INT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Credit_Supers
	SET @CustId = CustId
	, PT3rdProduct = 2
	WHERE PT3rdProduct = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckPT3rd_Credit @srecommend = @CustId;

	UPDATE dbo.Credit_Supers
	SET PT3rdProduct = 1
	WHERE CustId = @CustId
	AND PT3rdProduct = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'PT Game Credit', N'CheckSettingThreadCount', 3, N'
SET NOCOUNT ON;

DECLARE @CustId INT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Credit_Supers
	SET @CustId = CustId
	, PTGame = 2
	WHERE PTGame = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckPTGame_Credit @srecommend = @CustId;

	UPDATE dbo.Credit_Supers
	SET PTGame = 1
	WHERE CustId = @CustId
	AND PTGame = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'PT DCS Credit', N'CheckSettingThreadCount', 3, N'
SET NOCOUNT ON;

DECLARE @CustId INT, @RoleId TINYINT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Credit_DCS
	SET @CustId = CustId
	, @RoleId = RoleId
	, isFinished = 2
	WHERE isFinished = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckPT_DCS @CustId = @CustId, @RoleId = @RoleId;

	UPDATE dbo.Credit_DCS
	SET isFinished = 1
	WHERE CustId = @CustId
	AND RoleId = @RoleId
	AND isFinished = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'Status DCS Credit', N'CheckSettingThreadCount', 1, N'
SET NOCOUNT ON;

EXECUTE DBA_CheckStatus_Credit_DCS;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
')
	,	(N'Status Non-DCS Credit', N'CheckSettingThreadCount', 1, N'
SET NOCOUNT ON;

EXECUTE dbo.DBA_CheckStatus_Credit_NonDCS;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
')
	,	(N'Status DCS Deposit', N'CheckSettingThreadCount', 1, N'
SET NOCOUNT ON;

EXECUTE DBA_CheckStatus_Deposit_DCS;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
')
	,	(N'Status Non-DCS Deposit', N'CheckSettingThreadCount', 1, N'
SET NOCOUNT ON;

EXECUTE dbo.DBA_CheckStatus_Deposit_NonDCS;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'Commission Sportbooks Credit', N'CheckSettingThreadCount', 3, N'
SET NOCOUNT ON;

DECLARE @CustId INT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Credit_Supers
	SET @CustId = CustId
	, CommSportbook = 2
	WHERE CommSportbook = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckComm_Credit @srecommend = @CustId, @SportType = 0, @RuleId = 0;

	UPDATE dbo.Credit_Supers
	SET CommSportbook = 1
	WHERE CustId = @CustId
	AND CommSportbook = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'Commission 3rd Products Credit', N'CheckSettingThreadCount', 3, N'
SET NOCOUNT ON;

DECLARE @CustId INT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Credit_Supers
	SET @CustId = CustId
	, Comm3rdProduct = 2
	WHERE Comm3rdProduct = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckComm3rd_Credit @srecommend = @CustId, @SportType = 0, @RuleId = 0;

	UPDATE dbo.Credit_Supers
	SET Comm3rdProduct = 1
	WHERE CustId = @CustId
	AND Comm3rdProduct = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'Commission Game Credit', N'CheckSettingThreadCount', 3, N'
SET NOCOUNT ON;

DECLARE @CustId INT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Credit_Supers
	SET @CustId = CustId
	, CommGame = 2
	WHERE CommGame = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckCommGame_Credit @srecommend = @CustId, @SportType = 0, @RuleId = 0;

	UPDATE dbo.Credit_Supers
	SET CommGame = 1
	WHERE CustId = @CustId
	AND CommGame = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'Commission DCS Credit', N'CheckSettingThreadCount', 3, N'
SET NOCOUNT ON;

DECLARE @CustId INT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Credit_Supers
	SET @CustId = CustId
	, CommDCS = 2
	WHERE CommDCS = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckComm_DCS @srecommend = @CustId, @SportType = 0, @RuleId = 0;

	UPDATE dbo.Credit_Supers
	SET CommDCS = 1
	WHERE CustId = @CustId
	AND CommDCS = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'Commission Sportbooks Deposit', N'CheckSettingThreadCount', 0, N'
SET NOCOUNT ON;

DECLARE @CustId INT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Deposit_Supers
	SET @CustId = CustId
	, CommSportbook = 2
	WHERE CommSportbook = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckComm_Deposit @srecommend = @CustId, @SportType = 0, @RuleId = 0;

	UPDATE dbo.Deposit_Supers
	SET CommSportbook = 1
	WHERE CustId = @CustId
	AND CommSportbook = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'Commission 3rd Products Deposit', N'CheckSettingThreadCount', 0, N'
SET NOCOUNT ON;

DECLARE @CustId INT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Deposit_Supers
	SET @CustId = CustId
	, Comm3rdProduct = 2
	WHERE Comm3rdProduct = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckComm3rd_Deposit @srecommend = @CustId, @SportType = 0, @RuleId = 0;

	UPDATE dbo.Deposit_Supers
	SET Comm3rdProduct = 1
	WHERE CustId = @CustId
	AND Comm3rdProduct = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'Commission Game Deposit', N'CheckSettingThreadCount', 0, N'
SET NOCOUNT ON;

DECLARE @CustId INT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Deposit_Supers
	SET @CustId = CustId
	, CommGame = 2
	WHERE CommGame = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckCommGame_Deposit @srecommend = @CustId, @SportType = 0, @RuleId = 0;

	UPDATE dbo.Deposit_Supers
	SET CommGame = 1
	WHERE CustId = @CustId
	AND CommGame = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'Bet Limit Credit', N'CheckSettingThreadCount', 3, N'
SET NOCOUNT ON;

DECLARE @CustId INT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Credit_Supers
	SET @CustId = CustId
	, BetLimit = 2
	WHERE BetLimit = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckBetLimit_Credit @srecommend = @CustId, @SportType = 0, @RuleId = 0;

	UPDATE dbo.Credit_Supers
	SET BetLimit = 1
	WHERE CustId = @CustId
	AND BetLimit = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'Bet Limit 3rd Products Credit', N'CheckSettingThreadCount', 3, N'
SET NOCOUNT ON;

DECLARE @CustId INT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Credit_Supers
	SET @CustId = CustId
	, BetLimit3rdProduct = 2
	WHERE BetLimit3rdProduct = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckBetLimit3rd_Credit @srecommend = @CustId, @SportType = 0, @RuleId = 0;

	UPDATE dbo.Credit_Supers
	SET BetLimit3rdProduct = 1
	WHERE CustId = @CustId
	AND BetLimit3rdProduct = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'Bet Limit Keno Credit', N'CheckSettingThreadCount', 3, N'
SET NOCOUNT ON;

DECLARE @CustId INT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Credit_Supers
	SET @CustId = CustId
	, BetLimitKeno = 2
	WHERE BetLimitKeno = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckKenoBetLimit_Credit @srecommend = @CustId, @RuleId = 0;

	UPDATE dbo.Credit_Supers
	SET BetLimitKeno = 1
	WHERE CustId = @CustId
	AND BetLimitKeno = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'Bet Limit DCS Credit', N'CheckSettingThreadCount', 3, N'
SET NOCOUNT ON;

DECLARE @CustId INT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Credit_Supers
	SET @CustId = CustId
	, BetLimitDCS = 2
	WHERE BetLimitDCS = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckBetLimit_Credit_DCS @srecommend = @CustId, @SportType = 0, @RuleId = 0;

	UPDATE dbo.Credit_Supers
	SET BetLimitDCS = 1
	WHERE CustId = @CustId
	AND BetLimitDCS = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'Bet Limit Deposit', N'CheckSettingThreadCount', 3, N'
SET NOCOUNT ON;

DECLARE @CustId INT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Deposit_Supers
	SET @CustId = CustId
	, BetLimit = 2
	WHERE BetLimit = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckBetLimit_Dep @srecommend = @CustId, @RuleId = 0;

	UPDATE dbo.Deposit_Supers
	SET BetLimit = 1
	WHERE CustId = @CustId
	AND BetLimit = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'Stake Level Credit', N'CheckSettingThreadCount', 3, N'
SET NOCOUNT ON;

DECLARE @CustId INT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Credit_Supers
	SET @CustId = CustId
	, StakeLevel = 2
	WHERE StakeLevel = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckStakeLevel_Credit @srecommend = @CustId, @SportType = 0, @RuleId = 0;

	UPDATE dbo.Credit_Supers
	SET StakeLevel = 1
	WHERE CustId = @CustId
	AND StakeLevel = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'Stake Level DCS Credit', N'CheckSettingThreadCount', 3, N'
SET NOCOUNT ON;

DECLARE @CustId INT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Credit_Supers
	SET @CustId = CustId
	, StakeLevelDCS = 2
	WHERE StakeLevelDCS = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckDCSStakeLevel_Credit @srecommend = @CustId, @SportType = 0, @RuleId = 0;

	UPDATE dbo.Credit_Supers
	SET StakeLevelDCS = 1
	WHERE CustId = @CustId
	AND StakeLevelDCS = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'Stake Level DCS Deposit', N'CheckSettingThreadCount', 3, N'
SET NOCOUNT ON;

DECLARE @CustId INT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Deposit_Supers
	SET @CustId = CustId
	, StakeLevelDCS = 2
	WHERE StakeLevelDCS = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckDCSStakeLevel_Deposit @srecommend = @CustId, @SportType = 0, @RuleId = 0;

	UPDATE dbo.Deposit_Supers
	SET StakeLevelDCS = 1
	WHERE CustId = @CustId
	AND StakeLevelDCS = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');

INSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)
VALUES	(N'PT Deposit', N'CheckSettingThreadCount', 6, N'
SET NOCOUNT ON;

DECLARE @CustId INT;

WHILE 0 = 0
BEGIN
	SELECT @CustId = NULL;
	UPDATE TOP(1) dbo.Deposit_Supers
	SET @CustId = CustId
	, PT = 2
	WHERE PT = 0;

	IF @CustId IS NULL BREAK;

	EXECUTE dbo.DBA_CheckPositionTaking_Deposit_DCS  @srecommend = @CustId, @RuleId = 0;
	EXECUTE dbo.DBA_CheckPositionTaking_DepCustsetting  @srecommend = @CustId, @RuleId = 0;
	EXECUTE dbo.DBA_CheckPositionTaking_DepCustSetting3rd  @srecommend = @CustId, @RuleId = 0;
	EXECUTE dbo.DBA_CheckPositionTaking_DepCustSettingGame  @srecommend = @CustId, @RuleId = 0;

	UPDATE dbo.Deposit_Supers
	SET PT = 1
	WHERE CustId = @CustId
	AND PT = 2;
END;

UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)
SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1
WHERE	VarKey = N''~~~'';
');