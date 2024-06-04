/*<info serverAlias="DBAGE-bodb_AGE" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_CDC_bettrans_compact_CorrectData]
	@CheckTime DATETIME = NULL
AS
/*
	Created by: 20231201@Bobby
	Task: 153357 - Alpha - CDC bettrans_compact - check SUMDATA
	DB: DBAGE.bodb_AGE
	Revisions:
		- 20231201@Bobby: Implement bettrans_compact Redmine: [#153357]
		- 20240306@Lewis: Add Virtual Ice Hockey [RedmineID: #201129]
		- 20240321@Bobby: checkSum remove extraWinloss vs extraComm Redmine: [#200041]
		- 20240401@Bobby: Fix bug checkNotify & Correct Redmine: [#202655]
		- 20240522@Bobby: Enhance checkSum process [RedmineID: #205378]
		- 20240515@Lewis: Add SABA Kabaddi [RedmineID: #203763]
		- 20240602@Bobby: Enhance check & correct process [RedmineID: #205973]
*/
BEGIN

	SET NOCOUNT ON;

	DROP TABLE IF EXISTS #diffCustCheckSum;
	DROP TABLE IF EXISTS #diffCustProcess;
	DROP TABLE IF EXISTS #checkCorrectData;

	CREATE TABLE #diffCustProcess (rIdx INT IDENTITY(1,1), Winlostdate SMALLDATETIME, CustIds VARCHAR(MAX));
	CREATE TABLE #checkCorrectData(
		[custid] [int] NOT NULL,
		[winlostdate] [smalldatetime] NOT NULL,
		[productId] [tinyint] NOT NULL,
		[sporttype] [int] NOT NULL,
		[bettype] [smallint] NOT NULL,
		[leagueGroupID] [int] NOT NULL,
		[ticketType] [int] NOT NULL,
		[betcount] [int] NULL,
		[turnover] [money] NULL,
		[netTurnover] [money] NULL,
		[TurnoverNoDraw] [money] NULL,
		[winlost] [money] NULL,
		[awinlost] [money] NULL,
		[mwinlost] [money] NULL,
		[swinlost] [money] NULL,
		[playercomm] [money] NULL,
		[comm] [money] NULL,
		[acomm] [money] NULL,
		[scomm] [money] NULL,
		[grosscomm] [money] NULL,
		[extraComm] [decimal](38, 6) NULL,
		[extraWinloss] [decimal](38, 6) NULL,
		[checkSumKey] [INT],
		[roundCheck] [SMALLINT]
	);
	CREATE TABLE #diffCustCheckSum (custid INT, winlostdate SMALLDATETIME, checkSumKey INT, checkSumData INT, IsCompleted BIT, PRIMARY KEY(winlostdate, custid, checkSumKey));

	-- TODO: get diff custid vs winlostdate
	INSERT INTO #diffCustCheckSum (custid, winlostdate, checkSumKey, checkSumData, IsCompleted)
	SELECT DISTINCT custid, winlostdate, checkSumKey, checkSumData, 0 AS IsCompleted
	FROM (
		SELECT custid, winlostdate, checkSumKey, checkSumData, ROW_NUMBER() OVER (PARTITION BY custid, winlostdate, checkSumKey ORDER BY createdtime DESC) AS rIdx
		FROM dbo.bettrans_compact_checkSum WITH(NOLOCK)
		WHERE notifyStatus = 0
			AND roundCheck = 0
			AND createdTime = @CheckTime
	) AS t 
	WHERE t.rIdx = 1;

	IF @@ROWCOUNT = 0 RETURN;

	--TODO: process Correct data
	DECLARE @winlostdate SMALLDATETIME, @rCont INT = 1, @loopCheck INT, @limitCheck INT, @maxLoop INT
		, @notifyStatus TINYINT = 0
		, @GEN_custids VARCHAR(MAX);
	DECLARE @verifyCheckSumStatus TABLE (custid INT, winlostdate SMALLDATETIME, checkSumKey INT, roundCheck SMALLINT, notifyStatus TINYINT, keyValue VARCHAR(MAX));
	DECLARE @correctResult TABLE(
		[actionName] VARCHAR(50), 
		[custid] [int] NOT NULL,
		[winlostdate] [smalldatetime] NOT NULL,
		[productId] [tinyint] NOT NULL,
		[sporttype] [int] NOT NULL,
		[bettype] [smallint] NOT NULL,
		[leagueGroupID] [int] NOT NULL,
		[ticketType] [int] NOT NULL
	);

	--TODO: loop by un-completed diff custid
	SELECT @loopCheck	= 0
		, @limitCheck	= 5
		, @maxLoop		= 24;

	WHILE EXISTS (SELECT 1 FROM #diffCustCheckSum ck WHERE IsCompleted = 0 AND @loopCheck < @maxLoop) -- 2 min
	BEGIN
		TRUNCATE TABLE #diffCustProcess;

		INSERT INTO #diffCustProcess(Winlostdate, CustIds)
		SELECT c.Winlostdate, STRING_AGG(CAST(c.custid AS VARCHAR(MAX)), ',')
		FROM #diffCustCheckSum c
		WHERE c.IsCompleted = 0
		GROUP BY Winlostdate
		ORDER BY Winlostdate;

		--TODO: loop by winlostdate & supers
		SELECT @rCont = 1;
		WHILE EXISTS (SELECT 1 FROM #diffCustProcess WHERE rIdx = @rCont)
		BEGIN

			TRUNCATE TABLE #checkCorrectData;
			DELETE @verifyCheckSumStatus;

			SELECT @winlostdate = Winlostdate, @GEN_custids = CustIds
			FROM #diffCustProcess 
			WHERE rIdx = @rCont;

			--TODO: gen all data
			INSERT INTO #checkCorrectData(
				custid,winlostdate,productid,sporttype,bettype,leagueGroupID,ticketType
				,betcount,winlost,turnover,netTurnover,awinlost,mwinlost,swinlost,playercomm,comm,acomm,scomm,TurnoverNoDraw,grosscomm,ExtraComm,ExtraWinloss)
			EXEC dbo.[Task_Gen_Compact_bettrans] @winlostdate= @winlostdate, @custIds = @GEN_custids

			--GEN: checkSumKey
			UPDATE bt
			SET bt.checkSumKey = CHECKSUM(CONCAT_WS('|', bt.productid, bt.sporttype, bt.bettype, bt.leagueGroupID, bt.ticketType))
			FROM #checkCorrectData bt;

			--TODO: compare with bettrans_compact
			SET @notifyStatus = 0;
			;WITH bt_checkSum AS (
				SELECT cal.custid, cal.winlostdate
					, checkSumKey
					, (CHECKSUM(CONCAT_WS('|',betcount,	winlost, turnover,netTurnover
						,awinlost, mwinlost,swinlost,playercomm,comm,acomm,scomm,TurnoverNoDraw,grosscomm))) AS checkSumData
				FROM #checkCorrectData cal
			)
			,compact_checkSum AS (
				SELECT b.custid, b.winlostdate
					, CHECKSUM(CONCAT_WS('|', b.productId, b.sporttype, bettype, leagueGroupID, ticketType)) AS checkSumKey
					, (CHECKSUM(CONCAT_WS('|',betcount,	winlost, turnover,netTurnover
						, awinlost, mwinlost,swinlost,playercomm,comm,acomm,scomm,TurnoverNoDraw,grosscomm))) AS checkSumData 
		
				FROM dbo.bettrans_compact b WITH(NOLOCK)
				INNER JOIN (
					SELECT DISTINCT custid, winlostdate FROM #diffCustCheckSum diff WHERE diff.IsCompleted = 0 AND diff.winlostdate = @winlostdate
				) AS diff ON diff.custid = b.custid AND diff.winlostdate = b.winlostdate 
			),
			compile_checkSum AS (
				SELECT 
					@winlostdate AS winlostdate
					, ISNULL(bt.custid, ck.custid) AS custid
					, ISNULL(bt.checkSumKey, ck.checkSumKey) AS checkSumKey
					, ISNULL(bt.checkSumData, ck.checkSumData) AS checkSumData
					, IIF(ck.checkSumData = bt.checkSumData, 1, 0) AS sameCount -- passed
					, IIF(bt.custid IS NULL OR ck.custid IS NULL OR ck.checkSumData <> bt.checkSumData, 1, 0) AS diffCount
				FROM  bt_checksum bt
				FULL JOIN compact_checkSum ck ON ck.custid = bt.custid
					AND ck.winlostdate = bt.winlostdate
					AND ck.checkSumKey = bt.checkSumKey
			),
			verify_checkSum AS (
				SELECT cal.*
					,IIF(((cal.diffCount = 1 AND diff.checkSumData = cal.checkSumData) OR cal.sameCount = 1), 1, -1) AS roundCount
				FROM compile_checkSum cal
				INNER JOIN #diffCustCheckSum diff ON diff.custid = cal.custid AND diff.winlostdate = cal.winlostdate AND diff.checkSumKey = cal.checkSumKey AND diff.IsCompleted = 0
			
			)
			UPDATE up WITH(ROWLOCK, UPDLOCK)
			SET @notifyStatus		= IIF(vc.sameCount = 1 AND up.roundCheck = 2, 2, 0) --auto fixed / catch up
				,up.notifyStatus	= @notifyStatus
				,up.roundCheck		= IIF(vc.roundCount = -1, 0, ISNULL(up.roundCheck,0) + vc.roundCount)
				,up.checkSumData	= vc.checkSumData
			OUTPUT INSERTED.custid,INSERTED.winlostdate,INSERTED.checkSumKey, INSERTED.roundCheck, INSERTED.notifyStatus, INSERTED.keyValue
			INTO @verifyCheckSumStatus(custid, winlostdate, checkSumKey, roundCheck, notifyStatus, keyValue)
			FROM dbo.bettrans_compact_checkSum up
			INNER JOIN verify_checkSum vc ON vc.custid = up.custid AND vc.winlostdate = up.winlostdate AND vc.checkSumKey = up.checkSumKey
			WHERE up.notifyStatus = 0
				AND up.createdTime = @CheckTime

			-- TODO: UPDATE roundCheck to correct data
			UPDATE up SET
				up.roundCheck = vc.roundCheck
			FROM #checkCorrectData up
			INNER JOIN @verifyCheckSumStatus vc ON vc.custid = up.custid AND vc.winlostdate = up.winlostdate AND vc.checkSumKey = up.checkSumKey

			---UPDATE diff rows
			UPDATE up WITH(ROWLOCK, UPDLOCK)
			SET up.[betcount]		= tmp.[betcount]
				,up.[turnover]		= tmp.[turnover]
				,up.[netTurnover]	= tmp.[netTurnover]
				,up.[TurnoverNoDraw] = tmp.[TurnoverNoDraw]
				,up.[winlost]		= tmp.[winlost]
				,up.[awinlost]		= tmp.[awinlost]
				,up.[mwinlost]		= tmp.[mwinlost]
				,up.[swinlost]		= tmp.[swinlost]
				,up.[playercomm]	= tmp.[playercomm]
				,up.[comm]			= tmp.[comm]
				,up.[acomm]			= tmp.[acomm]
				,up.[scomm]			= tmp.[scomm]
				,up.[grosscomm]		= tmp.[grosscomm]
				,up.[extraWinloss]	= tmp.[extraWinloss]
				,up.[extraComm]		= tmp.[extraComm]
			
			OUTPUT 'UPDATE', INSERTED.custid, INSERTED.winlostdate, INSERTED.productid, INSERTED.sporttype, INSERTED.bettype, INSERTED.LeagueGroupID, INSERTED.ticketType
			INTO @correctResult(actionName, custid,winlostdate,productid,sporttype,bettype,LeagueGroupID,ticketType)
			FROM dbo.bettrans_compact up
			INNER JOIN #checkCorrectData tmp ON (
				up.custid				= tmp.custid
				AND up.[winlostdate]	= tmp.[winlostdate]
				AND up.[productId]		= tmp.[productId]
				AND up.[sporttype]		= tmp.[sporttype]
				AND up.[bettype]		= tmp.[bettype]
				AND up.[leagueGroupID]	= tmp.[leagueGroupID]
				AND up.[ticketType]		= tmp.[ticketType]
			)
			WHERE tmp.roundCheck >= @limitCheck;

			---INSERT diff rows
			INSERT INTO dbo.bettrans_compact(
				[custid]
				,[winlostdate]
				,[productId]
				,[sporttype]
				,[bettype]
				,[leagueGroupID]
				,[ticketType]
				,[betcount]
				,[turnover]
				,[netTurnover]
				,[TurnoverNoDraw]
				,[winlost]
				,[awinlost]
				,[mwinlost]
				,[swinlost]
				,[playercomm]
				,[comm]
				,[acomm]
				,[scomm]
				,[grosscomm]
				,[extraWinloss]
				,[extraComm]
			)
			OUTPUT 'INSERT', INSERTED.custid, INSERTED.winlostdate, INSERTED.productid, INSERTED.sporttype, INSERTED.bettype, INSERTED.LeagueGroupID, INSERTED.ticketType
			INTO @correctResult(actionName, custid,winlostdate,productid,sporttype,bettype,LeagueGroupID,ticketType)
			SELECT
				tmp.[custid]
				,tmp.[winlostdate]
				,tmp.[productId]
				,tmp.[sporttype]
				,tmp.[bettype]
				,tmp.[leagueGroupID]
				,tmp.[ticketType]
				,tmp.[betcount]
				,tmp.[turnover]
				,tmp.[netTurnover]
				,tmp.[TurnoverNoDraw]
				,tmp.[winlost]
				,tmp.[awinlost]
				,tmp.[mwinlost]
				,tmp.[swinlost]
				,tmp.[playercomm]
				,tmp.[comm]
				,tmp.[acomm]
				,tmp.[scomm]
				,tmp.[grosscomm]
				,tmp.[extraWinloss]
				,tmp.[extraComm]
			FROM #checkCorrectData tmp
			LEFT JOIN dbo.bettrans_compact up ON (
				up.custid				= tmp.custid
				AND up.[winlostdate]	= tmp.[winlostdate]
				AND up.[productId]		= tmp.[productId]
				AND up.[sporttype]		= tmp.[sporttype]
				AND up.[bettype]		= tmp.[bettype]
				AND up.[leagueGroupID]	= tmp.[leagueGroupID]
				AND up.[ticketType]		= tmp.[ticketType]
			)			
			WHERE tmp.roundCheck >= @limitCheck
				AND up.custid IS NULL;

			--DELETE diff rows
			;WITH CTE_CompactDiffCust AS (
				SELECT ck.[custid], ck.[winlostdate], ck.[productId], ck.[sporttype], ck.[bettype], ck.[leagueGroupID], ck.[ticketType]
				FROM dbo.bettrans_compact ck (NOLOCK)
				INNER JOIN (
					SELECT DISTINCT custid, winlostdate FROM #diffCustCheckSum diff WHERE diff.IsCompleted = 0 AND diff.winlostdate = @winlostdate
				) diff ON diff.custid = ck.custid AND diff.winlostdate = ck.winlostdate 
			)
			DELETE up
			OUTPUT 'DELETE', DELETED.custid, DELETED.winlostdate, DELETED.productid, DELETED.sporttype, DELETED.bettype, DELETED.LeagueGroupID, DELETED.ticketType
			INTO @correctResult (actionName, custid,winlostdate,productid,sporttype,bettype,LeagueGroupID,ticketType)
			FROM dbo.bettrans_compact up
			INNER JOIN CTE_CompactDiffCust tmp ON (
				up.custid				= tmp.custid
				AND up.[winlostdate]	= tmp.[winlostdate]
				AND up.[productId]		= tmp.[productId]
				AND up.[sporttype]		= tmp.[sporttype]
				AND up.[bettype]		= tmp.[bettype]
				AND up.[leagueGroupID]	= tmp.[leagueGroupID]
				AND up.[ticketType]		= tmp.[ticketType]
			)
			INNER JOIN @verifyCheckSumStatus vc ON (
				tmp.custid				= JSON_VALUE(vc.keyValue, '$.custid')
				AND tmp.[winlostdate]	= JSON_VALUE(vc.keyValue, '$.winlostdate')
				AND tmp.[productId]		= JSON_VALUE(vc.keyValue, '$.productId')
				AND tmp.[sporttype]		= JSON_VALUE(vc.keyValue, '$.sporttype')
				AND tmp.[bettype]		= JSON_VALUE(vc.keyValue, '$.bettype')
				AND tmp.[leagueGroupID]	= JSON_VALUE(vc.keyValue, '$.leagueGroupID')
				AND tmp.[ticketType]	= JSON_VALUE(vc.keyValue, '$.ticketType')
			)
			LEFT JOIN #checkCorrectData ck ON (
				ck.custid				= tmp.custid
				AND ck.[winlostdate]	= tmp.[winlostdate]
				AND ck.[productId]		= tmp.[productId]
				AND ck.[sporttype]		= tmp.[sporttype]
				AND ck.[bettype]		= tmp.[bettype]
				AND ck.[leagueGroupID]	= tmp.[leagueGroupID]
				AND ck.[ticketType]		= tmp.[ticketType]
			)
			WHERE ck.custid IS NULL -- NOT EXISTS in the SOURCE bettrans
				AND vc.roundCheck	>= @limitCheck
			;

			--TODO: update notifyStatus
			UPDATE vc
			SET vc.notifyStatus = CASE 
										WHEN rs.actionName = 'UPDATE' THEN 3 
										WHEN rs.actionName = 'INSERT' THEN 4 
										WHEN rs.actionName = 'DELETE' THEN 5
										ELSE 0 
									END 
			FROM @verifyCheckSumStatus vc
			INNER JOIN @correctResult rs ON (
				rs.custid				= JSON_VALUE(vc.keyValue, '$.custid')
				AND rs.[winlostdate]	= JSON_VALUE(vc.keyValue, '$.winlostdate')
				AND rs.[productId]		= JSON_VALUE(vc.keyValue, '$.productId')
				AND rs.[sporttype]		= JSON_VALUE(vc.keyValue, '$.sporttype')
				AND rs.[bettype]		= JSON_VALUE(vc.keyValue, '$.bettype')
				AND rs.[leagueGroupID]	= JSON_VALUE(vc.keyValue, '$.leagueGroupID')
				AND rs.[ticketType]		= JSON_VALUE(vc.keyValue, '$.ticketType')
			)
			WHERE vc.roundCheck	>= @limitCheck;

			--- TODO: mark as fixed
			UPDATE up WITH(ROWLOCK, UPDLOCK)
			SET up.NotifyStatus = ck.notifyStatus
			FROM dbo.bettrans_compact_checkSum up
			INNER JOIN @verifyCheckSumStatus ck ON ck.custid = up.custid 
				AND ck.winlostdate = up.winlostdate
				AND ck.checkSumKey = up.checkSumKey
			WHERE up.notifyStatus	= 0
				AND up.createdTime	= @CheckTime

			-- Mark as done to ignore in the next round
			UPDATE diff
			SET diff.IsCompleted	= IIF(ck.NotifyStatus >= 2, 1, 0)
				,diff.checkSumData	= ck.checkSumData
			FROM #diffCustCheckSum diff
			INNER JOIN dbo.bettrans_compact_checkSum ck ON ck.custid = diff.custid 
				AND ck.winlostdate	= diff.winlostdate
				AND ck.checkSumKey	= diff.checkSumKey
			WHERE ck.createdTime	= @CheckTime

			SET @rCont += 1;

		END

		WAITFOR DELAY '00:00:05'

		SET @loopCheck += 1;
		--PRINT @loopCheck
	END
END
