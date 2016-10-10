--nonSummary tables
CREATE TABLE [dbo].[MailKPI_Tasks](
	[TaskID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](100) NULL,
	[Schedule] [datetime] NULL,
	[Frequency] [tinyint] NULL,
	[Status] [tinyint] NULL,
	[Disabled] [bit] NULL,
 CONSTRAINT [PK_Mail_Task] PRIMARY KEY CLUSTERED 
(
	[TaskID] ASC
) ON licensee_table
) ON licensee_table



CREATE TABLE [dbo].[MailKPI_Reports](
	[ReportID] [int] IDENTITY(1,1) NOT NULL,
	[ReportName] [varchar](50) NULL,
	[Description] [varchar](200) NULL,
 CONSTRAINT [PK_MailKPI_Reports_1] PRIMARY KEY CLUSTERED 
(
	[ReportID] ASC
) ON licensee_table
) ON licensee_table



CREATE TABLE [dbo].[MailKPI_Sections](
	[SectionID] [int] IDENTITY(1,1) NOT NULL,
	[SectionName] [varchar](50) NULL,
	[spName] [varchar](500) NULL,
 CONSTRAINT [PK_MailKPI_Reports] PRIMARY KEY CLUSTERED 
(
	[SectionID] ASC
) ON licensee_table
) ON licensee_table


CREATE TABLE [dbo].[MailKPI_Users](
	[UserID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NULL,
	[Email] [varchar](50) NULL,
 CONSTRAINT [PK_MailKPI_Users] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC
) ON licensee_table
) ON licensee_table

--sp_rename 'tblKPI_SiteGroups','LicenseeGroups'

CREATE TABLE [dbo].[LicenseeGroups](
	[GroupID] [int] NOT NULL,
	[GroupName] [varchar](50) NULL,
	[Description] [varchar](200) NULL,
 CONSTRAINT [PK_LicenseeGroups] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC
) ON licensee_table
) ON licensee_table


CREATE TABLE [dbo].[tblKPI_Stats](
	[StatID] [int] NOT NULL,
	[StatName] [varchar](100) NULL,
 CONSTRAINT [PK_tbl_KPIStat] PRIMARY KEY CLUSTERED 
(
	[StatID] ASC
) ON licensee_table
) ON licensee_table


CREATE TABLE [dbo].[MailKPI_SendMailUsers](
	[TaskID] [int] NOT NULL,
	[UserID] [int] NOT NULL,
 CONSTRAINT [PK_MailKPI_UserReports_1] PRIMARY KEY CLUSTERED 
(
	[TaskID] ASC,
	[UserID] ASC
) ON licensee_table
) ON licensee_table


CREATE TABLE [dbo].[MailKPI_ReportSections](
	[ReportID] [int] NOT NULL,
	[SectionID] [int] NOT NULL,
	[SectionOrder] [smallint] NULL,
 CONSTRAINT [PK_ReportSections] PRIMARY KEY CLUSTERED 
(
	[ReportID] ASC,
	[SectionID] ASC
) ON licensee_table
) ON licensee_table


CREATE TABLE [dbo].[MailKPI_ReportPermission](
	[UserID] [int] NOT NULL,
	[ReportID] [int] NOT NULL,
	[SectionID] [int] NOT NULL,
	[Permission] [tinyint] NULL,
 CONSTRAINT [PK_Mail_KPI] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC,
	[ReportID] ASC,
	[SectionID] ASC
) ON licensee_table
) ON licensee_table

CREATE TABLE [dbo].[MailKPI_TaskLogs](
	[LogID] [int] IDENTITY(1,1) NOT NULL,
	[LogDate] [datetime] NULL,
	[TaskID] [int] NULL,
	[Description] [varchar](200) NULL,
	[Status] [tinyint] NULL,
	[UserID] [int] NULL,
 CONSTRAINT [PK_MailKPI_TaskLog] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
) ON licensee_table
) ON licensee_table


CREATE TABLE [dbo].[tblKPI_Budgets](
	[Date] [smalldatetime] NOT NULL,
	[GroupID] [int] NOT NULL,
	[StatID] [int] NOT NULL,
	[BudgetAmount] [float] NULL,
 CONSTRAINT [PK_tblKPI_Budgets] PRIMARY KEY CLUSTERED 
(
	[Date] ASC,
	[GroupID] ASC,
	[StatID] ASC
) ON [licensee_table]
) ON [licensee_table]
	
