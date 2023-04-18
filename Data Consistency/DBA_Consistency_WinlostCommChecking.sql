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
		@CheckMode =  1: Checking data of swinlost, mwinlost, awinlost, playercomm, comm, acomm, scomm in settled tickets on table bettransRNG/bettransLC/bettransG/bettrans
				
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
			FROM	bodb02.dbo.SportBettypeMatrix WITH(NOLOCK)
			WHERE	ProductID IN (1,3,8) --Sportsbook, Numer Game, Keno
		
			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM bodb02.dbo.bettrans b WITH(NOLOCK) 
				INNER JOIN @tmBettypes s ON b.bettype =  s.Bettype
			WHERE  b.bettype NOT IN (999) --No ticket bet
				AND statusid IN (111, 112, 113) --Draw/Won/Lose
				AND (winlostdate = @Today OR winlostdate = @yesterday)
				AND 1 = CASE WHEN b.bettype NOT IN (9,29) --Single
								AND
									(  ABS(aWinLost -(-(winlost-actual_stake) * apositiontaking)) > 0.0002 
									OR ABS(mWinLost -(-(winlost-actual_stake) * mpositiontaking)) > 0.0002
									OR ABS(sWinLost -(-(winlost-actual_stake) * spositiontaking)) > 0.0002
									) THEN 1
							WHEN b.bettype IN (9,29) --Parlay
								AND
									(  ABS(aWinLost -(-(winlost-actual_stake) * apositiontaking)) > 0.01 
									OR ABS(mWinLost -(-(winlost-actual_stake) * mpositiontaking)) > 0.01
									OR ABS(sWinLost -(-(winlost-actual_stake) * spositiontaking)) > 0.01
									) THEN 1
							WHEN   (
										statusid IN (112,113) AND (CAST(stake * playerdiscount AS money) <> playercomm)) 
									OR (statusid IN (112,113) AND (CAST(stake * discount * (1 - apositiontaking) AS money) <> comm)) 
									OR (statusid IN (112,113) AND (CAST(stake * adiscount * (1 - (mpositiontaking + apositiontaking)) AS money) <> acomm)) 
									OR (statusid IN (112,113) AND (CAST(stake * sdiscount * (1 - (spositiontaking + mpositiontaking + apositiontaking)) AS money) <> scomm)
									) THEN 1
							ELSE 0 END
		END
		IF @transId <> ''
		BEGIN
			SELECT	 @transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
					,@ErrCode = 100
					,@ErrMsg = 'Checking data of swinlost, mwinlost, awinlost, playercomm, comm, acomm, scomm in settled tickets on table ' + @tablename
					,@SampleData =  @tablename + '.TransId in (' + @transId + ')'
		END
		RETURN;
	END
END
