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
