USE [LASDB]
GO

/****** Object:  StoredProcedure [dbo].[Task_BalanceUp_background]    Script Date: 01/20/2015 00:30:19 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_BalanceUp_background    Script Date: 8/14/2014 3:27:29 PM ******/

CREATE PROCEDURE [dbo].[Task_BalanceUp_background]
	@fdate as date = NULL,
	@step as tinyint = 1
AS

Declare @Doing nvarchar(300)

/*
Created: 20140315@Victor
Task : Balance Up
DB: DBLAS.LASDB
Original: Suncity.Task_BalanceUp_background

Revisions: 
	- 20140415@Victor: Change LASDB table structure to support multiple products
	- 20140709@Victor: Support Legend Cash model
	
Param's Explanation: 

*/

IF @fdate IS NULL
BEGIN
	SELECT @fdate = DATEADD(DAY,7,VValue) 
	FROM dbo.SystemSettings
	WHERE VName = 'MainDB_OldBUDate'

	IF @fdate IS NULL
	BEGIN 
	-- raiserror here to continue to next step of jobs
		RAISERROR ('Please specify a balance up date (first time balance-up)', -- Message text.
					16, -- Severity.
					1 -- State.
					);
	END

	IF @fdate > CURRENT_TIMESTAMP
		SET @fdate = DATEADD(day, -7, @fdate)
END


PRINT '@fdate = ' + CONVERT(varchar(10), @fdate, 120)

/*
SET @Doing = 'call Task_BalanceUp_background @fdate = ' + CONVERT(nvarchar(10), @fdate, 120) + ', @step = ' + CAST(@step as nvarchar(2))
EXEC dbo.WriteLog_UserLog_T @UserID = 70, @Doing = @Doing  
*/



-- ================== STEP : 1 
IF @step = 1
BEGIN
-- ================== DATA VERIFY

	--- DATA VERIFY
	
	IF EXISTS (SELECT * FROM bettrans with (nolock) WHERE winlostdate < @fdate AND (Winlost IS NULL OR PlayerComm IS NULL))
	BEGIN 
	-- raiserror here to continue to next step of jobs
		RAISERROR ('Some records in BetTrans have Null Commission/WinLost of Member', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );
	END
	
	IF EXISTS (SELECT * FROM bettrans_Agent with (nolock) WHERE winlostdate < @fdate AND (AWinlost IS NULL OR AComm IS NULL))
	BEGIN 
	-- raiserror here to continue to next step of jobs
		RAISERROR ('Some records in bettrans_Agent have Null Commission/WinLost of Member', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );
	END
	
-- ================== END STEP : 1 
END
-- ================== DATA VERIFY

--- START --- START --- START ---
--- START --- START --- START ---
--- START --- START --- START ---


-- ================== STEP : 2
IF @step = 2
BEGIN
-- ================== Clear BalanceTable and Perform Backup

	UPDATE dbo.SystemSettings
	SET VValue = '1'
	WHERE VName = 'isArchivingBet' 

	---- for safety, shutdown trigger in BalanceTable_tmp	 
	EXEC Task_BalanceUp_TriggerControl @On = 0

	truncate table BalanceTable
	truncate table BalanceTable_tmp
	truncate table BalanceTable_Agent
	truncate table BalanceTable_Agent_Tmp

	---later
	EXEC dbo.Task_BalanceCheck_LAS @fdate, 11
	/*
	-- doing backup
	Declare @suffix varchar(10)
	SET @suffix = 'bbu' + RIGHT(CONVERT(varchar(10), @fdate,120),5)

	--EXEC dbo.Task_BackupFULL_TransDB @suffix
	--EXEC SVRPRO.ProdDB.dbo.Task_BackupFULL_ProdDB @suffix
	--EXEC SVRCUST.CustDB.dbo.Task_BackupFULL_CustDB @suffix
	-- doing backup : end
	*/
-- ================== END STEP : 2
END
-- ================== Clear BalanceTable and Perform Backup



