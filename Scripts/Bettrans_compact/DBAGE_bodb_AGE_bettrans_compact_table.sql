/*<info serverAlias="DBAGE-bodb_AGE" isNested="0"></info>*/
/*
	Created by: 20231201@Bobby
	Task: 153357 - Alpha - CDC bettrans_compact
	DB: DBAGE.bodb_AGE
	Revisions:
		
*/

USE [bodb_AGE]
GO

/****** Object:  Table [dbo].[bettrans_compact]    Script Date: 1/3/2024 11:27:49 AM ******/
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
) ON [cdc_bettrans_data]
GO
CREATE CLUSTERED INDEX [CIX_bettrans_compact] ON [dbo].[bettrans_compact]
(
	[winlostdate] ASC,
	[custid] ASC,
	[bettype] ASC
) ON [cdc_bettrans_data]

-------------[SystemSettings]
INSERT INTO [dbo].[SystemSettings]
    ([VName]
    ,[VValue])
VALUES
    ('Age_cdc_bettrans_compact'
    ,'{"lastRowId":162686752,"delayTime":0}')
GO