/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20210929@July
	Task: Script movebet Bitcoin
	DB: DBPRO/bodb02
	Revisions:   
		- 20210929@July: Initial [Redmine: #159842] 

*/

CREATE TABLE #__IdsList (rowId int identity(1,1) primary key, Id int)

----------- Table ResultDetail3rd ---------------

INSERT INTO #__IdsList(Id)
SELECT ResultID
FROM match3rd14 m (nolock)
	INNER JOIN ResultDetail3rd o with(nolock) on m.match3rdid = o.matchid
WHERE eventdate < '2021-09-26 00:00:00.000' and EventDate IN ('2021-09-17','2021-09-18','2021-09-19','2021-09-20')

INSERT INTO	dbo.ResultDetail3rd14
		(	ResultID, VendorID, MatchID, GameID, Custom1, Custom2, Custom3, ResultStatusID, SettlementStatusID, GameResult, OtherInfo, CreateBy, CreateDate, LastModifyBy, LastModifyDate, ResourceId)
SELECT	ResultID, VendorID, MatchID, GameID, Custom1, Custom2, Custom3, ResultStatusID, SettlementStatusID, GameResult, OtherInfo, CreateBy, CreateDate, LastModifyBy, LastModifyDate, ResourceId
FROM	dbo.ResultDetail3rd WITH (NOLOCK)
WHERE	ResultID IN (SELECT id from #__IdsList)

DELETE 
FROM	dbo.ResultDetail3rd
WHERE	ResultID IN (SELECT id from #__IdsList)
