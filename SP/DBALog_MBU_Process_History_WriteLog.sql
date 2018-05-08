/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isNested="0"></info>*/
USE [bodb_CustomerLog]
GO

ALTER PROCEDURE [dbo].[DBALog_MBU_Process_History_WriteLog]
AS

/*
	Created: 20180329@Percy
	DB: DBLOG.bodb_CustomerLog
	Task: Write log of MBBU process for all servers

	Revisions:
		- 20180329@Percy: Initialize SP [RedmineID: #92391]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE
		@WinlostDateList	VARCHAR(100),
		@StartTime			DATETIME,
		@EndTime			DATETIME,
		@ServerName			VARCHAR(100),
		@IsMoving			TINYINT,
		@MovingType			TINYINT,
		@LogDate			DATETIME,
		@flag_DBTRANS		VARCHAR(200),
		@flag_DBOthers		VARCHAR(200)

	DECLARE @CurrentDate DATETIME
	SELECT  @LogDate = GETDATE()
	SELECT  @CurrentDate = CONVERT(DATE, @LogDate)

	SELECT @StartTime = CASE WHEN ISDATE(VValue) = 1 THEN CONVERT(DATETIME, VValue) ELSE GETDATE() END
	FROM bodb02.dbo.SystemSettings WITH (NOLOCK)
	WHERE VName = 'StartMoving_Local'

	IF CONVERT(DATE, @StartTime) <> @CurrentDate -- No MB/BU today
	BEGIN
		RETURN
	END

	SELECT @StartTime = NULL

	DECLARE @MBBUSchedule TABLE(ScheduleId TINYINT, Winlostdate SMALLDATETIME)

	-- Check MB
	INSERT INTO @MBBUSchedule (ScheduleId, Winlostdate)
	EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel

	IF EXISTS (SELECT 1 FROM @MBBUSchedule)
	BEGIN
		SELECT @MovingType = 1
	END
	-- Check BU
	ELSE IF EXISTS (SELECT 1 FROM DBTXN.bodb02.dbo.Task_ArchiveDate WITH(NOLOCK))
	BEGIN
		SELECT @MovingType = 2

		INSERT INTO @MBBUSchedule (Winlostdate)
		SELECT Winlostdate FROM DBTXN.bodb02.dbo.Task_ArchiveDate WITH(NOLOCK)
	END
	ELSE -- no MB/BU
	BEGIN
		RETURN
	END

	SELECT @flag_DBTRANS = CASE @MovingType WHEN 1 THEN 'isMovingBet' WHEN 2 THEN 'isArchivingBet' END
	SELECT @flag_DBOthers = CASE @MovingType WHEN 1 THEN 'isMovingBet_Local' WHEN 2 THEN 'isArchivingBet_Local' END

	SELECT @WinlostDateList = STUFF((SELECT ',' + CONVERT(VARCHAR(50), Winlostdate, 121) FROM @MBBUSchedule ORDER BY Winlostdate FOR XML PATH('')), 1, 1, '')
	FROM @MBBUSchedule

	IF NOT EXISTS (SELECT 1 FROM dbo.DBALog_MBU_Process_History WITH (NOLOCK) WHERE LogDate >= @CurrentDate)
	BEGIN
		-- DBTRANS
		SELECT
			@StartTime = CASE WHEN VName = 'StartMoving_Local' THEN
							CASE WHEN ISDATE(VValue) = 1 THEN CONVERT(DATETIME, VValue) ELSE GETDATE() END
						ELSE @StartTime END,
			@EndTime = CASE WHEN VName = 'EndMoving_Local' THEN
							CASE WHEN ISDATE(VValue) = 1 THEN CONVERT(DATETIME, VValue) ELSE GETDATE() END
						ELSE @EndTime END,
			@ServerName = 'DBTRANS',
			@IsMoving = CASE WHEN VName = @flag_DBTRANS THEN CONVERT(TINYINT, VValue) ELSE @IsMoving END
		FROM DBTXN.bodb02.dbo.SystemSettings WITH (NOLOCK)
		WHERE VName IN ('StartMoving_Local','EndMoving_Local',@flag_DBTRANS)

		INSERT INTO dbo.DBALog_MBU_Process_History (WinlostDateList, StartTime, EndTime, ServerName, IsMoving, MovingType, LogDate)
		VALUES (@WinlostDateList, @StartTime, @EndTime, @ServerName, @IsMoving, @MovingType, @LogDate)

		-- DB06
		SELECT
			@StartTime = CASE WHEN VName = 'StartMoving_Local' THEN
							CASE WHEN ISDATE(VValue) = 1 THEN CONVERT(DATETIME, VValue) ELSE GETDATE() END
						ELSE @StartTime END,
			@EndTime = CASE WHEN VName = 'EndMoving_Local' THEN
							CASE WHEN ISDATE(VValue) = 1 THEN CONVERT(DATETIME, VValue) ELSE GETDATE() END
						ELSE @EndTime END,
			@ServerName = 'DB06',
			@IsMoving = CASE WHEN VName = @flag_DBOthers THEN CONVERT(TINYINT, VValue) ELSE @IsMoving END
		FROM DBACC.bodb02.dbo.SystemSettings WITH (NOLOCK)
		WHERE VName IN ('StartMoving_Local','EndMoving_Local',@flag_DBOthers)

		INSERT INTO dbo.DBALog_MBU_Process_History (WinlostDateList, StartTime, EndTime, ServerName, IsMoving, MovingType, LogDate)
		VALUES (@WinlostDateList, @StartTime, @EndTime, @ServerName, @IsMoving, @MovingType, @LogDate)

		-- DB052
		SELECT
			@StartTime = CASE WHEN VName = 'StartMoving_Local' THEN
							CASE WHEN ISDATE(VValue) = 1 THEN CONVERT(DATETIME, VValue) ELSE GETDATE() END
						ELSE @StartTime END,
			@EndTime = CASE WHEN VName = 'EndMoving_Local' THEN
							CASE WHEN ISDATE(VValue) = 1 THEN CONVERT(DATETIME, VValue) ELSE GETDATE() END
						ELSE @EndTime END,
			@ServerName = 'DB052',
			@IsMoving = CASE WHEN VName = @flag_DBOthers THEN CONVERT(TINYINT, VValue) ELSE @IsMoving END
		FROM DBLIC.bodb02.dbo.SystemSettings WITH (NOLOCK)
		WHERE VName IN ('StartMoving_Local','EndMoving_Local',@flag_DBOthers)

		INSERT INTO dbo.DBALog_MBU_Process_History (WinlostDateList, StartTime, EndTime, ServerName, IsMoving, MovingType, LogDate)
		VALUES (@WinlostDateList, @StartTime, @EndTime, @ServerName, @IsMoving, @MovingType, @LogDate)

		-- DB053
		SELECT
			@StartTime = CASE WHEN VName = 'StartMoving_Local' THEN
							CASE WHEN ISDATE(VValue) = 1 THEN CONVERT(DATETIME, VValue) ELSE GETDATE() END
						ELSE @StartTime END,
			@EndTime = CASE WHEN VName = 'EndMoving_Local' THEN
							CASE WHEN ISDATE(VValue) = 1 THEN CONVERT(DATETIME, VValue) ELSE GETDATE() END
						ELSE @EndTime END,
			@ServerName = 'DB053',
			@IsMoving = CASE WHEN VName = @flag_DBOthers THEN CONVERT(TINYINT, VValue) ELSE @IsMoving END
		FROM DBAGE.bodb02.dbo.SystemSettings WITH (NOLOCK)
		WHERE VName IN ('StartMoving_Local','EndMoving_Local',@flag_DBOthers)

		INSERT INTO dbo.DBALog_MBU_Process_History (WinlostDateList, StartTime, EndTime, ServerName, IsMoving, MovingType, LogDate)
		VALUES (@WinlostDateList, @StartTime, @EndTime, @ServerName, @IsMoving, @MovingType, @LogDate)
	END
END
GO