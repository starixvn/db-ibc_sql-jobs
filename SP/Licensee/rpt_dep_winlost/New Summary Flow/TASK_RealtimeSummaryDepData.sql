/*<info serverAlias="DBACC-bodb02" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[TASK_RealtimeSummaryDepData]
	@Winlostdate DATE = NULL,
	@isSuccessful BIT = 0 OUTPUT
AS
	/*
		Created By: Francis
		Created Date: 20160815
		Task: Summarize data (for every 10 seconds) for table rptDepWinlost_Trans for the input @Winlostdate 		
		DB: DBACC.bodb02
		Revisions:
		- 20161004@Francis: Add Error Message to Log when issue happens
		- 20161013@Jim : LRF - Implement Colossus Bets [Redmine: #63785]
		- 20161115@Jim: LRF - Integrate new product Fishing World [RedmineID : #66737]
		- 20170322@Paul: Implement Cash Out [RedmineID :#71727]
		- 20170712@Harper: Implement new Product Betradar VS [Redmine: #78241]
		- 20170619@Harper: LRF - Integrate Lottery [RedmineID: #79997]
		- 20170814@Harper: One RNG - Offer New Tablet Games [RedmineID: #78424]
		- 20170831@Paul: Resolve deadlock issue [RedmineID: #82516]

		Input Params:
		- @Winlostdate: The input Winlostdate to be summarized
		- @isSuccessful: -1: Data of the whole day have been summarized completely
						 -0: Data of the whole day have not been summarized completely
	*/
