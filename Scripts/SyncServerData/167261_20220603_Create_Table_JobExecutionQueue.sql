/*<info serverAlias="DBAGE-bodb02,DBACC-bodb02" isFunction="1" isNested="0"></info>*/
/*
	Created: 20220603@Sol
	Task: Database - Sync-up Standby Server data - [Redmine:167261]
	Database: DBAGE-bodb02,DBACC-bodb02
	
	Revision:
		- 20220603@Sol: Database - Sync-up Standby Server data - Create tabe - [Redmine:167261]
		
*/

USE bodb02;

GO

CREATE TABLE [dbo].[JobExecutionQueue](
	[QueueId] [int] IDENTITY(1,1) NOT NULL,
	[ServerName] [varchar](200) NULL,
	[AliasName] [varchar](200) NOT NULL,
	[SqlCommand] [varchar](max) NOT NULL,
	[Params] [varchar](max) NULL,
	[ExecStatus] [varchar](50) NOT NULL,
	[CreatedDate] [datetime] NULL,
	[CompletedDate] [datetime] NULL,
	[ModifiedDate] [datetime] NULL,
	[Remark] [varchar](4000) NULL,
	CONSTRAINT [PK_JobExecutionQueue_QueueId] PRIMARY KEY CLUSTERED 
	(
		[QueueId] ASC
	)
)
GO