-- drop table tblKPI_Sites
/*CREATE TABLE [dbo].[tblKPI_Sites](
	[SiteID] [int] NOT NULL,
	[GroupID] [int] NULL,
	[SiteName] [varchar](50) NULL,
	[Description] [varchar](200) NULL,
	[TxnRate] [money] NULL,
 CONSTRAINT [PK_tblKPI_Sites] PRIMARY KEY CLUSTERED 
(
	[SiteID] ASC
) ON licensee_table
) ON licensee_table
*/

--FOREIGN KEY
/*
ALTER TABLE [dbo].[MailKPI_ReportPermission]  WITH NOCHECK ADD  CONSTRAINT [FK_MailKPI_ReportPermission_MailKPI_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[MailKPI_Users] ([UserID])
NOT FOR REPLICATION

ALTER TABLE [dbo].[MailKPI_ReportPermission] NOCHECK CONSTRAINT [FK_MailKPI_ReportPermission_MailKPI_Users]


ALTER TABLE [dbo].[MailKPI_ReportSections]  WITH NOCHECK ADD  CONSTRAINT [FK_MailKPI_ReportSections_MailKPI_Reports] FOREIGN KEY([ReportID])
REFERENCES [dbo].[MailKPI_Reports] ([ReportID])
NOT FOR REPLICATION

ALTER TABLE [dbo].[MailKPI_ReportSections] NOCHECK CONSTRAINT [FK_MailKPI_ReportSections_MailKPI_Reports]


ALTER TABLE [dbo].[MailKPI_ReportSections]  WITH NOCHECK ADD  CONSTRAINT [FK_MailKPI_ReportSections_MailKPI_Sections] FOREIGN KEY([SectionID])
REFERENCES [dbo].[MailKPI_Sections] ([SectionID])


ALTER TABLE [dbo].[MailKPI_ReportSections] NOCHECK CONSTRAINT [FK_MailKPI_ReportSections_MailKPI_Sections]


ALTER TABLE [dbo].[MailKPI_SendMailUsers]  WITH NOCHECK ADD  CONSTRAINT [FK_MailKPI_SendMailUsers_MailKPI_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[MailKPI_Users] ([UserID])
NOT FOR REPLICATION

ALTER TABLE [dbo].[MailKPI_SendMailUsers] NOCHECK CONSTRAINT [FK_MailKPI_SendMailUsers_MailKPI_Users]


ALTER TABLE [dbo].[MailKPI_SendMailUsers]  WITH NOCHECK ADD  CONSTRAINT [FK_MailKPI_UserReports_MailKPI_Tasks] FOREIGN KEY([TaskID])
REFERENCES [dbo].[MailKPI_Tasks] ([TaskID])
NOT FOR REPLICATION

ALTER TABLE [dbo].[MailKPI_SendMailUsers] NOCHECK CONSTRAINT [FK_MailKPI_UserReports_MailKPI_Tasks]


ALTER TABLE [dbo].[MailKPI_TaskLogs]  WITH NOCHECK ADD  CONSTRAINT [FK_MailKPI_TaskLogs_MailKPI_SendMailUsers] FOREIGN KEY([TaskID], [UserID])
REFERENCES [dbo].[MailKPI_SendMailUsers] ([TaskID], [UserID])
NOT FOR REPLICATION

ALTER TABLE [dbo].[MailKPI_TaskLogs] NOCHECK CONSTRAINT [FK_MailKPI_TaskLogs_MailKPI_SendMailUsers]


ALTER TABLE [dbo].[tblKPI_Sites]  WITH NOCHECK ADD  CONSTRAINT [FK_tblKPI_Sites_LicenseeGroups] FOREIGN KEY([GroupID])
REFERENCES [dbo].[LicenseeGroups] ([GroupID])
NOT FOR REPLICATION

ALTER TABLE [dbo].[tblKPI_Sites] NOCHECK CONSTRAINT [FK_tblKPI_Sites_LicenseeGroups]

*/