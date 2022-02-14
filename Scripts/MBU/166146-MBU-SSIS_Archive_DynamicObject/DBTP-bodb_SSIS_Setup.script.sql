/*<info serverAlias="DBTP-bodb_SSIS"></info>*/
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBTP
*/
USE [master]
GO
/****** Object:  Database [bodb_SSIS]    Script Date: 2/11/2022 2:09:52 PM ******/
CREATE DATABASE [bodb_SSIS]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'bodb_SSIS', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER2014\MSSQL\DATA\bodb_SSIS.mdf' , SIZE = 4096KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'bodb_SSIS_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER2014\MSSQL\DATA\bodb_SSIS_log.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [bodb_SSIS] SET COMPATIBILITY_LEVEL = 120
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [bodb_SSIS].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [bodb_SSIS] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [bodb_SSIS] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [bodb_SSIS] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [bodb_SSIS] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [bodb_SSIS] SET ARITHABORT OFF 
GO
ALTER DATABASE [bodb_SSIS] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [bodb_SSIS] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [bodb_SSIS] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [bodb_SSIS] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [bodb_SSIS] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [bodb_SSIS] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [bodb_SSIS] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [bodb_SSIS] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [bodb_SSIS] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [bodb_SSIS] SET  DISABLE_BROKER 
GO
ALTER DATABASE [bodb_SSIS] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [bodb_SSIS] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [bodb_SSIS] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [bodb_SSIS] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [bodb_SSIS] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [bodb_SSIS] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [bodb_SSIS] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [bodb_SSIS] SET RECOVERY FULL 
GO
ALTER DATABASE [bodb_SSIS] SET  MULTI_USER 
GO
ALTER DATABASE [bodb_SSIS] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [bodb_SSIS] SET DB_CHAINING OFF 
GO
ALTER DATABASE [bodb_SSIS] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [bodb_SSIS] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
ALTER DATABASE [bodb_SSIS] SET DELAYED_DURABILITY = DISABLED 
GO
EXEC sys.sp_db_vardecimal_storage_format N'bodb_SSIS', N'ON'
GO
USE [bodb_SSIS]
GO
/****** Object:  Table [dbo].[SSIS_DynamicMapping]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_DynamicMapping](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[TableName] [varchar](100) NULL,
	[SourceServer] [varchar](100) NULL,
	[SourceDB] [varchar](100) NULL,
	[ExecCommand] [varchar](1000) NULL,
	[CommandType] [varchar](50) NULL,
	[BatchSize] [int] NULL,
	[ChunkSize] [int] NULL,
	[Active] [bit] NULL,
	[OutputFileInfo] [varchar](100) NULL,
 CONSTRAINT [PK_SSIS_DynamicMapping] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SSIS_DynamicMapping_OutputFile]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_DynamicMapping_OutputFile](
	[FileID] [int] IDENTITY(1,1) NOT NULL,
	[RuntimeID] [int] NULL,
	[DynamicMappingID] [int] NULL,
	[FileName] [varchar](1000) NULL,
	[RowTotal] [int] NULL,
	[ARC_Status] [bit] NULL,
	[HA_Status] [bit] NULL,
	[DR_Status] [bit] NULL,
	[CreateTime] [datetime] NULL,
 CONSTRAINT [PK_SSIS_DynamicMapping_OutputFile] PRIMARY KEY CLUSTERED 
(
	[FileID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SSIS_DynamicMapping_Package]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_DynamicMapping_Package](
	[DynamicMappingID] [int] NOT NULL,
	[PackageID] [int] NOT NULL,
 CONSTRAINT [PK_SSIS_DynamicMapping_Package] PRIMARY KEY CLUSTERED 
(
	[DynamicMappingID] ASC,
	[PackageID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SSIS_DynamicMapping_Param]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_DynamicMapping_Param](
	[DynamicMappingID] [int] NULL,
	[ParamName] [varchar](50) NULL,
	[ParamType] [varchar](50) NULL,
	[ParamDesc] [varchar](100) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SSIS_DynamicMapping_Target]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_DynamicMapping_Target](
	[TargetID] [int] IDENTITY(1,1) NOT NULL,
	[DynamicMappingID] [int] NOT NULL,
	[TargetTable] [varchar](100) NOT NULL,
	[TargetServer] [varchar](100) NOT NULL,
	[TargetDB] [varchar](100) NULL,
	[Active] [bit] NULL,
	[Environment] [varchar](10) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SSIS_Package]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_Package](
	[PackageID] [int] IDENTITY(1,1) NOT NULL,
	[PackageName] [varchar](100) NULL,
 CONSTRAINT [PK_SSIS_Package] PRIMARY KEY CLUSTERED 
(
	[PackageID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SSIS_Package_ENV]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_Package_ENV](
	[PackageID] [int] NULL,
	[Environment] [varchar](50) NULL,
	[Active] [bit] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SSIS_Package_Param]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_Package_Param](
	[PackageID] [int] NOT NULL,
	[ParamName] [varchar](50) NOT NULL,
	[ParamType] [varchar](50) NULL,
 CONSTRAINT [PK_SSIS_Package_Param] PRIMARY KEY CLUSTERED 
(
	[PackageID] ASC,
	[ParamName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SSIS_PackageRuntime]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_PackageRuntime](
	[RuntimeID] [int] IDENTITY(1,1) NOT NULL,
	[PackageID] [int] NOT NULL,
	[DynamicMappingID] [int] NULL,
	[Environment] [varchar](10) NULL,
	[Command] [varchar](250) NULL,
	[TargetInfo] [varchar](1000) NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[Status] [varchar](10) NULL,
	[Error] [varchar](250) NULL,
	[Creator] [varchar](50) NULL,
	[ParentID] [int] NULL,
	[Message] [varchar](250) NULL,
	[RowTotal] [int] NULL,
	[SessionID] [varchar](50) NULL,
 CONSTRAINT [PK_SSIS_PackageRuntime] PRIMARY KEY CLUSTERED 
(
	[RuntimeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SSIS_PackageRuntime_Param]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_PackageRuntime_Param](
	[RuntimeID] [int] NOT NULL,
	[ParamName] [varchar](100) NOT NULL,
	[ParamValue] [varchar](100) NULL
) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_Package_MappingTable_Select]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SSIS_Package_MappingTable_Select]
	-- Add the parameters for the stored procedure here
	@environment varchar(10)
	,@packageID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT dt.ID AS SourceID
	FROM [dbo].[SSIS_DynamicMapping] dt with(nolock)
	inner join [dbo].[SSIS_DynamicMapping_Package] pt with(nolock) on pt.[DynamicMappingID] = dt.[ID]
	inner join [dbo].[SSIS_Package] ps with(nolock) on ps.[PackageID] = pt.[PackageID]
	inner join [dbo].[SSIS_Package_ENV] pe with(nolock) on ps.[PackageID] = pe.[PackageID]
	where ps.PackageID = @packageID AND dt.Active=1
	AND pe.[Environment] = @environment
END
GO
/****** Object:  StoredProcedure [dbo].[SSIS_Package_Report_Status]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SSIS_Package_Report_Status]
	-- Add the parameters for the stored procedure here
	@processID int=0
	,@status varchar(10)='SUCCESS'
	,@runEvent bit=null
	,@runTVS bit=null
	,@runTransfer bit=null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @message varchar(250), @cntTask INT;

	select @message = ISNULL([Message],'')
	FROM dbo.SSIS_PackageRuntime p WITH(NOLOCK)
	WHERE p.RuntimeID=@processID

	SELECT @cntTask = LEN(@message) - LEN(REPLACE(@message, '#', ''))

	UPDATE p WITH(rowlock,updlock)
	SET [Status] = case when @cntTask =  1 then 'Closed' else  [Status] end
		, EndTime = case when @cntTask =  1 then GETDATE() end
		, SessionID=@processID
		, [Message] = @message + case when LEN(@message) = 0 then '' else '#' end + @status
	FROM dbo.SSIS_PackageRuntime p
	WHERE p.RuntimeID=@processID

	-- report status
	SELECT @status AS [status],t.item
	FROM (
		values
		('Process Event', @runEvent),
		('Process TVS', @runTVS),
		('Process Transfer', @runTransfer)
	) as t (item, val)
	WHERE t.val = CASE WHEN @status = 'SUCCESS' THEN 1 ELSE 0 END	
END
GO
/****** Object:  StoredProcedure [dbo].[SSIS_Package_Setting_Init]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SSIS_Package_Setting_Init]
	-- Add the parameters for the stored procedure here
	@environment varchar(10)='DEV'
	,@packageName varchar(100)=''
	,@creator varchar(100)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--declare @environment varchar(10);

	DECLARE @BUDate smalldatetime
		,@MBDate smalldatetime
		,@MinDate smalldatetime
		,@MaxDate smalldatetime
		,@HasEvent bit
		,@HasTransfer bit
		,@HasTVS bit
		,@HasENV bit
		,@SessionID varchar(50)
		,@processID int;

	with cte as (
		select 0 as IsENV
		union all
		SELECT top 1 1 as IsENV
		FROM dbo.SSIS_Package p with(nolock)
		inner join dbo.SSIS_Package_ENV e with(nolock) on e.PackageID = p.PackageID
		where e.Environment=@environment 
			and p.PackageName = @packageName
	)
	select @BUDate = MAX(bu.BUDate_New)
		,@MinDate = MAX(txn.MinDate) --AS MinDate
		,@MaxDate = MAX(txn.MaxDate) --AS MaxDate
		,@HasEvent = CAST(MAX(CASE WHEN txn.MaxDate is not null then 1 else 0 end) AS BIT) --AS HasEvent
		,@HasTransfer = CAST(MAX(CASE WHEN bu.BUDate_Current is not null then 1 else 0 end) AS BIT) --AS HasTransfer
		,@HasTVS = CAST(MAX(CASE WHEN txn.MinDate is not null then 1 else 0 end) AS BIT) --AS HasTVS
		,@HasENV = CAST(MAX(t.IsENV) AS BIT) --AS HasENV
	FROM cte t
	outer apply (
		select min(Winlostdate) AS MinDate, max(Winlostdate) as MaxDate
		FROM DBTXN.bodb02.dbo.Task_ArchiveDate with(nolock)
	) AS txn
	outer apply (
		select dateadd(DAY, -1, txn.MinDate) AS BUDate_Current
			,dateadd(DAY, 1, txn.MaxDate) AS BUDate_New
	) AS bu
	
	INSERT INTO [dbo].[SSIS_PackageRuntime]
           ([PackageID]
           ,[DynamicMappingID]
           ,[Environment]
           ,[Command]
           ,[TargetInfo]
           ,[StartTime]
           ,[EndTime]
           ,[Status]
           ,[Creator]
           ,[ParentID]
           ,[SessionID])
	SELECT p.[PackageID]
		,NULL AS [DynamicMappingID]
        ,@environment AS [Environment]
        ,NULL AS [Command]
        ,NULL AS [TargetInfo]
        ,getdate() AS [StartTime]
        ,NULL AS [EndTime]
        ,'InProgress' AS [Status]
        ,@creator AS [Creator]
        ,0 AS [ParentID]
        ,@SessionID AS [SessionID]
	FROM dbo.SSIS_Package p with(nolock)
	WHERE p.PackageName=@packageName
	
	SET @processID = SCOPE_IDENTITY();

	IF @processID > 0
	BEGIN
		INSERT INTO [dbo].[SSIS_PackageRuntime_Param]
			   ([RuntimeID]
			   ,[ParamName]
			   ,[ParamValue])
		SELECT [RuntimeID]
			   ,[ParamName]
			   ,[ParamValue]
		FROM (
			VALUES 
			(@processID, 'BUDate', CONVERT(char(10), @BUDate,126)),
			(@processID, 'MinDate', CONVERT(char(10), @MinDate,126)),
			(@processID, 'MaxDate', CONVERT(char(10), @MaxDate,126)),
			(@processID, 'HasEvent', CAST(@HasEvent AS char(10))),
			(@processID, 'HasTransfer', CAST(@HasTransfer AS char(10))),
			(@processID, 'HasTVS', CAST(@HasTVS AS char(10))),
			(@processID, 'HasENV', CAST(@HasENV AS char(10)))

		) AS t([RuntimeID],[ParamName],[ParamValue])
	END

	SELECT @BUDate AS BUDate
		,@MinDate AS MinDate
		,@MaxDate AS MaxDate
		,@HasEvent AS HasEvent
		,@HasTransfer AS HasTransfer
		,@HasTVS AS HasTVS
		,@HasENV AS HasENV
		,CAST(@processID AS char(10)) AS SessionID
		,@processID AS ProcessID
END
GO
/****** Object:  StoredProcedure [dbo].[SSIS_PackageRountine_EndUpdate]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SSIS_PackageRountine_EndUpdate]
	-- Add the parameters for the stored procedure here
	@rountineID int
	, @command varchar(1000)
	, @rowCount int
	, @error int
	, @message varchar(250)
	, @targetInfo varchar(1000)
	, @outputFileName varchar(1000)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE rt WITH(ROWLOCK, UPDLOCK)
	SET command=@command
		,Status = case when @error>0 then 'Failed' else 'Completed'  end
		,EndTime=getdate()
		,Error=@error, Message=case when @error>0 then @message end
		,RowTotal=@rowCount
		,TargetInfo=@targetInfo
	FROM dbo.SSIS_PackageRuntime rt
	WHERE RuntimeID=@rountineID

	IF ISNULL(@rowCount,0) > 0 AND LEN(@outputFileName) > 0 and isnull(@error,0) = 0
	BEGIN
		INSERT INTO [dbo].[SSIS_DynamicMapping_OutputFile]
			([RuntimeID]
			,[DynamicMappingID]
			,[FileName]
			,[RowTotal]
			,[ARC_Status]
			,[HA_Status]
			,[DR_Status]
			,[CreateTime])
		SELECT [RuntimeID]
			,[DynamicMappingID]
			,@outputFileName + '.csv' AS [FileName]
			,@rowCount AS [RowTotal]
			,1 AS [ARC_Status]
			,1 AS [HA_Status]
			,0 AS [DR_Status]
			,GETDATE() AS [CreateTime]
		FROM dbo.SSIS_PackageRuntime WITH(NOLOCK)
		WHERE RuntimeID=@rountineID
	END
	-- RETURN
	Select @error AS Error
END
GO
/****** Object:  StoredProcedure [dbo].[SSIS_PackageRountine_ErrorLog]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SSIS_PackageRountine_ErrorLog]
	-- Add the parameters for the stored procedure here
	@rountineID int
	, @error int
	, @message varchar(250)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	select @error AS Error, 1 AS RuntimeError;
END
GO
/****** Object:  StoredProcedure [dbo].[SSIS_PackageRountine_PreExec]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SSIS_PackageRountine_PreExec]
	-- Add the parameters for the stored procedure here
	@sourceID INT
	, @environment VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @targetInfo VARCHAR(8000);

	SELECT @targetInfo = COALESCE(@targetInfo + ';', '') + (tr.[TargetServer]+'#'+tr.[TargetDB]+'#'+tr.[TargetTable]) 
	FROM [dbo].[SSIS_DynamicMapping] dt with(nolock)
	inner join [dbo].[SSIS_DynamicMapping_Target] tr with(nolock) on tr.[DynamicMappingID] = dt.[ID] 
	WHERE dt.ID=@sourceID AND tr.Active=1 and tr.Environment=@environment;

	select @targetInfo as [TargetInfo];
END
GO
/****** Object:  StoredProcedure [dbo].[SSIS_PackageRountine_PreInit]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SSIS_PackageRountine_PreInit]
	-- Add the parameters for the stored procedure here
	@packageID int
	, @environment VARCHAR(10)
	, @runtimeID INT
	, @sourceID INT
	, @outputFileDir VARCHAR(1000)
	, @sessionID varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @routineID INT;
	--SET @packageID=?;
	--SET @env=?;
	--SET @runtimeID=?;
	--SET @sourceID=?;
	--SET @outputFileDir=?

	INSERT INTO [dbo].[SSIS_PackageRuntime]
		([PackageID],[DynamicMappingID]
		,[Environment]
		,[StartTime]
		,[Status]
		,[ParentID]
		,[SessionID])
	SELECT p.[PackageID], @sourceID AS [DynamicMappingID]
			,@environment  AS [Environment]
			,GETDATE() AS [StartTime]
			,'Running' AS [Status]
		,@runtimeID AS [ParentID]
		,@sessionID AS [SessionID]
	FROM dbo.SSIS_Package p with(nolock)
	where PackageID=@packageID;

	SET @routineID = SCOPE_IDENTITY();

	SELECT @routineID AS RoutineID, 0 AS Error
		,dt.SourceServer, dt.SourceDB
		,t.ExecCommand
		,ISNULL(@outputFileDir,'')+'\\'+@environment+'_'+CAST(@routineID AS varchar(10))+'_'+dt.TableName+ '_' + ti.subfix AS [outputFileName]
		,dt.OutputFileInfo
		,dt.BatchSize
		,dt.ChunkSize
		,dt.TableName
	FROM [dbo].[SSIS_DynamicMapping] dt with(nolock)
	CROSS APPLY (
		--select 'winlostdate' as 'ParamName', '2021-04-30' as ParamValue
		SELECT TOP 1 ParamName, ParamValue
		FROM dbo.SSIS_PackageRuntime_Param p with(nolock)
		WHERE p.RuntimeID = @runtimeID
	) AS rp
	CROSS APPLY (
		SELECT TOP 1 tp.ParamName
		FROM dbo.[SSIS_DynamicMapping_Param] tp with(nolock)
		WHERE tp.DynamicMappingID = dt.ID
	) AS rt
	cross apply (
		select 
			case 
				when dt.CommandType = 'SP' THEN 'EXEC ' + dt.[ExecCommand] + ' @'+rt.ParamName +'=''' + rp.ParamValue + '''' 
			else REPLACE(dt.[ExecCommand], '@'+rt.ParamName, '''' + rp.ParamValue +'''')
		END AS [ExecCommand]
	) as t
	cross apply (
		select replace(replace(CONVERT(varchar(30), getdate(),126), ':','-'),'.','-')
	) as ti(subfix)
	WHERE dt.ID=@sourceID AND rp.ParamName = rt.ParamName;
END
GO
/****** Object:  StoredProcedure [dbo].[SSIS_PackageRuntime_EndUpdate]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SSIS_PackageRuntime_EndUpdate]
	-- Add the parameters for the stored procedure here
	@runtimeID int
	,@runtimeError bit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	update rt with(rowlock,updlock)
	set 
		[Status] = case when @runtimeError = 1 then 'Failed' else 'Completed' end
		,Error = @runtimeError
		,EndTime = getdate()
	from dbo.SSIS_PackageRuntime rt
	where rt.RuntimeID = @runtimeID;

	--truncate table [dbo].[Task_ArchiveDate];
END
GO
/****** Object:  StoredProcedure [dbo].[SSIS_PackageRuntime_Init]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SSIS_PackageRuntime_Init]
	-- Add the parameters for the stored procedure here
	@winlostdate smalldatetime
	,@environment varchar(10)
	,@packageName varchar(100)
	,@creator varchar(100)
	,@sessionID varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @runtimeID INT;
    
	-- Insert statements for procedure here
	INSERT INTO [dbo].[SSIS_PackageRuntime]
           ([PackageID]
           ,[Environment]
           ,[StartTime]
           ,[Status]
		   ,[Creator])
     SELECT p.[PackageID]
           ,@environment AS [Environment]
           ,GETDATE() AS [StartTime]
           ,'Running' AS [Status]
		   ,@creator AS [Creator]
	FROM dbo.SSIS_Package p with(nolock)
	where PackageName=@packageName;

	SET @runtimeID = SCOPE_IDENTITY();

	if @runtimeID > 0
	begin
		update rt with(rowlock,updlock)
		set ParentID = @sessionID, SessionID=@sessionID
		FROM [dbo].[SSIS_PackageRuntime] rt
		where rt.RuntimeID = @runtimeID;

		INSERT INTO [dbo].[SSIS_PackageRuntime_Param]
           ([RuntimeID]
           ,[ParamName]
           ,[ParamValue])
		SELECT @runtimeID AS [RuntimeID]
           ,'winlostdate' AS [ParamName]
           ,CONVERT(char(10), @winlostdate,126) AS [ParamValue]
	end

	SELECT @runtimeID AS RuntimeID, p.PackageID
	FROM dbo.SSIS_Package p with(nolock)
	where PackageName=@packageName;
END
GO
/****** Object:  StoredProcedure [dbo].[SSIS_PackageRuntime_InitBU]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SSIS_PackageRuntime_InitBU]
	-- Add the parameters for the stored procedure here
	@BUDate smalldatetime
	,@environment varchar(10)
	,@packageName varchar(100)
	,@creator varchar(100)
	,@sessionID varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @runtimeID INT;
    
	-- Insert statements for procedure here
	INSERT INTO [dbo].[SSIS_PackageRuntime]
           ([PackageID]
           ,[Environment]
           ,[StartTime]
           ,[Status]
		   ,[Creator])
     SELECT p.[PackageID]
           ,@environment AS [Environment]
           ,GETDATE() AS [StartTime]
           ,'Running' AS [Status]
		   ,@creator AS [Creator]
	FROM dbo.SSIS_Package p with(nolock)
	where PackageName=@packageName;

	SET @runtimeID = SCOPE_IDENTITY();

	if @runtimeID > 0
	begin
		update rt with(rowlock,updlock)
		set ParentID = @sessionID, SessionID = @sessionID
		FROM [dbo].[SSIS_PackageRuntime] rt
		where rt.RuntimeID = @runtimeID;

		INSERT INTO [dbo].[SSIS_PackageRuntime_Param]
           ([RuntimeID]
           ,[ParamName]
           ,[ParamValue])
		SELECT @runtimeID AS [RuntimeID]
           ,'BUDate' AS [ParamName]
           ,CONVERT(char(10), @BUDate,126) AS [ParamValue]
	end

	SELECT @runtimeID AS RuntimeID, p.PackageID
	FROM dbo.SSIS_Package p with(nolock)
	where PackageName=@packageName;
END
GO
/****** Object:  StoredProcedure [dbo].[SSIS_PackageRuntime_PreInit]    Script Date: 2/11/2022 2:09:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SSIS_PackageRuntime_PreInit]
	-- Add the parameters for the stored procedure here
	@minDate smalldatetime
	,@maxdate smalldatetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	with cte (Winlostdate) as (
		select @minDate
		union all
		select dateadd(DAY,1,Winlostdate)
		from cte
		where Winlostdate<@maxdate
	)
	select Winlostdate
	from cte
	where @minDate<=@maxdate
	order by Winlostdate ASC;
END
GO
USE [master]
GO
ALTER DATABASE [bodb_SSIS] SET  READ_WRITE 
GO
