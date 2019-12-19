/*
	Created: 20191203@Bobby
	Task: Summarize Promotion data into rptLicPromotion [Redmine: #119538]
	DB: DBLIC.bodb_LicenseeReport
*/
USE master
GO

ALTER DATABASE [bodb_LicenseeReport]  
ADD FILEGROUP rptLicPromotion;  
GO  
ALTER DATABASE [bodb_LicenseeReport]   
ADD FILE   
(  
    NAME = rptLicPromotion_01,  
    FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rptLicPromotion_01.ndf',  
    SIZE = 10MB,  
    MAXSIZE = UNLIMITED,  
    FILEGROWTH = 32768KB  
),  
(  
    NAME = rptLicPromotion_02,  
    FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rptLicPromotion_02.ndf',  
    SIZE = 10MB,  
    MAXSIZE = UNLIMITED,  
    FILEGROWTH = 32768KB 
)  
TO FILEGROUP rptLicPromotion;  
GO

USE [bodb_LicenseeReport]
GO

/****** DROP:  Table [dbo].[rptLicPromotion]    Script Date: 12/3/2019 11:42:22 AM ******/
IF OBJECT_ID(N'dbo.rptLicPromotion', 'U') IS NOT NULL
	DROP TABLE [dbo].[rptLicPromotion]
GO

/****** CREATE:  Table [dbo].[rptLicPromotion]    Script Date: 12/3/2019 11:42:22 AM ******/
CREATE TABLE [dbo].[rptLicPromotion](
	[RptDate] [date] NOT NULL,
	[TimeZone] [smallint] NOT NULL,
	[RptDateGMT] [date] NOT NULL,
	[SiteID] [int] NOT NULL,
	[CurrencyID] [int] NOT NULL,
	[ProductID] [int] NOT NULL,
	[BetCount] [int] NULL,
	[BetCount_WonLose] [int] NULL,
	[Turnover] [money] NULL,
	[Turnover_WonLose] [money] NULL,
	[BetCountOfPromoTime] [int] NULL,
	[BetCountOfPromoTime_WonLose] [int] NULL,
	[CouponCount] [int] NULL,
	[RedemptionCount] [int] NULL,
	[RedemptionPrize] [money] NULL,
 CONSTRAINT [PK_rptLicPromotion] PRIMARY KEY CLUSTERED 
(
	[RptDate] ASC,
	[TimeZone] ASC,
	[RptDateGMT] ASC,
	[SiteID] ASC,
	[CurrencyID] ASC,
	[ProductID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [rptLicPromotion]
) ON [rptLicPromotion]
GO


/****** PERMISSION:  Table [dbo].[rptLicPromotion]    Script Date: 12/3/2019 11:42:22 AM ******/
GRANT SELECT ON [dbo].[rptLicPromotion] TO [bodbAdminNet]