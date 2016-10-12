--drop table [tbl_Customer_Account]
CREATE TABLE [dbo].[tbl_Customer_Account](
	[transid] [bigint] NOT NULL,
	[refno] [bigint] NOT NULL,	
	[custid] [int] NOT NULL,
	[currency] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[amount] [money] NULL,
	[creator] [int] NULL,
	[TransDesc] [nvarchar](200) NULL,
	[deleted] [bit] NULL,
	[balanceduppreviousday] [bit] NULL,
	[OtherCustid] [int] NULL,
	[recommend] [int] NULL,
	[mrecommend] [int] NULL,
	[srecommend] [int] NULL,
	[transtype] [smallint] NULL,
 CONSTRAINT [PK_customer_account] PRIMARY KEY CLUSTERED 
(
	[transid] ASC
) ON licensee_transfer
) ON licensee_transfer

GO

ALTER TABLE [dbo].[tbl_Customer_Account] ADD  CONSTRAINT [DF_tbl_Customer_Account_deleted]  DEFAULT ((0)) FOR [deleted]

CREATE NONCLUSTERED INDEX nl_tbl_Customer_Account_deleted
	ON dbo.tbl_Customer_Account (deleted)
	INCLUDE(TransDesc)
	
CREATE NONCLUSTERED INDEX nl_tbl_Customer_Account_OtherCustid_transdate_refno
	ON dbo.tbl_Customer_Account (OtherCustid,transdate,refno,transtype)
	INCLUDE(custid)
--dbcc dbreindex ('tbl_Customer_Account')

GO
-- drop table [bettrans]
CREATE TABLE [dbo].[bettrans](
	[transid] [bigint] NOT NULL,
	[custid] [int] NOT NULL,	
	[stake] [money] NOT NULL,
	statusid tinyint NULL,
	[status] [nvarchar](15) NULL,
	[winlost] [money] NULL,
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[playercomm] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[apositiontaking] [smallmoney] NULL,
	[mpositiontaking] [smallmoney] NULL,
	[tpositiontaking] [smallmoney] NULL,
	[liveindicator] [bit] NULL,
	[betteam] [nvarchar](10) NULL,
	[winlostdate] [smalldatetime] NULL,
	[betfrom] [nvarchar](1) NULL,
	[actualrate] [float] NULL,
	[matchid] [int] NULL,
	[recommend] [int] NOT NULL,
	[mrecommend] [int] NOT NULL,
	[actual_stake] [money] NULL,
	[currency] [tinyint] NULL,
	[scomm] [money] NULL,
	[spositiontaking] [smallmoney] NULL,
	[swinlost] [money] NULL,
	[srecommend] [int] NOT NULL,	
	[refno] [bigint] NULL,	
	[transdate] [smalldatetime] NULL,	
	[bettype] [smallint] NULL,
 CONSTRAINT [PK_bettrans] PRIMARY KEY CLUSTERED 
(
	[transid] ASC
) ON licensee_staging
) ON licensee_staging

GO
 

CREATE TABLE [dbo].[match](
	[matchid] [int] NOT NULL,
	[leagueid] [int] NOT NULL,
	[homeid] [int] NOT NULL,
	[awayid] [int] NOT NULL,
	[eventdate] [datetime] NULL,
	[finalhomescore] [int] NULL,
	[finalawayscore] [int] NULL,
	[exrisk] [float] NULL,
	[sporttype] [tinyint] NOT NULL,
	[matchcode] [nvarchar](50) NULL,
	[hthomescore] [int] NULL,
	[htawayscore] [int] NULL,
	[kickofftime] [datetime] NULL,
 CONSTRAINT [PK_match] PRIMARY KEY CLUSTERED 
(
	[matchid] ASC
)ON licensee_staging
) ON licensee_staging

GO
 
CREATE TABLE [dbo].[outright](
	[matchid] [int] NOT NULL,
	[leagueid] [int] NOT NULL,
	[homeid] [int] NOT NULL,
	[awayid] [int] NULL,
	[eventdate] [smalldatetime] NOT NULL,
	[kickofftime] [datetime] NOT NULL,
	[oddsstatus] [varchar](10) NULL,
	[odds] [smallmoney] NULL,
	[status] [varchar](10) NULL,
	[risk] [money] NULL,
	[groupmatch] [varchar](50) NULL,
 CONSTRAINT [PK_outright] PRIMARY KEY CLUSTERED 
(
	[matchid] ASC
)ON licensee_staging
) ON licensee_staging



