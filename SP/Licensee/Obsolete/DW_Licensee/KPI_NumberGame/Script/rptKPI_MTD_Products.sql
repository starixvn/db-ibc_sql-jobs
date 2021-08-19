USE [bodb_licensee]
GO
/****** Object:  Table [dbo].[rptKPI_MTD_3rdProducts]    Script Date: 10/26/2012 09:40:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[rptKPI_MTD_3rdProducts](
	[rptDate] [datetime] NOT NULL,
	[SiteID] [int] NOT NULL,
	[CurrencyID] [int] NOT NULL,
	[StatID] [int] NOT NULL,
	[Bettype] [int] NOT NULL,
	[MonthToDate] [float] NULL,
 CONSTRAINT [PK_rptKPI_MTD_3rdproducts] PRIMARY KEY CLUSTERED 
(
	[rptDate] ASC,
	[SiteID] ASC,
	[CurrencyID] ASC,
	[StatID] ASC,
	[Bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DW_KPI_DATA]
) ON [DW_KPI_DATA]
