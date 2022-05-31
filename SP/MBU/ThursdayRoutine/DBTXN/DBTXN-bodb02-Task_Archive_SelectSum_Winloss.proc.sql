SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_SelectSum_Winloss
AS
/*
	Created:	Unknown
	Task :		Package SSIS insert into sum_winloss_old
	Database:	DBTXN.bodb02

	Revisions:
		- 20160225@Sophia: Add column TunroverNoDraw [Redmine: #51427]
		- 20200723@Patrick: Add more fields (ExtraWinloss, ExtraComm) [Redmine: #138198]
		- 20221002@Danny: Add more fields LeagueGroupID and TicketType [Redmine: #167177]	
*/

SET NOCOUNT ON

Declare @min_winlostdate smalldatetime,
  @max_winlostdate smalldatetime
SELECT
 @min_winlostdate = MIN(winlostdate),
 @max_winlostdate = MAX(winlostdate)
FROM dbo.Task_ArchiveDate

-- to DB053/DB054.bodb_Summary.dbo.sum_winloss_old
-- JOE : Remark for SSIS, don't set Enable IDENTITY INSERT
SELECT
 [winlostdate],[username],[custid],[roleid],[recommend],[mrecommend],[srecommend],
 [turnover],[winlost],[awinlost],[mwinlost],[swinlost],[playercomm],[comm],[acomm],[scomm],
 [BetCount],[grosscomm],[sporttype],[bettype],[netTurnOver],[TunroverNoDraw], [ExtraWinloss], [ExtraComm], [leagueGroupID], [ticketType]
FROM dbo.sum_winloss  WITH(NOLOCK)
WHERE winlostdate
BETWEEN @min_winlostdate AND @max_winlostdate
GO


/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/