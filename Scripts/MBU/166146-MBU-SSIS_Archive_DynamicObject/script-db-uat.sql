/*<info serverAlias="DBARC-msdb"></info>*/
USE [master]
GO

CREATE DATABASE [bodb_archive_uat]
 ON  PRIMARY 
( NAME = N'bodb_Archive_uat_Data', FILENAME = N'G:\USER_DB\bodb_archive_uat\bodb_archive_uat.MDF' , SIZE = 4096KB , MAXSIZE = UNLIMITED, FILEGROWTH = 4096KB )
 LOG ON 
( NAME = N'bodb_Archive_uat_Log', FILENAME = N'G:\USER_DB\bodb_archive_uat\bodb_archive_uat_log.LDF' , SIZE = 4096KB , MAXSIZE = UNLIMITED , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO
ALTER DATABASE [bodb_archive_uat] ADD FILEGROUP [DATA]
ALTER DATABASE [bodb_archive_uat] ADD FILE ( NAME = N'DATA', FILENAME = N'G:\USER_DB\bodb_archive_uat\DATA.ndf' , SIZE = 8192KB , FILEGROWTH = 65536KB ) TO FILEGROUP [DATA]

USE [bodb_archive_uat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AutoPayoutResult_bk](
	[AutoPayoutResultId] [int] NOT NULL,
	[MatchId] [int] NOT NULL,
	[CalculationType] [tinyint] NOT NULL,
	[SourceId] [tinyint] NULL,
	[HomeValue] [varchar](50) NULL,
	[AwayValue] [varchar](50) NULL,
	[StatusId] [tinyint] NULL,
	[TryCount] [tinyint] NULL,
	[CreatedDate] [datetime] NULL,
	[ModifiedDate] [datetime] NULL,
 CONSTRAINT [PK_AutoPayoutResult_bk] PRIMARY KEY NONCLUSTERED 
(
	[AutoPayoutResultId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO

CREATE CLUSTERED INDEX [CIX_AutoPayoutResult_bk] ON [dbo].[AutoPayoutResult_bk]
(
	[MatchId] ASC,
	[CalculationType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AutoPayoutResult_bk_Temp](
	[MatchId] [int] NOT NULL,
	[CalculationType] [tinyint] NOT NULL,
	[SourceId] [tinyint] NULL,
	[HomeValue] [varchar](50) NULL,
	[AwayValue] [varchar](50) NULL,
	[StatusId] [tinyint] NULL,
	[TryCount] [tinyint] NULL,
	[CreatedDate] [datetime] NULL,
	[ModifiedDate] [datetime] NULL
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AutoRefundResult_bk](
	[AutoRefundResultId] [int] NOT NULL,
	[MatchId] [int] NOT NULL,
	[SourceId] [tinyint] NULL,
	[TypeId] [tinyint] NULL,
	[StatusId] [tinyint] NULL,
	[TryCount] [tinyint] NULL,
	[CreateDate] [datetime] NULL,
	[ModifiedDate] [datetime] NULL,
	[Remark] [varchar](1000) NULL,
 CONSTRAINT [PK_AutoRefundResult_bk] PRIMARY KEY CLUSTERED 
(
	[AutoRefundResultId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BalNetPosition_bk](
	[CustID] [int] NOT NULL,
	[MatchID] [int] NOT NULL,
	[Bettype] [smallint] NOT NULL,
	[Debit] [money] NOT NULL,
	[Credit] [money] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ArchiveDate] [date] NULL,
 CONSTRAINT [PK_BalNetPosition_bk] PRIMARY KEY CLUSTERED 
(
	[CustID] ASC,
	[MatchID] ASC,
	[Bettype] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BetLucky3Result_bk](
	[MatchId] [int] NOT NULL,
	[TransId] [bigint] NOT NULL,
	[CustId] [int] NOT NULL,
	[Bettype] [smallint] NOT NULL,
	[Currency] [tinyint] NOT NULL,
	[Hdp1] [smallmoney] NOT NULL,
	[Odds] [smallmoney] NOT NULL,
	[StatusId] [tinyint] NOT NULL,
	[Hits] [smallint] NOT NULL,
	[Prize] [tinyint] NOT NULL,
	[PrizeAmount] [money] NULL,
	[Winlost] [money] NULL,
	[aWinlost] [money] NULL,
	[mWinlost] [money] NULL,
	[sWinlost] [money] NULL,
	[PlayerComm] [money] NULL,
	[Comm] [money] NULL,
	[aComm] [money] NULL,
	[sComm] [money] NULL,
	[aPositionTaking] [smallmoney] NOT NULL,
	[mPositionTaking] [smallmoney] NOT NULL,
	[sPositionTaking] [smallmoney] NOT NULL,
	[PlayerDiscount] [decimal](9, 8) NOT NULL,
	[Discount] [decimal](9, 8) NOT NULL,
	[aDiscount] [decimal](9, 8) NOT NULL,
	[sDiscount] [decimal](9, 8) NOT NULL,
	[TransDesc] [nvarchar](1000) NULL,
	[WinlostDate] [smalldatetime] NULL
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BetParlayResult](
	[rID] [bigint] NOT NULL,
	[RefNo] [bigint] NULL,
	[Serial] [int] NULL,
	[transid] [bigint] NULL,
	[winlostdate] [smalldatetime] NULL,
	[statusid] [tinyint] NULL,
	[stake] [money] NULL,
	[Odds] [money] NULL,
	[mOdds] [money] NULL,
	[winlost] [money] NULL,
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[swinlost] [money] NULL,
	[playercomm] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[scomm] [money] NULL,
PRIMARY KEY CLUSTERED 
(
	[rID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[betParlayResult_Archive](
	[rID] [bigint] NOT NULL,
	[RefNo] [bigint] NULL,
	[Serial] [int] NULL,
	[winlostdate] [smalldatetime] NULL,
	[statusid] [tinyint] NULL,
	[Odds] [money] NULL,
	[mOdds] [money] NULL,
 CONSTRAINT [PK_betParlayResult_Archive] PRIMARY KEY CLUSTERED 
(
	[rID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BetTradeSelling180](
	[TradeID] [bigint] NOT NULL,
	[TicketID] [bigint] NULL,
	[MatchID] [int] NULL,
	[BuyBackNo] [bigint] NULL,
	[PayOut] [money] NULL,
	[PricingID] [varchar](50) NULL,
	[Status] [varchar](50) NULL,
	[CustID] [int] NULL,
	[CreateDate] [datetime] NULL,
	[ChangeDate] [datetime] NULL,
	[SBComm] [money] NULL,
	[ClientComm] [money] NULL,
	[BadDebtBySB] [money] NULL,
	[BadDebtByBT] [money] NULL,
	[StakeSold] [money] NULL,
	[PaidAmt] [money] NULL,
	[BetTradeCustID] [int] NULL,
	[VendorID] [smallint] NULL,
	[PreviousStake] [money] NULL,
	[SoldTicketID] [bigint] NULL,
	[MatchEventDate] [datetime] NOT NULL,
 CONSTRAINT [PK_BetTradeSelling180] PRIMARY KEY NONCLUSTERED 
(
	[TradeID] ASC,
	[MatchEventDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
CREATE CLUSTERED INDEX [IX_MatchEventData] ON [dbo].[BetTradeSelling180]
(
	[MatchEventDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BetTradeSellingCancelled180](
	[TicketID] [bigint] NULL,
	[Remark] [nvarchar](300) NULL,
	[BTBuyBack] [money] NULL,
	[BTComission] [money] NULL,
	[AfterBalance] [money] NULL,
	[Owner] [varchar](20) NULL,
	[Cancelled] [bit] NULL,
	[ChangeDate] [datetime] NULL,
	[CreateDate] [datetime] NULL,
	[TradeID] [bigint] NOT NULL,
	[MatchEventDate] [datetime] NOT NULL,
 CONSTRAINT [PK_BetTradeSellingCancelled] PRIMARY KEY CLUSTERED 
(
	[TradeID] ASC,
	[MatchEventDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[bettrans_AGCasino_bk](
	[TicketID] [bigint] NOT NULL,
	[CustID] [int] NULL,
	[Transdate] [datetime] NULL,
	[GameType] [varchar](10) NULL,
	[Stake] [money] NULL,
	[Actual_Stake] [money] NULL,
	[Winlost] [money] NULL,
	[Status] [nvarchar](10) NULL,
	[StatusID] [int] NULL,
	[PlayType] [smallint] NULL,
	[Winlostdate] [datetime] NULL,
	[Username] [varchar](50) NULL,
	[IP] [nvarchar](15) NULL,
	[recommend] [int] NULL,
	[mrecommend] [int] NULL,
	[srecommend] [int] NULL,
	[Currency] [tinyint] NULL,
	[IsVIPGame] [bit] NULL,
 CONSTRAINT [PK_AGCasino_TicketID] PRIMARY KEY CLUSTERED 
(
	[TicketID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[bettrans_bk](
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[oddsid] [int] NOT NULL,
	[hdp1] [smallmoney] NULL,
	[hdp2] [smallmoney] NULL,
	[odds] [smallmoney] NULL,
	[stake] [money] NOT NULL,
	[actual_stake] [money] NULL,
	[status] [varchar](10) NULL,
	[winlost] [money] NULL,
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[swinlost] [money] NULL,
	[playercomm] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[scomm] [money] NULL,
	[apositiontaking] [smallmoney] NULL,
	[mpositiontaking] [smallmoney] NULL,
	[spositiontaking] [smallmoney] NULL,
	[tpositiontaking] [smallmoney] NULL,
	[playerdiscount] [decimal](9, 8) NULL,
	[discount] [decimal](9, 8) NULL,
	[adiscount] [decimal](9, 8) NULL,
	[sdiscount] [decimal](9, 8) NULL,
	[livehomescore] [smallint] NULL,
	[liveawayscore] [smallint] NULL,
	[liveindicator] [bit] NULL,
	[betteam] [varchar](10) NULL,
	[creator] [int] NOT NULL,
	[refno] [bigint] NULL,
	[winlostdate] [smalldatetime] NULL,
	[betfrom] [varchar](1) NULL,
	[betcheck] [varchar](50) NULL,
	[checktime] [datetime] NULL,
	[oddsspread] [money] NULL,
	[actualrate] [float] NULL,
	[matchid] [int] NULL,
	[recommend] [int] NULL,
	[mrecommend] [int] NULL,
	[srecommend] [int] NULL,
	[ruben] [tinyint] NULL,
	[betid] [bigint] NULL,
	[statuswinlost] [tinyint] NULL,
	[modds] [smallmoney] NULL,
	[betdaqid] [bigint] NULL,
	[tstamp] [binary](8) NULL,
	[currency] [tinyint] NULL,
	[ip] [varchar](45) NULL,
	[transdesc] [nvarchar](1000) NULL,
	[virtualrate] [float] NULL,
	[oddstype] [tinyint] NULL,
	[statusID] [tinyint] NULL,
	[currency2] [tinyint] NULL,
	[transid] [bigint] NOT NULL,
	[bettype] [smallint] NULL,
	[balance] [money] NULL,
	[transid2] [bigint] NULL,
	[SecAcceptFlag] [bit] NULL,
	[recommdate] [datetime] NULL,
	[comstatus] [nvarchar](20) NULL,
	[CountryCode] [varchar](2) NULL,
	[ExtraInfo] [varchar](1000) NULL,
	[WalletType] [tinyint] NULL,
	[BonusID] [int] NULL,
	[RefCode] [bigint] NULL,
	[SettlementTime] [datetime] NULL,
	[epositiontaking] [smallmoney] NULL,
	[ReasonID] [smallint] NULL,
	[sort] [smallint] NULL
) ON [DATA] WITH (DATA_COMPRESSION = PAGE)
GO
ALTER TABLE [dbo].[bettrans_bk] SET (LOCK_ESCALATION = AUTO)
GO
CREATE CLUSTERED INDEX [CIX_winlostdate] ON [dbo].[bettrans_bk]
(
	[winlostdate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[bettrans_PlaytechCS_bk](
	[TicketID] [bigint] NOT NULL,
	[CustID] [int] NULL,
	[Transdate] [datetime] NULL,
	[SessionID] [bigint] NULL,
	[GameID] [int] NULL,
	[Windowcode] [int] NULL,
	[GameName] [varchar](50) NULL,
	[Stake] [money] NULL,
	[Actual_Stake] [money] NULL,
	[Winlost] [money] NULL,
	[Status] [nvarchar](10) NULL,
	[StatusID] [int] NULL,
	[Username] [varchar](50) NULL,
	[Winlostdate] [datetime] NULL,
	[PlaytechBalance] [money] NULL,
	[BrokenGameBet] [money] NULL,
	[LiveNetwork] [varchar](50) NULL,
	[recommend] [int] NULL,
	[mrecommend] [int] NULL,
	[srecommend] [int] NULL,
	[currency] [tinyint] NULL,
	[ProgressiveShare] [money] NULL,
	[ProgressiveWin] [money] NULL,
 CONSTRAINT [pk_TicketID] PRIMARY KEY CLUSTERED 
(
	[TicketID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[bettrans_Staging_bk](
	[SeqId] [int] NOT NULL,
	[OBTransId] [bigint] NOT NULL,
	[ObBetType] [smallint] NOT NULL,
	[Odds] [smallmoney] NULL,
	[ObCustId] [int] NOT NULL,
	[Stake] [money] NOT NULL,
	[ActualStake] [money] NULL,
	[GambleId] [bigint] NOT NULL,
	[Payout] [money] NULL,
	[NumberofHit] [smallint] NULL,
	[isSkipped] [bit] NULL,
 CONSTRAINT [PK_Bettrans_Staging] PRIMARY KEY CLUSTERED 
(
	[SeqId] ASC,
	[OBTransId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[bettransG](
	[transid] [int] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[oddsid] [int] NOT NULL,
	[odds] [smallmoney] NULL,
	[stake] [money] NOT NULL,
	[status] [nvarchar](10) NULL,
	[winlost] [money] NULL,
	[betteam] [nvarchar](50) NULL,
	[creator] [int] NOT NULL,
	[refno] [bigint] NOT NULL,
	[winlostdate] [smalldatetime] NULL,
	[betfrom] [nvarchar](1) NULL,
	[checktime] [smalldatetime] NULL,
	[apositiontaking] [smallmoney] NULL,
	[mpositiontaking] [smallmoney] NULL,
	[tpositiontaking] [smallmoney] NULL,
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[playerdiscount] [decimal](9, 8) NULL,
	[discount] [decimal](9, 8) NULL,
	[adiscount] [decimal](9, 8) NULL,
	[playercomm] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[actualrate] [float] NULL,
	[matchid] [int] NULL,
	[matchdate] [smalldatetime] NULL,
	[statuswinlost] [tinyint] NULL,
	[ruben] [tinyint] NULL,
	[bettype] [smallint] NULL,
	[spositiontaking] [smallmoney] NULL,
	[swinlost] [money] NULL,
	[sdiscount] [decimal](9, 8) NULL,
	[scomm] [money] NULL,
	[statusID] [tinyint] NULL,
	[virtualrate] [float] NULL,
	[SiteID] [varchar](7) NULL,
	[transdesc] [nvarchar](2000) NULL,
	[BetID3rd] [nvarchar](50) NULL,
	[epositiontaking] [smallmoney] NULL,
	[actual_stake] [money] NULL,
	[netstake] [money] NULL
) ON [DATA] WITH (DATA_COMPRESSION = PAGE)
GO
CREATE CLUSTERED INDEX [IX_bettransG] ON [dbo].[bettransG]
(
	[refno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[bettransLC_bk](
	[transid] [bigint] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[odds] [smallmoney] NULL,
	[stake] [money] NOT NULL,
	[status] [varchar](10) NULL,
	[apositiontaking] [smallmoney] NULL,
	[mpositiontaking] [smallmoney] NULL,
	[tpositiontaking] [smallmoney] NULL,
	[spositiontaking] [smallmoney] NULL,
	[playerdiscount] [decimal](9, 8) NULL,
	[discount] [decimal](9, 8) NULL,
	[adiscount] [decimal](9, 8) NULL,
	[sdiscount] [decimal](9, 8) NULL,
	[creator] [int] NOT NULL,
	[winlostdate] [smalldatetime] NOT NULL,
	[betfrom] [varchar](1) NULL,
	[virtualrate] [float] NOT NULL,
	[actualrate] [float] NULL,
	[actual_stake] [money] NULL,
	[currency] [tinyint] NULL,
	[CurrencyName] [nvarchar](50) NULL,
	[recommend] [int] NOT NULL,
	[mrecommend] [int] NOT NULL,
	[srecommend] [int] NOT NULL,
	[ip] [varchar](45) NULL,
	[statusID] [tinyint] NULL,
	[balance] [money] NULL,
	[Username] [nvarchar](50) NULL,
	[transdesc] [nvarchar](1000) NULL,
	[productID] [smallint] NOT NULL,
	[gameID] [smallint] NOT NULL,
	[vendorID] [int] NOT NULL,
	[GameId3rd] [varchar](50) NULL,
	[TranId3rd] [varchar](64) NULL,
	[RefNo] [bigint] NULL,
	[IsSum] [bit] NULL,
	[winlost] [money] NULL,
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[swinlost] [money] NULL,
	[playercomm] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[scomm] [money] NULL,
	[Transdate3rd] [datetime] NULL,
	[CountryCode] [varchar](2) NULL,
	[NetStake] [money] NULL,
	[epositiontaking] [smallmoney] NULL,
	[SiteID] [varchar](7) NULL
) ON [DATA] WITH(DATA_COMPRESSION = PAGE)
GO
CREATE CLUSTERED INDEX [CIX_winlostdate] ON [dbo].[bettransLC_bk]
(
	[winlostdate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[bettransm](
	[transid] [bigint] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[oddsid] [int] NOT NULL,
	[hdp1] [smallmoney] NULL,
	[hdp2] [smallmoney] NULL,
	[odds] [smallmoney] NULL,
	[stake] [money] NOT NULL,
	[status] [varchar](10) NULL,
	[winlost] [money] NULL,
	[livehomescore] [smallint] NULL,
	[liveawayscore] [smallint] NULL,
	[liveindicator] [bit] NULL,
	[betteam] [varchar](10) NULL,
	[creator] [int] NOT NULL,
	[refno] [bigint] NOT NULL,
	[comstatus] [varchar](20) NULL,
	[winlostdate] [smalldatetime] NULL,
	[betfrom] [varchar](1) NULL,
	[betcheck] [varchar](50) NULL,
	[oddsspread] [money] NULL,
	[apositiontaking] [smallmoney] NULL,
	[mpositiontaking] [smallmoney] NULL,
	[spositiontaking] [smallmoney] NULL,
	[tpositiontaking] [smallmoney] NULL,
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[swinlost] [money] NULL,
	[playerdiscount] [decimal](9, 8) NULL,
	[discount] [decimal](9, 8) NULL,
	[adiscount] [decimal](9, 8) NULL,
	[sdiscount] [decimal](9, 8) NULL,
	[playercomm] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[scomm] [money] NULL,
	[actualrate] [float] NULL,
	[matchid] [int] NULL,
	[matchdate] [smalldatetime] NULL,
	[finalodds] [smallmoney] NULL,
	[isfinish] [char](1) NULL,
	[statuswinlost] [tinyint] NULL,
	[ruben] [tinyint] NULL,
	[statusID] [tinyint] NULL,
	[bettype] [smallint] NULL,
	[recommdate] [datetime] NULL,
	[transdesc] [nvarchar](1000) NULL,
	[SecAcceptFlag] [bit] NULL,
	[checktime] [datetime] NULL,
	[ReasonIDm] [smallint] NULL
) ON [DATA] WITH(DATA_COMPRESSION = PAGE)
GO
CREATE CLUSTERED INDEX [IX_bettransm] ON [dbo].[bettransm]
(
	[refno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[bettransRnG_bk](
	[transid] [bigint] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[odds] [smallmoney] NULL,
	[stake] [money] NOT NULL,
	[status] [varchar](10) NULL,
	[apositiontaking] [smallmoney] NULL,
	[mpositiontaking] [smallmoney] NULL,
	[tpositiontaking] [smallmoney] NULL,
	[spositiontaking] [smallmoney] NULL,
	[playerdiscount] [decimal](9, 8) NULL,
	[discount] [decimal](9, 8) NULL,
	[adiscount] [decimal](9, 8) NULL,
	[sdiscount] [decimal](9, 8) NULL,
	[creator] [int] NOT NULL,
	[winlostdate] [smalldatetime] NOT NULL,
	[betfrom] [varchar](1) NULL,
	[virtualrate] [float] NOT NULL,
	[actualrate] [float] NULL,
	[actual_stake] [money] NULL,
	[currency] [tinyint] NULL,
	[CurrencyName] [nvarchar](50) NULL,
	[recommend] [int] NOT NULL,
	[mrecommend] [int] NOT NULL,
	[srecommend] [int] NOT NULL,
	[ip] [varchar](45) NULL,
	[statusID] [tinyint] NULL,
	[balance] [money] NULL,
	[Username] [nvarchar](50) NULL,
	[transdesc] [nvarchar](1000) NULL,
	[productID] [smallint] NOT NULL,
	[gameID] [smallint] NOT NULL,
	[vendorID] [int] NOT NULL,
	[GameId3rd] [varchar](50) NULL,
	[TranId3rd] [varchar](64) NULL,
	[RefNo] [bigint] NULL,
	[IsSum] [bit] NULL,
	[winlost] [money] NULL,
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[swinlost] [money] NULL,
	[playercomm] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[scomm] [money] NULL,
	[Transdate3rd] [datetime] NULL,
	[CountryCode] [varchar](2) NULL,
	[Additional] [varchar](1000) NULL,
	[JackpotInfo] [varchar](50) NULL,
	[RefNo2] [bigint] NULL,
	[ContributionRate] [decimal](9, 8) NULL,
	[BetStake] [money] NULL,
	[ContributionStake3rd] [decimal](19, 8) NULL,
	[epositiontaking] [smallmoney] NULL,
	[SiteID] [varchar](7) NULL
) ON [DATA] WITH(DATA_COMPRESSION = PAGE)
GO
CREATE CLUSTERED INDEX [CIX_winlostdate] ON [dbo].[bettransRnG_bk]
(
	[winlostdate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[bingoBall_bk](
	[Matchid] [int] NOT NULL,
	[Seq] [tinyint] NOT NULL,
	[Number] [tinyint] NULL,
	[UpdateTime] [datetime] NULL,
	[Color] [varchar](1) NULL,
 CONSTRAINT [PK_bingoBall_bk] PRIMARY KEY CLUSTERED 
(
	[Matchid] ASC,
	[Seq] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Bonus_sum_winloss_bk](
	[CustId] [int] NOT NULL,
	[BonusId] [int] NOT NULL,
	[winlostdate] [smalldatetime] NOT NULL,
	[Amount] [money] NULL
) ON [DATA]
GO
CREATE CLUSTERED INDEX [CIX_Bonus_sum_winloss_bk] ON [dbo].[Bonus_sum_winloss_bk]
(
	[CustId] ASC,
	[BonusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dot_Admin_AcceptTicketActionLog_BK](
	[matchid] [int] NOT NULL,
	[livelogid] [bigint] NOT NULL,
	[tickettype] [tinyint] NOT NULL,
	[accepttime] [datetime] NOT NULL,
	[maxtransid] [bigint] NOT NULL,
	[mintransid] [bigint] NOT NULL,
	[ticketcount] [int] NOT NULL,
 CONSTRAINT [PK_Dot_Admin_AcceptTicketActionLog] PRIMARY KEY CLUSTERED 
(
	[matchid] ASC,
	[livelogid] ASC,
	[tickettype] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA] WITH(DATA_COMPRESSION = PAGE)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dot_Admin_Assignment_Operator_bk](
	[ID] [int] NOT NULL,
	[matchid] [int] NULL,
	[OperatorType] [int] NULL,
	[OperatorID] [int] NULL,
	[bettype] [smallint] NULL,
 CONSTRAINT [PK_Dot_admin_Assignment_Operator_bk] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dot_Admin_Assignment_Operator_bk_vivi](
	[ID] [int] NOT NULL,
	[matchid] [int] NULL,
	[OperatorType] [int] NULL,
	[OperatorID] [int] NULL,
	[bettype] [smallint] NULL
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dot_Admin_Assignment_Trader_bk](
	[ID] [int] NOT NULL,
	[matchid] [int] NOT NULL,
	[bettype] [int] NOT NULL,
	[liveindicator] [bit] NOT NULL,
	[Detail_X] [smallint] NOT NULL,
	[Detail_Y] [smallint] NOT NULL,
	[Detail_Z] [smallint] NOT NULL,
	[Type] [tinyint] NOT NULL,
	[TraderID] [int] NOT NULL,
	[SuspenderID] [int] NULL,
	[UpdatedTime] [datetime] NOT NULL,
	[UpdatedUser] [int] NOT NULL,
 CONSTRAINT [PK_Dot_Admin_Assignment_Trade_bk] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dot_Admin_Intg_MatchMapping_bk](
	[MetaID] [int] NOT NULL,
	[RemarkID] [int] NOT NULL,
	[Ext_SourceID] [int] NOT NULL,
	[Ext_LeagueID] [int] NOT NULL,
	[Ext_MatchID] [varchar](50) NOT NULL,
	[MatchID] [int] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[MatchMappingID] [int] NOT NULL,
	[Confirmed] [int] NOT NULL,
	[MatchCode] [nvarchar](50) NULL,
	[ShowTime] [nvarchar](50) NULL,
	[SyncScore] [bit] NOT NULL,
	[isLive] [bit] NOT NULL,
	[NeutralReverse] [bit] NOT NULL,
	[RawID] [varchar](50) NULL,
 CONSTRAINT [PK_Dot_Admin_Intg_MatchMapping] PRIMARY KEY CLUSTERED 
(
	[MetaID] ASC,
	[RemarkID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dot_Admin_Intg_MetaFile_bk](
	[MetaID] [int] NOT NULL,
	[Type] [int] NOT NULL,
	[FullPath] [varchar](200) NOT NULL,
	[Ext_SourceID] [int] NOT NULL,
	[Ext_LeagueID] [int] NULL,
	[Ext_HomeID] [int] NULL,
	[Ext_AwayID] [int] NULL,
	[Ext_MatchID] [varchar](50) NULL,
	[Ext_Kickoff] [datetime] NULL,
	[Ext_BetType] [int] NULL,
	[Completed] [bit] NOT NULL,
	[Confirmed] [int] NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[Extra] [nvarchar](20) NULL,
	[SportType] [tinyint] NULL,
	[Ext_OddsID] [varchar](50) NULL,
 CONSTRAINT [PK_Dot_Admin_Intg_MetaFile] PRIMARY KEY CLUSTERED 
(
	[Type] ASC,
	[FullPath] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dot_Admin_LiveLog](
	[ID] [bigint] NOT NULL,
	[matchid] [int] NULL,
	[action_memo] [varchar](600) NULL,
	[OperatorID] [int] NULL,
	[transtime] [datetime] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [CIX_MatchID] ON [dbo].[Dot_Admin_LiveLog]
(
	[matchid] ASC,
	[transtime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EventInfo3rd_bk](
	[EventInfo3rdID] [int] NOT NULL,
	[ArenaID] [int] NOT NULL,
	[FightNo] [int] NOT NULL,
	[EventDate] [smalldatetime] NOT NULL,
	[HomeOwner] [nvarchar](256) NULL,
	[AwayOwner] [nvarchar](256) NULL,
 CONSTRAINT [PK_EventInfo3rd_bk] PRIMARY KEY NONCLUSTERED 
(
	[EventInfo3rdID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_ArenaFightNo] ON [dbo].[EventInfo3rd_bk]
(
	[ArenaID] ASC,
	[FightNo] ASC,
	[EventDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ExternalOddsMapping](
	[Id] [int] NOT NULL,
	[ProviderId] [int] NOT NULL,
	[FeedMatchId] [bigint] NULL,
	[MatchId] [int] NULL,
	[Reverse] [bit] NOT NULL,
	[ConfirmUser] [int] NULL,
	[ConfirmDate] [datetime] NULL,
	[ModifyUser] [int] NULL,
	[ModifyDate] [datetime] NULL,
 CONSTRAINT [PK_ExternalOddsMapping] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HRCode_bk](
	[CodeID] [int] NOT NULL,
	[CodeType] [tinyint] NOT NULL,
	[VendorID] [varchar](10) NULL,
	[CodeNameEn] [nvarchar](50) NOT NULL,
	[CodeNameCh] [nvarchar](50) NULL,
	[CodeNameCs] [nvarchar](50) NULL,
	[CodeDesc] [nvarchar](50) NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_HRCode] PRIMARY KEY CLUSTERED 
(
	[CodeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Intg_OddsFeed_SettlementAction_bk](
	[ActionId] [int] NOT NULL,
	[LeagueId] [int] NOT NULL,
	[MatchId] [int] NOT NULL,
	[ActionType] [tinyint] NOT NULL,
	[HTHomeScore] [int] NULL,
	[HTAwayScore] [int] NULL,
	[FTHomeScore] [int] NULL,
	[FTAwayScore] [int] NULL,
	[CreateTime] [datetime] NOT NULL,
	[OtherInfo] [varchar](max) NULL,
 CONSTRAINT [PK_Intg_OddsFeed_SettlementAction_bk] PRIMARY KEY CLUSTERED 
(
	[ActionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA] TEXTIMAGE_ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Intg_OddsFeed_SettlementAction_Outright_bk](
	[ActionId] [int] NOT NULL,
	[ActionType] [tinyint] NOT NULL,
	[OrId] [int] NOT NULL,
	[LeagueId] [int] NOT NULL,
	[TeamId] [int] NOT NULL,
	[Status] [varchar](10) NOT NULL,
	[IsDeadheat] [bit] NOT NULL,
	[Deadheat] [tinyint] NOT NULL,
	[CreateTime] [datetime] NOT NULL
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeagueDetail_bk](
	[LeagueDetailID] [int] NOT NULL,
	[leagueid] [int] NOT NULL,
	[ProgramID] [varchar](10) NOT NULL,
	[ProgramDate] [smalldatetime] NULL,
	[CountryCode] [varchar](10) NULL,
	[ToteCommWin] [decimal](9, 8) NULL,
	[ToteCommPlace] [decimal](9, 8) NULL,
	[ToteFee] [decimal](9, 8) NULL,
 CONSTRAINT [PK_LeagueDetail] PRIMARY KEY CLUSTERED 
(
	[LeagueDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[match_bk](
	[matchid] [int] NOT NULL,
	[leagueid] [int] NOT NULL,
	[homeid] [int] NOT NULL,
	[awayid] [int] NOT NULL,
	[eventdate] [datetime] NULL,
	[eventstatus] [varchar](50) NULL,
	[betstatus] [varchar](50) NULL,
	[livehomescore] [int] NULL,
	[liveawayscore] [int] NULL,
	[finalhomescore] [int] NULL,
	[finalawayscore] [int] NULL,
	[creator] [int] NOT NULL,
	[matchcode] [varchar](50) NULL,
	[kickofftime] [datetime] NULL,
	[closedtime] [datetime] NULL,
	[showtime] [varchar](50) NULL,
	[hthomescore] [int] NULL,
	[htawayscore] [int] NULL,
	[ruben] [tinyint] NULL,
	[multiple] [tinyint] NULL,
	[yenbet] [bit] NULL,
	[exrisk] [float] NULL,
	[sporttype] [tinyint] NULL,
	[tstamp] [binary](8) NULL,
	[homeid2] [int] NULL,
	[awayid2] [int] NULL,
	[DisplayMode] [tinyint] NULL,
	[LeaguePatternID] [smallint] NULL,
	[HomeDisplayPatternID] [smallint] NULL,
	[AwayDisplayPatternID] [smallint] NULL,
	[IsNeutral] [bit] NULL,
	[GoalRecord] [varchar](50) NULL,
	[GlobalShowTime] [smalldatetime] NULL,
	[ParentID] [int] NULL,
	[AutoSetting] [tinyint] NULL,
	[ShowTimeDT] [smalldatetime] NULL,
	[ChildMatchType] [tinyint] NULL,
 CONSTRAINT [PK_match_bk] PRIMARY KEY CLUSTERED 
(
	[matchid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Match_ExtraStatus_bk](
	[ESID] [int] NOT NULL,
	[MatchID] [int] NOT NULL,
	[GameStatusID] [tinyint] NOT NULL,
	[StatusValue] [varchar](50) NULL,
	[Creator] [int] NOT NULL,
	[CreateTime] [datetime] NOT NULL,
	[ArchiveDate] [date] NULL
) ON [DATA]
GO
CREATE CLUSTERED INDEX [CIX_ESID] ON [dbo].[Match_ExtraStatus_bk]
(
	[ESID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[match_remark](
	[matchid] [int] NOT NULL,
	[calculate] [bit] NULL,
	[multiple] [bit] NULL,
	[calrefund] [bit] NULL,
	[refund] [bit] NULL,
	[calStatus] [nvarchar](10) NULL,
	[IsTotalBetDenied_1] [bit] NULL,
	[IsTotalBetDenied_3] [bit] NULL,
	[IsTotalBetDenied_7] [bit] NULL,
	[IsTotalBetDenied_8] [bit] NULL,
	[LiveTimer] [datetime] NOT NULL,
	[HomeRedCard] [tinyint] NOT NULL,
	[AwayRedCard] [tinyint] NOT NULL,
	[LivePeriod] [tinyint] NOT NULL,
	[HedgeForecast] [tinyint] NOT NULL,
	[IsTotalBetDenied_20] [bit] NULL,
	[IsTotalBetDenied_21] [bit] NOT NULL,
	[IsNeutral] [bit] NOT NULL,
	[StreamingID] [varchar](50) NULL,
	[IsInternal] [bit] NOT NULL,
	[IsHTCal] [bit] NOT NULL,
	[LiveDeleteChecker] [int] NULL,
	[HomeColor] [varchar](20) NOT NULL,
	[AwayColor] [varchar](20) NOT NULL,
	[ConfirmHT] [int] NOT NULL,
	[ConfirmFT] [int] NOT NULL,
	[PausePeriod] [int] NULL,
	[TimerSuspend] [bit] NOT NULL,
	[IsPending] [bit] NOT NULL,
	[isUndecided] [bit] NOT NULL,
	[StdDelBetCheck] [int] NULL,
	[HomeSubstitutes] [tinyint] NULL,
	[AwaySubstitutes] [tinyint] NULL,
	[StartTeam] [tinyint] NULL,
	[HomePenalty] [tinyint] NULL,
	[AwayPenalty] [tinyint] NULL,
	[HomeYellowCard] [tinyint] NULL,
	[AwayYellowCard] [tinyint] NULL,
	[SettlementStatus] [tinyint] NULL,
	[Tier] [tinyint] NULL,
	[OfferLive] [bit] NULL,
	[CommGroup] [tinyint] NULL,
	[MainType] [tinyint] NULL,
	[SubType] [smallint] NULL,
 CONSTRAINT [PK_match_remark] PRIMARY KEY CLUSTERED 
(
	[matchid] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Match3rd_bk](
	[Match3rdId] [int] NOT NULL,
	[League3rdId] [int] NOT NULL,
	[HomeId] [int] NOT NULL,
	[AwayId] [int] NOT NULL,
	[EventDate] [date] NOT NULL,
	[SportType] [smallint] NOT NULL,
	[VendorMatchId] [varchar](50) NULL,
	[MatchNo] [varchar](30) NULL,
	[HasLive] [bit] NULL,
	[EventStatus] [varchar](50) NULL,
	[VendorEventStatus] [varchar](50) NULL,
	[CreateTime] [datetime] NOT NULL,
	[UpdateTime] [datetime] NULL,
	[VendorEventDate] [datetime] NULL,
	[GameResultDate] [datetime] NULL,
	[StartTime] [datetime] NULL,
	[MarketEndTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[BetStatus] [varchar](50) NULL,
 CONSTRAINT [PK_Match3rd_bk] PRIMARY KEY CLUSTERED 
(
	[Match3rdId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MatchMaxbet_bk](
	[MatchId] [int] NOT NULL,
	[BetType] [int] NOT NULL,
	[Maxbet] [float] NULL,
	[OperatorId] [int] NULL,
	[Spread] [float] NULL,
 CONSTRAINT [PK_MatchMaxbet_bk] PRIMARY KEY CLUSTERED 
(
	[MatchId] ASC,
	[BetType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NetPositionCalculationLog_bk](
	[NPCalculationLogID] [bigint] NOT NULL,
	[CustID] [int] NOT NULL,
	[MatchID] [int] NOT NULL,
	[Bettype] [smallint] NOT NULL,
	[AccumNPDebit] [money] NOT NULL,
	[AccumNPCredit] [money] NOT NULL,
	[NPAdjust] [money] NOT NULL,
	[IsLatest] [bit] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ArchiveDate] [date] NULL,
 CONSTRAINT [PK_NetPositionCalculationLog] PRIMARY KEY CLUSTERED 
(
	[NPCalculationLogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NetPositionTrans_bk](
	[TransID] [bigint] NOT NULL,
	[CustID] [int] NOT NULL,
	[MatchID] [int] NOT NULL,
	[Bettype] [smallint] NOT NULL,
	[Actual_stake] [money] NOT NULL,
	[Payout1] [money] NULL,
	[Payoutx] [money] NULL,
	[Payout2] [money] NULL,
	[SyncStatus] [bit] NOT NULL,
	[isSettled] [bit] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ArchiveDate] [date] NULL,
 CONSTRAINT [PK_NetPositionTrans] PRIMARY KEY CLUSTERED 
(
	[TransID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[odds_bk](
	[oddsid] [int] NOT NULL,
	[matchid] [int] NOT NULL,
	[bettype] [smallint] NULL,
	[switch] [bit] NULL,
	[hdp1] [float] NULL,
	[hdp2] [float] NULL,
	[odds1a] [float] NULL,
	[odds2a] [float] NULL,
	[odds1b] [float] NULL,
	[odds2b] [float] NULL,
	[odds1c] [float] NULL,
	[odds2c] [float] NULL,
	[odds1e] [float] NULL,
	[odds2e] [float] NULL,
	[odds1f] [float] NULL,
	[odds2f] [float] NULL,
	[odds1d] [float] NULL,
	[odds2d] [float] NULL,
	[odds1hka] [float] NULL,
	[odds2hka] [float] NULL,
	[odds1hkb] [float] NULL,
	[odds2hkb] [float] NULL,
	[odds1hkc] [float] NULL,
	[odds2hkc] [float] NULL,
	[odds1hke] [float] NULL,
	[odds2hke] [float] NULL,
	[odds1hkf] [float] NULL,
	[odds2hkf] [float] NULL,
	[odds1hkd] [float] NULL,
	[odds2hkd] [float] NULL,
	[oddsspreada] [float] NULL,
	[oddsspreadb] [float] NULL,
	[oddsspreadd] [float] NULL,
	[oddsspreade] [float] NULL,
	[oddsspreadf] [float] NULL,
	[oddsspreadc] [float] NULL,
	[autobookie] [bit] NULL,
	[gapodds1] [float] NULL,
	[gapodds2] [float] NULL,
	[maxstake1] [float] NULL,
	[maxstake2] [float] NULL,
	[minstake1] [float] NULL,
	[minstake2] [float] NULL,
	[diffbalance] [float] NULL,
	[maxodds] [float] NULL,
	[minodds] [float] NULL,
	[oddsstatus] [varchar](50) NULL,
	[liveindicator] [bit] NULL,
	[changetime] [datetime] NULL,
	[risk] [float] NULL,
	[stakerange] [float] NULL,
	[newoffersetup] [bit] NULL,
	[livehomescore] [int] NULL,
	[liveawayscore] [int] NULL,
	[creator] [int] NULL,
	[com1] [float] NULL,
	[comx] [float] NULL,
	[com2] [float] NULL,
	[cs00] [float] NULL,
	[cs01] [float] NULL,
	[cs10] [float] NULL,
	[cs11] [float] NULL,
	[cs02] [float] NULL,
	[cs12] [float] NULL,
	[cs22] [float] NULL,
	[cs21] [float] NULL,
	[cs20] [float] NULL,
	[cs30] [float] NULL,
	[cs31] [float] NULL,
	[cs32] [float] NULL,
	[cs33] [float] NULL,
	[cs23] [float] NULL,
	[cs13] [float] NULL,
	[cs03] [float] NULL,
	[cs43] [float] NULL,
	[cs42] [float] NULL,
	[cs41] [float] NULL,
	[cs40] [float] NULL,
	[cs44] [float] NULL,
	[cs14] [float] NULL,
	[cs24] [float] NULL,
	[cs04] [float] NULL,
	[cs34] [float] NULL,
	[cs50] [float] NULL,
	[cs05] [float] NULL,
	[comstatus] [bit] NULL,
	[csstatus] [varchar](50) NULL,
	[commaxbet] [float] NULL,
	[csmaxbet] [float] NULL,
	[com1total] [float] NULL,
	[comxtotal] [float] NULL,
	[com2total] [float] NULL,
	[bal00] [float] NULL,
	[bal10] [float] NULL,
	[bal11] [float] NULL,
	[bal01] [float] NULL,
	[bal20] [float] NULL,
	[bal21] [float] NULL,
	[bal22] [float] NULL,
	[bal12] [float] NULL,
	[bal02] [float] NULL,
	[bal30] [float] NULL,
	[bal31] [float] NULL,
	[bal32] [float] NULL,
	[bal33] [float] NULL,
	[bal23] [float] NULL,
	[bal13] [float] NULL,
	[bal03] [float] NULL,
	[bal40] [float] NULL,
	[bal41] [float] NULL,
	[bal42] [float] NULL,
	[bal43] [float] NULL,
	[bal44] [float] NULL,
	[bal34] [float] NULL,
	[bal24] [float] NULL,
	[bal14] [float] NULL,
	[bal04] [float] NULL,
	[bal50] [float] NULL,
	[bal05] [float] NULL,
	[maxbet] [float] NULL,
	[ht] [bit] NULL,
	[autoreject] [bit] NULL,
	[allowance] [int] NULL,
	[autosuspend] [bit] NULL,
	[multiple] [bit] NULL,
	[stakerange2] [float] NULL,
	[risk2] [float] NULL,
	[allowance2] [float] NULL,
	[site2] [float] NULL,
	[site3] [float] NULL,
	[site4] [float] NULL,
	[hometotal] [float] NULL,
	[awaytotal] [float] NULL,
	[sporttype] [tinyint] NOT NULL,
	[tstamp] [binary](8) NULL,
	[Resourceid] [varchar](20) NULL,
	[ResultKey] [varchar](50) NULL,
	[cs99] [float] NULL,
	[bal99] [float] NULL,
	[GapOddsCap1] [decimal](9, 4) NULL,
	[GapOddsCap2] [decimal](9, 4) NULL,
 CONSTRAINT [PK_odds_bk] PRIMARY KEY CLUSTERED 
(
	[oddsid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Odds3rd_bk](
	[oddsid] [int] NOT NULL,
	[matchid] [int] NOT NULL,
	[odds3rdid] [nvarchar](50) NOT NULL,
	[bettype] [smallint] NULL,
	[hdp1] [float] NULL,
	[hdp2] [float] NULL,
	[odds1a] [float] NULL,
	[odds2a] [float] NULL,
	[oddsstatus] [nvarchar](50) NULL,
	[changetime] [datetime] NULL,
	[creator] [int] NULL,
	[com1] [float] NULL,
	[comx] [float] NULL,
	[com2] [float] NULL,
	[cs00] [float] NULL,
	[cs01] [float] NULL,
	[cs10] [float] NULL,
	[cs11] [float] NULL,
	[cs02] [float] NULL,
	[cs12] [float] NULL,
	[cs22] [float] NULL,
	[cs21] [float] NULL,
	[cs20] [float] NULL,
	[cs30] [float] NULL,
	[cs31] [float] NULL,
	[cs32] [float] NULL,
	[cs33] [float] NULL,
	[cs23] [float] NULL,
	[cs13] [float] NULL,
	[cs03] [float] NULL,
	[cs99] [float] NULL,
	[sporttype] [smallint] NOT NULL,
	[cs04] [float] NULL,
	[cs05] [float] NULL,
	[Resourceid] [varchar](20) NULL,
 CONSTRAINT [PK_Odds3rd_bk] PRIMARY KEY CLUSTERED 
(
	[oddsid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[oddsES_bk](
	[oddsid] [int] NOT NULL,
	[matchid] [int] NOT NULL,
	[bettype] [smallint] NULL,
	[switch] [bit] NULL,
	[hdp1] [decimal](9, 4) NULL,
	[hdp2] [decimal](9, 4) NULL,
	[odds1a] [decimal](9, 4) NULL,
	[odds2a] [decimal](9, 4) NULL,
	[oddsspreada] [decimal](9, 4) NULL,
	[autobookie] [bit] NULL,
	[gapodds1] [decimal](9, 4) NULL,
	[gapodds2] [decimal](9, 4) NULL,
	[diffbalance] [float] NULL,
	[maxodds] [decimal](9, 4) NULL,
	[minodds] [decimal](9, 4) NULL,
	[oddsstatus] [varchar](30) NULL,
	[liveindicator] [bit] NULL,
	[changetime] [datetime] NULL,
	[risk] [decimal](9, 4) NULL,
	[stakerange] [decimal](9, 4) NULL,
	[newoffersetup] [bit] NULL,
	[livehomescore] [int] NULL,
	[liveawayscore] [int] NULL,
	[creator] [int] NULL,
	[com1] [decimal](9, 4) NULL,
	[com2] [decimal](9, 4) NULL,
	[csstatus] [varchar](30) NULL,
	[maxbet] [decimal](9, 2) NULL,
	[autosuspend] [bit] NULL,
	[stakerange2] [decimal](9, 4) NULL,
	[risk2] [decimal](9, 4) NULL,
	[site3] [decimal](9, 4) NULL,
	[sporttype] [tinyint] NULL,
	[HasBeenLinked] [bit] NULL,
	[Resourceid] [varchar](20) NULL,
	[Category] [tinyint] NULL,
	[IncreaseMaxbet] [bit] NULL,
	[odds1aH] [decimal](9, 4) NULL,
	[odds2aH] [decimal](9, 4) NULL,
	[IsCopyDeadball] [bit] NULL,
	[GoalLineDiff] [decimal](9, 4) NULL,
	[IsStatusIndep] [bit] NULL,
	[ParentOddsId] [int] NULL,
	[RefOddsSP] [decimal](9, 4) NULL,
	[RefOddsH] [decimal](9, 4) NULL,
	[RefOddsA] [decimal](9, 4) NULL,
	[RefTrueOdds] [decimal](9, 4) NULL,
	[CurrentTrueOdds] [decimal](9, 4) NULL,
	[EnableVirtualRate] [bit] NULL,
	[TraderId] [int] NULL,
	[cs00] [decimal](9, 4) NULL,
	[cs01] [decimal](9, 4) NULL,
	[cs10] [decimal](9, 4) NULL,
	[cs11] [decimal](9, 4) NULL,
	[cs02] [decimal](9, 4) NULL,
	[cs12] [decimal](9, 4) NULL,
	[cs22] [decimal](9, 4) NULL,
	[cs21] [decimal](9, 4) NULL,
	[cs20] [decimal](9, 4) NULL,
	[cs30] [decimal](9, 4) NULL,
	[cs31] [decimal](9, 4) NULL,
	[cs32] [decimal](9, 4) NULL,
	[cs33] [decimal](9, 4) NULL,
	[cs23] [decimal](9, 4) NULL,
	[cs13] [decimal](9, 4) NULL,
	[cs03] [decimal](9, 4) NULL,
	[cs43] [decimal](9, 4) NULL,
	[cs42] [decimal](9, 4) NULL,
	[cs41] [decimal](9, 4) NULL,
	[cs40] [decimal](9, 4) NULL,
	[cs44] [decimal](9, 4) NULL,
	[cs14] [decimal](9, 4) NULL,
	[cs24] [decimal](9, 4) NULL,
	[cs04] [decimal](9, 4) NULL,
	[cs34] [decimal](9, 4) NULL,
	[cs50] [decimal](9, 4) NULL,
	[cs05] [decimal](9, 4) NULL,
	[cs51] [decimal](9, 4) NULL,
	[cs52] [decimal](9, 4) NULL,
	[cs53] [decimal](9, 4) NULL,
	[cs54] [decimal](9, 4) NULL,
	[cs15] [decimal](9, 4) NULL,
	[cs25] [decimal](9, 4) NULL,
	[cs35] [decimal](9, 4) NULL,
	[cs45] [decimal](9, 4) NULL,
	[cs09] [decimal](9, 4) NULL,
	[cs90] [decimal](9, 4) NULL,
	[cs99] [decimal](9, 4) NULL,
	[bal00] [decimal](9, 4) NULL,
	[bal10] [decimal](9, 4) NULL,
	[bal11] [decimal](9, 4) NULL,
	[bal01] [decimal](9, 4) NULL,
	[bal20] [decimal](9, 4) NULL,
	[bal21] [decimal](9, 4) NULL,
	[bal22] [decimal](9, 4) NULL,
	[bal12] [decimal](9, 4) NULL,
	[bal02] [decimal](9, 4) NULL,
	[bal30] [decimal](9, 4) NULL,
	[bal31] [decimal](9, 4) NULL,
	[bal32] [decimal](9, 4) NULL,
	[bal33] [decimal](9, 4) NULL,
	[bal23] [decimal](9, 4) NULL,
	[bal13] [decimal](9, 4) NULL,
	[bal03] [decimal](9, 4) NULL,
	[bal40] [decimal](9, 4) NULL,
	[bal41] [decimal](9, 4) NULL,
	[bal42] [decimal](9, 4) NULL,
	[bal43] [decimal](9, 4) NULL,
	[bal44] [decimal](9, 4) NULL,
	[bal34] [decimal](9, 4) NULL,
	[bal24] [decimal](9, 4) NULL,
	[bal14] [decimal](9, 4) NULL,
	[bal04] [decimal](9, 4) NULL,
	[bal50] [decimal](9, 4) NULL,
	[bal05] [decimal](9, 4) NULL,
	[bal51] [decimal](9, 4) NULL,
	[bal52] [decimal](9, 4) NULL,
	[bal53] [decimal](9, 4) NULL,
	[bal54] [decimal](9, 4) NULL,
	[bal15] [decimal](9, 4) NULL,
	[bal25] [decimal](9, 4) NULL,
	[bal35] [decimal](9, 4) NULL,
	[bal45] [decimal](9, 4) NULL,
	[bal09] [decimal](9, 4) NULL,
	[bal90] [decimal](9, 4) NULL,
	[bal99] [decimal](9, 4) NULL,
 CONSTRAINT [PK_oddses_bk] PRIMARY KEY CLUSTERED 
(
	[oddsid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 50, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[oddsOS_bk](
	[oddsid] [int] NOT NULL,
	[matchid] [int] NOT NULL,
	[bettype] [smallint] NULL,
	[switch] [bit] NULL,
	[hdp1] [decimal](9, 4) NULL,
	[hdp2] [decimal](9, 4) NULL,
	[odds1a] [decimal](9, 4) NULL,
	[odds2a] [decimal](9, 4) NULL,
	[oddsspreada] [decimal](9, 4) NULL,
	[autobookie] [bit] NULL,
	[gapodds1] [decimal](9, 4) NULL,
	[gapodds2] [decimal](9, 4) NULL,
	[diffbalance] [float] NULL,
	[maxodds] [decimal](9, 4) NULL,
	[minodds] [decimal](9, 4) NULL,
	[oddsstatus] [varchar](30) NULL,
	[liveindicator] [bit] NULL,
	[changetime] [datetime] NULL,
	[risk] [decimal](9, 4) NULL,
	[stakerange] [decimal](9, 4) NULL,
	[newoffersetup] [bit] NULL,
	[com1] [decimal](9, 4) NULL,
	[comx] [decimal](9, 4) NULL,
	[com2] [decimal](9, 4) NULL,
	[cs00] [decimal](9, 4) NULL,
	[cs01] [decimal](9, 4) NULL,
	[cs10] [decimal](9, 4) NULL,
	[cs11] [decimal](9, 4) NULL,
	[cs02] [decimal](9, 4) NULL,
	[cs12] [decimal](9, 4) NULL,
	[cs22] [decimal](9, 4) NULL,
	[cs21] [decimal](9, 4) NULL,
	[cs20] [decimal](9, 4) NULL,
	[cs30] [decimal](9, 4) NULL,
	[cs31] [decimal](9, 4) NULL,
	[cs32] [decimal](9, 4) NULL,
	[cs33] [decimal](9, 4) NULL,
	[cs23] [decimal](9, 4) NULL,
	[cs13] [decimal](9, 4) NULL,
	[cs03] [decimal](9, 4) NULL,
	[cs43] [decimal](9, 4) NULL,
	[cs42] [decimal](9, 4) NULL,
	[cs41] [decimal](9, 4) NULL,
	[cs40] [decimal](9, 4) NULL,
	[cs44] [decimal](9, 4) NULL,
	[cs14] [decimal](9, 4) NULL,
	[cs24] [decimal](9, 4) NULL,
	[cs04] [decimal](9, 4) NULL,
	[cs34] [decimal](9, 4) NULL,
	[cs50] [decimal](9, 4) NULL,
	[cs05] [decimal](9, 4) NULL,
	[cs51] [decimal](9, 4) NULL,
	[cs52] [decimal](9, 4) NULL,
	[cs53] [decimal](9, 4) NULL,
	[cs54] [decimal](9, 4) NULL,
	[cs15] [decimal](9, 4) NULL,
	[cs25] [decimal](9, 4) NULL,
	[cs35] [decimal](9, 4) NULL,
	[cs45] [decimal](9, 4) NULL,
	[cs09] [decimal](9, 4) NULL,
	[cs90] [decimal](9, 4) NULL,
	[cs99] [decimal](9, 4) NULL,
	[comstatus] [bit] NULL,
	[csstatus] [varchar](50) NULL,
	[commaxbet] [decimal](9, 4) NULL,
	[com1total] [decimal](9, 4) NULL,
	[comxtotal] [decimal](9, 4) NULL,
	[com2total] [decimal](9, 4) NULL,
	[bal00] [decimal](9, 4) NULL,
	[bal10] [decimal](9, 4) NULL,
	[bal11] [decimal](9, 4) NULL,
	[bal01] [decimal](9, 4) NULL,
	[bal20] [decimal](9, 4) NULL,
	[bal21] [decimal](9, 4) NULL,
	[bal22] [decimal](9, 4) NULL,
	[bal12] [decimal](9, 4) NULL,
	[bal02] [decimal](9, 4) NULL,
	[bal30] [decimal](9, 4) NULL,
	[bal31] [decimal](9, 4) NULL,
	[bal32] [decimal](9, 4) NULL,
	[bal33] [decimal](9, 4) NULL,
	[bal23] [decimal](9, 4) NULL,
	[bal13] [decimal](9, 4) NULL,
	[bal03] [decimal](9, 4) NULL,
	[bal40] [decimal](9, 4) NULL,
	[bal41] [decimal](9, 4) NULL,
	[bal42] [decimal](9, 4) NULL,
	[bal43] [decimal](9, 4) NULL,
	[bal44] [decimal](9, 4) NULL,
	[bal34] [decimal](9, 4) NULL,
	[bal24] [decimal](9, 4) NULL,
	[bal14] [decimal](9, 4) NULL,
	[bal04] [decimal](9, 4) NULL,
	[bal50] [decimal](9, 4) NULL,
	[bal05] [decimal](9, 4) NULL,
	[bal51] [decimal](9, 4) NULL,
	[bal52] [decimal](9, 4) NULL,
	[bal53] [decimal](9, 4) NULL,
	[bal54] [decimal](9, 4) NULL,
	[bal15] [decimal](9, 4) NULL,
	[bal25] [decimal](9, 4) NULL,
	[bal35] [decimal](9, 4) NULL,
	[bal45] [decimal](9, 4) NULL,
	[bal09] [decimal](9, 4) NULL,
	[bal90] [decimal](9, 4) NULL,
	[bal99] [decimal](9, 4) NULL,
	[maxbet] [int] NULL,
	[autoreject] [bit] NULL,
	[autosuspend] [bit] NULL,
	[multiple] [bit] NULL,
	[stakerange2] [decimal](9, 4) NULL,
	[risk2] [decimal](9, 4) NULL,
	[isHedge] [bit] NULL,
	[sporttype] [tinyint] NOT NULL,
	[HasBeenLinked] [bit] NULL,
	[Resourceid] [varchar](20) NULL,
	[maxPayout] [decimal](9, 4) NOT NULL,
	[EnableVirtualRate] [bit] NOT NULL,
	[Category] [tinyint] NOT NULL,
	[Sort] [smallint] NULL,
	[odds1aH] [decimal](9, 4) NULL,
	[odds2aH] [decimal](9, 4) NULL,
	[IsCopyDeadball] [bit] NULL,
	[IsStatusIndep] [bit] NULL,
	[ParentOddsId] [int] NULL,
	[TraderId] [int] NULL,
 CONSTRAINT [PK_oddsos_bk] PRIMARY KEY CLUSTERED 
(
	[oddsid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[outright_bk](
	[orid] [int] NOT NULL,
	[leagueid] [int] NOT NULL,
	[teamid] [int] NOT NULL,
	[eventdate] [smalldatetime] NOT NULL,
	[kickofftime] [datetime] NOT NULL,
	[oddsstatus] [varchar](10) NULL,
	[odds] [smallmoney] NULL,
	[maxbet] [int] NULL,
	[gapodds] [smallmoney] NULL,
	[matchcode] [varchar](10) NULL,
	[groupmatch] [varchar](20) NULL,
	[status] [varchar](10) NULL,
	[creator] [int] NOT NULL,
	[bal] [money] NULL,
	[risk] [money] NULL,
	[DisplayMode] [tinyint] NULL,
	[PlaceOdds] [smallmoney] NULL,
	[Placing] [tinyint] NULL,
	[IsFavor] [bit] NULL,
	[IsSCR] [bit] NULL,
	[ProgramID] [varchar](10) NULL,
	[FOddsStatus] [varchar](10) NULL,
	[SCRTime] [datetime] NULL,
	[LeaguePatternID] [smallint] NULL,
	[TeamPatternID] [smallint] NULL,
	[ProgramDate] [smalldatetime] NULL,
	[IsDeadheat] [bit] NULL,
	[autosuspend] [bit] NULL,
	[EventID] [bigint] NULL,
	[Year] [int] NULL,
 CONSTRAINT [PK_outright_bk] PRIMARY KEY CLUSTERED 
(
	[orid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProviderExternalResultDetail_bk](
	[ProviderExternalId] [int] NOT NULL,
	[MatchId3rd] [int] NOT NULL,
	[MatchId] [int] NOT NULL,
	[SourceId] [smallint] NOT NULL,
	[ResourceId] [varchar](20) NOT NULL,
	[HomeValue] [varchar](50) NULL,
	[AwayValue] [varchar](50) NULL,
	[OtherInfo] [varchar](50) NULL,
	[CreateDate] [datetime] NULL,
	[LastModifyDate] [datetime] NULL,
	[CreateBy] [int] NULL,
	[LastModifyBy] [int] NULL,
 CONSTRAINT [PK_ProviderExternalResultDetail_bk] PRIMARY KEY NONCLUSTERED 
(
	[ProviderExternalId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
CREATE CLUSTERED INDEX [CIX_ProviderExternalResultDetail_bk] ON [dbo].[ProviderExternalResultDetail_bk]
(
	[MatchId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProviderExternalResultDetailES_bk](
	[ProviderExternalId] [int] NOT NULL,
	[MatchId3rd] [int] NOT NULL,
	[MatchId] [int] NOT NULL,
	[SourceId] [smallint] NOT NULL,
	[ResourceId] [varchar](20) NOT NULL,
	[HomeValue] [varchar](50) NULL,
	[AwayValue] [varchar](50) NULL,
	[OtherInfo] [varchar](50) NULL,
	[CreateDate] [datetime] NULL,
	[CreateBy] [int] NULL,
	[LastModifyDate] [datetime] NULL,
	[LastModifyBy] [int] NULL,
 CONSTRAINT [PK_ProviderExternalResultDetailES14] PRIMARY KEY NONCLUSTERED 
(
	[ProviderExternalId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
CREATE CLUSTERED INDEX [cix_ProviderExternalResultDetailES_bk] ON [dbo].[ProviderExternalResultDetailES_bk]
(
	[MatchId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProviderExternalResultDetailOS_bk](
	[ProviderExternalId] [int] NOT NULL,
	[MatchId3rd] [int] NOT NULL,
	[MatchId] [int] NOT NULL,
	[SourceId] [smallint] NOT NULL,
	[ResourceId] [varchar](20) NOT NULL,
	[HomeValue] [varchar](50) NULL,
	[AwayValue] [varchar](50) NULL,
	[OtherInfo] [varchar](50) NULL,
	[CreateDate] [datetime] NULL,
	[LastModifyDate] [datetime] NULL,
	[CreateBy] [int] NULL,
	[LastModifyBy] [int] NULL,
 CONSTRAINT [PK_ProviderExternalResultDetailOS_bk] PRIMARY KEY NONCLUSTERED 
(
	[ProviderExternalId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProviderResultDetail_bk](
	[ProviderResultDetailId] [int] NOT NULL,
	[MatchId] [int] NOT NULL,
	[SourceId] [tinyint] NOT NULL,
	[TypeId] [tinyint] NOT NULL,
	[HomeValue] [varchar](50) NULL,
	[AwayValue] [varchar](50) NULL,
	[CreatedDate] [datetime] NOT NULL,
	[IsConfirmed] [bit] NULL,
 CONSTRAINT [PK_ProviderResultDetail_bk] PRIMARY KEY NONCLUSTERED 
(
	[ProviderResultDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
CREATE CLUSTERED INDEX [CIX_ProviderResultDetail_bk] ON [dbo].[ProviderResultDetail_bk]
(
	[MatchId] ASC,
	[TypeId] ASC,
	[SourceId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProviderResultDetail_bk_Temp](
	[MatchId] [int] NOT NULL,
	[SourceId] [tinyint] NOT NULL,
	[TypeId] [tinyint] NOT NULL,
	[HomeValue] [varchar](50) NULL,
	[AwayValue] [varchar](50) NULL,
	[CreatedDate] [datetime] NOT NULL
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ResultDetail_bk](
	[MatchID] [int] NOT NULL,
	[ResourceID] [varchar](20) NOT NULL,
	[HomeValue] [varchar](50) NULL,
	[AwayValue] [varchar](50) NULL,
	[ResultStatusID] [tinyint] NULL,
	[SettlementStatusID] [tinyint] NULL,
	[CreateBy] [int] NULL,
	[CreateDate] [datetime] NULL,
	[LastModifyBy] [int] NULL,
	[LastModifyDate] [smalldatetime] NULL,
	[OtherInfo] [varchar](50) NULL,
 CONSTRAINT [PK_ResultDetail_bk] PRIMARY KEY CLUSTERED 
(
	[MatchID] ASC,
	[ResourceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ResultDetail3rd_bk](
	[ResultID] [int] NOT NULL,
	[VendorID] [int] NOT NULL,
	[MatchID] [int] NOT NULL,
	[GameID] [int] NOT NULL,
	[Custom1] [nvarchar](50) NULL,
	[Custom2] [nvarchar](50) NULL,
	[Custom3] [nvarchar](50) NULL,
	[ResultStatusID] [tinyint] NULL,
	[SettlementStatusID] [tinyint] NULL,
	[GameResult] [varchar](50) NULL,
	[OtherInfo] [varchar](50) NULL,
	[CreateBy] [int] NULL,
	[CreateDate] [datetime] NULL,
	[LastModifyBy] [int] NULL,
	[LastModifyDate] [datetime] NULL,
	[Resourceid] [varchar](20) NULL,
 CONSTRAINT [PK_ResultDetail3rd_bk] PRIMARY KEY CLUSTERED 
(
	[ResultID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ResultDetailES_bk](
	[MatchID] [int] NOT NULL,
	[ResourceID] [varchar](20) NOT NULL,
	[HomeValue] [varchar](50) NULL,
	[AwayValue] [varchar](50) NULL,
	[ResultStatusID] [tinyint] NULL,
	[SettlementStatusID] [tinyint] NULL,
	[CreateBy] [int] NULL,
	[CreateDate] [datetime] NULL,
	[LastModifyBy] [int] NULL,
	[LastModifyDate] [datetime] NULL,
	[OtherInfo] [varchar](50) NULL,
 CONSTRAINT [PK_ResultDetailES_bk] PRIMARY KEY CLUSTERED 
(
	[MatchID] ASC,
	[ResourceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ResultDetailOS_bk](
	[MatchID] [int] NOT NULL,
	[ResourceID] [varchar](20) NOT NULL,
	[HomeValue] [varchar](50) NULL,
	[AwayValue] [varchar](50) NULL,
	[ResultStatusID] [tinyint] NULL,
	[SettlementStatusID] [tinyint] NULL,
	[CreateBy] [int] NULL,
	[CreateDate] [datetime] NULL,
	[LastModifyBy] [int] NULL,
	[LastModifyDate] [datetime] NULL,
	[OtherInfo] [varchar](50) NULL,
 CONSTRAINT [PK_ResultDetailOS_bk] PRIMARY KEY CLUSTERED 
(
	[MatchID] ASC,
	[ResourceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SettlementNG2_Message_BK](
	[SeqID] [int] NOT NULL,
	[CreationTime] [datetime] NULL,
	[DoneAPI_Time] [datetime] NULL,
	[TotalRow] [int] NULL,
	[StartCalculate_Time] [datetime] NULL,
	[DoneCalculate_Time] [datetime] NULL,
	[Status] [varchar](20) NULL,
	[Task] [varchar](20) NULL,
	[EventDate] [smalldatetime] NULL,
	[GambleID] [bigint] NULL,
	[MatchId] [int] NULL,
 CONSTRAINT [PK_SettlementNG2_Message_BK] PRIMARY KEY CLUSTERED 
(
	[SeqID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SiteInfo](
	[SiteID] [smallint] IDENTITY(1,1) NOT NULL,
	[SiteName] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[SiteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SMP_Market_bk](
	[MarketId] [varchar](20) NOT NULL,
	[MatchId] [int] NOT NULL,
	[VendorId] [smallint] NOT NULL,
	[Price] [smallmoney] NOT NULL,
	[TradeStatus] [varchar](20) NOT NULL,
	[Result] [varchar](20) NULL,
	[ResultStatusId] [tinyint] NOT NULL,
	[SelectionCounts] [tinyint] NULL,
	[CreateTime] [datetime] NOT NULL,
	[UpdateTime] [datetime] NOT NULL,
 CONSTRAINT [PK_SMP_Market_bk] PRIMARY KEY CLUSTERED 
(
	[MatchId] ASC,
	[MarketId] ASC,
	[VendorId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SMP_MarketSelection_bk](
	[MarketSelectionId] [bigint] NOT NULL,
	[MarketId] [varchar](20) NOT NULL,
	[SelectionType] [int] NOT NULL,
	[Result] [varchar](20) NULL,
	[ResultStatusId] [tinyint] NOT NULL,
	[MatchId] [int] NOT NULL,
 CONSTRAINT [PK_SMP_MarketSelection_bk] PRIMARY KEY NONCLUSTERED 
(
	[MarketSelectionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_PADDING ON
GO
CREATE UNIQUE CLUSTERED INDEX [IXM_MatchId_MarketId] ON [dbo].[SMP_MarketSelection_bk]
(
	[MatchId] ASC,
	[MarketId] ASC,
	[SelectionType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SS_GameState_bk](
	[matchid] [int] NOT NULL,
	[ResultKey] [varchar](50) NOT NULL,
	[ResultValue] [varchar](120) NULL,
 CONSTRAINT [PK_SS_GameState_bk] PRIMARY KEY CLUSTERED 
(
	[matchid] ASC,
	[ResultKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TicketVoiding_AutoUnmarkSetting_bk](
	[ID] [int] NOT NULL,
	[Matchid] [int] NULL,
	[Bettype] [smallint] NULL,
	[IsConfirm] [bit] NULL,
	[CreatedDate] [datetime] NULL,
	[UserId] [int] NULL,
	[MarkedBy] [int] NULL,
	[betid] [bigint] NULL,
 CONSTRAINT [PK_TicketVoiding_AutoUnmarkSetting_bk_ID] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
CREATE CLUSTERED INDEX [CIX_TicketVoiding_AutoUnmarkSetting_bk_Matchid_Bettype] ON [dbo].[TicketVoiding_AutoUnmarkSetting_bk]
(
	[Matchid] ASC,
	[Bettype] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TicketVoiding_AutoVoidRequest_Queue_bk](
	[QueueId] [int] NOT NULL,
	[RequestId] [int] NOT NULL,
	[MatchId] [int] NOT NULL,
	[Action] [varchar](100) NULL,
	[StatusId] [tinyint] NULL,
	[UserId] [int] NULL,
	[Starttime] [datetime] NULL,
	[Exectime] [datetime] NULL,
	[Duration] [int] NULL,
	[IP] [varchar](50) NULL,
	[ErrMsg] [varchar](300) NULL,
	[sporttype] [smallint] NULL,
 CONSTRAINT [TicketVoiding_AutoVoidRequest_Queue_bk_QueueId] PRIMARY KEY NONCLUSTERED 
(
	[QueueId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TicketVoiding_OperatorInfo_bk](
	[RequestId] [int] NOT NULL,
	[OperatorId] [int] NOT NULL,
	[OperatorTypeId] [tinyint] NOT NULL,
	[Id] [int] NOT NULL,
 CONSTRAINT [PK_TicketVoiding_OperatorInfo_bk_Id] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
CREATE CLUSTERED INDEX [CIX_TicketVoiding_OperatorInfo_bk_RequestId] ON [dbo].[TicketVoiding_OperatorInfo_bk]
(
	[RequestId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TicketVoiding_Queue_bk](
	[QueueId] [int] NOT NULL,
	[RequestId] [int] NOT NULL,
	[MatchId] [int] NOT NULL,
	[VoidingHistoryId] [int] NOT NULL,
	[TransIds] [varchar](max) NULL,
	[StatusId] [tinyint] NULL,
	[UserId] [int] NULL,
	[Starttime] [datetime] NULL,
	[Exectime] [datetime] NULL,
	[Duration] [int] NULL,
	[IP] [varchar](50) NULL,
	[VoidingTypeId] [tinyint] NULL,
	[TotalTicket] [int] NULL,
	[ErrMsg] [varchar](300) NULL,
	[FailedTransIds] [varchar](max) NULL,
	[NegativeBalanceUsers] [varchar](max) NULL
) ON [DATA] TEXTIMAGE_ON [DATA]
GO
CREATE CLUSTERED INDEX [CIX_TicketVoiding_Queue_bk_VoidingHistoryId] ON [dbo].[TicketVoiding_Queue_bk]
(
	[VoidingHistoryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TicketVoiding_Reason_bk](
	[ReasonId] [int] NOT NULL,
	[ReasonEnglish] [nvarchar](150) NULL,
	[ReasonChineseSimplified] [nvarchar](150) NULL,
 CONSTRAINT [PK_TicketVoiding_Reason_bk_ReasonId] PRIMARY KEY CLUSTERED 
(
	[ReasonId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TicketVoiding_Request_bk](
	[RequestId] [int] NOT NULL,
	[Sporttype] [smallint] NULL,
	[SubIssueTypeId] [smallint] NULL,
	[ActionId] [tinyint] NULL,
	[Provider] [nvarchar](200) NULL,
	[Source] [nvarchar](200) NULL,
	[DecidedBy] [nvarchar](200) NULL,
	[MistakenBy] [nvarchar](200) NULL,
	[Remark] [nvarchar](max) NULL,
	[CheckedBy] [int] NULL,
	[UserId] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[LastModifiedBy] [int] NULL,
	[LastModifiedDate] [datetime] NULL,
	[IsTest] [bit] NULL,
	[IssueTypeId] [tinyint] NULL,
 CONSTRAINT [PK_TicketVoiding_Request_bk_RequestId] PRIMARY KEY CLUSTERED 
(
	[RequestId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA] TEXTIMAGE_ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TicketVoiding_RequestDetail_bk](
	[Id] [int] NOT NULL,
	[RequestId] [int] NOT NULL,
	[MatchId] [int] NOT NULL,
	[LeagueId] [int] NULL,
	[HomeId] [int] NULL,
	[AwayId] [int] NULL,
	[KickOffTime] [datetime] NULL,
	[LiveHomeScore] [int] NULL,
	[LiveAwayScore] [int] NULL,
	[IssueDetail] [nvarchar](300) NULL,
	[TransIds] [varchar](max) NULL,
	[RequestType] [tinyint] NULL,
	[FilterFromTransTime] [datetime] NULL,
	[FilterToTransTime] [datetime] NULL,
	[FilterFromBetId] [bigint] NULL,
	[FilterToBetId] [bigint] NULL,
	[IsFilterByTransTime] [bit] NULL,
	[SingleCount] [int] NULL,
	[MainParlayCount] [int] NULL,
	[MinSingleTransId] [bigint] NULL,
	[MaxSingleTransId] [bigint] NULL,
	[MinMainParlayTransId] [bigint] NULL,
	[MaxMainParlayTransId] [bigint] NULL,
	[VoidFromTime] [datetime] NULL,
	[VoidToTime] [datetime] NULL,
	[IsCheckedHomeTeam] [bit] NULL,
	[IsCheckedAwayTeam] [bit] NULL,
	[FilterBy] [tinyint] NULL,
	[Usernames] [nvarchar](max) NULL,
	[ProductIds] [varchar](50) NULL,
	[TicketStatusIds] [varchar](50) NULL,
	[FromWinlostDate] [datetime] NULL,
	[ToWinlostDate] [datetime] NULL,
	[SubIssueTypeId] [smallint] NULL,
 CONSTRAINT [PK_TicketVoiding_RequestDetail_bk_Id] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA] TEXTIMAGE_ON [DATA]
GO
CREATE CLUSTERED INDEX [CIX_TicketVoiding_RequestDetail_bk_RequestId] ON [dbo].[TicketVoiding_RequestDetail_bk]
(
	[RequestId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TicketVoiding_RequestDetailTicket_Single_bk](
	[Id] [int] NOT NULL,
	[RequestId] [int] NOT NULL,
	[IssueTypeId] [int] NOT NULL,
	[SubIssueTypeId] [int] NOT NULL,
	[TransId] [bigint] NOT NULL,
	[MatchId] [int] NOT NULL,
	[RequestDetailId] [int] NULL,
	[Bettype] [smallint] NULL,
	[BetId] [bigint] NULL,
 CONSTRAINT [PK_TicketVoiding_RequestDetailTicket_Single_bk] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
CREATE CLUSTERED INDEX [CIX_TicketVoiding_RequestDetailTicket_Single_bk_Request] ON [dbo].[TicketVoiding_RequestDetailTicket_Single_bk]
(
	[RequestId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TicketVoiding_RequestDetailTicket_SubParlay_bk](
	[Id] [int] NOT NULL,
	[RequestId] [int] NOT NULL,
	[IssueTypeId] [int] NOT NULL,
	[SubIssueTypeId] [int] NOT NULL,
	[TransId] [bigint] NOT NULL,
	[MatchId] [int] NOT NULL,
	[RequestDetailId] [int] NULL,
	[MainTransId] [bigint] NULL,
 CONSTRAINT [PK_TicketVoiding_RequestDetailTicket_SubParlay_bk] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
CREATE CLUSTERED INDEX [CIX_TicketVoiding_RequestDetailTicket_SubParlay_bk_Request] ON [dbo].[TicketVoiding_RequestDetailTicket_SubParlay_bk]
(
	[RequestId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TicketVoiding_VoidedTransaction_bk](
	[TransId] [bigint] NOT NULL,
	[MessageId] [int] NOT NULL,
	[ReasonId] [int] NOT NULL,
	[MatchId] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[Id] [int] NOT NULL,
	[IssueTypeID] [tinyint] NULL,
	[SubIssueTypeID] [tinyint] NULL,
	[CustID] [int] NULL,
 CONSTRAINT [PK_TicketVoiding_VoidedTransaction_bk_Id] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
CREATE CLUSTERED INDEX [CIX_TicketVoiding_VoidedTransaction_bk_Transid] ON [dbo].[TicketVoiding_VoidedTransaction_bk]
(
	[TransId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TicketVoiding_VoidingHistory_bk](
	[VoidingHistoryId] [int] NOT NULL,
	[RequestId] [int] NOT NULL,
	[MessageId] [int] NULL,
	[StatusId] [tinyint] NULL,
	[ReasonId] [int] NULL,
	[UserId] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[ModifiedDate] [datetime] NULL,
	[TransIds] [varchar](max) NULL,
	[VoidData] [xml] NULL,
 CONSTRAINT [PK_TicketVoiding_VoidingHistory_bk_VoidingHistoryId] PRIMARY KEY NONCLUSTERED 
(
	[VoidingHistoryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA] TEXTIMAGE_ON [DATA]
GO
CREATE CLUSTERED INDEX [CIX_TicketVoiding_VoidingHistory_bk_RequestId] ON [dbo].[TicketVoiding_VoidingHistory_bk]
(
	[RequestId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TOControl_Setting_bk](
	[CustID] [int] NOT NULL,
	[matchid] [int] NOT NULL,
	[MaxTurnOver] [money] NULL,
	[TotalTurnOver] [money] NULL,
	[IsNotified] [tinyint] NULL,
	[HouseTurnover] [money] NULL,
	[PercentLevel] [tinyint] NULL,
	[IsGroupHeadLine] [bit] NOT NULL,
	[winlostdate] [datetime] NULL,
	[ProfileID] [smallint] NULL,
	[IsEventLockTOLimit] [bit] NULL,
	[IsGlobalLockTOLimit] [bit] NULL
) ON [DATA]
GO
CREATE CLUSTERED INDEX [CIX_TOControl_Setting_bk] ON [dbo].[TOControl_Setting_bk]
(
	[CustID] ASC,
	[matchid] ASC,
	[IsGroupHeadLine] ASC,
	[ProfileID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[transfer_bk](
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[Debit] [money] NOT NULL,
	[Credit] [money] NOT NULL,
	[TransDesc] [nvarchar](1000) NULL,
	[winlostdate] [smalldatetime] NOT NULL,
	[recommend] [int] NOT NULL,
	[mrecommend] [int] NOT NULL,
	[srecommend] [int] NOT NULL,
	[currency] [tinyint] NULL,
	[refno] [bigint] NOT NULL,
	[creator] [int] NULL,
	[transid] [bigint] NOT NULL,
	[bettype] [smallint] NULL,
	[balance] [money] NULL
) ON [DATA] WITH (DATA_COMPRESSION = PAGE)
GO
CREATE CLUSTERED INDEX [CIX_winlostdate] ON [dbo].[transfer_bk]
(
	[winlostdate] ASC,
	[custid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Transfer_Coll_BK](
	[CustId] [int] NULL,
	[WinlostDate] [smalldatetime] NULL,
	[TransDate] [datetime] NULL,
	[Bettype] [smallint] NULL,
	[Debit] [money] NULL,
	[Credit] [money] NULL,
	[Currency] [tinyint] NULL,
	[ActualRate] [money] NULL,
	[TransID] [bigint] NOT NULL,
	[RefNo] [bigint] NULL,
	[Username] [nvarchar](50) NULL,
	[Recommend] [int] NULL,
	[MRecommend] [int] NULL,
	[SRecommend] [int] NULL,
	[Creator] [int] NULL,
	[TransDesc] [nvarchar](1000) NULL,
	[IP] [nvarchar](15) NULL,
 CONSTRAINT [PK_Transfer_Coll_BK] PRIMARY KEY NONCLUSTERED 
(
	[TransID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
CREATE CLUSTERED INDEX [CIX_winlostdate] ON [dbo].[Transfer_Coll_BK]
(
	[WinlostDate] ASC,
	[CustId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[transfer_fi](
	[transid] [bigint] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[bettype] [smallint] NULL,
	[actual_stake] [money] NOT NULL,
	[winlost] [money] NOT NULL,
	[TransDesc] [nvarchar](300) NULL,
	[winlostdate] [smalldatetime] NOT NULL,
	[recommend] [int] NOT NULL,
	[mrecommend] [int] NOT NULL,
	[srecommend] [int] NOT NULL,
	[currency] [tinyint] NULL,
	[refno] [bigint] NOT NULL,
	[creator] [int] NULL,
	[CheckerID] [int] NULL,
	[CheckerName] [varchar](50) NULL,
	[checkTime] [datetime] NULL,
	[ActualRate] [float] NULL,
	[isReversal] [bit] NULL
) ON [DATA]
GO
CREATE CLUSTERED INDEX [CIX_winlostdate] ON [dbo].[transfer_fi]
(
	[winlostdate] ASC,
	[custid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[translog_BK](
	[translogid] [bigint] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[odds] [smallmoney] NULL,
	[stake] [money] NOT NULL,
	[status] [nvarchar](10) NULL,
	[apositiontaking] [smallmoney] NULL,
	[mpositiontaking] [smallmoney] NULL,
	[tpositiontaking] [smallmoney] NULL,
	[spositiontaking] [smallmoney] NULL,
	[playerdiscount] [decimal](9, 8) NULL,
	[discount] [decimal](9, 8) NULL,
	[adiscount] [decimal](9, 8) NULL,
	[sdiscount] [decimal](9, 8) NULL,
	[creator] [int] NOT NULL,
	[winlostdate] [smalldatetime] NOT NULL,
	[betfrom] [nvarchar](1) NULL,
	[virtualrate] [float] NOT NULL,
	[actualrate] [float] NULL,
	[actual_stake] [money] NULL,
	[currency] [tinyint] NULL,
	[CurrencyName] [nvarchar](50) NULL,
	[recommend] [int] NOT NULL,
	[mrecommend] [int] NOT NULL,
	[srecommend] [int] NOT NULL,
	[ip] [varchar](45) NULL,
	[statusID] [tinyint] NULL,
	[balance] [money] NULL,
	[Username] [nvarchar](50) NULL,
	[transdesc] [nvarchar](1000) NULL,
	[productID] [int] NOT NULL,
	[gameID] [int] NOT NULL,
	[eventID] [int] NOT NULL,
	[vendorID] [int] NOT NULL,
	[GameId3rd] [nvarchar](50) NULL,
	[TranId3rd] [nvarchar](64) NULL,
	[custom1] [varchar](50) NULL,
	[custom2] [varchar](50) NULL,
	[custom3] [varchar](50) NULL,
	[LiveIndicator] [bit] NULL,
 CONSTRAINT [PK_translog_BK] PRIMARY KEY CLUSTERED 
(
	[translogid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VendorBettypeStatus_bk](
	[matchid] [int] NOT NULL,
	[bettype] [int] NOT NULL,
	[vendorid] [smallint] NOT NULL,
	[statusID] [tinyint] NOT NULL,
	[eventdate] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_VendorBettypeStatus] PRIMARY KEY CLUSTERED 
(
	[matchid] ASC,
	[bettype] ASC,
	[vendorid] ASC,
	[eventdate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VendorStatus_bk](
	[matchid] [int] NOT NULL,
	[vendorid] [smallint] NOT NULL,
	[SB_TradeStatusID] [tinyint] NOT NULL,
	[VD_TradeStatusID] [char](1) NOT NULL,
	[Link] [bit] NOT NULL,
	[Eventdate] [smalldatetime] NOT NULL,
	[Opened] [bit] NULL,
	[changetime] [datetime] NULL,
	[FixtureId] [varchar](20) NULL,
 CONSTRAINT [PK_VendorStatus] PRIMARY KEY CLUSTERED 
(
	[matchid] ASC,
	[vendorid] ASC,
	[Eventdate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VSOutright_bk](
	[Orid] [int] NOT NULL,
	[EventID] [int] NOT NULL,
	[RacerNum] [tinyint] NULL,
	[IsFavor] [varchar](3) NULL,
	[EventDate] [smalldatetime] NOT NULL,
	[KickoffTime] [datetime] NOT NULL,
	[RacerID] [int] NULL,
	[HumanID] [int] NULL,
	[WinOdds] [smallmoney] NULL,
	[PlaceOdds] [smallmoney] NULL,
	[Lane] [tinyint] NULL,
	[MaxBet] [int] NULL,
	[Placing] [tinyint] NULL,
	[Creator] [int] NOT NULL,
	[EventStatus] [varchar](50) NULL,
 CONSTRAINT [PK_VSOutright_BK] PRIMARY KEY CLUSTERED 
(
	[Orid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VSRaceInfo_bk](
	[EventID] [int] NOT NULL,
	[EventTime] [datetime] NOT NULL,
	[LeagueID] [int] NOT NULL,
	[PayOut] [tinyint] NULL,
	[EachWay] [tinyint] NULL,
	[CourseName] [varchar](100) NULL,
	[TrackType] [varchar](10) NULL,
	[Distance] [varchar](10) NULL,
	[Racers] [tinyint] NULL,
	[ForeCastPayout] [money] NULL,
	[TriCastPayout] [money] NULL,
	[CreateDate] [smalldatetime] NOT NULL,
	[Calculate] [bit] NOT NULL,
	[SportType] [tinyint] NOT NULL,
	[ChangeTime] [datetime] NULL,
	[EventStatus] [nvarchar](50) NULL,
	[BetStatus] [varchar](10) NULL,
 CONSTRAINT [PK_VSRaceInfo_bk] PRIMARY KEY CLUSTERED 
(
	[EventID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [DATA]
) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[zzzbettrans](
	[transid] [bigint] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[oddsid] [int] NOT NULL,
	[hdp1] [smallmoney] NULL,
	[hdp2] [smallmoney] NULL,
	[odds] [smallmoney] NULL,
	[stake] [money] NOT NULL,
	[winlost] [money] NULL,
	[status] [varchar](20) NULL,
	[livehomescore] [smallint] NULL,
	[liveawayscore] [smallint] NULL,
	[liveindicator] [bit] NULL,
	[betteam] [varchar](10) NULL,
	[creator] [int] NOT NULL,
	[refno] [bigint] NULL,
	[winlostdate] [smalldatetime] NULL,
	[betfrom] [varchar](1) NULL,
	[betcheck] [varchar](50) NULL,
	[checktime] [datetime] NULL,
	[matchid] [int] NULL,
	[bettype] [smallint] NULL,
	[keyid] [int] NOT NULL,
	[VoidingHistoryId] [int] NULL
) ON [DATA]
WITH
(
DATA_COMPRESSION = PAGE
)
GO
CREATE CLUSTERED INDEX [IX_zzzbettrans_transid] ON [dbo].[zzzbettrans]
(
	[transid] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[zzzbettrans_bk](
	[transid] [bigint] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[oddsid] [int] NOT NULL,
	[hdp1] [smallmoney] NULL,
	[hdp2] [smallmoney] NULL,
	[odds] [smallmoney] NULL,
	[stake] [money] NOT NULL,
	[status] [nvarchar](10) NULL,
	[winlost] [money] NULL,
	[livehomescore] [smallint] NULL,
	[liveawayscore] [smallint] NULL,
	[liveindicator] [bit] NULL,
	[betteam] [nvarchar](10) NULL,
	[creator] [int] NOT NULL,
	[refno] [bigint] NULL,
	[comstatus] [nvarchar](20) NULL,
	[winlostdate] [smalldatetime] NULL,
	[betfrom] [nvarchar](1) NULL,
	[betcheck] [nvarchar](50) NULL,
	[checktime] [datetime] NULL,
	[matchid] [int] NULL,
	[bettype] [smallint] NULL,
	[keyid] [int] NOT NULL,
	[VoidingHistoryId] [int] NULL,
 CONSTRAINT [PK_zzzbettrans_bk] PRIMARY KEY NONCLUSTERED 
(
	[keyid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 50, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
SET ANSI_PADDING ON
GO
CREATE CLUSTERED INDEX [IX_zzzbettrans_bk] ON [dbo].[zzzbettrans_bk]
(
	[custid] ASC,
	[matchid] ASC,
	[bettype] ASC,
	[status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[zzzbettransm_bk](
	[transid] [bigint] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[oddsid] [int] NOT NULL,
	[hdp1] [smallmoney] NULL,
	[hdp2] [smallmoney] NULL,
	[odds] [smallmoney] NULL,
	[stake] [money] NOT NULL,
	[status] [nvarchar](10) NULL,
	[winlost] [money] NULL,
	[livehomescore] [smallint] NULL,
	[liveawayscore] [smallint] NULL,
	[liveindicator] [bit] NULL,
	[betteam] [nvarchar](10) NULL,
	[creator] [int] NOT NULL,
	[refno] [bigint] NULL,
	[comstatus] [nvarchar](20) NULL,
	[winlostdate] [smalldatetime] NULL,
	[betfrom] [nvarchar](1) NULL,
	[betcheck] [nvarchar](50) NULL,
	[checktime] [datetime] NULL,
	[matchid] [int] NULL,
	[bettype] [smallint] NULL,
	[keyid] [int] NOT NULL,
	[VoidingHistoryId] [int] NULL,
 CONSTRAINT [PK_zzzbettransm_bk] PRIMARY KEY NONCLUSTERED 
(
	[keyid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_BetLucky3Result_bk_TransId] ON [dbo].[BetLucky3Result_bk]
(
	[TransId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [CIX_refno] ON [dbo].[BetParlayResult]
(
	[RefNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_winlostdate] ON [dbo].[BetParlayResult]
(
	[winlostdate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CIX_refno] ON [dbo].[betParlayResult_Archive]
(
	[RefNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_winlostdate] ON [dbo].[betParlayResult_Archive]
(
	[winlostdate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_TicketID] ON [dbo].[BetTradeSelling180]
(
	[TicketID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_custid] ON [dbo].[bettrans_bk]
(
	[custid] ASC
)
INCLUDE([winlostdate],[matchid],[bettype]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_transid] ON [dbo].[bettrans_bk]
(
	[transid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_CustID] ON [dbo].[bettransG]
(
	[custid] ASC
)
INCLUDE([winlostdate],[matchid]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_transid] ON [dbo].[bettransG]
(
	[transid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_winlostdate] ON [dbo].[bettransG]
(
	[winlostdate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_custid] ON [dbo].[bettransLC_bk]
(
	[custid] ASC
)
INCLUDE([winlostdate],[productID],[gameID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_RefNo] ON [dbo].[bettransLC_bk]
(
	[RefNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_transid] ON [dbo].[bettransm]
(
	[transid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_winlostdate] ON [dbo].[bettransm]
(
	[winlostdate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_custid] ON [dbo].[bettransRnG_bk]
(
	[custid] ASC
)
INCLUDE([winlostdate],[productID],[gameID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_RefNo] ON [dbo].[bettransRnG_bk]
(
	[RefNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_matchid] ON [dbo].[Dot_Admin_Assignment_Operator_bk]
(
	[matchid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_matchid] ON [dbo].[Dot_Admin_Assignment_Trader_bk]
(
	[matchid] ASC,
	[bettype] ASC,
	[liveindicator] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [DATA]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_Dot_Admin_Intg_MatchMapping_Ext_MatchID] ON [dbo].[Dot_Admin_Intg_MatchMapping_bk]
(
	[Ext_MatchID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_Dot_Admin_Intg_MetaFile_Ext_MatchID] ON [dbo].[Dot_Admin_Intg_MetaFile_bk]
(
	[Ext_MatchID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [PK_Dot_Admin_LiveLog] ON [dbo].[Dot_Admin_LiveLog]
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXM_MatchId_ProviderId] ON [dbo].[ExternalOddsMapping]
(
	[MatchId] ASC,
	[ProviderId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_matchid] ON [dbo].[Intg_OddsFeed_SettlementAction_bk]
(
	[MatchId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_eventdate] ON [dbo].[match_bk]
(
	[eventdate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_matchid] ON [dbo].[NetPositionTrans_bk]
(
	[MatchID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_matchid] ON [dbo].[odds_bk]
(
	[matchid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_matchid] ON [dbo].[Odds3rd_bk]
(
	[matchid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_OddsOS_bk_Matchid] ON [dbo].[oddsOS_bk]
(
	[matchid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_TicketVoiding_AutoUnmarkSetting_bk_CreatedDate] ON [dbo].[TicketVoiding_AutoUnmarkSetting_bk]
(
	[CreatedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_TicketVoiding_AutoVoidRequest_Queue_bk_MatchId_StatusID] ON [dbo].[TicketVoiding_AutoVoidRequest_Queue_bk]
(
	[MatchId] ASC,
	[StatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_TicketVoiding_Queue_bk_QueueId] ON [dbo].[TicketVoiding_Queue_bk]
(
	[QueueId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_TicketVoiding_Request_bk_CreatedDate] ON [dbo].[TicketVoiding_Request_bk]
(
	[CreatedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_TicketVoiding_RequestDetail_bk_MatchId] ON [dbo].[TicketVoiding_RequestDetail_bk]
(
	[MatchId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_TicketVoiding_RequestDetailTicket_Single_bk_MatchId_TransId] ON [dbo].[TicketVoiding_RequestDetailTicket_Single_bk]
(
	[MatchId] ASC,
	[TransId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_TicketVoiding_RequestDetailTicket_SubParlay_bk_MatchId_TransId] ON [dbo].[TicketVoiding_RequestDetailTicket_SubParlay_bk]
(
	[MatchId] ASC,
	[TransId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_IssueTypeID_CreatedDate_CustID] ON [dbo].[TicketVoiding_VoidedTransaction_bk]
(
	[IssueTypeID] ASC,
	[CreatedDate] ASC,
	[CustID] ASC
)
INCLUDE([SubIssueTypeID],[ReasonId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [ix_reasonid] ON [dbo].[TicketVoiding_VoidingHistory_bk]
(
	[ReasonId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_VoidingHistory_CreatedDate] ON [dbo].[TicketVoiding_VoidingHistory_bk]
(
	[CreatedDate] ASC
)
INCLUDE([MessageId],[StatusId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_TOControl_Setting_winlostdate] ON [dbo].[TOControl_Setting_bk]
(
	[winlostdate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_refno] ON [dbo].[transfer_fi]
(
	[refno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_winlostdate] ON [dbo].[translog_BK]
(
	[winlostdate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_Eventdate] ON [dbo].[VendorBettypeStatus_bk]
(
	[eventdate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_Eventdate] ON [dbo].[VendorStatus_bk]
(
	[Eventdate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_eventDate] ON [dbo].[VSOutright_bk]
(
	[EventDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_EventTime] ON [dbo].[VSRaceInfo_bk]
(
	[EventTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_transid] ON [dbo].[zzzbettrans_bk]
(
	[transid] ASC
)
INCLUDE([VoidingHistoryId],[matchid],[winlostdate]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_zzzbettrans_bk_VoidingHistoryId] ON [dbo].[zzzbettrans_bk]
(
	[VoidingHistoryId] ASC
)
WHERE ([VoidingHistoryId] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_transid] ON [dbo].[zzzbettransm_bk]
(
	[transid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
CREATE NONCLUSTERED INDEX [IX_zzzbettransm_bk_VoidingHistoryId] ON [dbo].[zzzbettransm_bk]
(
	[VoidingHistoryId] ASC
)
WHERE ([VoidingHistoryId] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
GO
ALTER TABLE [dbo].[AutoPayoutResult_bk_Temp] ADD  CONSTRAINT [DF_AutoPayoutResult_bk_IsCalculated]  DEFAULT ((0)) FOR [StatusId]
GO
ALTER TABLE [dbo].[AutoPayoutResult_bk_Temp] ADD  CONSTRAINT [DF_AutoPayoutResult_bk_TryCount]  DEFAULT ((0)) FOR [TryCount]
GO
ALTER TABLE [dbo].[AutoPayoutResult_bk_Temp] ADD  CONSTRAINT [DF_AutoPayoutResult_bk_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[AutoPayoutResult_bk_Temp] ADD  CONSTRAINT [DF_AutoPayoutResult_bk_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[Dot_Admin_Intg_MatchMapping_bk] ADD  CONSTRAINT [DF_Dot_Admin_Intg_MatchMapping_bk_Confirmed]  DEFAULT ((0)) FOR [Confirmed]
GO
ALTER TABLE [dbo].[Dot_Admin_Intg_MatchMapping_bk] ADD  CONSTRAINT [DF__Dot_Admin__SyncS__6FE99F9F]  DEFAULT ((0)) FOR [SyncScore]
GO
ALTER TABLE [dbo].[Dot_Admin_Intg_MatchMapping_bk] ADD  CONSTRAINT [Dot_Admin_Intg_MatchMapping_isLive]  DEFAULT ((0)) FOR [isLive]
GO
ALTER TABLE [dbo].[Dot_Admin_Intg_MatchMapping_bk] ADD  CONSTRAINT [DF_Dot_Admin_Intg_MatchMapping_NeutralReverse]  DEFAULT ((0)) FOR [NeutralReverse]
GO
ALTER TABLE [dbo].[Dot_Admin_Intg_MetaFile_bk] ADD  CONSTRAINT [DF_Dot_Admin_Intg_MetaFile_bk_Confirmed]  DEFAULT ((0)) FOR [Confirmed]
GO
ALTER TABLE [dbo].[Dot_Admin_Intg_MetaFile_bk] ADD  CONSTRAINT [DF_Dot_Admin_Intg_MetaFile_bk_Extra]  DEFAULT ('') FOR [Extra]
GO
ALTER TABLE [dbo].[match_remark] ADD  CONSTRAINT [DF_match_remark_SettlementStatus]  DEFAULT ((0)) FOR [SettlementStatus]
GO
ALTER TABLE [dbo].[ProviderResultDetail_bk_Temp] ADD  CONSTRAINT [DF_ProviderResultDetail_bk_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[TicketVoiding_AutoUnmarkSetting_bk] ADD  CONSTRAINT [DF_TicketVoiding_AutoUnmarkSetting_bk_IsConfirm]  DEFAULT ((0)) FOR [IsConfirm]
GO
ALTER TABLE [dbo].[TicketVoiding_AutoUnmarkSetting_bk] ADD  CONSTRAINT [DF_TicketVoiding_AutoUnmarkSetting_bk_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[TicketVoiding_AutoVoidRequest_Queue_bk] ADD  CONSTRAINT [DF_TicketVoiding_AutoVoidRequest_Queue_bk_Starttime]  DEFAULT (getdate()) FOR [Starttime]
GO
ALTER TABLE [dbo].[TicketVoiding_AutoVoidRequest_Queue_bk] ADD  CONSTRAINT [DF_TicketVoiding_AutoVoidRequest_Queue_bk_Duration]  DEFAULT ((0)) FOR [Duration]
GO
ALTER TABLE [dbo].[TicketVoiding_Queue_bk] ADD  CONSTRAINT [DF_TicketVoiding_Queue_bk_Starttime]  DEFAULT (getdate()) FOR [Starttime]
GO
ALTER TABLE [dbo].[TicketVoiding_Queue_bk] ADD  CONSTRAINT [DF_TicketVoiding_Queue_bk_Duration]  DEFAULT ((0)) FOR [Duration]
GO
ALTER TABLE [dbo].[TicketVoiding_Request_bk] ADD  CONSTRAINT [DF_TicketVoiding_Request_bk_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[TicketVoiding_Request_bk] ADD  CONSTRAINT [DF_TicketVoiding_Request_bk_LastModifiedDate]  DEFAULT (getdate()) FOR [LastModifiedDate]
GO
ALTER TABLE [dbo].[TicketVoiding_RequestDetail_bk] ADD  CONSTRAINT [DF_TicketVoiding_RequestDetail_bk_RequestType]  DEFAULT ((0)) FOR [RequestType]
GO
ALTER TABLE [dbo].[TicketVoiding_VoidedTransaction_bk] ADD  CONSTRAINT [DF_TicketVoiding_VoidedTransaction_bk_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[TicketVoiding_VoidingHistory_bk] ADD  CONSTRAINT [DF_TicketVoiding_VoidingHistory_bk_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[TicketVoiding_VoidingHistory_bk] ADD  CONSTRAINT [DF_TicketVoiding_VoidingHistory_bk_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[TOControl_Setting_bk] ADD  CONSTRAINT [DF_TOControl_Setting_bk_isNotified]  DEFAULT ((0)) FOR [IsNotified]
GO
ALTER TABLE [dbo].[TOControl_Setting_bk] ADD  CONSTRAINT [DF_TOControl_Setting_bk_PercentLevel]  DEFAULT ((0)) FOR [PercentLevel]
GO
ALTER TABLE [dbo].[TOControl_Setting_bk] ADD  CONSTRAINT [DF_TOControl_Setting_IsEventLockTOLimit]  DEFAULT ((0)) FOR [IsEventLockTOLimit]
GO
ALTER TABLE [dbo].[TOControl_Setting_bk] ADD  CONSTRAINT [DF_TOControl_Setting_IsGlobalLockTOLimit]  DEFAULT ((0)) FOR [IsGlobalLockTOLimit]
GO
