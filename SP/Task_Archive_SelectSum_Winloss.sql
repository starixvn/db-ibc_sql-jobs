ALTER PROCEDURE [dbo].[Task_Archive_SelectSum_Winloss]
AS

/*
    Created: Unknown
    Task :  Package SSIS insert into sum_winloss_old
    DB: DBTXN/bodb02 
	Revisions:
		- 20160225@Sophia: Add column TurnoverNoDraw [Redmine: #51427]
*/

SET NOCOUNT ON

Declare @min_winlostdate smalldatetime,
  @max_winlostdate smalldatetime
SELECT
 @min_winlostdate = MIN(winlostdate),
 @max_winlostdate = MAX(winlostdate)
FROM dbo.Task_ArchiveDate

-- to DB053/DB054.bodb_Summary.dbo.sum_winloss_old
SELECT
 [winlostdate],[username],[custid],[roleid],[recommend],[mrecommend],[srecommend],
 [turnover],[winlost],[awinlost],[mwinlost],[swinlost],[playercomm],[comm],[acomm],[scomm],
 [BetCount],[grosscomm],[sporttype],[bettype],[netTurnOver],[TunroverNoDraw]
FROM dbo.sum_winloss
WHERE winlostdate
BETWEEN @min_winlostdate AND @max_winlostdate