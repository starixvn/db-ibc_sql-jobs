 /*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.ExecRep_NAP_Admin_10
	@Winlostdate SMALLDATETIME = NULL
	,@Target VARCHAR(30) = 'DBTXN' -- DBTRANS/REPLICATED
	,@TableName VARCHAR(200) 
	,@isSiteDB BIT = 0
AS 

/*
	Created by: 20201006@Louisa
	Task: execRep SP for Settlement [Redmine:#140452]
	DB: DBTXN/bodb02
	
	Revisions:
		- 20201006@Louisa: SP for Settlement [Redmine:#140452]		
		- 20220801@Sophia: Scale out DB, borrow SPs for UAT test ExecRep_00 [RedmineID: #175253]

	Param's Explanation:
		- ExecRep SP: DBTrans_ExecRep
*/	
BEGIN
	SET NOCOUNT ON

	IF @Winlostdate IS NULL RETURN
	IF @Target NOT IN ('DBTXN', 'REPLICATED') RETURN
	
	DECLARE @SiteDBGroupID INT	
	SELECT @SiteDBGroupID = dbo.f_Get_SiteDBGroupID ()	 
	
	-- Check Central DBTRANS
	IF @Target = 'DBTXN' AND @isSiteDB = 0 AND @SiteDBGroupID <> 0 RETURN
	
	-- Check SiteDB
	IF @Target = 'DBTXN' AND @isSiteDB = 1 AND @SiteDBGroupID IN (0,1023) RETURN
	
	--Check replicated server
	IF @Target = 'REPLICATED' AND @SiteDBGroupID < 1023 RETURN
	
	
	IF OBJECT_ID (@TableName, N'U') IS NULL RETURN
	
	--CREATE TABLE #tmp (transid BIGINT, actualrate FLOAT, virtualrate FLOAT)

	CREATE TABLE #bettrans (transid BIGINT, actualrate FLOAT, virtualrate FLOAT, old_actualrate FLOAT)
	CREATE TABLE #translog (transid BIGINT, actualrate FLOAT, virtualrate FLOAT)
	CREATE TABLE #bettransRnG (transid BIGINT, actualrate FLOAT, virtualrate FLOAT)
	CREATE TABLE #bettransLC (transid BIGINT, actualrate FLOAT, virtualrate FLOAT)
	CREATE TABLE #Transfer_Coll (transid BIGINT, actualrate FLOAT)
	CREATE TABLE #bettransG (transid BIGINT, actualrate FLOAT, virtualrate FLOAT)
	CREATE TABLE #transfer (transid BIGINT, actualrate FLOAT)
	CREATE TABLE #CashOutSelling (transid BIGINT, virtualrate FLOAT)
	CREATE CLUSTERED INDEX ix_bettrans ON #bettrans (transid)

	IF @Target = 'DBTXN' AND @SiteDBGroupID < 1023    --- Run at Central DBTrans and SiteDBGroupID
	BEGIN
		IF @TableName = 'bettrans' --bettrans@dbtrans
		BEGIN
			-- update for SB's tickets (using virtualrate)
			INSERT INTO #bettrans(transid, actualrate, virtualrate, old_actualrate)
			SELECT transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) AS virtualrate, b.actualrate
			FROM dbo.bettrans b WITH(NOLOCK) 
				INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid
			WHERE b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate 
				AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) AND b.actualrate <> b.virtualrate
			 
			-- update for SB's tickets (without virtualrate)
			INSERT INTO #bettrans(transid, actualrate, virtualrate, old_actualrate)
			SELECT transid, e.actualrate, e.actualrate, b.actualrate 
			FROM dbo.bettrans b WITH(NOLOCK) 
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) 
				AND b.actualrate = b.virtualrate

			INSERT INTO #bettrans(transid, actualrate, virtualrate, old_actualrate)
			SELECT transid, e.actualrate, e.actualrate, b.actualrate 
			FROM dbo.bettrans b WITH(NOLOCK) 
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 
				AND b.actualrate = b.virtualrate AND b.currency2 IS NULL

			--==	
			INSERT INTO #bettrans(transid, actualrate, virtualrate, old_actualrate)
			SELECT transid, e.actualrate, b.virtualrate, b.actualrate
			FROM dbo.bettrans b WITH(NOLOCK) 
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 AND b.currency2 IS NOT NULL

			IF OBJECT_ID ('CashOutSelling', N'U') IS NOT NULL
			BEGIN
				INSERT INTO #CashOutSelling (transid, virtualrate)
				SELECT b.transid, b.actualrate * (co.VirtualRate/b.old_actualrate)
				FROM dbo.CashOutSelling co WITH(NOLOCK)
					INNER JOIN #bettrans b ON b.transid = co.TransID
			END
		END
		
		IF @TableName = 'translog'  --translog@dbtrans
		BEGIN
			-- update for TransLog table (using virtualrate)
			INSERT INTO #translog(transid, actualrate, virtualrate)
			SELECT translogid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
			FROM dbo.TransLog b WITH(NOLOCK) 				
				INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid 
			WHERE b.winlostdate >= @Winlostdate
				AND b.actualrate <> e.actualrate 				
			 
		END

		IF @TableName = 'bettransRnG' --bettransRnG@dbtrans
		BEGIN
			-- update for BettransRNG table (using virtualrate)
			INSERT INTO #bettransRnG(transid, actualrate, virtualrate)
			SELECT transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
			FROM dbo.BettransRNG b WITH(NOLOCK) 				
				INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid 
			WHERE b.winlostdate >= @Winlostdate
				AND b.actualrate <> e.actualrate 				
				 
		END
		
		IF @TableName = 'bettransLC' --bettransLC@dbtrans
		BEGIN
			-- update for BettransLC table (using virtualrate)
			INSERT INTO #bettransLC(transid, actualrate, virtualrate)
			select transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
			FROM dbo.BettransLC b WITH(NOLOCK) 				
				INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid 
			WHERE b.winlostdate >= @Winlostdate
				AND b.actualrate <> e.actualrate 
		END
		 
		IF @TableName = 'Transfer_Coll' --transfer_coll@dbtrans
		BEGIN
			-- Transfer_Coll tickets
			INSERT INTO #Transfer_Coll(transid, actualrate)
			SELECT b.transid, e.actualrate
			FROM dbo.Transfer_Coll b WITH(NOLOCK) 
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND b.bettype >= 19001
		END
		
		IF @TableName = 'bettransG' --bettransG@dbtrans
		BEGIN
			-- update for bettransG table 
			INSERT INTO #bettransG(transid, actualrate, virtualrate)
			SELECT b.transid, e.actualrate, e.actualrate * (b.virtualrate / b.actualrate) AS virtualrate
			FROM dbo.bettransG b WITH(NOLOCK)
				INNER JOIN CustDB.dbo.CustInfo c WITH (NOLOCK) ON c.custid = b.custid
				INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK)  ON e.exchangeid = c.currency	
			WHERE b.winlostdate >= @Winlostdate AND b.actualrate <> e.actualrate
		END

		IF @TableName = 'Transfer' --Transfer@dbtrans
		BEGIN
			-- update for transfer table 
			INSERT INTO #transfer(transid, actualrate)
			SELECT transid, e.actualrate
			FROM dbo.Transfer b WITH(NOLOCK) 
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate 
		END
	END
	
	IF @Target = 'REPLICATED' AND @SiteDBGroupID = 1023 
	BEGIN
		IF (
			SELECT COUNT(1)
			FROM sysobjects
			WHERE NAME IN ('custinfo', 'bettrans', 'exchange') AND type = 'U'
		) < 3 RETURN

		IF @TableName = 'bettrans' --bettrans@replicated
		BEGIN
			-- update for SB's tickets (using virtualrate)
			INSERT INTO #bettrans(transid, actualrate, virtualrate, old_actualrate)
			SELECT transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate, b.actualrate
			FROM dbo.bettrans b WITH(NOLOCK) 
				INNER JOIN bodb02.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid
			WHERE b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate 
				AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) AND b.actualrate <> b.virtualrate

			-- update for SB's tickets (without virtualrate)
			INSERT INTO #bettrans(transid, actualrate, virtualrate, old_actualrate)
			SELECT transid, e.actualrate, e.actualrate , b.actualrate
			FROM dbo.bettrans b WITH(nolock) 
				,bodb02.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) 
				AND b.actualrate = b.virtualrate
 
			--==
			INSERT INTO #bettrans(transid, actualrate, virtualrate, old_actualrate)
			SELECT transid, e.actualrate, e.actualrate, b.actualrate
			FROM dbo.bettrans b WITH(NOLOCK) 
				,bodb02.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 
				AND b.actualrate = b.virtualrate AND b.currency2 IS NULL
 
			-- OPENTOTE tickets
			INSERT INTO #bettrans(transid, actualrate, virtualrate, old_actualrate)
			SELECT transid, e.actualrate, b.virtualrate, b.actualrate
			FROM dbo.bettrans b WITH(NOLOCK) 
				,bodb02.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
			AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 AND b.currency2 IS NOT NULL

			IF OBJECT_ID ('CashOutSelling', N'U') IS NOT NULL
			BEGIN
				INSERT INTO #CashOutSelling (transid, virtualrate)
				SELECT b.transid, b.actualrate * (co.VirtualRate/b.old_actualrate)
				FROM dbo.CashOutSelling co WITH(NOLOCK)
					INNER JOIN #bettrans b ON b.transid = co.TransID
			END
		END
		
		IF @TableName = 'translog' --translog@replicated
		BEGIN
			-- update for TransLog table (using virtualrate)
			INSERT INTO #translog(transid, actualrate, virtualrate)
			SELECT translogid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) AS virtualrate
			FROM dbo.TransLog b WITH(NOLOCK) 			
				INNER JOIN bodb02.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid 
			WHERE b.winlostdate >= @Winlostdate
				AND b.actualrate <> e.actualrate 				
			 
		END
		
		IF @TableName = 'bettransRnG' --bettransRnG@replicated
		BEGIN
			-- update for BettransRNG table (using virtualrate)
			INSERT INTO #bettransRnG(transid, actualrate, virtualrate)
			SELECT transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) AS virtualrate
			FROM dbo.BettransRNG b WITH(NOLOCK) 			
				INNER JOIN bodb02.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid 
			WHERE b.winlostdate >= @Winlostdate
				AND b.actualrate <> e.actualrate 				
		END
		
		IF @TableName = 'bettransLC' --bettransLC@replicated
		BEGIN
			-- update for BettransLC table (using virtualrate)
			INSERT INTO #bettransLC(transid, actualrate, virtualrate)
			SELECT transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
			FROM dbo.BettransLC b WITH(NOLOCK) 				
				INNER JOIN bodb02.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid 
			WHERE b.winlostdate >= @Winlostdate
				AND b.actualrate <> e.actualrate 	 
		END
		
		IF @TableName = 'Transfer_Coll' --transfer_coll@replicated
		BEGIN 
			INSERT INTO #Transfer_Coll(transid, actualrate)
			select b.transid, e.actualrate 
			FROM dbo.Transfer_Coll b WITH(NOLOCK) 
				,dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND b.bettype >= 19001
		END
		
		IF @TableName = 'bettransG' --bettransG@replicated
		BEGIN
			-- update for bettransG table 
			INSERT INTO #bettransG(transid, actualrate, virtualrate)
			SELECT b.transid, e.actualrate, e.actualrate * (b.virtualrate / b.actualrate) AS virtualrate
			FROM dbo.bettransG b WITH (NOLOCK)
				INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON b.custid = c.custid
				INNER JOIN bodb02.dbo.exchange e WITH (NOLOCK) ON e.exchangeid = c.currency
			WHERE b.winlostdate >= @winlostdate
				  AND b.actualrate <> e.actualrate
		END  

		IF @TableName = 'Transfer' --Transfer@replicated
		BEGIN
			-- update for transfer table 
			INSERT INTO #transfer(transid, actualrate)
			SELECT transid, e.actualrate
			FROM dbo.Transfer b WITH(NOLOCK) 
				,bodb02.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate 
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
		
			DELETE TOP(2000) FROM #bettransRnG
			OUTPUT deleted.transid, deleted.actualrate, deleted.virtualrate INTO @__table
			SET @rowcount = @@ROWCOUNT
		
			UPDATE b WITH(ROWLOCK, UPDLOCK)
			SET b.actualrate = t.actualrate,
				b.virtualrate = t.virtualrate
			FROM @__table t 
				INNER JOIN dbo.bettransRnG b ON t.transid = b.transid
		END
	END
	
	IF @TableName = 'bettransLC' --update bettransLC
	BEGIN
		SET @rowcount = 1 
		WHILE @rowcount <> 0
		BEGIN
			DELETE FROM @__table
		
			DELETE TOP(2000) FROM #bettransLC
			OUTPUT deleted.transid, deleted.actualrate, deleted.virtualrate into @__table
			SET @rowcount = @@ROWCOUNT
		
			UPDATE b WITH(ROWLOCK, UPDLOCK)
			SET b.actualrate = t.actualrate,
				b.virtualrate = t.virtualrate
			FROM @__table t 
				INNER JOIN dbo.bettransLC b ON t.transid = b.transid 
		END
	END
	
	IF @TableName = 'translog' --update translog
	BEGIN
		SET @rowcount = 1 
		WHILE @rowcount <> 0
		BEGIN
			DELETE FROM @__table
		
			DELETE TOP(2000) FROM #translog
			OUTPUT deleted.transid, deleted.actualrate, deleted.virtualrate INTO @__table
			SET @rowcount = @@ROWCOUNT
		
			UPDATE b WITH(ROWLOCK, UPDLOCK)
			SET b.actualrate = t.actualrate,
				b.virtualrate = t.virtualrate
			FROM @__table t 
				INNER JOIN dbo.translog b on t.transid = b.translogid 
		END
	END
	
	IF @TableName = 'bettrans' --update bettrans
	BEGIN
		SET @rowcount = 1 
		WHILE @rowcount <> 0
		BEGIN
			DELETE FROM @__table
		
			DELETE TOP(2000) FROM #bettrans 
			OUTPUT deleted.transid, deleted.actualrate, deleted.virtualrate into @__table
			SET @rowcount = @@ROWCOUNT
		
			UPDATE b WITH(ROWLOCK, UPDLOCK)
			SET b.actualrate = t.actualrate,
				b.virtualrate = t.virtualrate
			FROM @__table t 
				INNER JOIN dbo.bettrans b ON t.transid = b.transid 
		END

		IF OBJECT_ID ('CashOutSelling', N'U') IS NOT NULL
		BEGIN
			SET @rowcount = 1
			WHILE @rowcount <> 0
			BEGIN
				DELETE FROM @__table

				DELETE TOP(2000) FROM #CashOutSelling
				OUTPUT deleted.transid, deleted.virtualrate INTO @__table (transid, virtualrate)
				SET @rowcount = @@ROWCOUNT

				UPDATE co WITH(ROWLOCK, UPDLOCK)
				SET co.VirtualRate = t.virtualrate
				FROM @__table t
					INNER JOIN dbo.CashOutSelling co ON co.TransID = t.transid
			END
		END
	END
	
	IF @TableName = 'Transfer_Coll' --update transfer_coll
	BEGIN 
		SET @rowcount = 1 
		WHILE @rowcount <> 0
		BEGIN
			DELETE FROM @__table
			
			DELETE TOP(2000) FROM #Transfer_Coll 
			OUTPUT deleted.transid, deleted.actualrate, 0 INTO @__table
			SET @rowcount = @@ROWCOUNT
			
			UPDATE b WITH(ROWLOCK, UPDLOCK)
			SET b.actualrate = t.actualrate			
			FROM @__table t 
				INNER JOIN dbo.Transfer_Coll b ON t.transid = b.transid 
		END
	END 
	
	IF @TableName = 'bettransG' --update bettransG
	BEGIN
		SET @rowcount = 1
		-- update for bettransG 
		WHILE @rowcount <> 0
		BEGIN
			DELETE FROM @__table
		
			DELETE TOP(2000) FROM #bettransG
			OUTPUT deleted.transid, deleted.actualrate, deleted.virtualrate INTO @__table
			SET @rowcount = @@ROWCOUNT
	
			UPDATE b WITH (ROWLOCK, UPDLOCK)
			SET b.actualrate = t.actualrate, b.virtualrate = t.virtualrate
			FROM @__table t 
				INNER JOIN dbo.bettransG b ON t.transid = b.transid 	
		END
	END

	IF @TableName = 'Transfer' --update Transfer
	BEGIN
		SET @rowcount = 1
		-- update for Transfer 
		WHILE @rowcount <> 0
		BEGIN
			DELETE FROM @__table
		
			DELETE TOP(2000) FROM #transfer
			OUTPUT deleted.transid, deleted.actualrate INTO @__table (transid, actualrate)
			SET @rowcount = @@ROWCOUNT
	
			UPDATE b WITH (ROWLOCK, UPDLOCK)
			SET b.actualrate = t.actualrate
			FROM @__table t 
				INNER JOIN dbo.Transfer b ON t.transid = b.transid 	
		END
	END
		
	DROP TABLE #bettrans
	DROP TABLE #bettransG
	DROP TABLE #bettransLC
	DROP TABLE #bettransRnG
	DROP TABLE #Transfer_Coll
	DROP TABLE #translog
	DROP TABLE #transfer
	DROP TABLE #CashOutSelling
END
GO


 
 