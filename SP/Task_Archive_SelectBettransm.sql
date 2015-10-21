USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_Archive_SelectBettransm]    Script Date: 10/12/2015 22:30:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_SelectBettransm]
	AS
SET NOCOUNT ON

Declare @min_winlostdate smalldatetime,
		@max_winlostdate smalldatetime
SELECT
	@min_winlostdate = MIN(winlostdate),
	@max_winlostdate = MAX(winlostdate)
FROM dbo.Task_ArchiveDate

-- to DB06.bodb_Archive.dbo.bettransm
SELECT 
	CONVERT(varchar(50), [betcheck]) BetCheck,
	CONVERT(varchar(1),  [betfrom]) BetFrom,
	CONVERT(varchar(10), [betteam]) BetTeam,
	CONVERT(varchar(20), [comstatus]) ComStatus,
	CONVERT(varchar(10), [status]) Status,

	[transdate],[transid],[custid],[matchid],[oddsid],[bettype],[hdp1],[hdp2],[stake],[odds],[finalodds],
	[apositiontaking],[mpositiontaking],[spositiontaking],[tpositiontaking],[awinlost],[mwinlost],[swinlost],
	[playerdiscount],[discount],[adiscount],[sdiscount],[playercomm],[comm],[acomm],[scomm],
	[liveawayscore],[livehomescore],[liveindicator],[matchdate],[isfinish],
	[oddsspread],[refno],[ruben],[statusID],[statuswinlost],[winlost],
	[actualrate],[checktime],[creator],[winlostdate]
FROM dbo.bettransm14
WHERE winlostdate
--BETWEEN @min_winlostdate AND @max_winlostdate
<= @max_winlostdate