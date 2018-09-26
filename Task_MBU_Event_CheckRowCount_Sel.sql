/*<info serverAlias="DB02-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_MBU_Event_CheckRowCount_Sel]
	@DateCheck SMALLDATETIME,
	@OutputData VARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20180925@Patrick
	Task: Check consistency data for archiving process
		
	Revisions:
		- 20180926@Patrick:	Initial - [RedmineId: #101207]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @__tempCount TABLE (rowcnt INT, tableName VARCHAR(128))

	--//odds
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'odds' 
	FROM dbo.odds14 WITH(NOLOCK) 
	WHERE matchid IN (SELECT matchid FROM dbo.match14 WITH(NOLOCK) WHERE eventdate = @DateCheck)
	
	--//match
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'match' 
	FROM dbo.match14 WITH(NOLOCK)
	WHERE eventdate = @DateCheck
	
	--//BingoBall
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'BingoBall' 
	FROM dbo.BingoBall14 WITH(NOLOCK) 
	WHERE matchid IN (SELECT matchid FROM dbo.match14 WITH(NOLOCK) WHERE eventdate = @DateCheck)	

	--//outright
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'outright' 
	FROM dbo.outright14 WITH(NOLOCK)
	WHERE eventdate = @DateCheck

	--//VSOutright
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'VSOutright' 
	FROM dbo.VSOutright14 WITH(NOLOCK)
	WHERE eventdate = @DateCheck
	
	--//match_remark
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'match_remark' 
	FROM dbo.match_remark WITH(NOLOCK) 
	WHERE matchid IN (SELECT matchid FROM dbo.match14 WITH(NOLOCK) WHERE eventdate = @DateCheck)
	
	--//matchMaxbet
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'matchMaxbet' 
	FROM dbo.matchMaxbet14 WITH(NOLOCK) 
	WHERE matchid IN (SELECT matchid FROM dbo.match14 WITH(NOLOCK) WHERE eventdate = @DateCheck)
	
	--//ResultDetail
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'ResultDetail' 
	FROM dbo.ResultDetail14 WITH(NOLOCK) 
	WHERE matchid IN (SELECT matchid FROM dbo.match14 WITH(NOLOCK) WHERE eventdate = @DateCheck)

	--//ResultDetail3rd
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'ResultDetail3rd' 
	FROM dbo.ResultDetail3rd14 WITH(NOLOCK) 
	WHERE matchid IN (SELECT matchid FROM dbo.match14 WITH(NOLOCK) WHERE eventdate = @DateCheck)
	
	--//EventInfo3rd14
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'EventInfo3rd' 
	FROM dbo.EventInfo3rd14 WITH(NOLOCK)
	WHERE eventdate = @DateCheck
	
	--//AutoPayoutResult
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'AutoPayoutResult' 
	FROM dbo.AutoPayoutResult14 WITH(NOLOCK) 
	WHERE matchid IN (SELECT matchid FROM dbo.match14 WITH(NOLOCK) WHERE eventdate = @DateCheck)

	--//ProviderResultDetail
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'ProviderResultDetail' 
	FROM dbo.ProviderResultDetail14 WITH(NOLOCK) 
	WHERE matchid IN (SELECT matchid FROM dbo.match14 WITH(NOLOCK) WHERE eventdate = @DateCheck)

	--//Odds3rd
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'Odds3rd' 
	FROM dbo.Odds3rd14 WITH(NOLOCK) 
	WHERE matchid IN (SELECT matchid FROM dbo.match14 WITH(NOLOCK) WHERE eventdate = @DateCheck)

	--//Intg_OddsFeed_SettlementAction
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'Intg_OddsFeed_SettlementAction' 
	FROM dbo.Intg_OddsFeed_SettlementAction WITH(NOLOCK) 
	WHERE matchid IN (SELECT matchid FROM dbo.match14 WITH(NOLOCK) WHERE eventdate = @DateCheck)

	--//Intg_OddsFeed_SettlementAction_Outright
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'Intg_OddsFeed_SettlementAction_Outright'
	FROM dbo.Intg_OddsFeed_SettlementAction_Outright WITH(NOLOCK) 
	WHERE orid IN (SELECT orid FROM outright14 WITH(NOLOCK) WHERE eventdate = @DateCheck)

	--//Match3rd
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'Match3rd' 
	FROM dbo.Match3rd14 WITH(NOLOCK)
	WHERE eventdate = @DateCheck

	--//
	SELECT @OutputData = (
		SELECT rowcnt AS r, tableName AS t
		FROM @__tempCount
		FOR XML RAW ('r')
	)

END
GO
