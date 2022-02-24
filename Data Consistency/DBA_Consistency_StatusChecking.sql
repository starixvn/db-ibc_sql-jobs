/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_StatusChecking]
	@ProductId		INT	
	,@Bettype		SMALLINT		= NULL	
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT 
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20180808@Kathy
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20180808@Kathy: Check status rules for poker game [Redmine:#98064]
		- 20181219@Vicky: Happy 5- Check Data Consistency [Redmine:#106481]
		- 20190715@Kathy: check status ticket for BetBuilder [Redmine:#116529]
		- 20200624@Max: Update Rule for Saba.Club, Modify Rule check Discount [Redmine: #136362]
		- 20200722@Max: Update Rule for Saba.Club - Exclude bettype 1631 - [Redmine: #138117]
		- 20201007@July:  Saba.club - Data Integrity/Consistency Detection for Free Bets and Blackjack - [Redmine:#140425]
		- 20210527@July: Check Data Consistency - Exclue bettype BlackJack for VGaming - [Redmine:#155762]
		- 20210924@July: Vgaming - Exclue bettype Casino Hold'em Poker - [Redmine:#161760]
		- 20211021@July: Vgaming - Exclue bettype Texas Hold'em Poker - [Redmine:#163463]
		- 20220106@July: Saba.club - Exclue bettype Casino Hold'em Poker(1650) - [Redmine:#167030]
		- 20220218@July: Vgaming - Exclue bettype Pai Gow Poker(3842) - [Redmine:#168578]
		- 20220222@July: Saba.games - Exclue bettype Hi-Lo(1651) - [Redmine:#168804]

	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @transId VARCHAR(MAX)
			,@yesterday DATETIME

	DECLARE @tmpMatchIds TABLE (MatchId INT)

	SET @transId = ''
	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))

	IF @ProductId = 1
	BEGIN
		INSERT INTO @tmpMatchIds (MatchId)
		SELECT	m.matchid
		FROM	bodb02.dbo.match m WITH(NOLOCK)
		WHERE	m.sporttype = 1
				AND m.eventdate = @yesterday

		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
		WHERE	b.bettype = ISNULL(@Bettype, b.bettype)
				AND b.winlostdate = @yesterday			
				AND b.statusID = 0
				AND b.matchid IN (SELECT MatchId FROM @tmpMatchIds)
	END
	ELSE IF @ProductId  IN (150,200) -- 150:Saba.club Free Bets - 200:Saba.Club
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
		WHERE	b.bettype < 20000
				AND b.winlostdate = @yesterday
				AND b.statusID = 0
				AND b.matchid = @ProductId
				AND b.bettype NOT IN (1622, 1631, 1634, 1650, 1651) --Exclude Keno Pro Viet, Bola Kangtas, Blackjack, Casino Hold'em Poker, Hi-Lo
	END
	ELSE IF @ProductId  IN (171,173) -- 171: VGaming - 173: VGaming FreeBets
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
		WHERE	 b.winlostdate = @yesterday
				AND b.statusID = 0
				AND b.matchid = @ProductId
				AND b.bettype NOT IN (3820, 3836, 3837, 3842) --Exclude Blackjack, Casino Hold'em Poker, Texas Hold'em Poker, Pai Gow Poker
	END
	ELSE
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
		WHERE	b.bettype < 20000
				AND b.winlostdate = @yesterday
				AND b.statusID = 0
				AND b.matchid = @ProductId
	END

	IF @transId <> ''
	BEGIN
		SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'All yesterday tickets must be settled on product ' + CAST(@ProductId AS VARCHAR)
				,@SampleData = 'bettrans.TransId = ' + @transId
	END
END
GO