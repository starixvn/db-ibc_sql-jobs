/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_OtherSportsPendingMatchChecking]
	@ProductId		INT = 0		
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20191025@Helen
	Task: Data consistency 
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20191025@Helen: Detect Yesterday pending  matches for Virtual sports, Virtual sports 2 [Redmine:#122716]
		- 20230414@July: Remove checking VSRaceInfo because this game is not offered anymore [Redmine:#186736]
	
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @matchid VARCHAR(MAX) = ''
	       ,@yesterday DATETIME 

	DECLARE @tblMatch TABLE (matchid INT)
	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
	
	INSERT INTO @tblMatch(matchid)
	SELECT matchid
	FROM bodb02.dbo.Match m WITH (NOLOCK)
		INNER JOIN bodb02.dbo.league l WITH (NOLOCK) ON l.leagueid = m.LeagueID AND l.isTest = 0
	WHERE (m.Sporttype= 180 OR m.sporttype BETWEEN 186 AND 199) and m.eventstatus = 'running' 
		AND m.eventdate = @yesterday
	
	SELECT TOP (100) @matchid = @matchid + ',' + CAST(matchid AS VARCHAR(50))
	FROM	@tblMatch
	
	IF @matchid <> ''
	BEGIN
		SELECT	@matchid = SUBSTRING(@matchid, 2, LEN(@matchid) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'Detect yesterday pending matches for Virtual Sports not completed yet'
				,@SampleData = 'Match.matchid in (' + @matchid + ')'
	END

END
GO