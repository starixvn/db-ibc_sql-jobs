USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_Archive_SelectBettrans]    Script Date: 10/12/2015 22:30:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_SelectBettrans]
	AS
SET NOCOUNT ON

Declare @winlostdate smalldatetime
SELECT TOP 1 @winlostdate = winlostdate FROM dbo.Task_ArchiveDate
ORDER BY 1

PRINT CONVERT(varchar(10), @winlostdate, 120)

-- to DB06.bodb_Archive.dbo.bettrans_bk
SELECT 
	CONVERT(varchar(50), [betcheck]) BetCheck,
	CONVERT(varchar(1),  [betfrom]) BetFrom,
	CONVERT(varchar(10), [betteam]) BetTeam,
	CONVERT(varchar(15), [ip]) IP,
	CONVERT(varchar(10), [status]) [Status],

	[acomm],[actual_stake],[actualrate],[adiscount],[apositiontaking],[awinlost],
	[balance],[betdaqid],[betid],[bettype],
	[checktime],[comm],[comstatus],[creator],[currency],[currency2],[custid],
	[discount],[hdp1],[hdp2],[liveawayscore],[livehomescore],[liveindicator],
	[matchid],[modds],[mpositiontaking],[mrecommend],[mwinlost],[odds],[oddsid],[oddsspread],[oddstype],
	[playercomm],[playerdiscount],[recommend],[refno],[ruben],
	[scomm],[sdiscount],[SecAcceptFlag],[spositiontaking],[srecommend],[stake],[statusID],[statuswinlost],[swinlost],
	[tpositiontaking],[transdate],[transdesc],b.[transid],[transid2],[tstamp],
	[virtualrate],[winlost],b.[winlostdate],
	IP.countryShort countryCode

FROM dbo.bettrans14 b
	INNER JOIN dbo.Task_bettrans14_IP2Country IP
	ON b.transid = IP.transid
WHERE 
	b.winlostdate = @winlostdate
--BETWEEN ' xxxx 2010' AND ' yyyy 2010'

DELETE FROM dbo.Task_ArchiveDate
WHERE winlostdate = @winlostdate