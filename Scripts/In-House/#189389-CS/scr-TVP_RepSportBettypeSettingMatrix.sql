/*<info serverAlias="DBAGE-bodb02, DBBOF-bodb02, DBTXN-custdb"></info>*/

CREATE TYPE [dbo].[TVP_RepSportBettypeSettingMatrix] AS TABLE (
	[SportType] [smallint] NOT NULL,
	[BetType] [int] NOT NULL,
	[isLicensee] [bit] NOT NULL,
	[isLive] [bit] NOT NULL,
	[Site] [varchar](50) NOT NULL,
	[isActive] [bit] NOT NULL,
	[SportTypeRefPT] [smallint] NULL,
	[BetTypeRefPT] [int] NULL,
	[isLivePT] [bit] NOT NULL,
	[TablePT] [varchar](50) NULL,
	[SportTypeRefComm] [smallint] NULL,
	[BetTypeRefComm] [int] NULL,
	[TableComm] [varchar](50) NULL,
	[SportTypeRefBetSetting] [smallint] NULL,
	[BetTypeRefBetSetting] [int] NULL,
	[TableBetSetting] [varchar](50) NULL,
	[IsLiveComm] [bit] NOT NULL,
	[IsLiveBetSetting] [bit] NOT NULL,
	[TableBettrans] [varchar](100) NULL,
	[RealProductId] [tinyint] NULL,
	[SporttypeRefWinlossLimit] [smallint] NULL,
	[BettypeRefWinlossLimit] [smallint] NULL,
	[ProductID] [tinyint] NULL,
	[isDeleted] [bit] NULL,
	[RepUpdateTime] [datetime2](7) NULL,
	[_FetchedTime] [datetime2](7) NULL
)
GO

GRANT EXECUTE ON TYPE::[dbo].[TVP_RepSportBettypeSettingMatrix] TO [repl_ap] AS [dbo]
GO