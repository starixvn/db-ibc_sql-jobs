/*<info serverAlias="DBACC-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[TASK_RealtimeSummaryDepData_Bettrans14]
	@Winlostdate DATE,
	@isSuccessful BIT = 0 OUTPUT
AS
	/*
		Created By: Francis
		Created Date: 20160815
		Task: Summarize data for table rptDepWinlost_Trans for the input @Winlostdate from bettrans14 		
		DB: DBACC.bodb02
		Revisions:
		- 20160924@Francis: Enhance performance when querying data from bettrans14
		- 20161004@Francis: Add Error Message to Log when issue happens
		- 20161013@Jim : LRF - Implement Colossus Bets [Redmine: #63785]
		- 20161115@Jim: LRF - Integrate new product Fishing World [RedmineID : #66737]
		- 20170322@Paul: Implement Cash Out [RedmineID :#71727]
		- 20170712@Harper: Implement new Product Betradar VS [Redmine: #78241]
		- 20170619@Harper: LRF - Integrate Lottery [RedmineID: #79997]
		- 20170814@Harper: One RNG - Offer New Tablet Games [RedmineID: #78424]
		- 20171225@Sophia: Integrate CitiBet Exchange Products [Redmine: #86640]
		- 20180212@Harper: Remove LC from product list [Redmine: #85965]
		- 20180409@Joseph: Implement new sports for VS2: BasketBall - Virual Soccer World Cup [Redmine: #90881]
		- 20180412@Harper: Integrate Bonus wallet [RedmineID: 91740]
		- 20180418@Joseph: Integrate new product PP [Redmine: #92318]
		- 20180814@Joseph: Remove Racing [RedmineID: #99378]
		- 20181031@Percy: Remove linked-server DBLIC [RedmineID: #103660]
		- 20181210@Joseph: Integrate Happy 5 for NumberGame [RedmineID: #103698]
		- 20190321@Joseph: Remove Microgaming LC + RNG [RedmineID: #107704]
		- 20190710@Amanda: Integrate Card Club [RedmineID: #115449]
		- 20190718@Amanda: Add rebate bonus ticket [RedmineID: #115445]

		Input Params:
		- @Winlostdate: The input Winlostdate to be summarized	
		- @isSuccessful: -1: Data of the whole day have been summarized completely
						 -0: Data of the whole day have not been summarized completely
	*/