-- ================== STEP : 3
IF @step = 3
BEGIN
-- ================== Calculate Balance

	-- =====================
	--   CALCULATE BALANCE
	-- =====================
 
		-- Member
		INSERT INTO BalanceTable(Custid, Amount, TicketCount, BalTicketCount)
		SELECT	custid,
				SUM (winlost - actual_stake + playercomm) amount,
				COUNT(*) TicketCount,
				SUM(CASE bettype WHEN 20000 THEN 1 ELSE 0 END) balTicketCount
		FROM  bettrans b WITH (ROWLOCK) -- INDEX HINT, index =IX_WinlostDate_StatusId_Bettype)
		WHERE	Winlostdate < @Fdate 
				AND StatusId NOT IN (0,1)	
				AND EXISTS (SELECT TOP 1 1 FROM dbo.CustInfo c WITH(NOLOCK) WHERE c.CustId = b.CustId) -- Member Only, exclude Agent's tickets		 
		GROUP BY custid

		CREATE TABLE #AgentKList (AgentID INT, ParentID INT) 

		INSERT INTO #AgentKList
		SELECT A.AgentID, PA.AgentID ParentHId
		FROM dbo.AgentInfo A WITH(NOLOCK)
			INNER JOIN dbo.AgentInfo PA WITH(NOLOCK) ON PA.AgentHId = A.AgentHId.GetAncestor(1)
		WHERE A.AgentLevel > 2  
	 
		-- Agent
		INSERT INTO BalanceTable_Agent (AgentId, Amount, TicketCount, BalTicketCount)		
		SELECT  AgentId, sum (Amount) Amount, 
			sum(TicketCount) TicketCount, 
			sum(balTicketCount) balTicketCount
		FROM
			(
			-- get winlost for direct child agent
			SELECT	BP.AgentId, 						
						SUM(BP.AWinlost + BP.AComm  - BA.AComm) as Amount,
						COUNT (*) TicketCount,
						0 AS balTicketCount
				FROM BetTrans_Agent BP  WITH (ROWLOCK) -- INDEX HINT, index =IX_WinlostDate_StatusId_Bettype) 		
				JOIN #AgentKList A WITH (NOLOCK) ON A.ParentID = BP.AgentId
				JOIN BetTrans_Agent BA WITH (ROWLOCK) ON A.AgentId = BA.AgentId AND BP.TransId = BA.TransId
				WHERE	BP.Winlostdate <  @Fdate		
						AND BP.STatusID NOT IN (0,1)	
						AND BP.BETTYPE<20000						
				GROUP BY BP.AgentId 
			UNION ALL				
			-- get winlost for direct member
			SELECT	BP.AgentId, 
						SUM(BP.AWinlost + BP.AComm  - (CASE WHEN ai.LegendType = 0 THEN B.PlayerComm ELSE 0 END)) as Amount,
						COUNT (*) TicketCount,
						0 balTicketCount
				FROM BetTrans_Agent BP  WITH (ROWLOCK) --INDEX HINT , index =IX_WinlostDate_StatusId_Bettype) 
					INNER JOIN bettrans B WITH (ROWLOCK) ON B.TransId = BP.TransId -- INDEX HINT, index =IX_WinlostDate_StatusId_Bettype) 	
					INNER  JOIN CustInfo c WITH (NOLOCK) ON c.AgentId = BP.AgentId	and c.CustId=b.CustId
					INNER JOIN AgentInfo ai WITH (NOLOCK) ON ai.AgentId = BP.AgentId
				WHERE	BP.Winlostdate <  @Fdate		
						AND BP.STatusID NOT IN (0,1)					 							
						AND B.Winlostdate <  @Fdate 
						AND B.STatusID NOT IN (0,1)						
				GROUP BY BP.AgentId
			UNION ALL
			-- for balance record
			SELECT	BP.AgentId, 
						SUM(BP.AWinlost) as Amount,
						0 as TicketCount,
						COUNT (*) balTicketCount
				FROM BetTrans_Agent BP  WITH (ROWLOCK) -- INDEX HINT, index =IX_WinlostDate_StatusId_Bettype) 			
				WHERE	BP.Winlostdate <  @Fdate		
						AND BP.STatusID NOT IN (0,1)	
						AND BP.bettype = 20000  --BALANCE 								
				GROUP BY BP.AgentId 	
			UNION ALL
			-- for agent's transfer tickets
			SELECT	b.CustId, 
					SUM(B.WinLost - b.Actual_Stake) as Amount,
					0 as TicketCount,
					COUNT (*) balTicketCount
			FROM dbo.Bettrans b  WITH (ROWLOCK) 
			WHERE	b.Winlostdate <  @Fdate		
					AND b.Ruben = 1
					AND B.bettype > 20000  -- Transfer
					AND EXISTS (SELECT TOP 1 1 FROM dbo.AgentInfo a (NOLOCK) WHERE a.AgentId = b.CustId AND a.AgentLevel > 1)
			GROUP BY B.CustId
			) T
		GROUP BY AgentId  
		
		DROP TABLE #AgentKList

		----- Delete AgentID not have data in AgentInfo (Deleted AgentID)
		DELETE	B
		FROM	BalanceTable_Agent B
		LEFT JOIN AgentInfo  A 
			ON	A.AgentId = B.AgentId
		WHERE	A.AgentID IS NULL

	 
		UPDATE b
		SET	currency  = c.currency,
			UserName  = c.username,
			CurrencyName = e.currency,
			actualrate = e.ActualRate ------Later: IsNull(ed.ActualRate, e.ActualRate)
		FROM BalanceTable b
			INNER JOIN bodb02.dbo.Custinfo c WITH (NOLOCK) ON b.custid = c.custid
			INNER JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON c.currency = e.exchangeid
			----Later : LEFT OUTER JOIN bodb02.dbo.ExchangeDailyOanda ed ON c.currency = ed.ExchangeId AND ed.ExchangeDate = @fdate


		UPDATE b
		SET	currency  = A.currency,
			UserName  = A.username,
			CurrencyName = E.currency,
			actualrate = E.ActualRate ------Later: IsNull(ed.ActualRate, e.ActualRate)
		FROM BalanceTable_Agent B
			INNER JOIN AgentInfo A WITH (NOLOCK) ON b.AgentId = A.AgentId
			INNER JOIN bodb02.dbo.Exchange E WITH (NOLOCK) ON A.currency = e.exchangeid
			----Later : LEFT OUTER JOIN bodb02.dbo.ExchangeDailyOanda ed ON A.currency = ed.ExchangeId AND ed.ExchangeDate = @fdate


		-- copy data, ready for insertion
		-- customer
		INSERT INTO BalanceTable_tmp(
			[WinlostDate]
			,[CustId]
			,[Amount]
			,[Currency]
			,[Username]
			,[CurrencyName]
			,[ActualRate]
			,[TicketCount]
			,[BalTicketCount])
		SELECT @fdate
			,[CustId]
			,[Amount]
			,[Currency]
			,[Username]
			,[CurrencyName]
			,[ActualRate]
			,[TicketCount]
			,[BalTicketCount]
		FROM BalanceTable

		--agent

		-- Generate a new TransID for BalanceUp record
		DECLARE @GTransID INT
		DECLARE @NewTransID BIGINT

		BEGIN TRANSACTION
		UPDATE dbo.ref with (rowlock, UPDLOCK)  SET   @GTransID=transcode=transcode+1
		WHERE  refid='las'

		if @@Error <> 0
		BEGIN
			ROLLBACK TRANSACTION

			RAISERROR ('Can not generate a new transaction for Balance Up record', -- Message text.
				   18, -- Severity.
				   1 -- State.
				   );
			RETURN
		END		

		SELECT @NewTransID=100000000000+@GTransID

		COMMIT TRANSACTION

		INSERT INTO BalanceTable_Agent_tmp(
				[TransID],[WinlostDate]
				,[AgentId],[Amount]	,[Currency]	,[Username]	,[CurrencyName]	,[ActualRate]
				,[TicketCount],[BalTicketCount])
		SELECT @NewTransID, @fdate,
				[AgentId],[Amount],[Currency],[Username],[CurrencyName],[ActualRate]
				,[TicketCount],[BalTicketCount] 
		FROM BalanceTable_Agent

	EXEC Task_BalanceUp_TriggerControl @on = 1

