/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_OtherSportsStatusChecking]
   --@ProductId		INT		= 0
	 @tablename		VARCHAR(50)	 = NULL	
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20191025@Helen
	Task: Data consistency 
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20191025@Helen: Virtual Sport, Number Games, Happy 5 - Check status rules for Apply new rule to detect pending payout for today running tickets [Redmine:#122716]
		- 20191025@Helen: check kickofftime instead of transdate for Virtual Sport, Number Games, Happy 5 [Redmine:#122716]
		- 20220222@July:  Apply for Saba.games - bettype 1651 (Hi-Lo) - [Redmine:#168804]
		- 20220413@July:  Apply for Vgaming - bettype 3844 (Hi-Lo) - [Redmine:#171349]
		- 20220620@July:  Apply for Virtual Sport 3 - [Redmine:#174264]

	Param's Expanation:
	Number Game: 161 ; bettype: 81 - 120
	Happy 5:164; bettype: 8101-8120
	Virtual Sport, Virtual Sport 2 - bettype: 180 - 199
		VS: bettype 1201 AND 1299
		VS2:bettype BETWEEN 2700 AND 2899
	Virtual Sport 3 : 231

	VSoutright vs VSHorceRace	
	181
	182
	183
	184
	185
	
	Saba.games (150,200); bettype 1651
	Vgaming (171,173); bettype 3844
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @transId VARCHAR(MAX) = ''
	DECLARE @date_compare DATETIME 
		   ,@date		  DATETIME

	SET @date = CONVERT(VARCHAR(12), GETDATE(),101)
	SET @date_compare = DATEADD (MI,-30,GETDATE())

	DECLARE @IsVS		BIT = 0
		  , @IsNG		BIT = 0
		  , @IsHappy5	BIT = 0
		  , @IsSaba		BIT = 0
		  , @IsVgaming	BIT = 0

	DECLARE @tblMatch TABLE (matchid INT, sporttype SMALLINT)
	DECLARE @tmpTicket TABLE (transid BIGINT, sporttype SMALLINT)
	
	IF @tablename = 'bettrans'
	BEGIN
		INSERT INTO @tblMatch (matchid,sporttype)
		SELECT matchid,m.sporttype
		FROM bodb02.dbo.Match m WITH (NOLOCK)
			INNER JOIN bodb02.dbo.league l WITH (NOLOCK) ON l.leagueid = m.LeagueID AND l.isTest = 0
		WHERE (m.Sporttype IN (161,164,180,231) OR m.sporttype BETWEEN 186 AND 199) 
				AND m.kickofftime < @date_compare
				AND m.eventdate = @date
		UNION ALL
		SELECT o.EventID, o.SportType
		FROM bodb02.dbo.VSRaceInfo o WITH (NOLOCK) 
			INNER JOIN bodb02.dbo.league l WITH (NOLOCK) ON l.leagueid = o.LeagueID AND l.isTest = 0
		WHERE o.Sporttype IN (181,182,183,184,185) 
				AND o.EventTime < @date_compare
				AND o.EventTime >= @date AND o.EventTime < DATEADD(d, 1, @date)

		INSERT INTO @tmpTicket (sporttype, transid)
		SELECT TOP (100) m.sporttype, b.transid
		FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
				INNER JOIN @tblMatch m ON b.matchid = m.matchid
		WHERE	b.bettype < 20000 AND b.statusID = 0
	
		SELECT @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM @tmpTicket

		IF @transId <> ''
		BEGIN
			SET @IsVS = (SELECT TOP 1 1 FROM @tmpTicket WHERE (sporttype BETWEEN 180 AND 199) OR sporttype = 231)
						
			SET @isNG = (SELECT TOP 1 1 FROM @tmpTicket WHERE sporttype = 161)
							
			SET @IsHappy5 = (SELECT TOP 1 1 FROM @tmpTicket WHERE sporttype = 164)
		
			SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
					,@ErrCode = 100
					,@ErrMsg = 'All today tickets running > 30 minutes must be settled on' 
								+ CASE WHEN @IsVS = 1 THEN  ' Virtual Sports' ELSE '' END
								+ CASE WHEN @isNG = 1 THEN  ' Number Games' ELSE '' END
								+ CASE WHEN @IsHappy5 = 1 THEN  ' Happy 5' ELSE '' END
					,@SampleData = @tablename + '.TransId in (' + @transId + ')'
		END
	END
	ELSE IF @tablename = 'bettransRNG'
	BEGIN
		INSERT INTO @tmpTicket (sporttype, transid)
		SELECT TOP (100) b.productID AS sporttype, b.transid
		FROM	bodb02.dbo.bettransRNG b WITH (NOLOCK)
		WHERE	b.statusID = 0
				AND b.productID IN (150,200,171,173)
				AND b.GameID IN (1651,3844)
				AND b.transdate < @date_compare
		
		SELECT @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM @tmpTicket

		IF @transId <> ''
		BEGIN
			SET @IsSaba = (SELECT TOP 1 1 FROM @tmpTicket WHERE sporttype IN (150,200))

			SET @IsVgaming = (SELECT TOP 1 1 FROM @tmpTicket WHERE sporttype IN (171,173))

			SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
					,@ErrCode = 100
					,@ErrMsg = 'All today tickets running > 30 minutes must be settled on' 
								+ CASE WHEN @IsSaba = 1 THEN  ' Saba.games' ELSE '' END
								+ CASE WHEN @IsVgaming = 1 THEN  ' Vgaming' ELSE '' END
					,@SampleData = @tablename + '.TransId in (' + @transId + ')'
		END
	END

END
GO