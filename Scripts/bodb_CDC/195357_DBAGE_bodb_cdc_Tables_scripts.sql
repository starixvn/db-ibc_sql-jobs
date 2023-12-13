/*<info serverAlias="DBAGE-bodb02" isNested="0"></info>*/
/*
	Created by: 20231201@Bobby
	Task: 153357 - Alpha - CDC bettrans_compact
	DB: DBAGE.bodb02
	Revisions:
		
*/

USE [bodb_cdc]
GO

/****** Object:  Table [dbo].[bettrans_compact]    Script Date: 12/11/2023 10:08:30 AM ******/
CREATE TABLE [dbo].[bettrans_compact](
	[custid] [int] NOT NULL,
	[winlostdate] [smalldatetime] NOT NULL,
	[productId] [tinyint] NOT NULL,
	[sporttype] [int] NOT NULL,
	[bettype] [smallint] NOT NULL,
	[leagueGroupID] [int] NOT NULL,
	[ticketType] [int] NOT NULL,
	[betcount] [int] NULL,
	[turnover] [money] NULL,
	[netTurnover] [money] NULL,
	[TurnoverNoDraw] [money] NULL,
	[winlost] [money] NULL,
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[swinlost] [money] NULL,
	[playercomm] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[scomm] [money] NULL,
	[grosscomm] [money] NULL,
	[extraWinloss] [decimal](38, 6) NULL,
	[extraComm] [decimal](38, 6) NULL,
	CONSTRAINT [PK_bettrans_compact] PRIMARY KEY CLUSTERED 
	(
		[custid] ASC,
		[winlostdate] ASC,
		[productId] ASC,
		[sporttype] ASC,
		[bettype] ASC,
		[leagueGroupID] ASC,
		[ticketType] ASC
	) ON [bettrans_compact_data]
) ON [bettrans_compact_data]
GO

/****** Object:  Table [dbo].[cdc_bettrans_batch]    Script Date: 12/11/2023 10:08:30 AM ******/
CREATE TABLE [dbo].[cdc_bettrans_batch](
	[rowId] [bigint] NOT NULL,
	[cmdType] [int] NOT NULL,
	[cmdId] [int] NULL,
	[cmdTxn] [binary](10) NOT NULL,
	[transid] [bigint] NULL,
	[custid] [int] NULL,
	[recommend] [int] NULL,
	[mrecommend] [int] NULL,
	[srecommend] [int] NULL,
	[odds] [smallmoney] NULL,
	[winlostdate] [smalldatetime] NULL,
	[bettype] [smallint] NULL,
	[stake] [money] NULL,
	[actual_stake] [money] NULL,
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
	[epositiontaking] [smallmoney] NULL,
	[statusID] [tinyint] NULL,
	[modds] [smallmoney] NULL,
	[oddsspread] [money] NULL,
	[betid] [bigint] NULL,
	[betdaqid] [bigint] NULL,
	[matchid] [int] NULL,
	[actiondate] [datetime] NULL
) ON [bettrans_compact_data]
GO
CREATE CLUSTERED INDEX [CIX_srecommend] ON [dbo].[cdc_bettrans_batch]
(
	[srecommend] ASC,
	[winlostdate] ASC,
	[bettype] ASC
) ON [bettrans_compact_data]
GO