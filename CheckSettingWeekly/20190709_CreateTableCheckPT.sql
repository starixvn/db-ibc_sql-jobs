USE CheckCustDB
GO
/*
	Created: 20190709@Winnie
	Task: Check PT weekly - [Redmine:#775336]
	
*/ 
-- BEGIN STEP 1: Deploy this SP at DBCUST.CustDB, Run only in the FIRST running

CREATE TABLE [dbo].[Licensees](
	[LicenseeID] [int] NOT NULL,
	[LicenseeName] [varchar](50) NOT NULL,
	[Description] [varchar](100) NULL,
	[IsDeposit] [bit] NULL,
	[AffectedDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL DEFAULT ((1)),
	[IsKPIActive] [bit] NOT NULL DEFAULT ((0)),
	[IsOneWorkActive] [bit] NOT NULL DEFAULT ((0)),
	[BrandName] [varchar](100) NOT NULL DEFAULT (''),
	[CompanyName] [varchar](100) NOT NULL DEFAULT (''),
	[IsAllowedMemberComm] [bit] NOT NULL DEFAULT ((0)),
	[EditBetSetting] [bit] NULL DEFAULT ((0)),
 CONSTRAINT [PK_Licensees] PRIMARY KEY CLUSTERED 
(
	[LicenseeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [Data]
) ON [Data]
GO
----
CREATE TABLE [dbo].[Licensee](
	[LicenseeId] [int] NOT NULL,
	[LicenseeName] [nvarchar](50) NULL,
	[LicenseeCompanyName] [nvarchar](50) NULL,
	[LicenseeStatusId] [tinyint] NULL,
	[SoftLaunch] [datetime] NULL,
	[FullLaunch] [datetime] NULL,
	[MainUrl] [varchar](3000) NULL,
	[APILinkageUrl] [varchar](3000) NULL,
	[LicenseeLocationId] [int] NULL,
	[RestrictedLocationRemark] [nvarchar](2000) NULL,
	[Remark] [nvarchar](300) NULL,
	[LicenseeTypeId] [tinyint] NULL,
	[IsChineseMarketOnly] [bit] NULL CONSTRAINT [DF_Licensee_IsChineseMarket]  DEFAULT ((0)),
	[InternalURL] [varchar](3000) NULL,
	[IsReseller] [bit] NULL CONSTRAINT [DF_Licensee_IsReseller]  DEFAULT ((0)),
	[RegisteredLicenseeName] [nvarchar](50) NULL,
 CONSTRAINT [PK_Licensee] PRIMARY KEY CLUSTERED 
(
	[LicenseeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [Data]
) ON [Data]
GO
----
CREATE TABLE [dbo].[LicenseeType](
	[LicenseeTypeId] [tinyint]       NOT NULL,
	[LicenseeTypeName] [varchar](30) NULL,
 CONSTRAINT [PK_LicenseeType] PRIMARY KEY CLUSTERED 
(
	[LicenseeTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [Data]
) ON [Data]
GO
----
INSERT INTO [dbo].[Licensees]
           ([LicenseeID]
           ,[LicenseeName]
           ,[Description]
           ,[IsDeposit]
           ,[AffectedDate]
           ,[IsActive]
           ,[IsKPIActive]
           ,[IsOneWorkActive]
           ,[BrandName]
           ,[CompanyName]
           ,[IsAllowedMemberComm]
           ,[EditBetSetting])
SELECT [LicenseeID]
           ,[LicenseeName]
           ,[Description]
           ,[IsDeposit]
           ,[AffectedDate]
           ,[IsActive]
           ,[IsKPIActive]
           ,[IsOneWorkActive]
           ,[BrandName]
           ,[CompanyName]
           ,[IsAllowedMemberComm]
           ,[EditBetSetting]
FROM DBLIC.bodb_Licensee.dbo.[Licensees] WITH(NOLOCK)
----

INSERT INTO [dbo].[Licensee]
           ([LicenseeID]
		   ,[LicenseeName]
           ,[LicenseeCompanyName]
           ,[LicenseeStatusId]
           ,[SoftLaunch]
           ,[FullLaunch]
           ,[MainUrl]
           ,[APILinkageUrl]
           ,[LicenseeLocationId]
           ,[RestrictedLocationRemark]
           ,[Remark]
           ,[LicenseeTypeId]
           ,[IsChineseMarketOnly]
           ,[InternalURL]
           ,[IsReseller]
           ,[RegisteredLicenseeName])
SELECT	   [LicenseeID]
		   ,[LicenseeName]
           ,[LicenseeCompanyName]
           ,[LicenseeStatusId]
           ,[SoftLaunch]
           ,[FullLaunch]
           ,[MainUrl]
           ,[APILinkageUrl]
           ,[LicenseeLocationId]
           ,[RestrictedLocationRemark]
           ,[Remark]
           ,[LicenseeTypeId]
           ,[IsChineseMarketOnly]
           ,[InternalURL]
           ,[IsReseller]
           ,[RegisteredLicenseeName]
FROM bodb_OIC.dbo.[Licensee] WITH(NOLOCK)
----
INSERT INTO [dbo].[LicenseeType]([LicenseeTypeId],[LicenseeTypeName])
SELECT [LicenseeTypeId],[LicenseeTypeName]
FROM bodb_OIC.dbo.[LicenseeType] WITH(NOLOCK)