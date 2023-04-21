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
		- 20210527@July: Check Data Consistency - Exclude bettype BlackJack for VGaming - [Redmine:#155762]
		- 20210924@July: Vgaming - Exclude bettype Casino Hold'em Poker - [Redmine:#161760]
		- 20211021@July: Vgaming - Exclude bettype Texas Hold'em Poker - [Redmine:#163463]
		- 20220106@July: Saba.club - Exclude bettype Casino Hold'em Poker(1650) - [Redmine:#167030]
		- 20220218@July: Vgaming - Exclude bettype Pai Gow Poker(3842) - [Redmine:#168578]
		- 20220222@July: Saba.games - Exclude bettype Hi-Lo(1651) - [Redmine:#168804]
		- 20220408@July: Saba.games - Exclude bettype Texas Hold'em Poker(1652) - [Redmine:#171263]
		- 20220413@July: Vgaming - Exclude bettype Hi-Lo(3844) - [Redmine:#171349]
		- 20220510@July: Remove code only support Sportbook - BetBuilder - [Redmine:#172310]
		- 20230421@July: Support product Happy 5, NumberGame - [Redmine:#186736]

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
	IF @ProductId IN (161,164)
	BEGIN
		INSERT INTO @tmpMatchIds (MatchId)
		SELECT m.matchid
		FROM bodb02.dbo.match m WITH(NOLOCK)
		WHERE m.sporttype = @ProductId
	
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
		WHERE	b.bettype < 20000
				AND b.winlostdate = @yesterday
				AND b.statusID = 0
				AND b.matchid IN (SELECT matchid FROM @tmpMatchIds)
	END
	
	IF @transId <> ''
	BEGIN
		SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'All yesterday tickets must be settled on product ' + CAST(@ProductId AS VARCHAR)
				,@SampleData = 'bettrans.TransId in (' + @transId + ')'
		
	END
END
GO