-- ================== END STEP : 3
END
-- ================== Calculate Balance


-- ======================
--   INSERT NEW BALANCE
-- ======================
-- start remove transaction/insert balance

-- ================== STEP : 4
IF @step = 4
BEGIN
-- ================== BalanceUp Cust
	SET NOCOUNT ON
	 EXEC Task_BalanceUp_Cust @fdate
	SET NOCOUNT OFF
-- ================== END STEP : 4
END
-- ================== BalanceUp Cust

-- ================== STEP : 5
IF @step = 5
BEGIN
-- ================== BalanceUp Agent
	SET NOCOUNT ON

	-- Remove Licensee's transfer tickets 
	DELETE b 
	FROM dbo.BetTrans b 
	WHERE BetType > 20000
		AND EXISTS (SELECT 1 FROM dbo.LicenseeProductSetting lp (NOLOCK) WHERE lp.Custid = b.CustID)
		AND WinLostDate < @fdate

	EXEC dbo.Task_BalanceUp_Agent @fdate
	SET NOCOUNT OFF
-- ================== END STEP : 5
END
-- ================== BalanceUp Agent


-- ================== STEP : 6
IF @step = 6
BEGIN
-- ================== Finishing

	EXEC dbo.Task_BalanceUp_TriggerControl @on = 0

	-- end comment

	----later
	--EXEC dbo.balancecheck @fdate, 21
	EXEC dbo.Task_BalanceCheck_LAS @fdate, 12

	UPDATE dbo.SystemSettings
	SET VValue = '0'
	WHERE VName = 'isArchivingBet' 

	/*
	SET @Doing = 'Task_BalanceUp_background : Done'
	EXEC dbo.WriteLog_UserLog_T @UserID = 70, @Doing = @Doing  
	*/
-- ================== END STEP : 6
END
-- ================== Finishing
GO


