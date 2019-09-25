SET	QUOTED_IDENTIFIER ON;
SET	ANSI_NULLS ON;
GO
ALTER PROCEDURE [dbo].[Task_Archive_Bet]
(
	@winlostdate DATETIME,
	@DeletedTarget VARCHAR(100) = ''
)
AS
/*
	Created: 20171017@Lukas
	Task: delete data on table14 

	Revisions:
		- 20180725@Billy:	Change the way of deleting data of IP2Country tables - [Redmine: #98857]
		- 20190704@Billy:	Add [MarkedTransaction] to Friday Routine - [Redmine: #115199]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE	@WaitFor	VARCHAR(50);

	IF @DeletedTarget = 'betParlayDetail'
	BEGIN

		SELECT IDENTITY(INT,1,1) id, refno, count(1) AS cnt, 5000/count(1) AS batch_size
		INTO #tmp
		FROM betparlaydetail WITH(NOLOCK)
		WHERE winlostdate <= DATEADD(DAY, - 14, @winlostdate)
		GROUP BY refno 
		ORDER BY cnt DESC 

		CREATE CLUSTERED INDEX CIX_id_TMP ON #tmp(id)
		
		DECLARE @rc INT,@i INT, @topn INT,@refnos VARCHAR(MAX) = ''

		SELECT @rc = MAX(id) FROM #tmp  

		SET @i = 1
		WHILE @i <= @rc 
		BEGIN	
			SELECT @topn = batch_size
			FROM #tmp
			WHERE id = @i 

			IF @topn = 0 OR @topn IS NULL
				SET @topn = 1

			SET @refnos = NULL
			SELECT TOP(@topn) @refnos = COALESCE(@refnos + '^' + CAST(refno AS VARCHAR(50)), CAST(refno AS VARCHAR(50)))
			FROM #tmp
			WHERE id >= @i 
			ORDER BY id ASC 

			EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = @winlostdate, @parlay = 29, @tableName = 'betParlayDetail', @refnos = @refnos
			SET @i = @i + @topn
		END 
		DROP TABLE #tmp 
		RETURN
	END 
	IF @DeletedTarget = 'betParlayResult'
	BEGIN
		-- call execRep SP
		EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = @winlostdate, @parlay = 29, @tableName = 'betParlayResult'
	END

	IF	@DeletedTarget = 'Task_bettrans14_IP2Country'
	BEGIN;
		WHILE 0 = 0
		BEGIN;
			DELETE	TOP(10000)
			FROM	dbo.Task_bettrans14_IP2Country WITH (ROWLOCK) 
			WHERE	winlostdate <= @winlostdate;

			IF	@@ROWCOUNT = 0
				BREAK;

			-- Dynamic Delay Time --
			SELECT	@WaitFor = dbo.f_BU_GetDelayTime('IP2Country');
			WAITFOR DELAY @WaitFor;
		END;

		RETURN;
	END;

	IF	@DeletedTarget = 'Task_bettransRNG14_IP2Country'
	BEGIN;
		WHILE 0 = 0
		BEGIN;
			DELETE	TOP(10000)
			FROM	dbo.Task_bettransRNG14_IP2Country WITH (ROWLOCK) 
			WHERE	winlostdate <= @winlostdate;

			IF	@@ROWCOUNT = 0
				BREAK;

			-- Dynamic Delay Time --
			SELECT	@WaitFor = dbo.f_BU_GetDelayTime('IP2Country');
			WAITFOR DELAY @WaitFor;
		END;

		RETURN;
	END;

	IF	@DeletedTarget = 'Task_bettransLC14_IP2Country'
	BEGIN;
		WHILE 0 = 0
		BEGIN;
			DELETE	TOP(10000)
			FROM	dbo.Task_bettransLC14_IP2Country WITH (ROWLOCK) 
			WHERE	winlostdate <= @winlostdate;

			IF	@@ROWCOUNT = 0
				BREAK;

			-- Dynamic Delay Time --
			SELECT	@WaitFor = dbo.f_BU_GetDelayTime('IP2Country');
			WAITFOR DELAY @WaitFor;
		END;

		RETURN;
	END;

	IF	@DeletedTarget = 'MarkedTransaction'
	BEGIN;
		DECLARE	@transList AS TABLE (
					TransId		BIGINT
				);

		DECLARE	@transDel AS TABLE (
					TransId		BIGINT
				);

		DECLARE	@transDelStr	SQL_VARIANT;

		INSERT INTO	@transList (TransId)
		SELECT	tbl.transid
		FROM		dbo.MarkedTransaction AS tbl WITH (NOLOCK)
		INNER JOIN	dbo.match14 AS m14 WITH (NOLOCK)
				ON	tbl.MatchId = m14.matchid
		WHERE	m14.eventdate <= @winlostdate;

		WHILE	0 = 0
		BEGIN;
			DELETE	@transDel;

			DELETE	TOP(200) @transList
			OUTPUT	Deleted.TransId
			INTO	@transDel (TransId);

			IF	@@ROWCOUNT = 0
				BREAK;

			SELECT	@transDelStr = CONVERT(SQL_VARIANT, CONVERT(VARCHAR(4000), trn.xml.value('.[1]', 'VARCHAR(4000)')))
			FROM	(
				SELECT	CAST(TransId AS VARCHAR(19)) + ','
				FROM	@transDel
				FOR XML PATH ('')
				,	TYPE
			) AS trn(xml);

			EXECUTE	dbo.ExecRep_02 @winlostdate = @winlostdate, @Command = 'ALL_DB', @DeletedTarget = 'MarkedTransaction', @tmp1 = @transDelStr;

			-- Dynamic Delay Time --
			SELECT	@WaitFor = dbo.f_BU_GetDelayTime('FriRoutine');
			WAITFOR DELAY @WaitFor;
		END;

		RETURN;
	END;
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/