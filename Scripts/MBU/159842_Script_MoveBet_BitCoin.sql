/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20210927@Helen
	Task: Script movebet Bitcoin
	DB: DBPRO/bodb02
	Revisions:   
		- 20210927@Helen: Initial [Redmine: #159842] 

*/

CREATE TABLE #__IdsList (rowId int identity(1,1) primary key, Id int)

----------- Table Odds3rd ---------------
INSERT INTO #__IdsList(Id)
SELECT o.oddsid
FROM match3rd14 m WITH (NOLOCK)
	INNER JOIN Odds3rd o WITH (NOLOCK) ON m.match3rdid = o.matchid
WHERE eventdate < '2021-09-23 00:00:00.000' and EventDate IN ('2021-09-21','2021-09-22')

INSERT INTO	dbo.Odds3rd14
	(	oddsid, matchid, odds3rdid, bettype, hdp1, hdp2, odds1a, odds2a, oddsstatus, changetime, creator, com1, comx, com2, cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32, cs33, cs23, cs13, cs03, cs99, sporttype, cs04, cs05, Resourceid)
SELECT	oddsid, matchid, odds3rdid, bettype, hdp1, hdp2, odds1a, odds2a, oddsstatus, changetime, creator, com1, comx, com2, cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32, cs33, cs23, cs13, cs03, cs99, sporttype, cs04, cs05, Resourceid
FROM	dbo.Odds3rd WITH (NOLOCK)
WHERE	oddsid IN (SELECT id from #__IdsList)

DELETE 
FROM	dbo.Odds3rd 
WHERE	oddsid IN (SELECT id from #__IdsList)

----------- Table ResultDetail3rd ---------------
TRUNCATE TABLE #__IdsList

INSERT INTO #__IdsList(Id)
SELECT ResultID
FROM match3rd14 m (nolock)
	INNER JOIN ResultDetail3rd o with(nolock) on m.match3rdid = o.matchid
WHERE eventdate < '2021-09-23 00:00:00.000' and EventDate IN ('2021-09-21','2021-09-22')

INSERT INTO	dbo.ResultDetail3rd14
		(	ResultID, VendorID, MatchID, GameID, Custom1, Custom2, Custom3, ResultStatusID, SettlementStatusID, GameResult, OtherInfo, CreateBy, CreateDate, LastModifyBy, LastModifyDate, ResourceId)
SELECT	ResultID, VendorID, MatchID, GameID, Custom1, Custom2, Custom3, ResultStatusID, SettlementStatusID, GameResult, OtherInfo, CreateBy, CreateDate, LastModifyBy, LastModifyDate, ResourceId
FROM	dbo.ResultDetail3rd WITH (NOLOCK)
WHERE	ResultID IN (SELECT id from #__IdsList)

DELETE 
FROM	dbo.ResultDetail3rd
WHERE	ResultID IN (SELECT id from #__IdsList)
