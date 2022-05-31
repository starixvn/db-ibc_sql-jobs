/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_Sum_Winloss_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: Task_Archive_SelectSum_Winloss 
	
	Revisions:
		- 20130831@Bobby: Init
		- 20220519@Danny: Add more fields LeagueGroupID and TicketType [Redmine: #167177]
 */
BEGIN
	SET NOCOUNT ON

	Declare @min_winlostdate smalldatetime,
	  @max_winlostdate smalldatetime

	SELECT
	 @min_winlostdate = @winlostdate,
	 @max_winlostdate = @winlostdate

	--SELECT
	-- @min_winlostdate = MIN(winlostdate),
	-- @max_winlostdate = MAX(winlostdate)
	--FROM dbo.Task_ArchiveDate

	-- to DB053/DB054.bodb_Summary.dbo.sum_winloss_old
	-- JOE : Remark for SSIS, don't set Enable IDENTITY INSERT
	SELECT
	 [winlostdate],[username],[custid],[roleid],[recommend],[mrecommend],[srecommend],
	 [turnover],[winlost],[awinlost],[mwinlost],[swinlost],[playercomm],[comm],[acomm],[scomm]
	 ,[BetCount],[grosscomm],[sporttype],[bettype],[netTurnover],[TunroverNoDraw], [ExtraWinloss], [ExtraComm], [leagueGroupID], [ticketType]
	FROM dbo.sum_winloss  WITH(NOLOCK)
	WHERE winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
END
GO
