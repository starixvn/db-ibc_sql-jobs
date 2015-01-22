USE [bodb_Archive]
GO

/****** Object:  StoredProcedure [dbo].[TASK_NonPartionedTable_ArchivedData_Purge]    Script Date: 01/22/2015 00:16:22 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[TASK_NonPartionedTable_ArchivedData_Purge]


AS
/*
	Created by: Francis
	CreatedDate: 2014-12-11
	Task: Purge over-18-month data for non-partitioned tables in bodb_Archive 
	DB: DBTP.bodb_Archive

	Revisions:
*/
BEGIN

	set nocount on;

	if @@SERVERNAME <> 'DBTP'
		return
	
	declare @fromdate datetime, @todate datetime

	--get the first day of the month that is 19-month-ago from the current time 
	select @fromdate = DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(MONTH,-18,GETDATE())), 0)
	--get the last day of the month that is 19-month-ago from the current time
	select @todate = DATEADD(DAY,-1,DATEADD(MONTH,1,@fromdate))

	if OBJECT_ID('tempdb..#tmp_match') IS NOT NULL
		drop table #tmp_match

	create table #tmp_match (matchid int)

	insert into #tmp_match
	select matchid from dbo.match_bk with (nolock)
	where eventdate between @fromdate and @todate
	
	--indexed on matchid
	delete dbo.match_bk
	where matchid in (select matchid from #tmp_match)
	
	delete dbo.bingoBall_bk
	where matchid in (select matchid from #tmp_match)
	
	delete dbo.Dot_Admin_Assignment_Operator_bk
	where matchid in (select matchid from #tmp_match)
	
	delete dbo.Dot_Admin_LiveLog
	where matchid in (select matchid from #tmp_match)
	
	delete dbo.MatchMaxbet_bk
	where matchid in (select matchid from #tmp_match)
	
	delete dbo.odds_bk
	where matchid in (select matchid from #tmp_match)
	
	delete dbo.ResultDetail_bk
	where matchid in (select matchid from #tmp_match)
	
	delete dbo.SS_GameState_bk
	where matchid in (select matchid from #tmp_match)
	
	--not indexed on matchid
	delete dbo.BetParlayResult
	where winlostdate between @fromdate and @todate
	
	delete dbo.outright_bk
	where eventdate between @fromdate and @todate
	
	delete dbo.VSOutright_bk
	where eventdate between @fromdate and @todate
	
	delete dbo.zzzbettrans
	where winlostdate between @fromdate and @todate

	if OBJECT_ID('tempdb..#tmp_Match') IS NOT NULL
		drop table #tmp_Match
END




GO

GRANT VIEW DEFINITION ON [dbo].[TASK_NonPartionedTable_ArchivedData_Purge] TO [vnteam] AS [dbo]
GO


