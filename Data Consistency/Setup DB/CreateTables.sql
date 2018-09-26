USE [bodb_Consistency]
GO
/*	
	Created:20180912@Kathy
	DB: DBTP/bodb_Consistency
	Task: Data consistency checking
*/

CREATE TABLE [dbo].[DBA_ConversationHandle](
	[Id] [tinyint] NULL,
	[ConversationHandle] [uniqueidentifier] NULL
) ON [bodb_Consistency_DATA]

GO

CREATE TABLE [dbo].[DBA_LastLogId](
	[LogId] [bigint] NULL
) ON [bodb_Consistency_DATA]

GO

CREATE TABLE [dbo].[DBA_JobActivity](
	[JobId] [int] IDENTITY(1,1) NOT NULL,
	[ScheduleId] [int] NOT NULL,
	[StatusId] [tinyint] NULL,
	[StartExecutionDate] [datetime] NULL,
	[LastExecutedDate] [datetime] NULL,
	[StopExecutionDate] [datetime] NULL,
	[NextExecutedDate] [datetime] NULL,
	[LastDuration] [int] NULL,
 CONSTRAINT [PK_DBA_JobActivity_JobId] PRIMARY KEY CLUSTERED 
(
	[JobId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [bodb_Consistency_INDEX]
) ON [bodb_Consistency_INDEX]

GO

CREATE TABLE [dbo].[DBA_Rules](
	[RuleId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](128) NULL,
	[Description] [nvarchar](max) NULL,
	[SeverityLevel] [varchar](20) NULL,
 CONSTRAINT [PK_DBA_Rules_RuleId] PRIMARY KEY CLUSTERED 
(
	[RuleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [bodb_Consistency_INDEX]
) ON [bodb_Consistency_INDEX] TEXTIMAGE_ON [bodb_Consistency_DATA]

GO

CREATE TABLE [dbo].[DBA_ScheduleErrorLogs](
	[LogId] [bigint] NOT NULL,
	[Message] [varchar](max) NULL,
	[SampleData] [varchar](max) NULL,
 CONSTRAINT [PK_DBA_ScheduleErrorLogs_LogId] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [bodb_Consistency_INDEX]
) ON [bodb_Consistency_INDEX] TEXTIMAGE_ON [bodb_Consistency_DATA]

GO
CREATE TABLE [dbo].[DBA_ScheduleLogs](
	[LogId] [bigint] IDENTITY(1,1) NOT NULL,
	[ScheduleId] [int] NULL,
	[Command] [nvarchar](max) NULL,
	[IsPassed] [bit] NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[IsSent] [bit] NULL,
 CONSTRAINT [PK_DBA_ScheduleLogs_LogId] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [bodb_Consistency_INDEX]
) ON [bodb_Consistency_INDEX] TEXTIMAGE_ON [bodb_Consistency_DATA]

GO

CREATE TABLE [dbo].[DBA_Schedules](
	[ScheduleId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](128) NULL,
	[TaskId] [int] NULL,
	[IsEnable] [bit] NULL,
	[FrequenceType] [int] NULL,
	[FrequenceInterval] [int] NULL,
	[FrequenceSubDayType] [int] NULL,
	[FrequenceSubdayInterval] [int] NULL,
	[ActiveStartDate] [datetime] NULL,
	[ActiveEndDate] [datetime] NULL,
	[ActiveStartTime] [time](7) NULL,
	[ActiveEndTime] [time](7) NULL,
	[DateCreated] [datetime] NULL,
	[DateModified] [datetime] NULL,
	[NotifyLevelEmail] [int] NULL,
	[Emails] [varchar](max) NULL,
 CONSTRAINT [PK_DBA_Schedules_ScheduleId] PRIMARY KEY CLUSTERED 
(
	[ScheduleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [bodb_Consistency_INDEX]
) ON [bodb_Consistency_INDEX] TEXTIMAGE_ON [bodb_Consistency_DATA]

GO


CREATE TABLE [dbo].[DBA_Tasks](
	[TaskId] [int] IDENTITY(1,1) NOT NULL,
	[RuleId] [int] NULL,
	[command] [nvarchar](max) NULL,
 CONSTRAINT [PK_DBA_Tasks_TaskId] PRIMARY KEY CLUSTERED 
(
	[TaskId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [bodb_Consistency_INDEX]
) ON [bodb_Consistency_INDEX] TEXTIMAGE_ON [bodb_Consistency_DATA]

GO