BEGIN
	SET NOCOUNT ON
	--1.Set low deadlock priority
	SET @isSuccessful = 0
	
	SET DEADLOCK_PRIORITY LOW
	
	DECLARE @CurrentDate DATE,
			@CurrentHour TINYINT,
			@LogDesc VARCHAR(8000) = 'Date generated: ',
			@LogID BIGINT,
			@NumberofCus INT= 0,
			@MoveBetDay SMALLDATETIME,
			@ErrMsg VARCHAR(1000) = ''
	
	SELECT @CurrentDate = CONVERT(DATE,CURRENT_TIMESTAMP,112)
	SELECT @CurrentHour = DATEPART(HOUR,CURRENT_TIMESTAMP)
	
	SELECT @MoveBetDay = MAX(eventdate)
	FROM dbo.match14 WITH(NOLOCK)
			
	IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.bettrans14 WITH (NOLOCK) WHERE winlostdate = @Winlostdate AND bettype < 19999 AND bettype != 18000)
	   OR @WinlostDate > @MoveBetDay
		BEGIN
			PRINT 'EXEC TASK_RealtimeSummaryDepData_Bettrans14: There is no data in bettrans14 to summarize or input @Winlostdate is greater than MoveBet day ==> RETURN'
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

	-- For Bonus
	DECLARE @BonusList TABLE (BonusType TINYINT, BonusBettype INT, AdjustmentBettype INT)
	INSERT INTO @BonusList(BonusType, BonusBettype, AdjustmentBettype)
	VALUES( 1, 22200, 22201) -- Bonus Wallet
	
	CREATE TABLE #rptDepWinlostDetails (CustID INT, PartnerID INT DEFAULT(-1), Bettype INT, Deposit MONEY DEFAULT(0), Withdrawal MONEY DEFAULT(0)
			, Aff2MemTransfer MONEY DEFAULT(0), Bonus MONEY DEFAULT(0), Adjustment MONEY DEFAULT(0), TurnOver MONEY DEFAULT(0), OutStanding MONEY DEFAULT(0)
			, Winloss MONEY DEFAULT(0), Transfer3rd MONEY DEFAULT(0), DrawGame MONEY DEFAULT(0), Turnover_BA MONEY DEFAULT(0), Comm_BA MONEY DEFAULT(0)
			, AmountDueTo_BA MONEY DEFAULT(0), playercomm MONEY DEFAULT(0), Transfer3rdOthers MONEY DEFAULT(0), Transfer3rdOthers_In MONEY DEFAULT(0)
			, Transfer3rdOthers_Out MONEY DEFAULT(0), Comm_BetTrade MONEY DEFAULT(0), Comm_BetTrade_Full MONEY DEFAULT(0)
			, WLBoughtTicket_BetTrade MONEY DEFAULT(0), AmountDueTo_BetTrade MONEY DEFAULT(0), BetCount INT DEFAULT(0)
			, BonusWallet MONEY DEFAULT(0), AdjBonusWallet MONEY DEFAULT(0)
			UNIQUE CLUSTERED (CustID, PartnerID, Bettype)
			)
	
	CREATE TABLE #rptDepWinlost (CustID INT, Deposit MONEY DEFAULT(0), Withdrawal MONEY DEFAULT(0), Aff2MemTransfer MONEY DEFAULT(0)
			, Bonus MONEY DEFAULT(0), Adjustment MONEY DEFAULT(0), TurnOver MONEY DEFAULT(0), OutStanding MONEY DEFAULT(0), Winloss MONEY DEFAULT(0), Transfer3rd MONEY DEFAULT(0)
			, DrawGame MONEY DEFAULT(0), Turnover_BA MONEY DEFAULT(0), Comm_BA MONEY DEFAULT(0), AmountDueTo_BA MONEY DEFAULT(0), playercomm MONEY DEFAULT(0)
			, Transfer3rdOthers MONEY DEFAULT(0), Comm_BetTrade MONEY DEFAULT(0), WLBoughtTicket_BetTrade MONEY DEFAULT(0), AmountDueTo_BetTrade MONEY DEFAULT(0)
			, BonusWallet MONEY DEFAULT(0), AdjBonusWallet MONEY DEFAULT(0)
			UNIQUE CLUSTERED (CustID)
			)
			
	CREATE TABLE #BATrans(TransID BIGINT UNIQUE CLUSTERED (TransID))
	
	CREATE TABLE #DepCustID (CustID INT UNIQUE CLUSTERED (CustID))
						
	CREATE TABLE #rptDepWinlostTransfer3rdOthers (CustID INT, PartnerID INT, TransferAmount MONEY DEFAULT(0), TransferIn MONEY DEFAULT(0), TransferOut MONEY DEFAULT(0)
			UNIQUE CLUSTERED (CustID, PartnerID)
			)
	
	CREATE TABLE #rptDepWinlostBonusWallet (CustID INT, BonusType TINYINT DEFAULT(1), Bonus MONEY DEFAULT(0), Adjustment MONEY DEFAULT(0)
			UNIQUE CLUSTERED (CustID, BonusType)
			)

	BEGIN TRY

		--3.Prepare staging data for table rptDepWinlost_Trans
		--Insert Details for rptDepWinlost/rptDepWinlostByProduct/rptDepWinlostTransfer3rdOthers
		INSERT INTO #rptDepWinlostDetails (CustID, BetType, Deposit, Withdrawal, Aff2MemTransfer, Bonus, Adjustment, Transfer3rd, BonusWallet, AdjBonusWallet)
		SELECT b.custid, 
			b.bettype,
			SUM(CASE WHEN b.bettype = 22001 THEN b.winlost-b.actual_stake ELSE 0 END), --Deposit
			-SUM(CASE WHEN b.bettype IN (22002,22003) THEN b.winlost-b.actual_stake ELSE 0 END),--Withdrawal
			SUM(CASE WHEN b.bettype = 21006 THEN b.winlost-b.actual_stake ELSE 0 END), --Aff2MemTransfer
			SUM(CASE WHEN b.bettype IN (22004, 22202) THEN b.winlost-b.actual_stake ELSE 0 END),--Bonus
			SUM(CASE WHEN b.bettype IN (21001, 21002, 21003, 21004, 21005, 22005, 22203) THEN b.winlost-b.actual_stake ELSE 0 END), --Adjustment
			SUM(CASE WHEN b.bettype IN (22006,22007) THEN b.winlost-b.actual_stake ELSE 0 END),--Transfer3rd
			SUM(CASE WHEN b.bettype = 22200 THEN b.winlost-b.actual_stake ELSE 0 END), -- Bonus Wallet
			SUM(CASE WHEN b.bettype = 22201 THEN b.winlost-b.actual_stake ELSE 0 END) -- AdjBonusWallet
		FROM dbo.bettrans b WITH (NOLOCK)
			INNER JOIN dbo.Dep_CustSuper d WITH (NOLOCK) ON b.srecommend = d.custid
			INNER JOIN dbo.CustInfo c WITH (NOLOCK) ON b.custid = c.custid
		WHERE b.winlostdate = @Winlostdate
			  AND b.matchid >= 0
			  AND c.roleid = 1
		GROUP BY b.custid, b.bettype
		OPTION (RECOMPILE, MAXDOP 8)
		
		INSERT INTO #DepCustID (CustID)
		SELECT CustID
		FROM #rptDepWinlostDetails
		WHERE PartnerID = -1
		GROUP BY CustID
		
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
		
		
		/*--Force seek predicate on custid for bettrans14 part
		DECLARE @n INT = 2147483647
		*/
		
		INSERT INTO #rptDepWinlostDetails (CustID, BetType, TurnOver, OutStanding, Winloss, DrawGame, playercomm, Comm_BetTrade, WLBoughtTicket_BetTrade, BetCount)
			SELECT
				b.custid,
				CASE				
					WHEN b.bettype BETWEEN 81 AND 120 THEN 161--Number Game 
					WHEN b.bettype BETWEEN 8101 AND 8120 THEN 164 --Number Game: Happy 5
					WHEN b.bettype IN (71,72,23002) THEN 251--Casino
					WHEN b.bettype = 1000 THEN 253--games
					WHEN b.bettype BETWEEN 1201 AND 1299 THEN 180--Virtual Sport
					WHEN b.bettype BETWEEN 1501 AND 1599 THEN 202--Keno
					WHEN bettype BETWEEN 18000 AND 18006 THEN 204 --Colossus Bet
					WHEN b.bettype BETWEEN 4001 AND 4100 THEN 212--Voidbridge
					WHEN b.bettype = 901 THEN -2--BetTrade - Sold
					WHEN b.bettype = 902 THEN -3--BetTrade - Bought.
					WHEN b.bettype = 903 THEN -4--BetTrade - Commission
					WHEN b.bettype = 904 THEN -5--BetTrade - Winloss
					WHEN b.bettype = 911 THEN -6--Cash Out - Sold
					WHEN b.bettype = 912 THEN -7--Cash Out - Bought.
					WHEN b.bettype = 913 THEN -8--Cash Out - Commission
					WHEN b.bettype = 914 THEN -9--Cash Out - Winloss
					WHEN b.bettype BETWEEN 1800 AND 1899 THEN 250 -- AGC
					WHEN b.bettype BETWEEN 1700 AND 1799 THEN 255 -- GD
					WHEN b.bettype = 1900 THEN 249 -- VG
					WHEN b.bettype BETWEEN 2101 AND 2199 THEN 208
					WHEN b.bettype BETWEEN 2201 AND 2299 THEN 209
					WHEN (b.bettype BETWEEN 2301 AND 2399 OR b.bettype BETWEEN 2901 AND 2999) THEN 210
					WHEN b.bettype BETWEEN 2401 AND 2499 THEN 211 -- Allbet
					WHEN b.bettype BETWEEN 1011 AND 1020 THEN 219
					WHEN b.bettype BETWEEN 2701 AND 2799 THEN 190 -- Betradar VS
					WHEN b.bettype BETWEEN 2800 AND 2829 THEN 193 -- Betradar VS: Virtual Basketball
					WHEN b.bettype BETWEEN 1021 AND 1049 THEN 220 -- Lottery
					WHEN b.bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
					WHEN b.bettype BETWEEN 4101 AND 4300 THEN 248 -- PP
					WHEN b.bettype BETWEEN 1901 AND 1999 THEN 165 -- CC
				ELSE 0 END,--SportType
				SUM(CASE WHEN b.statusID NOT IN(101, 102, 103) THEN b.stake ELSE 0 END),--Turnover
				SUM(CASE WHEN b.ruben=0 THEN b.actual_stake ELSE 0 END),--Outstanding
				SUM(CASE WHEN b.ruben=1 THEN b.winlost-b.actual_stake ELSE 0 END),--Winloss				
				SUM(CASE WHEN b.statusID = 111 THEN b.stake ELSE 0 END),--DrawGame		
				SUM(CASE WHEN b.ruben=1 THEN b.playercomm ELSE 0 END),--Playercomm
				SUM(CASE WHEN b.bettype = 903 AND b.ruben = 1 AND b.statusID NOT IN (101, 102, 103) THEN b.awinlost ELSE 0 END),--Comm_BetTrade
				SUM(CASE WHEN b.bettype = 902 AND b.ruben = 1 AND b.statusID NOT IN (101, 102, 103) THEN b.winlost - b.actual_stake ELSE 0 END),--WLBoughtTicket_BetTrade
				SUM(CASE WHEN b.bettype < 19999 AND b.StatusID NOT IN (101, 102, 103) THEN 1 ELSE 0 END) --BetCount
			FROM bettrans14 b WITH (NOLOCK) 
				INNER JOIN #DepCustID d on b.custid = d.CustID
			/*
				FROM (SELECT TOP (@n) custid FROM #DepCustID) d
				INNER JOIN bettrans14 b WITH (NOLOCK) on b.custid = d.CustID 
				WHERE b.winlostdate = @Winlostdate
				GROUP BY b.custid, b.bettype
				OPTION(OPTIMIZE FOR (@n = 1)) --Trick SQL optimizer to use nested loop
			*/	
			WHERE b.winlostdate = @Winlostdate
				AND b.bettype < 19999
			GROUP BY b.custid,
				CASE				
					WHEN b.bettype BETWEEN 81 AND 120 THEN 161--Number Game 
					WHEN b.bettype BETWEEN 8101 AND 8120 THEN 164 --Number Game: Happy 5
					WHEN b.bettype IN (71,72,23002) THEN 251--Casino
					WHEN b.bettype = 1000 THEN 253--games
					WHEN b.bettype BETWEEN 1201 AND 1299 THEN 180--Virtual Sport
					WHEN b.bettype BETWEEN 1501 AND 1599 THEN 202--Keno
					WHEN bettype BETWEEN 18000 AND 18006 THEN 204 --Colossus Bet
					WHEN b.bettype BETWEEN 4001 AND 4100 THEN 212--Voidbridge
					WHEN b.bettype = 901 THEN -2--BetTrade - Sold
					WHEN b.bettype = 902 THEN -3--BetTrade - Bought.
					WHEN b.bettype = 903 THEN -4--BetTrade - Commission
					WHEN b.bettype = 904 THEN -5--BetTrade - Winloss
					WHEN b.bettype = 911 THEN -6--Cash Out - Sold
					WHEN b.bettype = 912 THEN -7--Cash Out - Bought.
					WHEN b.bettype = 913 THEN -8--Cash Out - Commission
					WHEN b.bettype = 914 THEN -9--Cash Out - Winloss
					WHEN b.bettype BETWEEN 1800 AND 1899 THEN 250 -- AGC
					WHEN b.bettype BETWEEN 1700 AND 1799 THEN 255 -- GD
					WHEN b.bettype = 1900 THEN 249 -- VG
					WHEN b.bettype BETWEEN 2101 AND 2199 THEN 208
					WHEN b.bettype BETWEEN 2201 AND 2299 THEN 209
					WHEN (b.bettype BETWEEN 2301 AND 2399 OR b.bettype BETWEEN 2901 AND 2999) THEN 210
					WHEN b.bettype BETWEEN 2401 AND 2499 THEN 211 -- Allbet
					WHEN b.bettype BETWEEN 1011 AND 1020 THEN 219
					WHEN b.bettype BETWEEN 2701 AND 2799 THEN 190 -- Betradar VS
					WHEN b.bettype BETWEEN 2800 AND 2829 THEN 193 -- Betradar VS: Virtual Basketball
					WHEN b.bettype BETWEEN 1021 AND 1049 THEN 220 -- Lottery
					WHEN b.bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
					WHEN b.bettype BETWEEN 4101 AND 4300 THEN 248 -- PP
					WHEN b.bettype BETWEEN 1901 AND 1999 THEN 165 -- CC
				ELSE 0 END--SportType
			OPTION (RECOMPILE, MAXDOP 8)
			
		/*--PREPARE DATA FOR rptDepWinlost--*/
		INSERT INTO #rptDepWinlost (CustID, Deposit, Withdrawal, Aff2MemTransfer, Bonus, Adjustment, TurnOver, OutStanding, Winloss, Transfer3rd
											, DrawGame, playercomm, Transfer3rdOthers, Comm_BetTrade, WLBoughtTicket_BetTrade, BonusWallet, AdjBonusWallet)
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
			SUM(WLBoughtTicket_BetTrade),--WLBoughtTicket_BetTrade
			SUM(BonusWallet), -- Bonus Wallet
			SUM(AdjBonusWallet) -- Adjustment Bonus Wallet
		FROM #rptDepWinlostDetails
		WHERE Bettype NOT IN (-8, -9)
		GROUP BY custid
		
		--Update BA attributes
		INSERT INTO #BATrans (transid)
		SELECT transid
		FROM bodb_Licensee.dbo.LicenseeBATransaction_bk WITH (NOLOCK) WHERE WinlostDate = @Winlostdate
		
		UPDATE #rptDepWinlost
		SET Turnover_BA = ISNULL(t.turnover_ba,0),
			Comm_BA = ISNULL(t.Comm_BA,0),
			AmountDueTo_BA = ISNULL(t.AmountDueTo_BA,0)
		FROM (SELECT b.custid,
					 SUM(b.stake) Turnover_BA,  
					 SUM(b.comm) AS Comm_BA,  
					 -SUM(b.winlost - b.actual_stake + b.awinlost + b.comm) AS AmountDueTo_BA    
			  FROM bettrans14 b WITH(NOLOCK)  
			  WHERE transid IN (SELECT transid FROM #BATrans)
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
			  FROM dbo.bettrans14 b WITH (NOLOCK)
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
			  AND Comm_BetTrade = 0 AND AmountDueTo_BetTrade = 0 AND BonusWallet = 0 AND AdjBonusWallet = 0
		/*--END PREPARE DATA FOR rptDepWinlost--*/
		
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
		
		/*--PREPARE DATA FOR rptDepWinlostBonusWallet--*/
		INSERT INTO #rptDepWinlostBonusWallet(CustID, BonusType, Bonus, Adjustment)		
		SELECT t.CustId
			, d.BonusType			
			, SUM(ISNULL(t.BonusWallet, 0)) -- Bonus value of Bonus Wallet
			, SUM(ISNULL(t.AdjBonusWallet, 0))-- Adjustment value of Bonus Wallet
		FROM #rptDepWinlostDetails t
			INNER JOIN @BonusList d ON t.Bettype IN (d.BonusBettype, d.AdjustmentBettype)			  
		GROUP BY t.CustId, d.BonusType

		/*--END PREPARE DATA FOR rptDepWinlostBonusWallet--*/

		--4.Delete/Reinsert data of the input @Winlostdate
		DELETE FROM bodb_Report.dbo.rptDepWinlost_Trans WITH (ROWLOCK, UPDLOCK) WHERE Winlostdate = @Winlostdate
		DELETE FROM bodb_Report.dbo.rptDepWinlost_BonusWallet WITH (ROWLOCK, UPDLOCK) WHERE Winlostdate = @Winlostdate

		--For rptDepWinlost
		INSERT INTO bodb_Report.dbo.rptDepWinlost_Trans(Winlostdate, CustID, SportType, PartnerID, Deposit, Withdrawal, Aff2MemTransfer, Bonus, Adjustment, Turnover
			, Outstanding, Winloss, Transfer3rd, DrawGame, Turnover_BA, Comm_BA, AmountDueTo_BA, playercomm, Transfer3rdOthers, Comm_BetTrade, Comm_BetTrade_Full
			, AmountDueTo_BetTrade
			)
			SELECT @Winlostdate, CustID, -1, -1, Deposit, Withdrawal, Aff2MemTransfer, Bonus, Adjustment, TurnOver
			, OutStanding, Winloss, Transfer3rd, DrawGame, Turnover_BA, Comm_BA, AmountDueTo_BA, playercomm, Transfer3rdOthers, Comm_BetTrade, 0
			, AmountDueTo_BetTrade
			FROM #rptDepWinlost	
		SELECT @NumberofCus = @@ROWCOUNT
		
		--For rptDepWinlostByProduct
		INSERT INTO bodb_Report.dbo.rptDepWinlost_Trans(Winlostdate, CustID, SportType, PartnerID, Turnover, DrawGame, Winloss, playercomm, BetCount, Outstanding)
			SELECT @Winlostdate, CustID, Bettype, -1, TurnOver, DrawGame, Winloss, playercomm, BetCount, OutStanding
			FROM #rptDepWinlostDetails
			WHERE Bettype < 19999 --Only get SportType of bet ticket
				AND PartnerID = -1
			
		--For rptDepWinlost_Transfer3rdOthers
		INSERT INTO bodb_Report.dbo.rptDepWinlost_Trans(Winlostdate, CustID, SportType, PartnerID, TransferAmount, TransferIn, TransferOut)
			SELECT @Winlostdate, CustID, -1, PartnerID, TransferAmount, TransferIn, TransferOut
			FROM #rptDepWinlostTransfer3rdOthers

		--For rptDepWinlost_BonusWallet
		INSERT INTO bodb_Report.dbo.rptDepWinlost_BonusWallet(Winlostdate, CustID, BonusType, Bonus, Adjustment)
		SELECT @Winlostdate, CustID, BonusType, Bonus, Adjustment
		FROM #rptDepWinlostBonusWallet
		
		SELECT @isSuccessful = 1, @ErrMsg = ''
		
		--5.Update Log
		SELECT @LogDesc = @LogDesc + CONVERT(VARCHAR(20),@Winlostdate) + ' (No. of Customer affected: ' + CONVERT(VARCHAR(20), @NumberofCus) + '); Type: realtime'
		
		UPDATE bodb_Report.dbo.rptDepWinlost_Log WITH (ROWLOCK, UPDLOCK) 
		SET ENDTime = CURRENT_TIMESTAMP, LogDesc = @LogDesc, StatusID = @isSuccessful
		WHERE LogID = @LogID
		
	END TRY
	BEGIN CATCH
		SELECT @isSuccessful = 0, @ErrMsg = LEFT(ERROR_MESSAGE(),1000)
		SELECT @LogDesc = @LogDesc + '; Type: realtime' + '; ErrMsg: ' + @ErrMsg
		UPDATE bodb_Report.dbo.rptDepWinlost_Log WITH (ROWLOCK, UPDLOCK) 
		SET ENDTime = CURRENT_TIMESTAMP, LogDesc = @LogDesc, StatusID = @isSuccessful
		WHERE LogID = @LogID	
		PRINT 'EXEC TASK_RealtimeSummaryDepData_Bettrans14, Winlostdate = ' + CONVERT(VARCHAR(20),@Winlostdate,120) + ', ErrMsg: ' + ERROR_MESSAGE()
	END CATCH
	
	DROP TABLE #rptDepWinlostDetails
	DROP TABLE #rptDepWinlost 
	DROP TABLE #rptDepWinlostTransfer3rdOthers
	DROP TABLE #rptDepWinlostBonusWallet
	DROP TABLE #BATrans
	DROP TABLE #DepCustID
END
GO