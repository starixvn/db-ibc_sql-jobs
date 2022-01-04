ALTER PROCEDURE [dbo].[ExecRep_00] 
	@Winlostdate SMALLDATETIME = NULL
	,@Target VARCHAR(30) = 'DBTRANS' -- DBTRANS/REPLICATED
	,@TableName VARCHAR(200) = ''
AS
/*
 	DB: DBTXN/bodb02
  	Creator : Viet
 	Date : May 18, 2010
 	Task : Update rates for all existed tickets once financial change rates
 	
 	Revisions:			
		- 20101225@Henry: change bettype to new range
		- 20121022@Thien: change from "b.bettype between 50 and 98" to "b.bettype between 50 and 19998"
		- 20121224@Thien: prevent from running for the day in the past
		- 20130507@Thien: change to use ExecRep [Bet_ExecRep_04], old SP is DBA_UpdateExRates
 		- 20131108@Elodie: Splitting bodb02 into CustDB (call custinfo, exchange by link database)
 		- 20140124@Viet: fix splitting issue
		- 20140701@Jamie: Get virtualmultiplier of bettrans 
		- 20160412@Sophia: Add related tables: BettransRNG, BettransLC, Translog (will apply on bettransm later)
 		- 20171020@Lukas: clone SP from ExecRep_00, the bet_execRep_04 is no longer use 
		- 20181106@Sophia: Add table Transfer_Coll [Redmine: #98621]
		- 20200309@Malcolm : Add table bettransG [Redmine : #128057]
		- 20220104@Malcolm: Update rates for all existed tickets once financial change rates [RedmineId : #163417]

 	Param's Explanation: 
 		@Winlostdate: the date that new rates are updated		
 */

