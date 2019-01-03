USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Bet_ExecRep_04]    Script Date: 12/28/2018 3:23:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Bet_ExecRep_04] 
	@Winlostdate DATETIME = NULL
	,@Target VARCHAR(30) = 'DBTRANS' -- DBTRANS/REPLICATED
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
 		- 20171020@Lukas: move to ExecRep_00, this SP is no longer use 
		- 20181106@Sophia: Add table Transfer_Coll [Redmine: #98621]
	
 	Param's Explanation: 
 		@Winlostdate: the date that new rates are updated		
 */

BEGIN
	IF @Winlostdate IS NULL RETURN
	IF @Target NOT IN ('DBTRANS', 'REPLICATED') RETURN
	IF @Target = 'DBTRANS' AND @@SERVERNAME <> 'DBTRANS' RETURN
	IF @Target = 'REPLICATED' AND @@SERVERNAME = 'DBTRANS' RETURN

	PRINT 'START: Reminder of UPDATE Exchange Rate Oanda: EXEC CustDB.dbo.DBA_ExchangeDailyOandaUpd_Actualrate @ExchangeDate=''xxx'''

	DECLARE @Cnt INT
	DECLARE @virtualmultiplier SMALLMONEY
	
	CREATE TABLE #tmp (transid BIGINT, actualrate float, virtualrate float)
	CREATE TABLE #translog (translogid BIGINT, actualrate float, virtualrate float)
	CREATE TABLE #bettransRnG (transid BIGINT, actualrate float, virtualrate float)
	CREATE TABLE #bettransLC (transid BIGINT, actualrate float, virtualrate float)
	CREATE TABLE #Transfer_Coll (transid BIGINT, actualrate float)
	
	SET NOCOUNT OFF

	IF @@SERVERNAME = 'DBTRANS'
	BEGIN
		
		-- update for SB's tickets (using virtualrate)
		PRINT '1.--------SB''s tickets (using virtualrate)--------'
			
		insert into #tmp(transid, actualrate, virtualrate)
		select transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
		FROM dbo.bettrans b WITH(nolock) 
			INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid
		WHERE b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate 
			AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) AND b.actualrate <> b.virtualrate

			 
		PRINT '2.--------SB''s tickets (without virtualrate)--------'
		-- update for SB's tickets (without virtualrate)
		 
		insert into #tmp(transid, actualrate, virtualrate)
		select transid, e.actualrate, e.actualrate 
		FROM dbo.bettrans b WITH(nolock) 
			,CustDB.dbo.exchange e WITH (NOLOCK)
		WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) AND b.actualrate = b.virtualrate
 

		PRINT '3.----------------'			
		insert into #tmp(transid, actualrate, virtualrate)
		select transid, e.actualrate, e.actualrate 
		FROM dbo.bettrans b WITH(nolock) 
			,CustDB.dbo.exchange e WITH (NOLOCK)
		WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 AND b.actualrate = b.virtualrate AND b.currency2 IS NULL
 

		PRINT '4.-------OPENTOTE tickets---------'

		-- OPENTOTE tickets
			
		insert into #tmp(transid, actualrate, virtualrate)
		select transid, e.actualrate, b.virtualrate
		FROM dbo.bettrans b WITH(nolock) 
			,CustDB.dbo.exchange e WITH (NOLOCK)
		WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 AND b.currency2 IS NOT NULL


		PRINT '5.-------transfer tickets---------'
		-- transfer tickets		 
			
		insert into #tmp(transid, actualrate, virtualrate)
		select transid, e.actualrate, b.virtualrate
		FROM dbo.bettrans b WITH(nolock) 
			,CustDB.dbo.exchange e WITH (NOLOCK)
		WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND b.bettype >= 19001
 
		-- update for TransLog table (using virtualrate)
		PRINT '6.--------TransLog table--------' 
							
		insert into #translog(translogid, actualrate, virtualrate)
		select translogid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
		FROM dbo.TransLog b WITH(nolock) 				
			INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK)
				ON b.currency = e.exchangeid 
		WHERE 
			b.winlostdate >= @Winlostdate
			--AND b.actualrate <> b.virtualrate 
			AND b.actualrate <> e.actualrate 				
			 
 
		
		-- update for BettransRNG table (using virtualrate)
		PRINT '8.--------BettransRNG table--------'

			 
		insert into #bettransRnG(transid, actualrate, virtualrate)
		select transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
		FROM dbo.BettransRNG b WITH(nolock) 				
			INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK)
				ON b.currency = e.exchangeid 
		WHERE 
			b.winlostdate >= @Winlostdate
			--AND b.actualrate <> b.virtualrate 
			AND b.actualrate <> e.actualrate 				
				 

		-- update for BettransLC table (using virtualrate)
		PRINT '10.--------BettransLC table--------'
 
			 
		insert into #bettransLC(transid, actualrate, virtualrate)
		select transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
		FROM dbo.BettransLC b WITH(nolock) 				
			INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK)
				ON b.currency = e.exchangeid 
		WHERE 
			b.winlostdate >= @Winlostdate
			--AND b.actualrate <> b.virtualrate 
			AND b.actualrate <> e.actualrate 		

		PRINT '11.-------Transfer_Coll table ---------'
		-- Transfer_Coll tickets		 
		IF EXISTS (SELECT 1 FROM sys.objects WHERE Object_Name(Object_ID) = 'Transfer_Coll')
		BEGIN
			insert into #Transfer_Coll(transid, actualrate)
			select b.transid, e.actualrate
			FROM dbo.Transfer_Coll b WITH(nolock) 
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND b.bettype >= 19001
		END
				
		PRINT 'END: Reminder of UPDATE Exchange Rate Oanda: EXEC CustDB.dbo.DBA_ExchangeDailyOandaUpd_Actualrate @ExchangeDate=''xxx'''
	END
	
	IF @@SERVERNAME <> 'DBTRANS'
	BEGIN
		IF (
			SELECT COUNT(1)
			FROM sysobjects
			WHERE NAME IN ('custinfo', 'bettrans', 'exchange') AND type = 'U'
		) < 3 RETURN
		-- update for SB's tickets (using virtualrate)
		PRINT '1.-------SB''s tickets (using virtualrate)---------'
			
		insert into #tmp(transid, actualrate, virtualrate)
		select transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
		FROM dbo.bettrans b WITH(nolock) 
			INNER JOIN bodb02.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid
		WHERE b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate 
			AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) AND b.actualrate <> b.virtualrate

			 
		PRINT '2.-------- SB''s tickets (without virtualrate)--------'

		-- update for SB's tickets (without virtualrate)
		  
				
		insert into #tmp(transid, actualrate, virtualrate)
		select transid, e.actualrate, e.actualrate 
		FROM dbo.bettrans b WITH(nolock) 
			,bodb02.dbo.exchange e WITH (NOLOCK)
		WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) AND b.actualrate = b.virtualrate
 

		PRINT '3.----------------' 
			 
		insert into #tmp(transid, actualrate, virtualrate)
		select transid, e.actualrate, e.actualrate 
		FROM dbo.bettrans b WITH(nolock) 
			,bodb02.dbo.exchange e WITH (NOLOCK)
		WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 AND b.actualrate = b.virtualrate AND b.currency2 IS NULL
 

		PRINT '4.-------OPENTOTE tickets---------'

		-- OPENTOTE tickets
		 
			
		insert into #tmp(transid, actualrate, virtualrate)
		select transid, e.actualrate, b.virtualrate
		FROM dbo.bettrans b WITH(nolock) 
			,bodb02.dbo.exchange e WITH (NOLOCK)
		WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 AND b.currency2 IS NOT NULL


		PRINT '5.-------transfer tickets---------'
		-- transfer tickets
		 
			--UPDATE TOP (5000) b
			--SET actualrate = e.actualrate
		insert into #tmp(transid, actualrate, virtualrate)
		select transid, e.actualrate, b.virtualrate
		FROM dbo.bettrans b WITH(nolock) 
			,bodb02.dbo.exchange e WITH (NOLOCK)
		WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND b.bettype >= 19001
 
		-- update for TransLog table (using virtualrate)
		PRINT '6.--------TransLog table--------' 
			 
				
		insert into #translog(translogid, actualrate, virtualrate)
		select translogid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
		FROM dbo.TransLog b WITH(nolock) 			
			INNER JOIN bodb02.dbo.exchange e WITH (NOLOCK)
				ON b.currency = e.exchangeid 
		WHERE 
			b.winlostdate >= @Winlostdate
			--AND b.actualrate <> b.virtualrate 
			AND b.actualrate <> e.actualrate 				
			 
 
		
		-- update for BettransRNG table (using virtualrate)
		PRINT '8.-------BettransRNG table---------' 
			 
		insert into #bettransRnG(transid, actualrate, virtualrate)
		select transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
		FROM dbo.BettransRNG b WITH(nolock) 			
			INNER JOIN bodb02.dbo.exchange e WITH (NOLOCK)
				ON b.currency = e.exchangeid 
		WHERE 
			b.winlostdate >= @Winlostdate
			--AND b.actualrate <> b.virtualrate 
			AND b.actualrate <> e.actualrate 				
				 

		-- update for BettransLC table (using virtualrate)
		PRINT '10.-------BettransLC table---------' 

		insert into #BettransLC(transid, actualrate, virtualrate)
		select transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
		FROM dbo.BettransLC b WITH(nolock) 				
			INNER JOIN bodb02.dbo.exchange e WITH (NOLOCK)
				ON b.currency = e.exchangeid 
		WHERE 
			b.winlostdate >= @Winlostdate
			--AND b.actualrate <> b.virtualrate 
			AND b.actualrate <> e.actualrate 	 
			
			
		PRINT '11.-------Transfer_Coll table ---------'
		-- Transfer_Coll tickets		 
		IF EXISTS (SELECT 1 FROM sys.objects WHERE Object_Name(Object_ID) = 'Transfer_Coll')
		BEGIN 
			insert into #Transfer_Coll(transid, actualrate)
			select b.transid, e.actualrate 
			FROM dbo.Transfer_Coll b WITH(nolock) 
				,dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND b.bettype >= 19001
		END
		
		PRINT 'END: Reminder of UPDATE Exchange Rate Oanda: EXEC CustDB.dbo.DBA_ExchangeDailyOandaUpd_Actualrate @ExchangeDate=''xxx'''
		
	end 
	
	SET NOCOUNT ON 
	-- update bettransRnG
	declare @table table (transid bigint, actualrate float, virtualrate float)
	declare @rowcount int = 1
	
	while @rowcount <> 0
	begin
		delete from @table
		
		delete top(2000) 		
		from #bettransRnG
		output deleted.transid, deleted.actualrate, deleted.virtualrate into @table
		set @rowcount = @@ROWCOUNT
		
		update b with(rowlock,updlock)
		set b.actualrate = t.actualrate,
			b.virtualrate = t.virtualrate
		from @table t 
			inner join bettransRnG b on t.transid = b.transid
	end
	
	set @rowcount = 1 
	-- update for bettransLC 
	while @rowcount <> 0
	begin
		delete from @table
		
		delete top(2000) 		
		from #bettransLC
		output deleted.transid, deleted.actualrate, deleted.virtualrate into @table
		set @rowcount = @@ROWCOUNT
		
		update b with(rowlock,updlock)
		set b.actualrate = t.actualrate,
			b.virtualrate = t.virtualrate
		from @table t 
			inner join bettransLC b on t.transid = b.transid 
	end
	
	set @rowcount = 1 
	-- update for translog 
	while @rowcount <> 0
	begin
		delete from @table
		
		delete top(2000) 		
		from #translog
		output deleted.translogid, deleted.actualrate, deleted.virtualrate into @table
		set @rowcount = @@ROWCOUNT
		
		update b with(rowlock,updlock)
		set b.actualrate = t.actualrate,
			b.virtualrate = t.virtualrate
		from @table t 
			inner join translog b on t.transid = b.translogid 
	end
	
	set @rowcount = 1 
	-- update for bettrans 
	while @rowcount <> 0
	begin
		delete from @table
		
		delete top(2000) 		
		from #tmp 
		output deleted.transid, deleted.actualrate, deleted.virtualrate into @table
		set @rowcount = @@ROWCOUNT
		
		update b with(rowlock,updlock)
		set b.actualrate = t.actualrate,
			b.virtualrate = t.virtualrate
		from @table t 
			inner join bettrans b on t.transid = b.transid 
	end
	
	IF EXISTS (SELECT 1 FROM sys.objects WHERE Object_Name(Object_ID) = 'Transfer_Coll')
	BEGIN 
		set @rowcount = 1 
		-- update for Transfer_Coll
		while @rowcount <> 0
		begin
			delete from @table
			
			delete top(2000) 		
			from #Transfer_Coll 
			output deleted.transid, deleted.actualrate, 0 into @table
			set @rowcount = @@ROWCOUNT
			
			update b with(rowlock,updlock)
			set b.actualrate = t.actualrate			
			from @table t 
				inner join Transfer_Coll b on t.transid = b.transid 
		end
	END 
END

