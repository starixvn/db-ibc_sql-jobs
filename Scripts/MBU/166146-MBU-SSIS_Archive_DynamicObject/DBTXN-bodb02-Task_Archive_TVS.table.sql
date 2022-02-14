/*<info serverAlias="DBTXN-bodb02"></info>*/
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
 */
USE [bodb02]
GO

CREATE TABLE [dbo].[Task_Archive_TVS](
	[Winlostdate] [smalldatetime] NULL,
	[RequestID] [bigint] NULL
) ON [PRIMARY]
GO

CREATE CLUSTERED INDEX [CIX_Winlostdate] ON [dbo].[Task_Archive_TVS]
(
	[Winlostdate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO