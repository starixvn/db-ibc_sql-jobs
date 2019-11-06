/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_OtherSportsStatusChecking]
	@ProductId		INT		= 0
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
	
	Param's Expanation:
	Number Game: 161 ; bettype: 81 - 120
	Happy 5:164; bettype: 8101-8120
	Virtual Sport, Virtual Sport 2 - bettype: 180 - 199
		VS: bettype 1201 AND 1299
		VS2:bettype BETWEEN 2700 AND 2899
	
	VSoutright vs VSHorceRace	
	181
	182
	183
	184
	185
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @transId VARCHAR(MAX)
	DECLARE @date_compare DATETIME 
	DECLARE @tblMatch TABLE (matchid INT, sporttype SMALLINT)
	DECLARE @IsVS BIT = 0, @isNG BIT = 0, @IsHappy5 BIT = 0
	
	DECLARE @date datetime
	
	SET @date = CONVERT(VARCHAR(12), GETDATE(),101)
	SET @date_compare = DATEADD (MI,-30,GETDATE())
	
	SET @transId = ''
	
	INSERT INTO @tblMatch (matchid,sporttype)
	SELECT matchid,m.sporttype
	FROM bodb02.dbo.Match m WITH (NOLOCK)
		INNER JOIN bodb02.dbo.league l WITH (NOLOCK) ON l.leagueid = m.LeagueID AND l.isTest = 0
	WHERE (m.Sporttype IN (161,164,180) OR m.sporttype BETWEEN 186 AND 199) 
			and m.eventstatus = 'Completed' 
			AND m.kickofftime < @date_compare
			AND m.eventdate = @date
	UNION ALL
	SELECT o.EventID, o.SportType
	FROM bodb02.dbo.VSRaceInfo o WITH (NOLOCK) 
		INNER JOIN bodb02.dbo.league l WITH (NOLOCK) ON l.leagueid = o.LeagueID AND l.isTest = 0
	WHERE o.Sporttype IN (181,182,183,184,185) AND o.eventstatus = 'Completed'	
			AND o.EventTime < @date_compare
			AND o.EventTime >= @date AND o.EventTime < DATEADD(d, 1, @date)

	SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
	FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
	WHERE	b.bettype < 20000
			AND b.statusID = 0
			AND b.matchid IN (SELECT matchid FROM @tblMatch)
	
	IF @transId <> ''
	BEGIN
		SET @IsVS = (SELECT TOP 1 1 
					FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
					WHERE	b.bettype < 20000
						AND b.statusID = 0
						AND b.matchid IN (SELECT matchid FROM @tblMatch WHERE sporttype BETWEEN 180 AND 199))
						
		SET @isNG = (SELECT TOP 1 1 
					FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
					WHERE	b.bettype < 20000
						AND b.statusID = 0
						AND b.matchid IN (SELECT matchid FROM @tblMatch WHERE sporttype = 161) )
							
		SET @IsHappy5 = (SELECT TOP 1 1 
					FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
					WHERE	b.bettype < 20000
						AND b.statusID = 0
						AND b.matchid IN (SELECT matchid FROM @tblMatch WHERE sporttype = 164) )								
	END
	IF @transId <> ''
	BEGIN
		SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'All today tickets running > 30 minutes must be settled on' + CASE WHEN @IsVS = 1 THEN  ' Virtual Sports' ELSE '' END
							+ CASE WHEN @isNG = 1 THEN  ' Number Games' ELSE '' END
							+ CASE WHEN @IsHappy5 = 1 THEN  ' Happy 5' ELSE '' END
				
				,@SampleData = 'bettrans.TransId in (' + @transId + ')'
	END

END
GO