/*<info serverAlias="DBSSIS-SSISDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_Package_Setting_Init]
	@environment varchar(10)='DEV'
	,@packageName varchar(100)=''
	,@creator varchar(100)=''
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBSSIS.SSISDB
	Revisions:
		- 20130831@Bobby: Init
*/
BEGIN
	SET NOCOUNT ON;

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
		FROM DBTXN.bodb02.dbo.SSIS_Task_ArchiveDate_Test with(nolock)
	) AS txn
	outer apply (
		select dateadd(DAY, -1, txn.MinDate) AS BUDate_Current
			,dateadd(DAY, 0, txn.MaxDate) AS BUDate_New
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
