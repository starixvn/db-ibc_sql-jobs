/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_LicenseeReport]
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

/****** Object:  Stored Procedure dbo.Task_PrepareStaging    Script Date: 11/18/2016 5:30:32 PM ******/
ALTER PROCEDURE [dbo].[Task_PrepareStaging]  
    @datefrom smalldatetime=null
    ,@dateto smalldatetime=null
	,@ErrorMsg VARCHAR(MAX) = '' OUTPUT
	,@ProductCodes VARCHAR(1000) = ''
WITH RECOMPILE
AS  
/*
Created: 
Task: 
DB: DB052.bodb_LicenseeReport

Revisions:
    -20120423@Jim: Add more information for BARM agent 
    -20120613@Don: Fixed bug 'custid=0'
    -20150127@Don: Expand bet type ranges for Sportbook when processing BA
	-20150324@Jim: exclude waiting ticket
	-20150623@Patrick: Support BetTrade
	-20150003@Patrick: #42910 (Exclude ticket 901 for BA ticket)
	-20150929@Patrick: Revise code of BetTrade
	-20160118@Patrick: Hotfix: #51053 for bettrade - turn off BA for ticket 901
	-20160318@Victor:  Support Colossus bet - [Redmine: #52575]
	-20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
	-20160727@Jim: LRF - Commercial terms changed for Bet Trade [Redmine: #61342]
	-20160913@Jim: LRF - Implement Colossus Bets [Redmine: #63785 :fix refno issue]
	-20161121@Sophia: Correct formula CashOutAmount,WinPrizeAmount value [RedmineID : #67473]
	-20161205@Jim: LA - GD commercial terms changed for credit sites [RedmineID #67310]
	-20170323@Harper: LA - Implement Cashout Product [Redmine: #73310]
	-20170525@Paul: Check IsStagingBettrans flag before staging bettrans; insert sporttype, eventdate into staging match table [Redmine: #72914]
	-20170619@Harper: LA - Edit formula when cout CO ticket [Redmine: #78085]
	-20180316@Harper: LA - Colossus Bets Free Play Integration [RedmineID: #89768]
	-20180910@Bruce: LA - WL report for Poker Games & Bullfighting [#98487]
	-20181107@Patrick: DB052 Indexes Revolution [Redmine: #103572]
	-20181226@bruce: Implement E-sport 2 [Redmine: #105723]
	-20190306@Parsons: Implement BetBuilder [Redmine: #108995]
	-20190819@Parsons: Provide House Turnover In NG WL Report [Redmine: #117674]

Param's Explanation:
	EXEC Task_PrepareStaging '2018-02-01', '2018-02-28'
*/
BEGIN
	SET NOCOUNT ON;

	UPDATE bodb02.dbo.SystemSettings WITH(ROWLOCK, UPDLOCK)
	SET VValue = 1
	WHERE VName = 'IsStagingBettrans'
		AND VValue = 0

	IF @@ROWCOUNT = 0
	BEGIN
		SET @ErrorMsg = 'Another task is using staging bettrans';

		RAISERROR(@ErrorMsg, 16, 1)

		RETURN;
	END

	DECLARE @today datetime, @thedaybefore datetime
	SELECT @today=@dateto, @thedaybefore=@datefrom
	
    IF (NOT (@today IS NULL OR @thedaybefore IS NULL))
        SELECT @today=CONVERT(varchar(10),DATEADD(day,1,@today),120), @thedaybefore=CONVERT(varchar(10),@thedaybefore,120)
    ELSE
        SELECT @today=CONVERT(varchar(10),current_timestamp,120), @thedaybefore=DATEADD(day,-3,@today)
    
	---------PROCESS OUTRIGHT DATA--------------------------------------------------------------------------------------------  
	TRUNCATE TABLE dbo.outright  
	
    INSERT INTO dbo.outright(matchid, leagueid)
	    SELECT orid AS matchid, leagueid
        FROM bodb02.dbo.outright (NOLOCK)
        WHERE eventdate>=@thedaybefore AND eventdate<@today
        UNION ALL
        SELECT orid AS matchid, leagueid
        FROM bodb02.dbo.outright14 (NOLOCK)
        WHERE eventdate>=@thedaybefore AND eventdate<@today

	---------PROCESS MATCH DATA--------------------------------------------------------------------------------------------  
	TRUNCATE TABLE dbo.match  
	
    INSERT INTO dbo.match(matchid, leagueid, sporttype, eventdate)
	    SELECT matchid, leagueid, sporttype, eventdate
        FROM bodb02.dbo.match (NOLOCK)
        WHERE eventdate>=@thedaybefore AND eventdate<@today
        UNION ALL
        SELECT matchid, leagueid, sporttype, eventdate
        FROM bodb02.dbo.match14 (NOLOCK)
        WHERE eventdate>=@thedaybefore AND eventdate<@today
	  
	---------PROCESS BETTRANS DATA--------------------------------------------------------------------------------------------  
	TRUNCATE TABLE dbo.[bettrans]  
	
	DECLARE @__matchIds TABLE (matchid int PRIMARY KEY)
    
    --CREATE TABLE #Customer (t_custid int PRIMARY KEY)
	CREATE TABLE #BetTradeCust (custid int PRIMARY KEY)
	CREATE TABLE #CashoutCust (CustId INT PRIMARY KEY)

	INSERT INTO #BetTradeCust(CustId)
	SELECT CustId FROM bodb02.dbo.f_GetBetTradeCustList('ALL')

	INSERT INTO #CashoutCust(CustId)
	SELECT CustId FROM bodb02.dbo.f_GetCashoutCustList('ALL', 14) -- 14: VendorID of Cashout
    
    DECLARE @count int,@movebetdate smalldatetime,@tmpDate smalldatetime
	SELECT @count=DATEDIFF(DAY,@thedaybefore,@today) - 1
	SELECT @movebetdate=MAX(winlostdate) FROM bodb02.dbo.bettrans14 (NOLOCK)
	
	DECLARE @BettypeProductMapping AS TABLE(Bettype INT, ProductID INT)
	INSERT INTO @BettypeProductMapping (Bettype, ProductID)
		SELECT Bettype, ProductId
			FROM bodb_licensee.dbo.LA_f_BettypeProductMapping(0, @ProductCodes)
		
	WHILE (@count>=0)
	BEGIN
		SELECT @tmpDate=DATEADD(DAY,@count,@thedaybefore)
		
		IF (@tmpDate > @movebetdate)
		BEGIN
			--Copy LIVE data (bettrans) 
			DELETE @__matchIds
		
		    INSERT INTO @__matchIds(matchid)
            SELECT matchid FROM bodb02.dbo.bettrans (NOLOCK) WHERE winlostdate=@tmpDate AND bettype<19000 GROUP BY matchid
            
			INSERT INTO dbo.bettrans
			    ([transid]
                ,winlostdate
                ,liveindicator
                ,bettype
                ,[custid]
                ,[stake]
                ,actual_stake
                ,[winlost],[awinlost],[mwinlost],swinlost
                ,acomm,scomm,playercomm,comm
                ,matchid
                ,[status]
                ,[srecommend]
                ,currency
                ,recommend,mrecommend
                ,transdate
                ,statusid
                ,virtualrate
                ,discount
                ,tpositiontaking
                ,customercategory
				,isBA
				,refno
				,oddsspread
				,ExtraInfo
				,betdaqid
				,TicketType)
			SELECT 
			    b.transid,
	            b.winlostdate,
	            b.liveindicator,
	            b.bettype,
	            b.custid,
	            ABS(b.stake) stake,
	            b.actual_stake,
	            b.winlost,b.awinlost,b.mwinlost,b.swinlost,
	            b.acomm, b.scomm, b.playercomm, b.comm,
	            b.matchid,
	            CASE WHEN (b.bettype IN (1, 3, 7, 8, 17, 18, 124, 125) AND ABS(b.modds) = 0.25 AND [status] IN('WON', 'LOSE')) OR (b.bettype IN (33,43) AND [status] <> 'refund' AND b.liveawayscore=0) THEN 'HALF ' ELSE '' END + b.status AS [status],
                b.srecommend, 
                b.currency, 
                b.recommend,b.mrecommend,
                b.transdate,
                b.statusid,
                b.virtualrate,
                b.discount,
                b.tpositiontaking,
                CASE WHEN b.recommend=52466 THEN 27 --8RM
					 WHEN b.recommend=5707545 THEN 28 	--BARM
					 WHEN b.bettype = 901 AND b.recommend NOT IN (52466,5707545) THEN CASE WHEN b.transid2 = 0 THEN 1001 ELSE 1002 END --bettrade
					 WHEN b.bettype = 911 AND b.recommend NOT IN (52466,5707545) THEN CASE WHEN b.transid2 = 0 THEN 1003 ELSE 1004 END -- cashout
				ELSE -1 END customercategory,
				CASE WHEN b.transid2 = 1 AND b.bettype NOT IN (901, 911) AND (b.bettype NOT BETWEEN 1401 AND 1499) THEN 1 ELSE 0 END,
				b.refno,
				oddsspread,
				CASE WHEN b.bettype BETWEEN 1401 AND 1499 THEN CAST(b.transid2 AS VARCHAR(50)) ELSE b.ExtraInfo END, -- poker games: gem & insurance
				b.betdaqid,
				ISNULL(b.currency2, 0)
			FROM bodb02.dbo.bettrans b (NOLOCK)
			    INNER JOIN @__matchIds r ON b.matchid=r.matchid
			WHERE b.bettype<19000
	            AND b.winlostdate=@tmpDate
	            AND b.custid>0
				AND b.recommend > 0
				--AND b.matchid > 0
				AND statusid NOT IN (0,1,101,102,121)
				AND (@ProductCodes = '' OR b.bettype IN (SELECT Bettype FROM @BettypeProductMapping))
	        
            --DELETE dbo.bettrans WHERE winlostdate=@tmpDate AND statusid IN (0,1,101,102,121)

			-- Colossus bet tickets
			;WITH CBAmount AS
			(	
				SELECT b.transid, 
					SUM(CASE WHEN bm.bettype = 18002 THEN bm.oddsspread ELSE 0 END) AS CashInAmount, 
					SUM(CASE 
							WHEN (b.winlost - b.actual_stake ) < 0 AND b.statusID = 112 
								 THEN 0
							ELSE CASE WHEN bm.bettype = 18002 
									  THEN bm.winlost-bm.stake 
									  ELSE 0 
							END
						END) AS CashOutAmount,
					SUM(CASE 
							WHEN (b.winlost - b.actual_stake ) < 0 AND b.statusID = 112 
							THEN 0
							ELSE CASE WHEN bm.bettype IN (18004, 18005, 18006) 
									  THEN bm.Winlost-bm.stake 
									  ELSE 0 
							END
						END) AS WinPrizeAmount,
				SUM(CONVERT(MONEY,bm.transdesc)) AS transdesc
				FROM dbo.bettrans b WITH (NOLOCK) 
					INNER JOIN bodb02.dbo.bettransm bm WITH (NOLOCK) ON b.refno = bm.refno
				WHERE b.bettype = 18000 AND b.winlostdate=@tmpDate
					 AND bm.bettype BETWEEN 18000 AND 18006
					 AND (@ProductCodes = '' OR b.bettype IN (SELECT Bettype FROM @BettypeProductMapping))	
				GROUP BY b.transid
			)
			UPDATE b
			SET b.CashInAmount = cb.CashInAmount,
				b.WinPrizeAmount = cb.WinPrizeAmount,
				b.CashOutAmount = cb.CashOutAmount,
				b.ExtraInfo = cb.transdesc -- Extra Info contain real TO value of CB Free Play ticket
			FROM dbo.bettrans b
				INNER JOIN CBAmount cb ON cb.transid = b.transid
			WHERE b.bettype = 18000 AND b.Winlostdate = @tmpDate
        END
		ELSE
        BEGIN
			--Copy archived data (bettrans14)
			--TRUNCATE TABLE #Customer
			
			--INSERT INTO #Customer
	  --          SELECT DISTINCT custid
	  --          FROM bodb02.dbo.bettrans14 (NOLOCK)
	  --          WHERE winlostdate=@tmpDate AND custid>0
	            
			INSERT INTO dbo.bettrans
			    ([transid]
                ,winlostdate
                ,liveindicator
                ,bettype
                ,[custid]
                ,[stake]
                ,actual_stake
                ,[winlost],[awinlost],[mwinlost],swinlost
                ,acomm,scomm,playercomm,comm
                ,matchid
                ,[status]
                ,[srecommend]
                ,currency
                ,recommend,mrecommend
                ,transdate
                ,statusid
                ,virtualrate
                ,discount
                ,tpositiontaking
                ,customercategory
				,isBA
				,refno
				,oddsspread
				,ExtraInfo
				,betdaqid
				,TicketType)
			SELECT 
			    b.transid,
	            b.winlostdate,
	            b.liveindicator,
	            b.bettype,
	            b.custid,
	            ABS(b.stake) stake,
	            b.actual_stake,
	            b.winlost,b.awinlost,b.mwinlost,b.swinlost,
	            b.acomm, b.scomm, b.playercomm, b.comm,
	            b.matchid,
	            CASE WHEN (b.bettype IN (1, 3, 7, 8, 17, 18, 124, 125) AND ABS(b.modds) = 0.25 AND [status] IN('WON', 'LOSE')) OR (b.bettype IN (33,43) AND [status] <> 'refund' AND b.liveawayscore=0) THEN 'HALF ' ELSE '' END + b.status AS [status],
                b.srecommend, 
                b.currency, 
                b.recommend,b.mrecommend,
                b.transdate,
                b.statusid,
                b.virtualrate,
                b.discount,
                b.tpositiontaking,
                CASE WHEN b.recommend=52466 THEN 27 --8RM
					 WHEN b.recommend=5707545 THEN 28 	--BARM
					 WHEN b.bettype = 901 AND b.recommend NOT IN (52466,5707545) THEN CASE WHEN b.transid2 = 0 THEN 1001 ELSE 1002 END --bettrade
					 WHEN b.bettype = 911 AND b.recommend NOT IN (52466,5707545) THEN CASE WHEN b.transid2 = 0 THEN 1003 ELSE 1004 END -- cashout
					ELSE -1 END customercategory,
				CASE WHEN b.transid2 = 1 AND b.bettype NOT IN (901, 911) AND (b.bettype NOT BETWEEN 1401 AND 1499) THEN 1 ELSE 0 END,
				b.refno,
				oddsspread,
				CASE WHEN b.bettype BETWEEN 1401 AND 1499 THEN CAST(b.transid2 AS VARCHAR(50)) ELSE b.ExtraInfo END, -- poker games: gem & insurance
				b.betdaqid,
				ISNULL(b.currency2, 0)
			FROM bodb02.dbo.bettrans14 b (NOLOCK)
			    --INNER JOIN #Customer c (NOLOCK) ON b.winlostdate=@tmpDate AND b.custid=c.t_custid
			WHERE b.statusid NOT IN (0,101,102,121)  -- 'void', 'reject', 'running','done'
				AND b.winlostdate = @tmpDate AND b.custid > 0
				AND (@ProductCodes = '' OR b.bettype IN (SELECT Bettype FROM @BettypeProductMapping))


			-- Colossus bet tickets
			;WITH CBAmount AS
			(	
				SELECT b.transid, 
					SUM(CASE WHEN bm.bettype = 18002 THEN bm.oddsspread ELSE 0 END) AS CashInAmount, 
					SUM(CASE 
							WHEN (b.winlost - b.actual_stake ) < 0 AND b.statusID = 112 
							THEN 0
							ELSE CASE WHEN bm.bettype = 18002   
									  THEN bm.winlost-bm.stake 
									   ELSE 0 
							END
						END) AS CashOutAmount,
					SUM(CASE 
							WHEN (b.winlost - b.actual_stake ) < 0 AND b.statusID = 112 
							THEN 0
							ELSE CASE WHEN bm.bettype IN (18004, 18005, 18006) 
									  THEN bm.Winlost-bm.stake 
									  ELSE 0 
							END
						END) AS WinPrizeAmount,
					SUM(CONVERT(MONEY,bm.transdesc)) AS transdesc
				FROM dbo.bettrans b WITH (NOLOCK) 
					INNER JOIN bodb02.dbo.bettransm14 bm WITH (NOLOCK) ON b.refno = bm.refno
				WHERE b.bettype = 18000 AND b.winlostdate=@tmpDate
					AND (@ProductCodes = '' OR b.bettype IN (SELECT Bettype FROM @BettypeProductMapping))
				GROUP BY b.transid
			)
			UPDATE b
			SET b.CashInAmount = cb.CashInAmount,
				b.WinPrizeAmount = cb.WinPrizeAmount,
				b.CashOutAmount = cb.CashOutAmount,
				b.ExtraInfo = cb.transdesc
			FROM dbo.bettrans b
				INNER JOIN CBAmount cb ON cb.transid = b.transid
			WHERE b.bettype = 18000 AND b.Winlostdate = @tmpDate
        END

		SELECT @count = @count - 1
	END
	
	-- Cashout Product
	UPDATE b
	SET b.CashOutAmount = b.actual_stake
	FROM dbo.bettrans b
	WHERE b.bettype = 911

	UPDATE b
	SET isBA = CASE WHEN isBA = 1 AND b.bettype NOT IN (912, 913, 914) THEN 1 ELSE 0 END
		, customercategory = CASE WHEN isBA = 0 THEN 1003 ELSE 1004 END -- Cashout
	FROM dbo.bettrans b
		INNER JOIN #CashoutCust ctc ON b.CustId = ctc.CustId
			
	UPDATE b
	SET isBA = CASE WHEN isBA = 1 AND b.bettype NOT IN (902,903,904) THEN 1 ELSE 0 END
		, customercategory = CASE WHEN isBA = 0 THEN 1001 ELSE 1002 END --bettrade
	FROM dbo.bettrans b
		INNER JOIN #BetTradeCust btc ON b.CustId = btc.CustId

	--DROP TABLE #Recommend_List
	--DROP TABLE #Customer
		
	UPDATE dbo.bettrans
	SET statusid=CASE WHEN [status]='HALF WON' THEN 114 WHEN [status]='HALF LOSE' THEN 115 END
	WHERE [status] IN ('HALF WON','HALF LOSE')
	
	--///// PROCESS UPDATE BA STATUS FOR TICKETS ///////////////////
    CREATE TABLE #BATransids (transID bigint)

    SELECT @today = current_timestamp

    INSERT #BATransids(transid)
        SELECT b.transid
        FROM dbo.bettrans b (NOLOCK)
	        INNER JOIN bodb_Licensee.dbo.LicenseeBAHistory h (NOLOCK) 
	            ON b.custid=h.custid AND (transdate BETWEEN OnDate AND ISNULL(OffDate,@today))
        WHERE (Bettype < 31
				OR (Bettype >= 121 AND Bettype < 1000)
				OR (Bettype >= 1301 AND Bettype < 1400)
				OR (Bettype >= 9001 AND Bettype < 9400)
				OR (Bettype = 38) -- BetBuilder
			)
	        AND tpositiontaking = 0
			AND b.bettype NOT IN (901, 902, 903, 904, 911, 912, 913, 914)

    UPDATE dbo.bettrans
    SET IsBA = 1
    WHERE transid IN (SELECT transid FROM #BATransids)

	DROP TABLE #BATransids

	DROP TABLE #BetTradeCust

END
GO