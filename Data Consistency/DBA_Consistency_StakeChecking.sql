/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_StakeChecking]
	@ProductId		INT	
	,@tablename		VARCHAR(50)		= NULL	
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
		- 20180808@Kathy: Check stake rules for poker game [Redmine:#98064]
		- 20181219@Vicky: Happy 5- Check Data Consistency [Redmine:#106481]
		- 20190405@Helen: Allbet - Stake rule check from bettransLC [Redmine: 111040]
		- 20190715@Kathy: check Stake rule for BetBuilder [Redmine:#116529]
		- 20190923@Kathy: Pocker game -  Stake rule check from bettransRNG [Redmine:#116529]
		- 20200429@Helen: Saba changes [Redmine:#133401]
		- 20200602@Max: Data Consistency for BBIN, Update for Indo 4D - [Redmine: #135239]
		- 20201026@July: Pragmatic & Arcadia Gaming - Check Data Consistency - [Redmine: #144168]
		- 20201104@July: Check Data Consistency for Exclude SA gaming - [Redmine: #144813]
		- 20210201@July: Check Data Consistency for Four Guardians - [Redmine: #149821]
		- 20210713@July: Exclude bettypes for VGaming - [Redmine: #158179]
		- 20210914@July: Saba.club - Exclude new bettype 1644 - [Redmine: #160869]
		- 20210924@July: Vgaming - Exclude bettype The Legend of Heroes - [Redmine:#162127]
		- 20220221@July: Spadegaming - Exclude bettype 4599 (contribution bettype) - [Redmine:#168750]
		- 20220418@July: Saba.games - Exclude new bettype 1653 (Nightclub Lady) - [Redmine: #171560]
		- 20220421@July: Allbet - Exclude bettype 2499 & AESexy - Exclue bettype 3150 - [Redmine:#171770]
		- 20220526@July: Vgaming - Exclude bettype 3845 (Nightclub Lady) - [Redmine:#173227]
		- 20220628@July: Saba.games - Exclude bettype 1654 (Treasure Island) - [Redmine: #174581]

	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @transId VARCHAR(MAX)
			,@Today DATETIME 

	DECLARE @tmpMatchIds TABLE (MatchId INT)

	SET @transId = ''
	SET @Today = CAST(GETDATE() AS DATE)
	
	IF @ProductId IN (211) OR @tablename = 'bettransLC'
	BEGIN
		SET @tablename = 'bettransLC'

		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM	bodb02.dbo.bettransLC b WITH (NOLOCK)
		WHERE	ProductID = @ProductId
				AND b.stake <= 0
				AND b.status <> 'Completed'
				AND b.gameID NOT IN (2499, 3150)
	END
	ELSE IF @ProductId IN (165, 248) OR @tablename = 'bettransRNG'
	BEGIN
		SET @tablename = 'bettransRNG'
		
		IF @ProductId = 165 -- Card Club (Arcadia Gaming)
		BEGIN
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM	bodb02.dbo.bettransRNG b WITH (NOLOCK)
			WHERE	ProductID = @ProductId
					AND b.stake <= 0
					AND b.status <> 'Completed'
					AND b.gameID NOT IN (1906)--'Bonus'
		END
		ELSE IF @ProductId = 248 -- Pragmatic Play
		BEGIN
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM	bodb02.dbo.bettransRNG b WITH (NOLOCK)
			WHERE	ProductID = @ProductId
					AND b.stake <= 0
					AND b.status <> 'Completed'
					AND b.gameID NOT IN (4297, 4298, 4299, 4300)
		END
		ELSE IF @ProductId = 200 -- Saba.club
		BEGIN
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM	bodb02.dbo.bettransRNG b WITH (NOLOCK)
			WHERE	ProductID = @ProductId
					AND b.stake <= 0
					AND b.status <> 'Completed'
					AND b.gameID NOT IN (1640, 1698, 1699, 1644, 1653, 1654)
		END
		ELSE IF @ProductId = 171 -- Vgaming
		BEGIN
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM	bodb02.dbo.bettransRNG b WITH (NOLOCK)
			WHERE	ProductID = @ProductId
					AND b.stake <= 0
					AND b.status <> 'Completed'
					AND b.gameID NOT IN (3829, 3898, 3899, 3835, 3845) 
		END
		ELSE IF @ProductId = 247 -- Spadegaming
		BEGIN
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM	bodb02.dbo.bettransRNG b WITH (NOLOCK)
			WHERE	ProductID = @ProductId
					AND b.stake <= 0
					AND b.status <> 'Completed'
					AND b.gameID NOT IN (4599)
		END
		ELSE 
		BEGIN
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM	bodb02.dbo.bettransRNG b WITH (NOLOCK)
			WHERE	ProductID = @ProductId
					AND b.stake <= 0
					AND b.status <> 'Completed'
		END	
	END
	ELSE
	BEGIN
		SET @tablename = 'bettrans'

		IF @ProductId = 1
		BEGIN
			INSERT INTO @tmpMatchIds (MatchId)
			SELECT	m.matchid
			FROM	bodb02.dbo.match m WITH(NOLOCK)
			WHERE	m.sporttype = 1
					AND m.eventdate = @Today
			
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
			WHERE	b.bettype = ISNULL(@Bettype, b.bettype)
					AND b.stake <= 0
					AND b.matchid IN (SELECT MatchId FROM @tmpMatchIds)
					AND b.winlostdate = @Today
					AND b.status <> 'Completed'
		END
		ELSE IF @ProductId = 241 --BBIN
		BEGIN
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
			WHERE	b.bettype < 20000
					AND b.stake <= 0
					AND b.matchid = @ProductId
					AND b.status NOT IN ('running','Completed')
		END
		ELSE
		BEGIN
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
			WHERE	b.bettype < 20000
					AND b.stake <= 0
					AND b.matchid = @ProductId
					AND b.status <> 'Completed'
		END
	END
	
	IF @transId <> ''
	BEGIN
		SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'Stake must be larger than 0 on product ' + CAST(@ProductId AS VARCHAR)
				,@SampleData = @tablename + '.TransId in (' + @transId + ')'
	END		

END
GO
