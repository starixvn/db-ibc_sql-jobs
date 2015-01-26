USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_CPUCheck]    Script Date: 01/26/2015 05:18:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Task_CPUCheck]
AS
	SET NOCOUNT ON

	Declare @CPU smallmoney
	DECLARE @CPU_BUSY int, @IDLE int, @m money
	Declare @LogMesg nvarchar(200)


	SELECT @CPU_BUSY = @@CPU_BUSY, @IDLE = @@IDLE, @m = 1
	WAITFOR DELAY '000:00:01'

	SELECT @CPU = (@@CPU_BUSY - @CPU_BUSY)/((@@IDLE - @IDLE + @@CPU_BUSY - @CPU_BUSY) * @m) *100 --AS 'CPU Utilization'

	IF @CPU < 60 RETURN

	BEGIN
		-- start to collect CPU average for 20 seconds
		Declare @CPUs TABLE (rn int PRIMARY KEY IDENTITY(1,1), CPU smallmoney)
		Declare @rn int

		SET @rn = 1
		WHILE @rn <= 15
		BEGIN
			SELECT @CPU_BUSY = @@CPU_BUSY, @IDLE = @@IDLE, @m = 1
			WAITFOR DELAY '000:00:01'

			INSERT INTO @CPUs (CPU)
			SELECT (@@CPU_BUSY - @CPU_BUSY)/((@@IDLE - @IDLE + @@CPU_BUSY - @CPU_BUSY) * @m) *100 --AS 'CPU Utilization'

			SET @rn = @rn + 1
		END

		SELECT @CPU = AVG(CPU) FROM @CPUs
	END

	IF @CPU < 60 RETURN

	BEGIN
		SET @LogMesg = 'System:(1) update BETTRANS statistics due to CPU average (15 seconds) = ' + CAST(@CPU as nvarchar(10))
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @LogMesg
		-- update stats on bettrans
		UPDATE STATISTICS dbo.bettrans

		WAITFOR DELAY '000:00:05.000'

		DELETE FROM @CPUs
		SET @rn = 1
		WHILE @rn <= 10
		BEGIN
			SELECT @CPU_BUSY = @@CPU_BUSY, @IDLE = @@IDLE, @m = 1
			WAITFOR DELAY '000:00:01'

			INSERT INTO @CPUs (CPU)
			SELECT (@@CPU_BUSY - @CPU_BUSY)/((@@IDLE - @IDLE + @@CPU_BUSY - @CPU_BUSY) * @m) *100 --AS 'CPU Utilization'

			SET @rn = @rn + 1
		END

		SELECT @CPU = AVG(CPU) FROM @CPUs
	END

	IF @CPU < 60 RETURN

	BEGIN
		SET @LogMesg = 'System:(2) calling RecompileAll due to CPU average (10 seconds) = ' + CAST(@CPU as nvarchar(10)) + ' after update BETTRANS statistics'
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @LogMesg
		-- call recompile All
		EXEC dbo.DBA_RecompileAll

		WAITFOR DELAY '000:00:05.000'

		DELETE FROM @CPUs
		SET @rn = 1
		WHILE @rn <= 10
		BEGIN
			SELECT @CPU_BUSY = @@CPU_BUSY, @IDLE = @@IDLE, @m = 1
			WAITFOR DELAY '000:00:01'

			INSERT INTO @CPUs (CPU)
			SELECT (@@CPU_BUSY - @CPU_BUSY)/((@@IDLE - @IDLE + @@CPU_BUSY - @CPU_BUSY) * @m) *100 --AS 'CPU Utilization'

			SET @rn = @rn + 1
		END

		SELECT @CPU = AVG(CPU) FROM @CPUs
	END

	IF @CPU < 60 RETURN

	BEGIN
		SET @LogMesg = 'System:(3) calling Update Statistics due to CPU average (10 seconds) = ' + CAST(@CPU as nvarchar(10)) + ' after update Bettrans Statistics'
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @LogMesg
		-- run update stat
		EXEC sp_updatestats
	END

--	Declare @LogMsg varchar(200)
--	SET @LogMsg = 'System: Start RecompileAll and Update Statistics due to CPU average (last 2 minutes) = ' + CAST(@CPU as nvarchar(10))
--	EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @LogMsg

--	EXEC dbo.DBA_RecompileAll


/* -- get average of CPU last 2 minutes
	Declare @CPU int

    SELECT 
            @CPU = AVG(record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int')) --AS SQLProcessUtilization
    FROM (
            SELECT TOP 2 TIMESTAMP, CONVERT(XML, record) AS record 
            FROM sys.dm_os_ring_buffers 
            WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
            AND record LIKE '% %'
			ORDER BY TIMESTAMP DESC) AS x
*/
GO

GRANT VIEW DEFINITION ON [dbo].[Task_CPUCheck] TO [vnteam] AS [dbo]
GO


