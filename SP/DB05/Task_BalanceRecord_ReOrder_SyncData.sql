/*<info serverAlias="DBBAH-BalanceRecord" isFunction="0" isNested="0"></info>*/
ALTER Procedure dbo.Task_BalanceRecord_ReOrder_SyncData
/*
	Created: 20220620@Sol
	Task: Database Improvement - New BalanceRecord_ReOrder - [Redmine:172094]
	Database: DBBAH-BalanceRecord
	
	Revision:
		- 20220620@Sol: Database Improvement - New BalanceRecord_ReOrder - [Redmine:172094]
		
*/
AS
begin
	---local variables
	DECLARE @fromRowId BIGINT
		,@toRowId BIGINT
		,@custid INT = NULL
		,@rowPerBatch smallint = 5000

	DECLARE @minTransdate DATETIME
	DECLARE @minDateOfChangedRow DATETIME = NULL
		,@maxRowId BIGINT = NULL
	DECLARE @stopIndex INT
		,@previousNewBalance MONEY = NULL
	DECLARE @errMess VARCHAR(max)

	---get last rowid from system setting
	SELECT @fromRowId = CAST(s.VValue AS BIGINT) FROM bodb02.dbo.SystemSettings s WITH(NOLOCK) 
	WHERE s.VName = 'BalanceRecord_LastRowId'

	SELECT @toRowId = @fromRowId + @rowPerBatch

	---test value
	--select @fromRowId = 292071409, @toRowId = 292090698 , @custid = 64075339

	---declare temp table
	BEGIN
		CREATE TABLE #BatchRowsNeedToProcess (
			RowID BIGINT PRIMARY KEY
			,custid INT
			,transid BIGINT
			,bettype SMALLINT
			,actual_stake MONEY
			,winlost MONEY
			,playercomm MONEY
			,BalanceChanged MONEY
			,NewBalance MONEY
			,ActionDate DATETIME
			,ActionID TINYINT
			,Action VARCHAR(200)
			,BTBalance MONEY
			,StatusId TINYINT
			,MatchId INT
			,SettlementType TINYINT
			,awinlost MONEY
			,mwinlost MONEY
			,swinlost MONEY
			,comm MONEY
			,acomm MONEY
			,scomm MONEY
			,modds SMALLMONEY
			,transdate DATETIME
			)

		---table list custid
		CREATE TABLE #ListCustId (CustId INT)

		---table check transid order 
		CREATE TABLE #RunningTrans (
			RowId BIGINT
			,transdate DATETIME
			)

		---data processed by custid
		CREATE TABLE #RowsProcessByCustId (
			Id INT identity
			,IsEndOfChanged BIT DEFAULT 0
			,RowID BIGINT PRIMARY KEY
			,custid INT
			,transid BIGINT
			,bettype SMALLINT
			,actual_stake MONEY
			,winlost MONEY
			,playercomm MONEY
			,BalanceChanged MONEY
			,NewBalance MONEY
			,ActionDate DATETIME
			,ActionID TINYINT
			,Action VARCHAR(200)
			,BTBalance MONEY
			,StatusId TINYINT
			,MatchId INT
			,SettlementType TINYINT
			,awinlost MONEY
			,mwinlost MONEY
			,swinlost MONEY
			,comm MONEY
			,acomm MONEY
			,scomm MONEY
			,modds SMALLMONEY
			,transdate DATETIME
			)
	END

	---get row need to process to temp table
	BEGIN
		INSERT INTO #BatchRowsNeedToProcess (
			RowID
			,custid
			,transid
			,bettype
			,actual_stake
			,winlost
			,playercomm
			,BalanceChanged
			,NewBalance
			,ActionDate
			,ActionID
			,Action
			,BTBalance
			,StatusId
			,MatchId
			,SettlementType
			,awinlost
			,mwinlost
			,swinlost
			,comm
			,acomm
			,scomm
			,modds
			)
		SELECT RowID
			,custid
			,transid
			,bettype
			,actual_stake
			,winlost
			,playercomm
			,BalanceChanged
			,NewBalance
			,ActionDate
			,ActionID
			,Action
			,BTBalance
			,StatusId
			,MatchId
			,SettlementType
			,awinlost
			,mwinlost
			,swinlost
			,comm
			,acomm
			,scomm
			,modds
		FROM BalanceRecord.dbo.BalanceRecord_bk bk WITH (NOLOCK)
		WHERE bk.RowID > @fromRowId 
			AND bk.RowID <= @toRowId
	
		UNION
	
		SELECT RowID
			,custid
			,transid
			,bettype
			,actual_stake
			,winlost
			,playercomm
			,BalanceChanged
			,NewBalance
			,ActionDate
			,ActionID
			,Action
			,BTBalance
			,StatusId
			,MatchId
			,SettlementType
			,awinlost
			,mwinlost
			,swinlost
			,comm
			,acomm
			,scomm
			,modds
		FROM bodb02.dbo.BalanceRecord b WITH (NOLOCK)
		WHERE b.RowID > @fromRowId 
			AND b.RowID <= @toRowId
		ORDER BY RowID
	END

	---insert list custid that need to process
	INSERT INTO #ListCustId (CustId)
	SELECT DISTINCT custid
	FROM #BatchRowsNeedToProcess
	--where custid = @custid  --delete after test done this where clause

	---loop custid
	WHILE EXISTS (
			SELECT TOP 1 1
			FROM #ListCustId
			)
	BEGIN

		---reset temp table to empty
		TRUNCATE TABLE #RowsProcessByCustId
		TRUNCATE TABLE #RunningTrans
		SELECT @minTransdate = NULL, @minDateOfChangedRow = NULL, @maxRowId = 0, @stopIndex = 0, @previousNewBalance = 0

		---get custid to process
		SELECT TOP 1 @custid = l.CustId
		FROM #ListCustId l WITH (NOLOCK)
		ORDER BY l.CustId

		---delete from temp table
		DELETE
		FROM #ListCustId
		WHERE CustId = @custid

		---get data by custid
		INSERT INTO #RowsProcessByCustId 
		(
			RowID
			,custid
			,transid
			,bettype
			,actual_stake
			,winlost
			,playercomm
			,BalanceChanged
			,NewBalance
			,ActionDate
			,ActionID
			,Action
			,BTBalance
			,StatusId
			,MatchId
			,SettlementType
			,awinlost
			,mwinlost
			,swinlost
			,comm
			,acomm
			,scomm
			,modds 
		)
		SELECT RowID
			,custid
			,transid
			,bettype
			,actual_stake
			,winlost
			,playercomm
			,BalanceChanged
			,NewBalance
			,b.ActionDate
			,ActionID
			,Action
			,BTBalance
			,StatusId
			,MatchId
			,SettlementType
			,awinlost
			,mwinlost
			,swinlost
			,comm
			,acomm
			,scomm
			,modds --, transdate
		FROM #BatchRowsNeedToProcess b WITH(NOLOCK)
		WHERE b.custid = @custid

		---get min transdate and get more data from new table if need
		--bettrans
		SELECT @minTransdate = MIN(b.transdate)
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #RowsProcessByCustId bp WITH (NOLOCK)
				ON b.transid = bp.transid AND b.custid = bp.custid
		WHERE bp.ActionID = 10

		--transfer
		SELECT @minTransdate = ISNULL(MIN(t.transdate), @minTransdate)
		FROM bodb02.dbo.Transfer t WITH (NOLOCK)
			INNER JOIN #RowsProcessByCustId bp WITH (NOLOCK) 
				ON t.transid = bp.transid AND t.custid = bp.custid
		WHERE bp.ActionID = 110 AND t.TransDate <= @minTransdate

		---get more data from new table if any
		IF EXISTS (
				SELECT TOP 1 1
				FROM BalanceRecord.dbo.BalanceRecord_ReOrder bn WITH (NOLOCK)
				WHERE bn.ActionDate >= @minTransdate AND bn.custid = @custid
				)
		BEGIN
			---delete from new table and insert into temp table #BatchRowsNeedToProcess to re-insert later after sorting
			DELETE
			FROM BalanceRecord.dbo.BalanceRecord_ReOrder
			OUTPUT deleted.RowID
				,deleted.custid
				,deleted.transid
				,deleted.bettype
				,deleted.actual_stake
				,deleted.winlost
				,deleted.playercomm
				,deleted.BalanceChanged
				,deleted.NewBalance
				,deleted.ActionDate
				,deleted.ActionID
				,deleted.Action
				,deleted.BTBalance
				,deleted.StatusId
				,deleted.MatchId
				,deleted.SettlementType
				,deleted.awinlost
				,deleted.mwinlost
				,deleted.swinlost
				,deleted.comm
				,deleted.acomm
				,deleted.scomm
				,deleted.modds
			INTO #RowsProcessByCustId(RowID, custid, transid, bettype, actual_stake, winlost, playercomm, BalanceChanged, NewBalance, ActionDate, ActionID, Action, BTBalance, StatusId, MatchId, SettlementType, awinlost, mwinlost, swinlost, comm, acomm, scomm, modds)
			WHERE custid = @custid AND ActionDate >= @minTransdate
		END

		---get only running, first transfer
		INSERT INTO #RunningTrans (
			RowId
			,transdate
			)
		SELECT bp.RowID
			,b.transdate
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #RowsProcessByCustId bp WITH (NOLOCK) 
				ON b.transid = bp.transid AND b.custid = bp.custid
		WHERE bp.ActionID = 10
		UNION ALL
		SELECT bp.RowID
			,t.TransDate
		FROM bodb02.dbo.Transfer t WITH (NOLOCK)
			INNER JOIN #RowsProcessByCustId bp WITH (NOLOCK) 
				ON t.transid = bp.transid AND t.custid = bp.custid
		WHERE bp.ActionID = 110 AND t.TransDate <= @minTransdate
		ORDER BY RowID
		
		---check to see if the order need to re-sort again and get min date of changed rows
		;WITH rs
		AS (
			SELECT *
				,lag(transdate, 1) OVER (
					ORDER BY rowid
					) AS previoustransdate
			FROM #RunningTrans
			)
		SELECT @minDateOfChangedRow = min(transdate)
			,@maxRowId = max(rowid)
		FROM rs
		WHERE transdate < previoustransdate

		---yes, the order need to re-sort again
		IF @minDateOfChangedRow IS NOT NULL
		BEGIN
			---update transdate to temp table
			UPDATE bp
				SET transdate = CASE WHEN r.RowId IS NULL THEN bp.ActionDate ELSE r.transdate END
			FROM #RowsProcessByCustId bp
				LEFT JOIN #RunningTrans r ON bp.rowid = r.rowid

			---update x to mark the end of re-calc -- for marked only
			UPDATE #RowsProcessByCustId
				SET IsEndOfChanged = 1
			WHERE RowID = @maxRowId

			---get previous newbalance from current batch, if no row is found, search in new table
			SELECT @previousNewBalance = NewBalance
			FROM #RowsProcessByCustId b WITH (NOLOCK)
			WHERE transdate = (
					SELECT max(transdate)
					FROM #RowsProcessByCustId b WITH (NOLOCK)
					WHERE transdate < @minDateOfChangedRow
					)

			--if null then search in new table
			IF ISNULL(@previousNewBalance, 0) = 0
			BEGIN
				SELECT @previousNewBalance = NewBalance
				FROM BalanceRecord.dbo.BalanceRecord_ReOrder b WITH (NOLOCK)
				WHERE ActionDate = (
						SELECT max(ActionDate)
						FROM BalanceRecord.dbo.BalanceRecord_ReOrder b WITH (NOLOCK)
						WHERE ActionDate < @minDateOfChangedRow
							AND b.custid = @custid
						)
					AND b.custid = @custid
			END

			---get stop index
			SELECT @stopIndex = Id
			FROM #RowsProcessByCustId
			WHERE RowID = @maxRowId

			;WITH rs
				AS (
						SELECT ROW_NUMBER() OVER (ORDER BY transdate) AS newIndex,*
						FROM #RowsProcessByCustId
					)
					,dataNeedToUpdate
				AS (
						SELECT *
						FROM rs
						WHERE transdate >= @minDateOfChangedRow AND newIndex <= @stopIndex
					)
			UPDATE b
				SET 
					@previousNewBalance = ISNULL(@previousNewBalance, 0) + ISNULL(b.BalanceChanged, 0)
					,b.NewBalance = @previousNewBalance
			FROM #RowsProcessByCustId b
				INNER JOIN dataNeedToUpdate d ON b.RowID = d.RowID
			
			IF EXISTS (
				SELECT TOP 1 1
				FROM #RowsProcessByCustId b
				WHERE b.custid = @custid
					AND EXISTS (
							SELECT 1
							FROM BalanceRecord.dbo.BalanceRecord_ReOrder bn WITH(NOLOCK)
							WHERE b.RowID = bn.RowID AND b.custid = bn.custid
						)
			)
			BEGIN
				SET @errMess = 'Duplicated RowId!'

				RAISERROR (@errmess, 16, 1)
				RETURN
			END
		END

		---insert into new table
		BEGIN TRY
			INSERT INTO BalanceRecord.dbo.BalanceRecord_ReOrder (
				RowID
				,custid
				,transid
				,bettype
				,actual_stake
				,winlost
				,playercomm
				,BalanceChanged
				,NewBalance
				,ActionDate
				,ActionID
				,Action
				,BTBalance
				,StatusId
				,MatchId
				,SettlementType
				,awinlost
				,mwinlost
				,swinlost
				,comm
				,acomm
				,scomm
				,modds --, transdate
				)
			SELECT RowID
				,custid
				,transid
				,bettype
				,actual_stake
				,winlost
				,playercomm
				,BalanceChanged
				,NewBalance
				,ISNULL(b.transdate, b.ActionDate)
				,ActionID
				,Action
				,BTBalance
				,StatusId
				,MatchId
				,SettlementType
				,awinlost
				,mwinlost
				,swinlost
				,comm
				,acomm
				,scomm
				,modds --, transdate
			FROM #RowsProcessByCustId b WITH(NOLOCK)
			ORDER BY transdate
		END TRY

		BEGIN CATCH
			SET @errMess = ERROR_MESSAGE()

			RAISERROR (@errMess, 16, 1)
		END CATCH
	END

	---update last rowid to systemsetting table
	UPDATE bodb02.dbo.SystemSettings 
		SET VValue = @toRowId
	WHERE VName = 'BalanceRecord_LastRowId'

	---drop temp table
	DROP TABLE #BatchRowsNeedToProcess
	DROP TABLE #ListCustId
	DROP TABLE #RunningTrans
	DROP TABLE #RowsProcessByCustId

end