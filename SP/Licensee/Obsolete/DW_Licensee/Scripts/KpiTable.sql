CREATE TABLE [dbo].[rptKPI_Account](
	[rptDate] [datetime] NOT NULL,
	[SiteID] [int] NOT NULL,
	[Hour] [tinyint] NOT NULL,
	[UniqueBettorCount] [int] NULL,
	[PeakBettorCount] [int] NULL,
 CONSTRAINT [PK_rptKPI_Account] PRIMARY KEY CLUSTERED 
(
	[rptDate] ASC,
	[SiteID] ASC,
	[Hour] ASC
) ON licensee_DW
) ON licensee_DW
CREATE TABLE [dbo].[rptKPI_Transfer](
	[rptDate] [datetime] NOT NULL,
	[SiteID] [int] NOT NULL,
	[CurrencyID] [int] NOT NULL,
	[TransferInCount] [int] NULL,
	[FirstTransferInAmt] [money] NULL,
	[FirstTransferInCount] [int] NULL,
	[TransferOutCount] [int] NULL,
 CONSTRAINT [PK_rptKPI_Transfer] PRIMARY KEY CLUSTERED 
(
	[rptDate] ASC,
	[SiteID] ASC,
	[CurrencyID] ASC
) ON licensee_DW
) ON licensee_DW


CREATE TABLE [dbo].[rptKPI_MTD](
	[rptDate] [datetime] NOT NULL,
	[SiteID] [int] NOT NULL,
	[StatID] [int] NOT NULL,
	[MonthToDate] [float] NULL,
 CONSTRAINT [PK_rptKPI_MTD] PRIMARY KEY CLUSTERED 
(
	[rptDate] ASC,
	[SiteID] ASC,
	[StatID] ASC
) ON licensee_DW
) ON licensee_DW

-- drop table [rpt_Betting]

CREATE TABLE [dbo].[rpt_Betting](
	RecordID bigint identity(1,1),
	[rptDate] [datetime] NOT NULL,
	[SiteID] [int] NOT NULL,
	[Bettype] [smallint] NOT NULL,
	[LeagueID] [int] NOT NULL,
	[CurrencyID] [int] NOT NULL,
	[Status] [smallint] NOT NULL,
	[IsLive] [bit] NOT NULL,
	[BetCount] [int] NULL,
	[MemberCount] [int] NULL,
	[Turnover] [money] NULL,
	[WinLoss] [money] NULL,
 CONSTRAINT [PK_rpt_Betting] PRIMARY KEY CLUSTERED 
(	RecordID ASC,
	[rptDate] ASC	
) ON ps_rptBetting_monthly(rptDate)
) ON ps_rptBetting_monthly(rptDate)

CREATE UNIQUE INDEX un_rpt_Betting 
ON rpt_Betting([rptDate] ASC,
			[SiteID] ASC,
			[Bettype] ASC,
			[LeagueID] ASC,
			[CurrencyID] ASC,
			[Status] ASC,
			[IsLive] ASC)
ON	ps_rptBetting_monthly(rptDate)

CREATE NONCLUSTERED INDEX nl_rpt_Betting_WinLoss
ON [dbo].[rpt_Betting] ([SiteID],[rptDate],[Bettype],leagueid,[IsLive])
INCLUDE ([CurrencyID],[BetCount],[Turnover],[WinLoss],[Comm],[Fee])

dbcc dbreindex ('rpt_Betting')

-- drop table [rpt_LicMemberBetting]

CREATE TABLE [dbo].[rpt_LicMemberBetting](
	[RecordID] [bigint] IDENTITY(1,1) NOT NULL,
	[rptDate] [datetime] NOT NULL,
	[CustID] [int] NOT NULL,
	[LicenseeID] [int] NOT NULL,
	[Bettype] [smallint] NOT NULL,
	[SportID] [smallint] NOT NULL,
	[CurrencyID] [int] NOT NULL,
	[Status] [smallint] NOT NULL,
	[IsLive] [bit] NOT NULL,
	[BetCount] [int] NULL,
	[Turnover] [money] NULL,
	[WinLoss] [money] NULL,
	[WinLossA] [money] NULL,
	[CommissionA] [money] NULL,
	[WinLossVirtual] [money] NULL,
	[CommissionPVirtual] [money] NULL
) ON ps_rptBetting_monthly(rptDate)

CREATE CLUSTERED INDEX CIX_rpt_LicMemberBetting 
ON rpt_LicMemberBetting([rptDate] ASC,
            [CustID] ASC,
			[LicenseeID] ASC,
			[Bettype] ASC,
			[SportID] ASC,
			[CurrencyID] ASC,
			[Status] ASC,
			[IsLive] ASC)
ON	ps_rptBetting_monthly(rptDate)

-- drop table [rpt_LicMemberBetting_BA]

CREATE TABLE [dbo].[rpt_LicMemberBetting_BA](
	[RecordID] [bigint] IDENTITY(1,1) NOT NULL,
	[rptDate] [datetime] NOT NULL,
	[CustID] [int] NOT NULL,
	[LicenseeID] [int] NOT NULL,
	[Bettype] [smallint] NOT NULL,
	[SportID] [smallint] NOT NULL,
	[CurrencyID] [int] NOT NULL,
	[Status] [smallint] NOT NULL,
	[IsLive] [bit] NOT NULL,
	[DiscountLevel] [decimal](9,8) NOT NULL,
	[BetCount] [int] NULL,
	[Turnover] [money] NULL,
	[WinLoss] [money] NULL,
	[WinLossA] [money] NULL,
	[CommissionA] [money] NULL,
	[WinLossVirtual] [money] NULL,
	[CommissionPVirtual] [money] NULL
) ON ps_rptBetting_monthly(rptDate)

CREATE CLUSTERED INDEX CIX_rpt_LicMemberBetting_BA 
ON [rpt_LicMemberBetting_BA]([rptDate] ASC,
            [CustID] ASC,
			[LicenseeID] ASC,
			[Bettype] ASC,
			[SportID] ASC,
			[CurrencyID] ASC,
			[Status] ASC,
			[IsLive] ASC,
            [DiscountLevel] ASC)
ON	ps_rptBetting_monthly(rptDate)


--FOREIGN KEY
/*
ALTER TABLE [dbo].[rptKPI_MTD]  WITH NOCHECK ADD  CONSTRAINT [FK_rptKPI_MTD_tbl_KPIStat] FOREIGN KEY([StatID])
REFERENCES [dbo].[tblKPI_Stats] ([StatID])
NOT FOR REPLICATION
ALTER TABLE [dbo].[rptKPI_MTD] NOCHECK CONSTRAINT [FK_rptKPI_MTD_tbl_KPIStat]
*/

