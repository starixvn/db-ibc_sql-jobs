/*<info serverAlias="DBARC-bodb_Report"></info>*/
/*
	Created: 20230504@Bobby
	Task: 172604 - LAP - Winloss Analysis - Setup DB structure
	DB: DBARC.bodb_Report
	Remark: 
		- Run on DB061 or DB062 only
*/
use [bodb_Report]
go
  
CREATE TABLE [dbo].[rptLicenseeWinloss_UAT](
	[Recommend] [int] NOT NULL,
	[WinlostDate] [smalldatetime] NOT NULL,
	[Product3rdId] [tinyint] NOT NULL,
	[Sporttype] [smallint] NOT NULL,
	[Bettype] [smallint] NOT NULL,
	[CustId] [int] NOT NULL,
	[StatusId] [smallint] NOT NULL,
	[LiveIndicator] [tinyint] NOT NULL,
	[LeagueGroupId] [smallint] NOT NULL,
	[TicketType] [tinyint] NOT NULL,
	[Betfrom] [varchar](4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[APositiontaking] [smallmoney] NULL,
	[BetCount] [int] NULL,
	[Turnover] [money] NULL,
	[NetTurnover] [money] NULL,
	[Winlost] [money] NULL,
	[PComm] [money] NULL,
	[AWinlost] [money] NULL,
	[AComm] [money] NULL
) ON [DATA];
GO

CREATE CLUSTERED INDEX CIX_Winlostdate ON [dbo].[rptLicenseeWinloss_UAT]([WinlostDate], [Recommend])
GO