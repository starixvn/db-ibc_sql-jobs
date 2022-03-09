/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_Match3rd14_Export]
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
	
	SELECT	Match3rdId, League3rdId, HomeId, AwayId, EventDate, SportType, VendorMatchId, MatchNo, EventStatus, CreateTime, UpdateTime, StartTime, MarketEndTime, EndTime, BetStatus
	FROM	dbo.Match3rd14 AS t1 WITH (NOLOCK)
	WHERE	t1.eventdate = @winlostdate;
END
GO
