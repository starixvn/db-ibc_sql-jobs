/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_SpecificRulesChecking]
(
	@ProductId		INT			    = NULL		
	,@tablename		VARCHAR(50)		= NULL
	,@Rule			VARCHAR(50)
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT 
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
)
AS
/*
	Created: 20180808@Kathy
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20180808@Kathy: Check status rules for poker game [Redmine:#98064]
		- 20181212@Helen: Check status rules for GoldDeluxe [Redmine:70177]
		- 20181219@Vicky: Happy 5- Check Data Consistency [Redmine:#106481]
		- 20190405@Helen: GD - ignore ticket with void/reject/refund status in bettrans and bettransG for checking stake and winlost - [Redmine: 111040]
		- 20190405@Helen: Allbet -  ticket bettype 2402 Vip baccarat - [Redmine: 111040]
		- 20191125@Max: New rule of Allbet Bull Game [Redmine:#124351]
		- 20200401@Max: Data Consistency for New Product - [Redmine: #131857]
		- 20200602@Max: Data Consistency for BBIN, Update for Indo 4D - [Redmine: #135239]
		- 20200624@Max: Update Rule for Saba.Club, Modify Rule check Discount [Redmine: #136362]
		- 20200722@Max: Update Rule for Saba.Club - Exclude bettype 1631 from Rule '3min', Add new Rule for bettype 1631 - [Redmine: #138117]
		- 20201007@July:  Saba.club - Data Integrity/Consistency Detection for Free Bets and Blackjack - [Redmine:#140425]
		- 20201030@July: Check Data Consistency - All products - exclude checking commission/discount of licensee tickets for rule 16 - [Redmine:#144533]
		- 20210510@July: Check Data Consistency - VGaming & Creative Gaming - [Redmine:#154502]
		- 20210527@July: Check Data Consistency - Exclude bettype BlackJack for VGaming - [Redmine:#155762]
		- 20210924@July: Vgaming - Exclude bettype Casino Hold'em Poker - [Redmine:#161760]
		- 20211021@July: Vgaming - Exclude bettype Texas Hold'em Poker - [Redmine:#163463]
		- 20220106@July: Saba.club - Exclude bettype Casino Hold'em Poker(1650) - [Redmine:#167030]
		- 20220218@July: Vgaming - Exclude bettype Pai Gow Poker(3842) - [Redmine:#168578]
		- 20220222@July: Saba.games - Exclude bettype Hi-Lo(1651) - [Redmine:#168804]
		- 20220408@July: Saba.games - Exclude bettype Texas Hold'em Poker(1652) - [Redmine:#171263]
		- 20220413@July: Vgaming - Exclude bettype Hi-Lo(3844) - [Redmine:#171349]
		- 20220608@July: Check Member Stake/WinLost consistent among tables BettransLC, bettransRNG and Bettrans for all related products - [Redmine:#173808]
		- 20220608@July: Param @ProductId miss default NULL - [Redmine:#173808]
		- 20220616@July: Check tickets before yesterday in dbo.bettrans - [Redmine:#173956]
		- 20220620@July: Check tickets before yesterday in bettrans/bettransLC/bettransRNG & Remove code for Poker Games(163), GoldDeluxe(255) product - [Redmine:#174264]
		- 20221005@July: MG-RNG - Add rule check if no discount, no comm [Redmine:#178718]

		Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @transId VARCHAR(MAX)
			,@maxError INT = 100
			,@translogid VARCHAR(MAX)
			
	DECLARE @yesterday SMALLDATETIME
			,@Today SMALLDATETIME
	
	SET @Today = CAST(GETDATE() AS DATE)
	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))

	CREATE TABLE #tmpBettrans (		
		transId				BIGINT
		,betid				BIGINT
		,oddsspread			MONEY
		,tpositiontaking	SMALLMONEY
		,spositiontaking	SMALLMONEY
		,mpositiontaking	SMALLMONEY
		,apositiontaking	SMALLMONEY
		,swinlost			MONEY
		,mwinlost			MONEY
		,awinlost			MONEY
		,scomm				MONEY
		,acomm				MONEY
		,comm				MONEY
		,playercomm			MONEY
		,modds				SMALLMONEY
		,bettype			SMALLINT
		,statusId			TINYINT
		,transid2			BIGINT
		,hdp2				SMALLMONEY
		,stake				MONEY
		,winlost			MONEY
		,custid				INT
		,srecommend			INT
		,winlostdate		SMALLDATETIME
		,currency			TINYINT
		,refno				BIGINT
		,sdiscount			DECIMAL(9,5)
		,adiscount			DECIMAL(9,5)
		,discount			DECIMAL(9,5)
		,playerdiscount		DECIMAL(9,5)
		,actual_stake		MONEY
	)

	CREATE TABLE #tmpBettransG (		
		custid		INT
		,refno 		BIGINT
		,stake		MONEY
		,winlost	MONEY
	)
	CREATE TABLE #tmpBettransLC (		
		custid		INT
		,refno 		BIGINT
		,stake		MONEY
		,winlost	MONEY
	)
	CREATE TABLE #tmpBettransRNG (		
		custid		INT
		,refno 		BIGINT
		,stake		MONEY
		,winlost	MONEY
	)

	
	SET @transId = ''
	SET @translogid = ''
	
	INSERT INTO #tmpBettrans(transId, betid, oddsspread, tpositiontaking, spositiontaking, mpositiontaking, apositiontaking
		,swinlost, mwinlost, awinlost
		,scomm, acomm, comm, playercomm
		,modds, bettype, statusId, transid2, hdp2, stake,winlost, custid,srecommend,winlostdate,currency
		,refno,playerdiscount,discount,sdiscount,adiscount,actual_stake)
	SELECT	transId, betid, oddsspread, tpositiontaking, spositiontaking, mpositiontaking, apositiontaking
		,swinlost, mwinlost, awinlost
		,scomm, acomm, comm, playercomm
		,modds, bettype, statusId, transid2, hdp2, stake,winlost,custid,srecommend,winlostdate,currency
		,refno,playerdiscount,discount,sdiscount,adiscount,actual_stake
	FROM	bodb02.dbo.bettrans WITH (NOLOCK)
	WHERE 1 = CASE WHEN matchid = @ProductId THEN 1 
				   WHEN winlostdate <= @yesterday AND (@tablename = 'bettransLC' OR @tablename = 'bettransRNG') THEN 1
				   ELSE 0 END

	IF @ProductId IN (244, 241)
	BEGIN
		INSERT INTO #tmpBettransG(custid,refno, stake, winlost)
		SELECT	custid, refno, sum(stake) AS stake, sum(winlost) AS winlost
		FROM	bodb02.dbo.bettransG b WITH (NOLOCK)
		WHERE b.matchid = @ProductId
		GROUP BY custid, refno
	END

	IF @ProductId IN (244) OR @tablename = 'bettransLC'
	BEGIN
		INSERT INTO #tmpBettransLC(custid,refno, stake, winlost)
		SELECT custid, refno, sum(stake) AS stake, sum(winlost) AS winlost
		FROM bodb02.dbo.bettransLC WITH (NOLOCK)
		WHERE IsSum = 1
			AND 1 = CASE WHEN productID = @ProductId THEN 1
						 WHEN winlostdate <= @yesterday AND	@tablename = 'bettransLC' AND productID <> 244 THEN 1
						 ELSE 0 END
		GROUP BY custid, refno
	END

	IF @tablename = 'bettransRNG'
	BEGIN
		INSERT INTO #tmpBettransRNG(custid,refno, stake, winlost)
		SELECT custid, refno, sum(stake) AS stake, sum(winlost) AS winlost
		FROM bodb02.dbo.bettransRNG WITH (NOLOCK)
		WHERE IsSum = 1 AND winlostdate <= @yesterday
		GROUP BY custid, refno
	END
			
	IF @ProductId = 211
	BEGIN
		IF @Rule = 'VipBaccarat_2402'
		BEGIN
			--
			SET @transId = ''
			SELECT TOP (@maxError) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM	#tmpBettrans b WITH (NOLOCK)
			WHERE	b.bettype = 2402 
					AND b.winlostdate = @yesterday 
					AND b.currency NOT IN (20,27,28,72)	
					AND b.statusId IN (112,113,111)
					AND b.srecommend NOT IN (SELECT custid FROM bodb02.dbo.Dep_CustSuper WITH(NOLOCK))	
	
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 100
						,@ErrMsg = 'Wrong ticket bettype 2402 Vip baccarat in bettrans on product ' + CAST(@ProductId AS VARCHAR)
						,@SampleData = 'bettrans.TransId in (' + @transId + ')'
				
				RETURN
			END
			
		END
		IF @Rule = 'BullGame_2407'
		BEGIN
			SET @transId = ''
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM	bodb02.dbo.bettransLC b WITH (NOLOCK)
			WHERE b.productID = @ProductId
				AND b.gameID = 2407
				AND (b.transdesc LIKE 'choice=8011%'
					 OR b.transdesc LIKE 'choice=8111%'
					 OR b.transdesc LIKE 'choice=8012%'
					 OR b.transdesc LIKE 'choice=8112%'
					 OR b.transdesc LIKE 'choice=8013%'
					 OR b.transdesc LIKE 'choice=8113%'
					)
				AND b.actual_stake <> b.stake * 5
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 100
						,@ErrMsg = 'Wrong actual_stake ticket in bettransLC on product ' + CAST(@ProductId AS VARCHAR)
						,@SampleData = 'bettransLC.TransId in (' + @transId + ')'
				
				RETURN
			END
		END
	END

	--Rule #26, #27 for SA Gaming
	IF @ProductId = 244
	BEGIN
		IF @Rule = 'winlost'
		BEGIN
			
			SELECT TOP (@maxError) @transId = @transId + ',' + CAST(bt.transid AS VARCHAR)
			FROM	#tmpBettrans bt
				INNER HASH JOIN #tmpBettransG btg ON bt.transId = btg.refno AND bt.winlost <> btg.winlost
				INNER HASH JOIN #tmpBettransLC blc ON blc.refno = bt.transId AND bt.winlost <> blc.winlost
			WHERE bt.statusId NOT IN (101,102,103)
							 
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 100
						,@ErrMsg = 'Wrong winlost value between bettrans and bettransG and bettransLC on product ' + CAST(@ProductId AS VARCHAR)
						,@SampleData = 'bettrans.TransId in (' + @transId + ')'

				RETURN
			END
		END
		IF @Rule = 'stake'
		BEGIN
			
			SELECT TOP (@maxError) @transId = @transId + ',' + CAST(bt.transid AS VARCHAR)
			FROM	#tmpBettrans bt
				INNER HASH JOIN #tmpBettransG btg ON bt.transId = btg.refno AND bt.stake <> btg.stake
				INNER HASH JOIN #tmpBettransLC blc ON bt.transId = blc.refno AND bt.stake <> blc.stake
			WHERE bt.statusId NOT IN (101,102,103)  
							 
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 100
						,@ErrMsg = 'Wrong stake value between bettrans and bettransG and bettransLC on product ' + CAST(@ProductId AS VARCHAR)
						,@SampleData = 'bettrans.TransId in (' + @transId + ')'

				RETURN
			END
		END
	END

	--Rule #30 for Saba.club Free Bets, Saba.club, VGaming, VGaming Free Bets
	IF @ProductId  IN (150, 200, 171, 173)
	BEGIN
		IF @Rule = '3min'
		BEGIN
			
			SELECT TOP (@maxError) @transId = @transId + ',' + CAST(b.transid AS VARCHAR)
			FROM	bodb02.dbo.bettransRnG b WITH (NOLOCK)
			WHERE b.productID = @ProductId
				AND b.statusID IN (0,1)
				AND b.transdate < DATEADD(MINUTE, -3, GETDATE())
				AND b.gameID NOT IN (1622, 1631, 1634, 3820, 3836, 3837, 1650, 3842, 1651, 1652, 3844) --Exclude Saba.club(1622-Keno Pro Viet, 1631-Bola Kangtas, 1634-Blackjack, 1650-Casino Hold'em Poker, 1651-Hi-Lo, 1652-Texas Hold'em Poker) + VGaming(3820-Blackjack, 3836-Casino Hold'em Poker, 3837-Texas Hold'em Poker, 3842-Pai Gow Poker, 3844-Hi-Lo)
							 
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 100
						,@ErrMsg = 'Tickets bet after 3 minutes still running on product ' + CAST(@ProductId AS VARCHAR)
						,@SampleData = 'bettransRNG.TransId in (' + @transId + ')'

				RETURN
			END
		END
		IF @Rule = '25h' -- Check only for game 1631-Bola Kangtas
		BEGIN
			
			SELECT TOP (@maxError) @transId = @transId + ',' + CAST(b.transid AS VARCHAR)
			FROM	bodb02.dbo.bettransRnG b WITH (NOLOCK)
			WHERE b.productID = @ProductId
				AND b.statusID IN (0,1)
				AND b.transdate < DATEADD(HOUR, -25, GETDATE())
				AND b.gameID IN (1631) --Bola Kangtas
							 
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 100
						,@ErrMsg = 'Tickets 1631-Bola Kangtas bet after 25 hours still running on product ' + CAST(@ProductId AS VARCHAR)
						,@SampleData = 'bettransRNG.TransId in (' + @transId + ')'

				RETURN
			END
		END
	END

	/* Rule #18: Check settled tickets in translog but not having in bettrans
			for Virtual Games, Table Games, Sports Lottery
	*/
	IF @ProductId IN (245, 222, 169)
	BEGIN
		IF @Rule = 'translog'
		BEGIN
			
			SELECT TOP (@maxError) @transId = @transId + ',' + CAST(t.translogid AS VARCHAR)
			FROM	bodb02.dbo.translog t WITH (NOLOCK)
			WHERE t.productID = @ProductId
				AND t.statusID NOT IN (0, 1, 101, 102, 103)
				AND t.translogid NOT IN (SELECT refno FROM #tmpBettrans)
							 
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 100
						,@ErrMsg = 'Settled tickets in translog but not having in bettrans on product ' + CAST(@ProductId AS VARCHAR)
						,@SampleData = 'translog.translogid in (' + @transId + ')'

				RETURN
			END
		END
	END

	/* Rule #3: Check if no discount, no comm (apply to product non-offer comm)
			for Virtual Games, Table Games, Sports Lottery, Saba.club, Saba.club Free Bets, VGaming, VGaming Free Bets, FGG, Keno, Lottery, Funky Games, Macau Games, PP, PG Soft, SG, Arcadia Gaming, Joker, MaxGame, Habanero, CG, AdvantPlay, AdvantPlay Mini, Virtual Sports, Virtual Sports 2, Virtual Sports 3, MG-RNG
	*/
	IF @ProductId IN (245, 222, 169, 200, 150, 171, 173, 176, 202, 220, 224, 212, 248, 232, 247, 165, 234, 237, 238, 167, 172, 174, 180, 181, 182, 183, 184, 185, 186, 190, 191, 192, 193, 194, 195, 196, 197, 231, 155)
	BEGIN
		IF @Rule = 'no_discount_comm'
		BEGIN
			
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM	#tmpBettrans
			WHERE	srecommend NOT IN (SELECT custId FROM bodb02.dbo.Dep_CustSuper WITH (NOLOCK)) --only check for credit site
					AND (ISNULL(playerdiscount, 0) <> 0
						OR ISNULL(discount, 0) <> 0
						OR ISNULL(adiscount, 0) <> 0
						OR ISNULL(sdiscount, 0) <> 0
						OR ISNULL(playercomm, 0) <> 0
						OR ISNULL(comm, 0) <> 0
						OR ISNULL(acomm, 0) <> 0
						OR ISNULL(scomm, 0) <> 0)
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 100
						,@ErrMsg = 'Wrong discount or comm value on product ' + CAST(@ProductId AS VARCHAR)
						,@SampleData = 'bettrans.TransId in (' + @transId + ')'

				RETURN
			END
		END
	END

	--Rule #29 for Indo 4D
	IF @ProductId = 223
	BEGIN
		IF @Rule = 'actualstake'
		BEGIN
			
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM	#tmpBettrans b
			WHERE b.actual_stake >= b.stake
				AND b.statusId NOT IN (131)

			SELECT TOP (100) @translogid = @translogid + ',' + CAST(t.translogid AS VARCHAR)
			FROM	bodb02.dbo.translog t WITH (NOLOCK)
			WHERE t.productID = @ProductId
				AND t.actual_stake >= t.stake
				AND t.statusID NOT IN (131)
				
			IF @transId <> '' OR @translogid <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, CASE WHEN LEN(@transId) - 1 < 0 THEN LEN(@transId) ELSE LEN(@transId) - 1 END)
						,@translogid = SUBSTRING(@translogid, 2, CASE WHEN LEN(@translogid) - 1 < 0 THEN LEN(@translogid) ELSE LEN(@translogid) - 1 END)
						,@ErrCode = 100
						,@ErrMsg = 'Member Actual Stake greater than Member Original Stake on product ' + CAST(@ProductId AS VARCHAR)
						,@SampleData = 'bettrans.TransId in (' + @transId + ') or translog.translogid in (' + @translogid + ')'

				RETURN
			END
		END
	END
	IF @ProductId = 241 --BBIN
	BEGIN
		IF @Rule = 'winlost'
		BEGIN
			
			SELECT TOP (@maxError) @transId = @transId + ',' + CAST(bt.transid AS VARCHAR)
			FROM	#tmpBettrans bt
				INNER HASH JOIN #tmpBettransG btg ON bt.transId = btg.refno AND bt.winlost <> btg.winlost
			WHERE bt.statusId NOT IN (0)
							 
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 100
						,@ErrMsg = 'Wrong winlost value between bettrans and bettransG on product ' + CAST(@ProductId AS VARCHAR)
						,@SampleData = 'bettrans.TransId in (' + @transId + ')'

				RETURN
			END
		END
		IF @Rule = 'stake'
		BEGIN
			
			SELECT TOP (@maxError) @transId = @transId + ',' + CAST(bt.transid AS VARCHAR)
			FROM	#tmpBettrans bt
				INNER HASH JOIN #tmpBettransG btg ON bt.transId = btg.refno AND bt.stake <> btg.stake
			WHERE bt.statusId NOT IN (0)
							 
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 100
						,@ErrMsg = 'Wrong stake value between bettrans and bettransG on product ' + CAST(@ProductId AS VARCHAR)
						,@SampleData = 'bettrans.TransId in (' + @transId + ')'

				RETURN
			END
		END
	END

	--Rule #34: Check Member Winlost Consistent among tables BettransLC/BettransRNG and Bettrans
	IF @Rule = 'winlost'
	BEGIN
		IF @tablename = 'bettransLC'
		BEGIN
			SELECT TOP (@maxError) @transId = @transId + ',' + CAST(bt.transid AS VARCHAR)
			FROM	#tmpBettrans bt
				INNER HASH JOIN #tmpBettransLC blc ON bt.transId = blc.refno AND bt.winlost <> blc.winlost
			WHERE bt.statusId NOT IN (101,102,103)  
							 
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 100
						,@ErrMsg = 'Wrong winlost value between bettrans and bettransLC '
						,@SampleData = 'bettrans.TransId in (' + @transId + ')'

				RETURN
			END
		END
		IF @tablename = 'bettransRNG'
		BEGIN
			SELECT TOP (@maxError) @transId = @transId + ',' + CAST(bt.transid AS VARCHAR)
			FROM	#tmpBettrans bt
				INNER HASH JOIN #tmpBettransRNG rng ON bt.transId = rng.refno AND bt.winlost <> rng.winlost
			WHERE bt.statusId NOT IN (101,102,103)  
							 
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 100
						,@ErrMsg = 'Wrong winlost value between bettrans and bettransRNG '
						,@SampleData = 'bettrans.TransId in (' + @transId + ')'

				RETURN
			END
		END
	END

	--Rule #35: Check Member Stake Consistent among tables BettransLC/BettransRNG and Bettrans
	IF @Rule = 'stake'
	BEGIN
		IF @tablename = 'bettransLC'
		BEGIN
			SELECT TOP (@maxError) @transId = @transId + ',' + CAST(bt.transid AS VARCHAR)
			FROM	#tmpBettrans bt
				INNER HASH JOIN #tmpBettransLC blc ON bt.transId = blc.refno AND bt.stake <> blc.stake
			WHERE bt.statusId NOT IN (101,102,103)  
							 
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 100
						,@ErrMsg = 'Wrong stake value between bettrans and bettransLC '
						,@SampleData = 'bettrans.TransId in (' + @transId + ')'

				RETURN
			END
		END
		IF @tablename = 'bettransRNG'
		BEGIN
			SELECT TOP (@maxError) @transId = @transId + ',' + CAST(bt.transid AS VARCHAR)
			FROM	#tmpBettrans bt
				INNER HASH JOIN #tmpBettransRNG rng ON bt.transId = rng.refno AND bt.stake <> rng.stake
			WHERE bt.statusId NOT IN (101,102,103)  
							 
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 100
						,@ErrMsg = 'Wrong stake value between bettrans and bettransRNG '
						,@SampleData = 'bettrans.TransId in (' + @transId + ')'

				RETURN
			END
		END
	END

	DROP TABLE #tmpBettrans
	DROP TABLE #tmpBettransG
	DROP TABLE #tmpBettransLC
	DROP TABLE #tmpBettransRNG
END
GO