BEGIN
	SET NOCOUNT ON

	IF @Winlostdate IS NULL RETURN
	IF @Target NOT IN ('DBTRANS', 'REPLICATED') RETURN
	IF @Target = 'DBTRANS' AND @@SERVERNAME <> 'DBTRANS' RETURN
	IF @Target = 'REPLICATED' AND @@SERVERNAME = 'DBTRANS' RETURN
	IF OBJECT_ID (@TableName, N'U') IS NULL RETURN
	
	CREATE TABLE #tmp (transid BIGINT, actualrate FLOAT, virtualrate FLOAT)

	IF @@SERVERNAME = 'DBTRANS'
	BEGIN
		IF @TableName = 'bettrans' --bettrans@dbtrans
		BEGIN
			-- update for SB's tickets (using virtualrate)
			INSERT INTO #tmp(transid, actualrate, virtualrate)
			SELECT transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) AS virtualrate
			FROM dbo.bettrans b WITH(NOLOCK) 
				INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid
			WHERE b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate 
				AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) AND b.actualrate <> b.virtualrate
			 
			-- update for SB's tickets (without virtualrate)
			INSERT INTO #tmp(transid, actualrate, virtualrate)
			SELECT transid, e.actualrate, e.actualrate 
			FROM dbo.bettrans b WITH(NOLOCK) 
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) 
				AND b.actualrate = b.virtualrate

			INSERT INTO #tmp(transid, actualrate, virtualrate)
			SELECT transid, e.actualrate, e.actualrate 
			FROM dbo.bettrans b WITH(NOLOCK) 
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 
				AND b.actualrate = b.virtualrate AND b.currency2 IS NULL

			--==	
			INSERT INTO #tmp(transid, actualrate, virtualrate)
			SELECT transid, e.actualrate, b.virtualrate
			FROM dbo.bettrans b WITH(NOLOCK) 
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 AND b.currency2 IS NOT NULL

			-- transfer tickets		 
			INSERT INTO #tmp(transid, actualrate, virtualrate)
			SELECT transid, e.actualrate, b.virtualrate
			FROM dbo.bettrans b WITH(NOLOCK) 
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND b.bettype >= 19001
		
		END
		ELSE IF @TableName = 'translog' --translog@dbtrans
		BEGIN
			-- update for TransLog table (using virtualrate)
			INSERT INTO #tmp(transid, actualrate, virtualrate)
			SELECT translogid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
			FROM dbo.TransLog b WITH(NOLOCK) 				
				INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid 
			WHERE b.winlostdate >= @Winlostdate
				AND b.actualrate <> e.actualrate 				
			 
		END
		ELSE IF @TableName = 'bettransRnG' --bettransRnG@dbtrans
		BEGIN
			-- update for BettransRNG table (using virtualrate)
			INSERT INTO #tmp(transid, actualrate, virtualrate)
			SELECT transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
			FROM dbo.BettransRNG b WITH(NOLOCK) 				
				INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid 
			WHERE b.winlostdate >= @Winlostdate
				AND b.actualrate <> e.actualrate 				
				 
		END
		ELSE IF @TableName = 'bettransLC' --bettransLC@dbtrans
		BEGIN
			-- update for BettransLC table (using virtualrate)
			INSERT INTO #tmp(transid, actualrate, virtualrate)
			select transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
			FROM dbo.BettransLC b WITH(NOLOCK) 				
				INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid 
			WHERE b.winlostdate >= @Winlostdate
				AND b.actualrate <> e.actualrate 
		END
		ELSE IF @TableName = 'Transfer_Coll' --transfer_coll@dbtrans
		BEGIN
			-- Transfer_Coll tickets
			INSERT INTO #tmp(transid, actualrate)
			SELECT b.transid, e.actualrate
			FROM dbo.Transfer_Coll b WITH(NOLOCK) 
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND b.bettype >= 19001
		END
		ELSE IF @TableName = 'bettransG' --bettransG@dbtrans
		BEGIN
			-- update for bettransG table 
			INSERT INTO #tmp(transid, actualrate, virtualrate)
			SELECT b.transid, e.actualrate, e.actualrate * (b.virtualrate / b.actualrate) AS virtualrate
			FROM dbo.bettransG b WITH(NOLOCK)
				INNER JOIN CustDB.dbo.CustInfo c WITH (NOLOCK) ON c.custid = b.custid
				INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK)  ON e.exchangeid = c.currency	
			WHERE b.winlostdate >= @Winlostdate AND b.actualrate <> e.actualrate
		END
	END
	
	IF @@SERVERNAME <> 'DBTRANS'
	BEGIN
		IF (
			SELECT COUNT(1)
			FROM sysobjects
			WHERE NAME IN ('custinfo', 'bettrans', 'exchange') AND type = 'U'
		) < 3 RETURN

		IF @TableName = 'bettrans' --bettrans@replicated
		BEGIN
			-- update for SB's tickets (using virtualrate)
			INSERT INTO #tmp(transid, actualrate, virtualrate)
			SELECT transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
			FROM dbo.bettrans b WITH(NOLOCK) 
				INNER JOIN bodb02.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid
			WHERE b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate 
				AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) AND b.actualrate <> b.virtualrate

			-- update for SB's tickets (without virtualrate)
			INSERT INTO #tmp(transid, actualrate, virtualrate)
			SELECT transid, e.actualrate, e.actualrate 
			FROM dbo.bettrans b WITH(nolock) 
				,bodb02.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) 
				AND b.actualrate = b.virtualrate
 
			--==
			INSERT INTO #tmp(transid, actualrate, virtualrate)
			SELECT transid, e.actualrate, e.actualrate 
			FROM dbo.bettrans b WITH(NOLOCK) 
				,bodb02.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 
				AND b.actualrate = b.virtualrate AND b.currency2 IS NULL
 
			-- OPENTOTE tickets
			INSERT INTO #tmp(transid, actualrate, virtualrate)
			SELECT transid, e.actualrate, b.virtualrate
			FROM dbo.bettrans b WITH(NOLOCK) 
				,bodb02.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
			AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 AND b.currency2 IS NOT NULL
		
			-- transfer tickets
			INSERT INTO #tmp(transid, actualrate, virtualrate)
			SELECT transid, e.actualrate, b.virtualrate
			FROM dbo.bettrans b WITH(NOLOCK) 
				,bodb02.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND b.bettype >= 19001
		
		END
		ELSE IF @TableName = 'translog' --translog@replicated
		BEGIN
			-- update for TransLog table (using virtualrate)
			INSERT INTO #tmp(transid, actualrate, virtualrate)
			SELECT translogid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) AS virtualrate
			FROM dbo.TransLog b WITH(NOLOCK) 			
				INNER JOIN bodb02.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid 
			WHERE b.winlostdate >= @Winlostdate
				AND b.actualrate <> e.actualrate 				
			 
		END
		ELSE IF @TableName = 'bettransRnG' --bettransRnG@replicated
		BEGIN
			-- update for BettransRNG table (using virtualrate)
			INSERT INTO #tmp(transid, actualrate, virtualrate)
			SELECT transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) AS virtualrate
			FROM dbo.BettransRNG b WITH(NOLOCK) 			
				INNER JOIN bodb02.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid 
			WHERE b.winlostdate >= @Winlostdate
				AND b.actualrate <> e.actualrate 				
		END
		ELSE IF @TableName = 'bettransLC' --bettransLC@replicated
		BEGIN
			-- update for BettransLC table (using virtualrate)
			INSERT INTO #tmp(transid, actualrate, virtualrate)
			SELECT transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
			FROM dbo.BettransLC b WITH(NOLOCK) 				
				INNER JOIN bodb02.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid 
			WHERE b.winlostdate >= @Winlostdate
				AND b.actualrate <> e.actualrate 	 
		END
		ELSE IF @TableName = 'Transfer_Coll' --transfer_coll@replicated
		BEGIN 
			INSERT INTO #tmp(transid, actualrate)
			select b.transid, e.actualrate 
			FROM dbo.Transfer_Coll b WITH(NOLOCK) 
				,dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND b.bettype >= 19001
		END
		ELSE IF @TableName = 'bettransG' --bettransG@replicated
		BEGIN
			-- update for bettransG table 
			INSERT INTO #tmp(transid, actualrate, virtualrate)
			SELECT b.transid, e.actualrate, e.actualrate * (b.virtualrate / b.actualrate) AS virtualrate
			FROM dbo.bettransG b WITH (NOLOCK)
				INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON b.custid = c.custid
				INNER JOIN bodb02.dbo.exchange e WITH (NOLOCK) ON e.exchangeid = c.currency
			WHERE b.winlostdate >= @winlostdate
				  AND b.actualrate <> e.actualrate
		END  
	END 
	
	
	DECLARE @__table TABLE (transid BIGINT, actualrate FLOAT, virtualrate FLOAT)
	DECLARE @rowcount INT = 1
	
	IF @TableName = 'bettransRnG' --update bettransRnG
	BEGIN
		SET @rowcount = 1
		WHILE @rowcount <> 0
		BEGIN
			DELETE FROM @__table
		
			DELETE TOP(2000) FROM #tmp
			OUTPUT deleted.transid, deleted.actualrate, deleted.virtualrate INTO @__table
			SET @rowcount = @@ROWCOUNT
		
			UPDATE b WITH(ROWLOCK, UPDLOCK)
			SET b.actualrate = t.actualrate,
				b.virtualrate = t.virtualrate
			FROM @__table t 
				INNER JOIN dbo.bettransRnG b ON t.transid = b.transid
		END
	END
	ELSE IF @TableName = 'bettransLC' --update bettransLC
	BEGIN
		SET @rowcount = 1 
		WHILE @rowcount <> 0
		BEGIN
			DELETE FROM @__table
		
			DELETE TOP(2000) FROM #tmp
			OUTPUT deleted.transid, deleted.actualrate, deleted.virtualrate into @__table
			SET @rowcount = @@ROWCOUNT
		
			UPDATE b WITH(ROWLOCK, UPDLOCK)
			SET b.actualrate = t.actualrate,
				b.virtualrate = t.virtualrate
			FROM @__table t 
				INNER JOIN dbo.bettransLC b ON t.transid = b.transid 
		END
	END
	ELSE IF @TableName = 'translog' --update translog
	BEGIN
		SET @rowcount = 1 
		WHILE @rowcount <> 0
		BEGIN
			DELETE FROM @__table
		
			DELETE TOP(2000) FROM #tmp
			OUTPUT deleted.transid, deleted.actualrate, deleted.virtualrate INTO @__table
			SET @rowcount = @@ROWCOUNT
		
			UPDATE b WITH(ROWLOCK, UPDLOCK)
			SET b.actualrate = t.actualrate,
				b.virtualrate = t.virtualrate
			FROM @__table t 
				INNER JOIN dbo.translog b on t.transid = b.translogid 
		END
	END
	ELSE IF @TableName = 'bettrans' --update bettrans
	BEGIN
		SET @rowcount = 1 
		WHILE @rowcount <> 0
		BEGIN
			DELETE FROM @__table
		
			DELETE TOP(2000) FROM #tmp 
			OUTPUT deleted.transid, deleted.actualrate, deleted.virtualrate into @__table
			SET @rowcount = @@ROWCOUNT
		
			UPDATE b WITH(ROWLOCK, UPDLOCK)
			SET b.actualrate = t.actualrate,
				b.virtualrate = t.virtualrate
			FROM @__table t 
				INNER JOIN dbo.bettrans b ON t.transid = b.transid 
		END
	END
	ELSE IF @TableName = 'Transfer_Coll' --update transfer_coll
	BEGIN 
		SET @rowcount = 1 
		WHILE @rowcount <> 0
		BEGIN
			DELETE FROM @__table
			
			DELETE TOP(2000) FROM #tmp 
			OUTPUT deleted.transid, deleted.actualrate, 0 INTO @__table
			SET @rowcount = @@ROWCOUNT
			
			UPDATE b WITH(ROWLOCK, UPDLOCK)
			SET b.actualrate = t.actualrate			
			FROM @__table t 
				INNER JOIN dbo.Transfer_Coll b ON t.transid = b.transid 
		END
	END 
	ELSE IF @TableName = 'bettransG' --update bettransG
	BEGIN
		SET @rowcount = 1
		-- update for bettransG 
		WHILE @rowcount <> 0
		BEGIN
			DELETE FROM @__table
		
			DELETE TOP(2000) FROM #tmp
			OUTPUT deleted.transid, deleted.actualrate, deleted.virtualrate INTO @__table
			SET @rowcount = @@ROWCOUNT
	
			UPDATE b WITH (ROWLOCK, UPDLOCK)
			SET b.actualrate = t.actualrate, b.virtualrate = t.virtualrate
			FROM @__table t 
				INNER JOIN dbo.bettransG b ON t.transid = b.transid 	
		END
	END
		
	DROP TABLE #tmp 
END
GO