BEGIN
	SET NOCOUNT ON
	
	SET @isSuccessful = 0
	
	--1.Set low deadlock priority
	SET DEADLOCK_PRIORITY LOW
	
	DECLARE @CurrentDate DATE,
			@CurrentHour TINYINT,
			@LogDesc VARCHAR(8000) = 'Date generated: ',
			@LogID BIGINT,
			@NumberofCus INT= 0,
			@ErrMsg VARCHAR(1000) = ''
	
	SELECT @CurrentDate = CONVERT(DATE,CURRENT_TIMESTAMP,112)
	SELECT @CurrentHour = DATEPART(HOUR,CURRENT_TIMESTAMP)
	
	IF @Winlostdate IS NULL
		SELECT @Winlostdate = @CurrentDate
		
	IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.bettrans WITH (NOLOCK) WHERE winlostdate = @Winlostdate AND bettype < 19999 AND bettype != 18000)
	   OR @WinlostDate > @CurrentDate
		BEGIN
			PRINT 'EXEC TASK_RealtimeSummaryDepData: There is no data in bettrans to summarize or input @Winlostdate is greater than current day ==> RETURN'
			RETURN
		END
	
	--2.Insert Log
	INSERT INTO bodb_Report.dbo.rptDepWinlost_Log(Logdate, LogHour, LogType, StartTime)
		SELECT @CurrentDate, @CurrentHour, 4, CURRENT_TIMESTAMP AS StartTime
		
	SELECT @LogID = @@IDENTITY
	
	DECLARE @CasinoPartner TABLE (PartnerId INT, TransferId INT, CancelTransferId INT)
	INSERT INTO @CasinoPartner(PartnerId, TransferId, CancelTransferId)
	SELECT PartnerId, TransferId, CancelTransferId
	FROM bodb_report.dbo.tblCasinoPartners WITH(NOLOCK)
	WHERE TransferId IS NOT NULL OR CancelTransferId IS NOT NULL
		
	CREATE TABLE #rptDepWinlostDetails (CustID INT, PartnerID INT DEFAULT(-1), Bettype INT, Deposit MONEY DEFAULT(0), Withdrawal MONEY DEFAULT(0)
			, Aff2MemTransfer MONEY DEFAULT(0), Bonus MONEY DEFAULT(0), Adjustment MONEY DEFAULT(0), TurnOver MONEY DEFAULT(0), OutStanding MONEY DEFAULT(0)
			, Winloss MONEY DEFAULT(0), Transfer3rd MONEY DEFAULT(0), DrawGame MONEY DEFAULT(0), Turnover_BA MONEY DEFAULT(0), Comm_BA MONEY DEFAULT(0)
			, AmountDueTo_BA MONEY DEFAULT(0), playercomm MONEY DEFAULT(0), Transfer3rdOthers MONEY DEFAULT(0), Transfer3rdOthers_In MONEY DEFAULT(0)
			, Transfer3rdOthers_Out MONEY DEFAULT(0), Comm_BetTrade MONEY DEFAULT(0), Comm_BetTrade_Full MONEY DEFAULT(0)
			, WLBoughtTicket_BetTrade MONEY DEFAULT(0), AmountDueTo_BetTrade MONEY DEFAULT(0), BetCount INT DEFAULT(0)
			UNIQUE CLUSTERED (CustID, PartnerID, Bettype)
			)
	
	CREATE TABLE #rptDepWinlost (CustID INT, Deposit MONEY DEFAULT(0), Withdrawal MONEY DEFAULT(0), Aff2MemTransfer MONEY DEFAULT(0)
			, Bonus MONEY DEFAULT(0), Adjustment MONEY DEFAULT(0), TurnOver MONEY DEFAULT(0), OutStanding MONEY DEFAULT(0), Winloss MONEY DEFAULT(0), Transfer3rd MONEY DEFAULT(0)
			, DrawGame MONEY DEFAULT(0), Turnover_BA MONEY DEFAULT(0), Comm_BA MONEY DEFAULT(0), AmountDueTo_BA MONEY DEFAULT(0), playercomm MONEY DEFAULT(0)
			, Transfer3rdOthers MONEY DEFAULT(0), Comm_BetTrade MONEY DEFAULT(0), Comm_BetTrade_Full MONEY DEFAULT(0), WLBoughtTicket_BetTrade MONEY DEFAULT(0)
			, AmountDueTo_BetTrade MONEY DEFAULT(0)
			UNIQUE CLUSTERED (CustID)
			)
			
						
	CREATE TABLE #rptDepWinlostByProduct (CustID INT, SportType SMALLINT, turnover MONEY DEFAULT(0), drawTO MONEY DEFAULT(0), Winlost MONEY DEFAULT(0)
			, playercomm MONEY DEFAULT(0), BetCount INT DEFAULT(0), OutStanding MONEY DEFAULT(0)
			UNIQUE CLUSTERED (CustID, SportType)
			)
			
	CREATE TABLE #rptDepWinlostTransfer3rdOthers (CustID INT, PartnerID INT, TransferAmount MONEY DEFAULT(0), TransferIn MONEY DEFAULT(0), TransferOut MONEY DEFAULT(0)
			UNIQUE CLUSTERED (CustID, PartnerID)
			)
	
	CREATE TABLE #rptDepWinlostOutstanding (CustID INT, SportType SMALLINT DEFAULT(-1), TurnOver MONEY DEFAULT(0), OutStanding MONEY DEFAULT(0), BetCount INT DEFAULT(0)
			UNIQUE CLUSTERED (CustID, SportType)
			)

	DECLARE @recommend TABLE (recommend INT PRIMARY KEY)
	DECLARE @recommend1 TABLE (recommend INT PRIMARY KEY)

	INSERT INTO @recommend1 (recommend)
	SELECT c.custid
	FROM dbo.Customer c WITH(NOLOCK)
		INNER JOIN dbo.Dep_CustSuper cs WITH(NOLOCK) ON c.srecommend = cs.custid
	WHERE c.roleid = 2
	
	INSERT INTO @recommend (recommend)
	SELECT r.recommend 
	FROM @recommend1 r
	WHERE EXISTS (
		SELECT 1 
		FROM dbo.bettransRnG b WITH(NOLOCK) 
		WHERE b.recommend = r.recommend AND b.winlostdate = @Winlostdate
	)

	BEGIN TRY
		--3.Prepare staging data for table rptDepWinlost_Trans
		--Insert Details for rptDepWinlost/rptDepWinlostByProduct/rptDepWinlostTransfer3rdOthers
		IF @Winlostdate < @CurrentDate
		BEGIN
			INSERT INTO #rptDepWinlostDetails (CustID, BetType, Deposit, Withdrawal, Aff2MemTransfer, Bonus, Adjustment, TurnOver, OutStanding, Winloss, Transfer3rd
												, DrawGame, playercomm, Comm_BetTrade, Comm_BetTrade_Full, WLBoughtTicket_BetTrade, BetCount)
			SELECT b.custid, 
				b.bettype,
				SUM(CASE WHEN b.bettype = 22001 THEN b.winlost-b.actual_stake ELSE 0 END), --Deposit  
				-SUM(CASE WHEN b.bettype IN (22002, 22003) THEN b.winlost-b.actual_stake ELSE 0 END),--Withdrawal  
				SUM(CASE WHEN b.bettype = 21006 THEN b.winlost-b.actual_stake ELSE 0 END), --Aff2MemTransfer  
				SUM(CASE WHEN b.bettype = 22004 THEN b.winlost-b.actual_stake ELSE 0 END),--Bonus  
				SUM(CASE WHEN b.bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN b.winlost-b.actual_stake ELSE 0 END),--Adjustment  
				SUM(CASE WHEN b.bettype < 19999 AND b.StatusID NOT IN (101, 102, 103) THEN b.stake ELSE 0 END),--Turnover
				SUM(CASE WHEN (bettype < 19999 OR bettype = 23002) AND b.ruben = 0 THEN b.actual_stake ELSE 0 END),--Outstanding 
				SUM(CASE WHEN b.bettype < 19999 AND b.ruben = 1 THEN b.winlost-b.actual_stake ELSE 0 END),--Winloss      
				SUM(CASE WHEN b.bettype IN (22006, 22007) THEN b.winlost-b.actual_stake ELSE 0 END),--Transfer3rd   
				SUM(CASE WHEN b.bettype < 19999 AND b.statusID = 111 THEN b.stake ELSE 0 END),--DrawGame  
				SUM(CASE WHEN b.bettype < 19999 AND b.ruben = 1 THEN b.playercomm ELSE 0 END),--playercomm  	
				SUM(CASE WHEN b.bettype = 903 AND b.ruben = 1 AND b.statusID NOT IN (101, 102, 103) THEN b.awinlost ELSE 0 END),--Comm_BetTrade
				SUM(CASE WHEN b.bettype = 903 AND b.ruben = 1 AND b.statusID NOT IN (101, 102, 103) THEN b.winlost - b.actual_stake ELSE 0 END),--Comm_BetTrade_Full
				SUM(CASE WHEN b.bettype = 902 AND b.ruben = 1 AND b.statusID NOT IN (101, 102, 103) THEN b.winlost - b.actual_stake ELSE 0 END),--WLBoughtTicket_BetTrade
				SUM(CASE WHEN b.bettype < 19999 AND b.StatusID NOT IN (101, 102, 103) THEN 1 ELSE 0 END) --BetCount
			FROM dbo.bettrans b WITH (NOLOCK)
				INNER JOIN dbo.Dep_CustSuper d WITH (NOLOCK) ON b.srecommend = d.custid
				INNER JOIN dbo.CustInfo c WITH (NOLOCK) ON b.custid = c.custid
			WHERE b.winlostdate = @Winlostdate
				  AND b.matchid >= 0
				  AND c.roleid = 1
			GROUP BY b.custid, b.bettype
			OPTION (RECOMPILE, MAXDOP 8)
			
			INSERT INTO #rptDepWinlostOutstanding (CustID, SportType, TurnOver, OutStanding, BetCount)
			SELECT t.custid, t.SportType, SUM(t.TurnOver), SUM(t.OutStanding), SUM(t.BetCount)
			FROM (SELECT tl.custid
					   , tl.productID AS SportType
					   ,SUM(CASE WHEN tl.statusID IN (0,1) then tl.stake ELSE 0 END) AS TurnOver
					   ,SUM(CASE WHEN tl.statusID IN (0,1) then tl.actual_stake ELSE 0 END) AS OutStanding 
					   ,SUM(CASE WHEN tl.statusID IN (0,1) then 1 ELSE 0 END) AS BetCount 
				  FROM dbo.translog tl WITH (ROWLOCK)
						INNER JOIN dbo.Dep_CustSuper s WITH(NOLOCK) ON s.custid = tl.srecommend
				  WHERE tl.winlostdate = @Winlostdate
						AND tl.productID IN (202,203,204)
				  GROUP BY tl.custid, tl.productID
				  UNION ALL -- microgaming_RNG & OneRnG & Voidbridge
				  SELECT g.custid
						,g.productID AS SportType
						,SUM(CASE WHEN g.statusID IN (0,1) then g.stake ELSE 0 END) AS TurnOver
						,SUM(CASE WHEN g.statusID IN (0,1) then g.actual_stake ELSE 0 END) AS OutStanding
						,SUM(CASE WHEN g.statusID IN (0,1) then 1 ELSE 0 END) AS BetCount
				  FROM dbo.bettransRnG g WITH (ROWLOCK)
						INNER JOIN @recommend r on g.recommend = r.recommend
				  WHERE g.winlostdate = @Winlostdate  
				  GROUP BY g.custid, g.productID
				  UNION ALL -- AG Casino, Allbet
				  SELECT l.custid
						,l.productID AS SportType
						,SUM(CASE WHEN l.statusID IN (0,1) then l.stake ELSE 0 END) AS TurnOver
						,SUM(CASE WHEN l.statusID IN (0,1) then l.actual_stake ELSE 0 END) AS OutStanding
						,SUM(CASE WHEN l.statusID IN (0,1) then 1 ELSE 0 END) AS BetCount
				  FROM dbo.bettransLC l WITH (ROWLOCK)
						INNER JOIN dbo.Dep_CustSuper s WITH(NOLOCK) ON s.custid = l.srecommend
				  WHERE l.winlostdate = @Winlostdate
				  GROUP BY l.custid, l.productID) t
			GROUP BY t.custid, t.SportType
		END
		ELSE --@Winlostdate = @CurrentDate
		BEGIN	
			INSERT INTO #rptDepWinlostDetails (CustID, BetType, Deposit, Withdrawal, Aff2MemTransfer, Bonus, Adjustment, TurnOver, OutStanding, Winloss, Transfer3rd
												, DrawGame, playercomm, Comm_BetTrade, Comm_BetTrade_Full, WLBoughtTicket_BetTrade, BetCount)
			SELECT b.custid, 
				b.bettype,
				SUM(CASE WHEN b.winlostdate = @Winlostdate AND b.bettype = 22001 THEN b.winlost-b.actual_stake ELSE 0 END), --Deposit  
				-SUM(CASE WHEN b.winlostdate = @Winlostdate AND b.bettype IN (22002, 22003) THEN b.winlost-b.actual_stake ELSE 0 END),--Withdrawal  
				SUM(CASE WHEN b.winlostdate = @Winlostdate AND b.bettype = 21006 THEN b.winlost-b.actual_stake ELSE 0 END), --Aff2MemTransfer  
				SUM(CASE WHEN b.winlostdate = @Winlostdate AND b.bettype = 22004 THEN b.winlost-b.actual_stake ELSE 0 END),--Bonus  
				SUM(CASE WHEN b.winlostdate = @Winlostdate AND b.bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN b.winlost-b.actual_stake ELSE 0 END),--Adjustment  
				SUM(CASE WHEN b.winlostdate = @Winlostdate AND b.bettype < 19999 AND b.StatusID NOT IN (101, 102, 103) THEN b.stake ELSE 0 END),--Turnover
				SUM(CASE WHEN (bettype < 19999 OR bettype = 23002) AND b.ruben = 0 THEN b.actual_stake ELSE 0 END),--Outstanding 
				SUM(CASE WHEN b.winlostdate = @Winlostdate AND b.bettype < 19999 AND b.ruben = 1 THEN b.winlost-b.actual_stake ELSE 0 END),--Winloss      
				SUM(CASE WHEN b.winlostdate = @Winlostdate AND b.bettype IN (22006, 22007) THEN b.winlost-b.actual_stake ELSE 0 END),--Transfer3rd   
				SUM(CASE WHEN b.winlostdate = @Winlostdate AND b.bettype < 19999 AND b.statusID = 111 THEN b.stake ELSE 0 END),--DrawGame  
				SUM(CASE WHEN b.winlostdate = @Winlostdate AND b.bettype < 19999 AND b.ruben = 1 THEN b.playercomm ELSE 0 END),--playercomm  	
				SUM(CASE WHEN b.winlostdate = @Winlostdate AND b.bettype = 903 AND b.ruben = 1 AND b.statusID NOT IN (101, 102, 103) THEN b.awinlost ELSE 0 END),--Comm_BetTrade
				SUM(CASE WHEN b.winlostdate = @Winlostdate AND b.bettype = 903 AND b.ruben = 1 AND b.statusID NOT IN (101, 102, 103) THEN b.winlost - b.actual_stake ELSE 0 END),--Comm_BetTrade_Full
				SUM(CASE WHEN b.winlostdate = @Winlostdate AND b.bettype = 902 AND b.ruben = 1 AND b.statusID NOT IN (101, 102, 103) THEN b.winlost - b.actual_stake ELSE 0 END),--WLBoughtTicket_BetTrade
				SUM(CASE WHEN b.winlostdate = @Winlostdate AND b.bettype < 19999 AND b.StatusID NOT IN (101, 102, 103) THEN 1 ELSE 0 END) --BetCount
			FROM dbo.bettrans b WITH (NOLOCK)
				INNER JOIN dbo.Dep_CustSuper d WITH (NOLOCK) ON b.srecommend = d.custid
				INNER JOIN dbo.CustInfo c WITH (NOLOCK) ON b.custid = c.custid
			WHERE b.winlostdate >= @Winlostdate
				  AND b.matchid >= 0
				  AND c.roleid = 1
			GROUP BY b.custid, b.bettype
			OPTION (RECOMPILE, MAXDOP 8)
			
			INSERT INTO #rptDepWinlostOutstanding (CustID, SportType, TurnOver, OutStanding, BetCount)
			SELECT t.custid, t.SportType, SUM(t.TurnOver), SUM(t.OutStanding), SUM(t.BetCount)
			FROM (SELECT tl.custid
					   , tl.productID AS SportType
					   ,SUM(CASE WHEN tl.winlostdate = @Winlostdate AND tl.statusID IN (0,1) then tl.stake ELSE 0 END) AS TurnOver
					   ,SUM(CASE WHEN tl.statusID IN (0,1) then tl.actual_stake ELSE 0 END) AS OutStanding 
					   ,SUM(CASE WHEN tl.winlostdate = @Winlostdate AND tl.statusID IN (0,1) then 1 ELSE 0 END) AS BetCount 
				  FROM dbo.translog tl WITH (ROWLOCK)
						INNER JOIN dbo.Dep_CustSuper s WITH(NOLOCK) ON s.custid = tl.srecommend
				  WHERE tl.winlostdate >= @Winlostdate
						AND tl.productID IN (202,203,204)
				  GROUP BY tl.custid, tl.productID
				  UNION ALL -- microgaming_RNG & OneRnG & Voidbridge
				  SELECT g.custid
						,g.productID AS SportType
						,SUM(CASE WHEN g.winlostdate = @Winlostdate AND g.statusID IN (0,1) then g.stake ELSE 0 END) AS TurnOver
						,SUM(CASE WHEN g.statusID IN (0,1) then g.actual_stake ELSE 0 END) AS OutStanding
						,SUM(CASE WHEN g.winlostdate = @Winlostdate AND g.statusID IN (0,1) then 1 ELSE 0 END) AS BetCount
				  FROM dbo.bettransRnG g WITH (ROWLOCK)
						INNER JOIN @recommend r on g.recommend = r.recommend
				  WHERE g.winlostdate >= @Winlostdate  
				  GROUP BY g.custid, g.productID
				  UNION ALL -- AG Casino, Allbet
				  SELECT l.custid
						,l.productID AS SportType
						,SUM(CASE WHEN l.winlostdate = @Winlostdate AND l.statusID IN (0,1) then l.stake ELSE 0 END) AS TurnOver
						,SUM(CASE WHEN l.statusID IN (0,1) then l.actual_stake ELSE 0 END) AS OutStanding
						,SUM(CASE WHEN l.winlostdate = @Winlostdate AND l.statusID IN (0,1) then 1 ELSE 0 END) AS BetCount
				  FROM dbo.bettransLC l WITH (ROWLOCK)
						INNER JOIN dbo.Dep_CustSuper s WITH(NOLOCK) ON s.custid = l.srecommend
				  WHERE l.winlostdate >= @Winlostdate
				  GROUP BY l.custid, l.productID) t
			GROUP BY t.custid, t.SportType
		END
		
		--Update Transfer3rdOthers attributes
		UPDATE #rptDepWinlostDetails 
		SET PartnerID = t.PartnerId,
			Transfer3rdOthers = t.Transfer3rdOthers,
			Transfer3rdOthers_In = t.Transfer3rdOthers_In,
			Transfer3rdOthers_Out = t.Transfer3rdOthers_Out
		FROM (SELECT b.custid,
					 p.PartnerId,
					 b.bettype, 
			         SUM(b.winlost-b.actual_stake) AS Transfer3rdOthers,
			         SUM(CASE WHEN (winlost-actual_stake) < 0 THEN -(winlost-actual_stake) ELSE 0 END) AS Transfer3rdOthers_In,
					 SUM(CASE WHEN (winlost-actual_stake) > 0 THEN -(winlost-actual_stake) ELSE 0 END) AS Transfer3rdOthers_Out
			  FROM bettrans b WITH (NOLOCK)
				   INNER JOIN @CasinoPartner p ON b.bettype IN (p.TransferId, p.CancelTransferId) 	  	
			  WHERE winlostdate = @Winlostdate 
					AND b.matchid = 0
			  GROUP BY b.custid, p.PartnerId, b.bettype) t
		WHERE #rptDepWinlostDetails.CustID = t.custid AND #rptDepWinlostDetails.Bettype = t.bettype
		
		/*--PREPARE DATA FOR rptDepWinlost--*/
		INSERT INTO #rptDepWinlost (CustID, Deposit, Withdrawal, Aff2MemTransfer, Bonus, Adjustment, TurnOver, OutStanding, Winloss, Transfer3rd
											, DrawGame, playercomm, Transfer3rdOthers, Comm_BetTrade, Comm_BetTrade_Full, WLBoughtTicket_BetTrade)
		SELECT custid,
			SUM(Deposit), --Deposit  
			SUM(Withdrawal),--Withdrawal  
			SUM(Aff2MemTransfer), --Aff2MemTransfer  
			SUM(Bonus),--Bonus  
			SUM(Adjustment),--Adjustment  
			SUM(Turnover),--Turnover
			SUM(Outstanding),--Outstanding 
			SUM(Winloss),--Winloss      
			SUM(Transfer3rd),--Transfer3rd   
			SUM(DrawGame),--DrawGame  
			SUM(Playercomm),--Playercomm 
			SUM(Transfer3rdOthers),--Transfer3rdOthers 	
			SUM(Comm_BetTrade),--Comm_BetTrade
			SUM(Comm_BetTrade_Full),--Comm_BetTrade_Full
			SUM(WLBoughtTicket_BetTrade)--WLBoughtTicket_BetTrade
		FROM #rptDepWinlostDetails
		WHERE Bettype NOT IN (913, 914)
		GROUP BY custid
		
		--Update BA attributes
		UPDATE #rptDepWinlost
		SET Turnover_BA = ISNULL(t.turnover_ba,0),
			Comm_BA = ISNULL(t.Comm_BA,0),
			AmountDueTo_BA = ISNULL(t.AmountDueTo_BA,0)
		FROM (SELECT b.custid,
					 SUM(b.stake) Turnover_BA,  
					 SUM(b.comm) AS Comm_BA,  
					 -SUM(b.winlost - b.actual_stake + b.awinlost + b.comm) AS AmountDueTo_BA    
			  FROM bettrans b WITH(NOLOCK)  
			  WHERE transid IN (			
									SELECT transid FROM DBLIC.bodb_licensee.dbo.LicenseeBATransaction_active WITH (NOLOCK)
									UNION ALL
									SELECT NULL --Force intermediate materialization
								)
			AND b.winlostdate = @Winlostdate  
			AND b.ruben = 1  
			AND b.statusID NOT IN(101, 102, 103)  
		GROUP BY b.custid) t
		WHERE #rptDepWinlost.CustID = t.CustID
		
		--Update BetTrade attribute
		UPDATE #rptDepWinlost 
		SET AmountDueTo_BetTrade = ISNULL(t.WLBeticket, 0) + WLBoughtTicket_BetTrade - Comm_BetTrade
		FROM (SELECT b.custid,
					 SUM(CASE WHEN b.bettype NOT IN (902,903) THEN b.winlost - b.actual_stake ELSE 0 END) AS WLBeticket --WL of bet ticket of bettrade
			  FROM dbo.bettrans b WITH (NOLOCK)
			  INNER JOIN dbo.f_GetBetTradeCustList('All') bt ON b.custid = bt.Custid
			  WHERE b.winlostdate = @Winlostdate
				    --AND (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999 OR b.bettype BETWEEN 1301 AND 1399)
					AND b.ruben = 1  
					AND b.statusID NOT IN(101, 102, 103)  
			  GROUP BY b.custid) t
		WHERE #rptDepWinlost.custid = t.custid
		
		--Delete redundant data
		DELETE FROM #rptDepWinlost  
		WHERE Deposit = 0 AND Withdrawal = 0 AND Aff2MemTransfer = 0 AND Bonus = 0 AND Adjustment = 0 AND TurnOver = 0 AND OutStanding = 0 AND Winloss = 0 
			  AND Transfer3rd = 0 AND DrawGame = 0 AND Turnover_BA = 0 AND Comm_BA = 0 AND AmountDueTo_BA = 0 AND playercomm = 0 AND Transfer3rdOthers = 0
			  AND Comm_BetTrade = 0 AND AmountDueTo_BetTrade = 0
 
		DELETE FROM #rptDepWinlostOutstanding
		WHERE TurnOver = 0 AND OutStanding = 0 AND BetCount = 0

		--Start update TurnOver and Outstanding for Keno, MicroGamingRNG, OneRNG, VoidBridge, AGCasino
		MERGE #rptDepWinlost AS TARGET
		USING (SELECT CustID, SUM(TurnOver), SUM(OutStanding) FROM #rptDepWinlostOutstanding GROUP BY CustID)
		   AS SOURCE (CustID, TurnOver, OutStanding)
			ON (TARGET.CustID = SOURCE.CustID)
		WHEN MATCHED THEN 
			 UPDATE SET TARGET.TurnOver = TARGET.TurnOver + SOURCE.TurnOver,
						TARGET.Outstanding = TARGET.Outstanding + SOURCE.Outstanding
		WHEN NOT MATCHED THEN	
			INSERT (CustID, TurnOver, OutStanding)
			VALUES (SOURCE.CustID, SOURCE.TurnOver, SOURCE.OutStanding);
		--End update TurnOver and Outstanding for Keno, MicroGamingRNG, OneRNG, VoidBridge, AGCasino
		/*--END PREPARE DATA FOR rptDepWinlost--*/
		
		/*--PREPARE DATA FOR rptDepWinlostByProduct--*/
		INSERT INTO #rptDepWinlostByProduct (CustID, SportType, turnover, drawTO, Winlost
			, playercomm, BetCount, OutStanding)
		SELECT CustID,
			   CASE				
					WHEN bettype IN (31,32,33,41,42,43) THEN 151--Horse Racing
					WHEN bettype BETWEEN 81 AND 120 THEN 161--Number Game 
					WHEN bettype IN (71,72,23002) THEN 251--Casino
					WHEN bettype = 1000 THEN 253--games
					WHEN bettype BETWEEN 1101 AND 1199 THEN 162--Live Casino
					WHEN bettype BETWEEN 1201 AND 1299 THEN 180--Virtual Sport
					WHEN bettype BETWEEN 1501 AND 1599 THEN 202--Keno
					WHEN bettype BETWEEN 2001 AND 2007 THEN 203--Live MicroGaming
					WHEN bettype BETWEEN 18000 AND 18006 THEN 204 --Colossus Bet
					WHEN bettype BETWEEN 2008 AND 2009 THEN 205--RNG MicroGaming
					WHEN bettype BETWEEN 4001 AND 7999 THEN 212--Voidbridge
					WHEN bettype = 901 THEN -2--BetTrade - Sold
					WHEN bettype = 902 THEN -3--BetTrade - Bought.
					WHEN bettype = 903 THEN -4--BetTrade - Commission
					WHEN bettype = 904 THEN -5--BetTrade - Winloss
					WHEN bettype = 911 THEN -6--Cash Out - Sold
					WHEN bettype = 912 THEN -7--Cash Out - Bought.
					WHEN bettype = 913 THEN -8--Cash Out - Commission
					WHEN bettype = 914 THEN -9--Cash Out - Winloss
					WHEN bettype BETWEEN 1800 AND 1899 THEN 250 -- AGC
					WHEN bettype BETWEEN 1700 AND 1799 THEN 255 -- GD
					WHEN bettype BETWEEN 1900 AND 1999 THEN 249 -- VG
					WHEN bettype BETWEEN 2101 AND 2199 THEN 208
					WHEN bettype BETWEEN 2201 AND 2299 THEN 209
					WHEN (bettype BETWEEN 2301 AND 2399 OR bettype BETWEEN 2901 AND 2999) THEN 210
					WHEN bettype BETWEEN 2401 AND 2499 THEN 211
					WHEN bettype BETWEEN 1011 AND 1020 THEN 219
					WHEN bettype BETWEEN 2701 AND 2799 THEN 190 -- Betradar VS
					WHEN bettype BETWEEN 1021 AND 1049 THEN 220 -- Lottery
				ELSE 0 END,--SportType
				SUM(TurnOver),--Turnover  
				SUM(DrawGame),--Draw game TO			
				SUM(Winloss),--Winloss      
				SUM(playercomm),--Playercomm      
				SUM(BetCount),--BetCount
				SUM(OutStanding)--Outstanding 
		FROM #rptDepWinlostDetails
		WHERE Bettype < 19999
			AND PartnerID = -1
		GROUP BY CustID, 
				 CASE
					WHEN bettype IN (31,32,33,41,42,43) THEN 151--Horse Racing
					WHEN bettype BETWEEN 81 AND 120 THEN 161--Number Game 
					WHEN bettype IN (71,72,23002) THEN 251--Casino
					WHEN bettype = 1000 THEN 253--games
					WHEN bettype BETWEEN 1101 AND 1199 THEN 162--Live Casino
					WHEN bettype BETWEEN 1201 AND 1299 THEN 180--Virtual Sport
					WHEN bettype BETWEEN 1501 AND 1599 THEN 202--Keno
					WHEN bettype BETWEEN 2001 AND 2007 THEN 203--Live MicroGaming
					WHEN bettype BETWEEN 18000 AND 18006 THEN 204 -- Colossus Bet
					WHEN bettype BETWEEN 2008 AND 2009 THEN 205--RNG MicroGaming
					WHEN bettype BETWEEN 4001 AND 7999 THEN 212--Voidbridge
					WHEN bettype = 901 THEN -2--BetTrade - Sold
					WHEN bettype = 902 THEN -3--BetTrade - Bought
					WHEN bettype = 903 THEN -4--BetTrade - Commission
					WHEN bettype = 904 THEN -5--BetTrade Winloss Sharing
					WHEN bettype = 911 THEN -6--Cash Out - Sold
					WHEN bettype = 912 THEN -7--Cash Out - Bought.
					WHEN bettype = 913 THEN -8--Cash Out - Commission
					WHEN bettype = 914 THEN -9--Cash Out - Winloss
					WHEN bettype BETWEEN 1800 AND 1899 THEN 250 -- AGC
					WHEN bettype BETWEEN 1700 AND 1799 THEN 255 -- GD
					WHEN bettype BETWEEN 1900 AND 1999 THEN 249 -- VG
					WHEN bettype BETWEEN 2101 AND 2199 THEN 208
					WHEN bettype BETWEEN 2201 AND 2299 THEN 209
					WHEN (bettype BETWEEN 2301 AND 2399 OR bettype BETWEEN 2901 AND 2999) THEN 210
					WHEN bettype BETWEEN 2401 AND 2499 THEN 211 -- Allbet
					WHEN bettype BETWEEN 1011 AND 1020 THEN 219
					WHEN bettype BETWEEN 2701 AND 2799 THEN 190 -- Betradar VS
					WHEN bettype BETWEEN 1021 AND 1049 THEN 220 -- Lottery
				ELSE 0 END
		--Start update TurnOver and Outstanding for Keno, MicroGamingRNG, OneRNG, VoidBridge, AGCasino
		MERGE #rptDepWinlostByProduct AS TARGET
		USING (SELECT CustID, SportType, TurnOver, OutStanding, BetCount FROM #rptDepWinlostOutstanding)
		   AS SOURCE (CustID, SportType, TurnOver, OutStanding, BetCount)
			ON (TARGET.CustID = SOURCE.CustID AND TARGET.SportType = SOURCE.SportType)
		WHEN MATCHED THEN 
			 UPDATE SET TARGET.TurnOver = TARGET.TurnOver + SOURCE.TurnOver,
						TARGET.Outstanding = TARGET.Outstanding + SOURCE.Outstanding,
						TARGET.BetCount = TARGET.BetCount + SOURCE.BetCount
		WHEN NOT MATCHED THEN	
			INSERT (CustID, SportType, TurnOver, OutStanding, BetCount)
			VALUES (SOURCE.CustID, SOURCE.SportType, SOURCE.TurnOver, SOURCE.OutStanding, SOURCE.BetCount);
		--End update TurnOver and Outstanding for Keno, MicroGamingRNG, OneRNG, VoidBridge, AGCasino
		/*--END PREPARE DATA FOR rptDepWinlostByProduct--*/
		
		/*--PREPARE DATA FOR rptDepWinlostTransfer3rdOthers--*/
		DECLARE @RefNoList AS TABLE (RefNo BIGINT)
		DECLARE @TransferData AS TABLE (CustId INT, PartnerID INT, TransferIn MONEY, TransferOut MONEY)
		
		INSERT INTO @RefNoList(RefNo)
		SELECT b.refno
		FROM dbo.bettrans b WITH (NOLOCK)
			INNER JOIN @CasinoPartner p ON b.bettype = p.CancelTransferId
			INNER JOIN dbo.CustInfo c WITH (NOLOCK) ON b.custid = c.custid
			INNER JOIN dbo.Dep_CustSuper s WITH(NOLOCK) ON s.custid = c.srecommend
		WHERE b.matchid = 0 AND b.winlostdate = @Winlostdate AND c.roleid = 1
		GROUP BY b.refno
		
		INSERT INTO @TransferData(CustId, PartnerId, TransferIn, TransferOut)
		SELECT b.CustId
		    , p.PartnerId
			, SUM(CASE WHEN (b.winlost-b.actual_stake) < 0 THEN -(b.winlost-b.actual_stake) ELSE 0 END)--TransferIn
			, SUM(CASE WHEN (b.winlost-b.actual_stake) > 0 THEN -(b.winlost-b.actual_stake) ELSE 0 END) --TransferOut
		FROM dbo.bettrans b WITH (NOLOCK)
			INNER JOIN @CasinoPartner p ON b.bettype IN (p.CancelTransferId, p.PartnerId)
		WHERE b.refno IN (SELECT RefNo FROM @RefNoList)
		GROUP BY b.custid, p.PartnerId
		
		INSERT INTO #rptDepWinlostTransfer3rdOthers(CustId, PartnerId, TransferAmount, TransferIn, TransferOut)
		SELECT t.CustId
			, t.PartnerId
			, SUM(t.Transfer3rdOthers)--TransferAmount
			, SUM(t.Transfer3rdOthers_In - ISNULL(d.TransferIn, 0))--TransferIn
			, SUM(t.Transfer3rdOthers_Out - ISNULL(d.TransferOut, 0))--TransferOut
		FROM #rptDepWinlostDetails t
		INNER JOIN dbo.customer c WITH (NOLOCK) ON t.custid = c.custid  
		INNER JOIN dbo.customer agent WITH (NOLOCK) ON c.recommend = agent.custid
		LEFT JOIN @TransferData d ON t.custid = d.CustId AND t.PartnerId = d.PartnerId
		WHERE t.PartnerId > -1
			  AND (c.username2 IS NOT NULL OR (c.username2 IS NULL AND agent.username NOT LIKE '%ACC%'))	
		GROUP BY t.CustId, t.PartnerId
		/*--END PREPARE DATA FOR rptDepWinlostTransfer3rdOthers--*/
		
		--4.Delete/Reinsert data of the input @Winlostdate
		DELETE FROM bodb_Report.dbo.rptDepWinlost_Trans WITH (ROWLOCK, UPDLOCK) WHERE Winlostdate = @Winlostdate
		
		--For rptDepWinlost
		INSERT INTO bodb_Report.dbo.rptDepWinlost_Trans(Winlostdate, CustID, SportType, PartnerID, Deposit, Withdrawal, Aff2MemTransfer, Bonus, Adjustment, Turnover
			, Outstanding, Winloss, Transfer3rd, DrawGame, Turnover_BA, Comm_BA, AmountDueTo_BA, playercomm, Transfer3rdOthers, Comm_BetTrade, Comm_BetTrade_Full
			, AmountDueTo_BetTrade
			)
			SELECT @Winlostdate, CustID, -1, -1, Deposit, Withdrawal, Aff2MemTransfer, Bonus, Adjustment, TurnOver
			, OutStanding, Winloss, Transfer3rd, DrawGame, Turnover_BA, Comm_BA, AmountDueTo_BA, playercomm, Transfer3rdOthers, Comm_BetTrade, Comm_BetTrade_Full
			, AmountDueTo_BetTrade
			FROM #rptDepWinlost	
		SELECT @NumberofCus = @@ROWCOUNT
		
		--For rptDepWinlostByProduct
		INSERT INTO bodb_Report.dbo.rptDepWinlost_Trans(Winlostdate, CustID, SportType, PartnerID, Turnover, DrawGame, Winloss, playercomm, BetCount, Outstanding)
			SELECT @Winlostdate, CustID, SportType, -1, turnover, drawTO, Winlost, playercomm, BetCount, OutStanding
			FROM #rptDepWinlostByProduct
			
		--For rptDepWinlost_Transfer3rdOthers
		INSERT INTO bodb_Report.dbo.rptDepWinlost_Trans(Winlostdate, CustID, SportType, PartnerID, TransferAmount, TransferIn, TransferOut)
			SELECT @Winlostdate, CustID, -1, PartnerID, TransferAmount, TransferIn, TransferOut
			FROM #rptDepWinlostTransfer3rdOthers
		
		SELECT @isSuccessful = 1, @ErrMsg = ''
		
		--5.Update Log
		SELECT @LogDesc = @LogDesc + CONVERT(VARCHAR(20),@Winlostdate) + ' (No. of Customer affected: ' + CONVERT(VARCHAR(20), @NumberofCus) + '); Type: realtime'
		
		UPDATE bodb_Report.dbo.rptDepWinlost_Log WITH (ROWLOCK, UPDLOCK) 
		SET EndTime = CURRENT_TIMESTAMP, LogDesc = @LogDesc, StatusID = @isSuccessful
		WHERE LogID = @LogID
		
	END TRY
	BEGIN CATCH
		SELECT @isSuccessful = 0, @ErrMsg = LEFT(ERROR_MESSAGE(),1000)
		SELECT @LogDesc = @LogDesc + '; Type: realtime' + '; ErrMsg: ' + @ErrMsg
		UPDATE bodb_Report.dbo.rptDepWinlost_Log WITH (ROWLOCK, UPDLOCK) 
		SET EndTime = CURRENT_TIMESTAMP, LogDesc = @LogDesc, StatusID = @isSuccessful
		WHERE LogID = @LogID	
		PRINT 'EXEC TASK_RealtimeSummaryDepData, Winlostdate = ' + CONVERT(VARCHAR(20),@Winlostdate,120) + ', ErrMsg: ' + ERROR_MESSAGE()
	END CATCH
	
	DROP TABLE #rptDepWinlostDetails 
	DROP TABLE #rptDepWinlost
	DROP TABLE #rptDepWinlostByProduct
	DROP TABLE #rptDepWinlostTransfer3rdOthers
	DROP TABLE #rptDepWinlostOutstanding
END
GO