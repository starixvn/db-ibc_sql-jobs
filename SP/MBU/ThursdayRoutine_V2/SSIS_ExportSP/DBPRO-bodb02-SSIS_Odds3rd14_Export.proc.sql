/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_Odds3rd14_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBPRO.bodb02
	Original: DB06x.bodb_archive.Task_Archive_Event_Copy
	
	Revisions:
		- 20130831@Bobby: Init
 */
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT	oddsid, matchid, odds3rdid, bettype, hdp1, hdp2, odds1a, odds2a, oddsstatus, changetime, creator, com1, comx, com2, cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32
		,	cs33, cs23, cs13, cs03, cs99, sporttype, cs04, cs05, Resourceid
	FROM	dbo.Odds3rd14 AS t1 WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate)
	UNION
	SELECT	oddsid, matchid, odds3rdid, bettype, hdp1, hdp2, odds1a, odds2a, oddsstatus, changetime, creator, com1, comx, com2, cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32
		,	cs33, cs23, cs13, cs03, cs99, sporttype, cs04, cs05, Resourceid
	FROM	dbo.Odds3rd14 AS t1 WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match3rd14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.match3rdid AND t2.eventdate = @winlostdate);
END
GO
