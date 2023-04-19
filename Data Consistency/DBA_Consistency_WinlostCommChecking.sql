/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_WinlostCommChecking]
	 @CheckMode		INT			   		
	,@tablename		VARCHAR(50)		= NULL
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT 
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20230414@July
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20230414@July: Checking data of swinlost, mwinlost, awinlost, playercomm, comm, acomm, scomm in settled tickets in bettrans, bettransLC, bettransRNG, bettransG - [Redmine:#186426]

	Param's Expanation:
		Notes: For SAGaming(244), BBIN(241) check data in bettransG
		@CheckMode =  1: Checking data of swinlost, mwinlost, awinlost, playercomm, comm, acomm, scomm in settled tickets on table bettransRNG/bettransLC/bettransG
		                 Checking data of swinlost, mwinlost, awinlost in settled tickets on table bettrans
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @transId VARCHAR(MAX)
			,@Today SMALLDATETIME
			,@yesterday SMALLDATETIME 

	SET @transId = ''
	SET @Today = CAST(GETDATE() AS DATE)
	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
	
	IF @CheckMode = 1
	BEGIN
		IF @tablename = 'bettransRNG'
		BEGIN
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM bodb02.dbo.bettransRNG WITH(NOLOCK) 
			WHERE statusid IN (111, 112, 113) --Draw/Won/Lose
				AND (winlostdate = @Today OR winlostdate = @yesterday) 
				AND gameID NOT IN (2198, 2398, 2998, 1698, 3898, 4297, 4599)
				AND
				(  ABS(aWinLost -(-(winlost-actual_stake) * apositiontaking)) > 0.0002 
				OR ABS(mWinLost -(-(winlost-actual_stake) * mpositiontaking)) > 0.0002
				OR ABS(sWinLost -(-(winlost-actual_stake) * spositiontaking)) > 0.0002
				
				OR (statusid IN (112,113) AND (CAST(BetStake * playerdiscount AS money) <> playercomm)) 
				OR (statusid IN (112,113) AND (CAST(BetStake * discount * (1 - apositiontaking) AS money) <> comm))
				OR (statusid IN (112,113) AND (CAST(BetStake * adiscount * (1 - (mpositiontaking + apositiontaking)) AS money) <> acomm))	
				OR (statusid IN (112,113) AND (CAST(BetStake * sdiscount * (1 - (spositiontaking + mpositiontaking + apositiontaking)) AS money) <> scomm))
				) 
			 
		END
		IF @tablename = 'bettransLC'
		BEGIN
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM bodb02.dbo.bettransLC WITH(NOLOCK) 
			WHERE statusid IN (111, 112, 113) --Draw/Won/Lose
				AND (winlostdate = @Today OR winlostdate = @yesterday)
				AND productID NOT IN (244)
				AND
				(  ABS(aWinLost -(-(winlost-actual_stake) * apositiontaking)) > 0.0002 
				OR ABS(mWinLost -(-(winlost-actual_stake) * mpositiontaking)) > 0.0002
				OR ABS(sWinLost -(-(winlost-actual_stake) * spositiontaking)) > 0.0002
			
				OR (statusid IN (112,113) AND (CAST(netstake * playerdiscount AS money) <> playercomm)) 
				OR (statusid IN (112,113) AND (CAST(netstake * discount * (1 - apositiontaking) AS money) <> comm)) 
				OR (statusid IN (112,113) AND (CAST(netstake * adiscount * (1 - (mpositiontaking + apositiontaking)) AS money) <> acomm)) 
				OR (statusid IN (112,113) AND (CAST(netstake * sdiscount * (1 - (spositiontaking + mpositiontaking + apositiontaking)) AS money) <> scomm)) 
				) 
		END
		IF @tablename = 'bettransG'
		BEGIN
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM bodb02.dbo.bettransG WITH(NOLOCK) 
			WHERE statusid IN (111, 112, 113) --Draw/Won/Lose
				AND (winlostdate = @Today OR winlostdate = @yesterday)
				AND matchid IN (244, 241)
				AND
				(  ABS(aWinLost -(-(winlost-actual_stake) * apositiontaking)) > 0.0002 
				OR ABS(mWinLost -(-(winlost-actual_stake) * mpositiontaking)) > 0.0002
				OR ABS(sWinLost -(-(winlost-actual_stake) * spositiontaking)) > 0.0002
				
				OR (statusid IN (112,113) AND (CAST(netstake * playerdiscount AS money) <> playercomm)) 
				OR (statusid IN (112,113) AND (CAST(netstake * discount * (1 - apositiontaking) AS money) <> comm)) 
				OR (statusid IN (112,113) AND (CAST(netstake * adiscount * (1 - (mpositiontaking + apositiontaking)) AS money) <> acomm)) 
				OR (statusid IN (112,113) AND (CAST(netstake * sdiscount * (1 - (spositiontaking + mpositiontaking + apositiontaking)) AS money) <> scomm)) 
				) 
				
		END
		IF @tablename = 'bettrans'
		BEGIN
			DECLARE @tmBettypes TABLE (Bettype SMALLINT)
			INSERT INTO @tmBettypes (Bettype)
			SELECT	DISTINCT BetType
			FROM bodb02.dbo.SportBettypeMatrix WITH(NOLOCK)
			WHERE RefTable IN (0,3) --0: bettrans, 3 translog
				AND IsTest = 0 AND Enabled = 1
		
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM bodb02.dbo.bettrans b WITH(NOLOCK) 
				INNER JOIN @tmBettypes s ON b.bettype =  s.Bettype
			WHERE  b.bettype NOT IN (999) --No ticket bet
				AND statusid IN (111, 112, 113) --Draw/Won/Lose
				AND (winlostdate = @Today OR winlostdate = @yesterday)
				AND
				(  ABS(aWinLost -(-(winlost-actual_stake) * apositiontaking)) > 0.01 
				OR ABS(mWinLost -(-(winlost-actual_stake) * mpositiontaking)) > 0.01
				OR ABS(sWinLost -(-(winlost-actual_stake) * spositiontaking)) > 0.01
				) 
				
		END
		IF @transId <> ''
		BEGIN
			SELECT	 @transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
					,@ErrCode = 100
					,@ErrMsg = CASE WHEN @tablename = 'bettrans' THEN 'Checking data of swinlost, mwinlost, awinlost in settled tickets on table bettrans'
																 ELSE 'Checking data of swinlost, mwinlost, awinlost, playercomm, comm, acomm, scomm in settled tickets on table ' + @tablename END
					,@SampleData =  @tablename + '.TransId in (' + @transId + ')'
		END
		RETURN;
	END
	IF @CheckMode = 2
	BEGIN
		IF @tablename = 'bettrans'
		BEGIN
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM bodb02.dbo.bettrans WITH(NOLOCK) 
			WHERE (winlostdate = @Today OR winlostdate = @yesterday) 
				AND (actual_stake IS NULL OR winlost IS NULL OR playercomm IS NULL)
		END
		ELSE IF @tablename = 'bettransRNG'
		BEGIN
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM bodb02.dbo.bettransRNG WITH(NOLOCK) 
			WHERE (winlostdate = @Today OR winlostdate = @yesterday) 
				AND (actual_stake IS NULL OR winlost IS NULL OR playercomm IS NULL)
		END
		ELSE IF @tablename = 'bettransLC'
		BEGIN
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM bodb02.dbo.bettransLC WITH(NOLOCK) 
			WHERE (winlostdate = @Today OR winlostdate = @yesterday) 
				AND (actual_stake IS NULL OR winlost IS NULL OR playercomm IS NULL)
		END
	
		IF @transId <> ''
		BEGIN
			SELECT	 @transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
					,@ErrCode = 100
					,@ErrMsg = 'Check actual_stake, winlost, playercomm NULL on table ' + @tablename
					,@SampleData = @tablename + '.TransId in (' + @transId + ')'
		END
		RETURN;
	END
END
