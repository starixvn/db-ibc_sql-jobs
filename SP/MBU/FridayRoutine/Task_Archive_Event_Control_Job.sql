/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE dbo.Task_Archive_Event_Control_Job
	
AS
/*
	Created: 20220804@Patrick
	Task: Task_Archive_Event_Control
	DB: DBTXN/bodb02
	Revisions:   
		- 20220804@Patrick: Support scale-out for deposit site Redmine: [#175602]
*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @archiveDate TABLE (rid int PRIMARY KEY IDENTITY(1,1), winlostdate smalldatetime)
	INSERT INTO @archiveDate (winlostdate)
	SELECT winlostdate FROM dbo.task_archivedate
	ORDER BY 1

	Declare @wldate smalldatetime, @__aliasServer VARCHAR(128)
	DECLARE @__startStep VARCHAR(50) = CONVERT(VARCHAR(10), GETDATE(), 121)

	--turn on flag wait for delete event
	EXEC dbo.ExecRep_10 @FunctionName = 'ScaleOut', @AliasServer = @__aliasServer OUTPUT
	IF @__aliasServer = 'DBSite' --only run that command at DBSite server
	BEGIN
		EXEC DBCTG.bodb02.dbo.Task_UpdSystemSetting @VName = 'Fri-routine-s', @VValue = @__startStep
		EXEC DBCTG.bodb02.dbo.Task_UpdSystemSetting @VName = 'Fri-routine-f', @VValue = '1', @IsOverride = 0
	END

	SELECT @wldate = MAX(winlostdate) FROM @archiveDate;
	EXECUTE dbo.Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = 'MarkedTransaction';
	WAITFOR DELAY '00:00:30';

	EXEC Task_Archive_Bet_Control

	--turn on flag wait for delete event
	IF @__aliasServer = 'DBSite' --only run that command at DBSite server
	BEGIN
		EXEC DBCTG.bodb02.dbo.Task_UpdSystemSetting @VName = 'Fri-routine-f', @VValue = '-1', @IsOverride = 0
	END

	--only run at central DB
	IF @__aliasServer = 'DBCTG'
	BEGIN
		--check flag to make sure DBSite already done above steps
		DECLARE @__start DATETIME
		SET @__start = GETDATE()
		WHILE EXISTS (
			SELECT TOP 1 1 
			FROM dbo.SystemSettings WHERE VName = 'Fri-routine-f' AND VValue <> '0'
		) OR EXISTS (
			SELECT TOP 1 1 
			FROM dbo.SystemSettings 
			WHERE VName = 'Fri-routine-s' 
				AND CAST(VValue AS DATE) < DATEADD(DAY, -1, CAST(@__start AS DATE)) --not in less than yesterday ==> job at DBSite not start yet
		)
		BEGIN
			WAITFOR DELAY '00:01:00:000' --waitfor Friday delete event 14...
			IF DATEDIFF(MINUTE, @__start, GETDATE()) > 120
			BEGIN
				--Send notification to dba
				DECLARE @__doing VARCHAR(300)
				SET @__doing = 'Friday routine - hey guys, Friday routine at DBSite not start yet or running long time at step 2. Please check!!!'
				EXEC dbo.DBA_Task_Send_SimpleNotifyMessageToDBA
					@SubjectName = 'Friday routine - Notification',
					@MessageName = @__doing

			END
		END

		--delete event ==> only perform from central
		SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 1   EXEC DB02.bodb02.dbo.Task_Archive_Event @wldate, @Action = 'delete'
		WAITFOR DELAY '00:00:05'
		SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 2   EXEC DB02.bodb02.dbo.Task_Archive_Event @wldate, @Action = 'delete'
		WAITFOR DELAY '00:01:05'
		SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 3   EXEC DB02.bodb02.dbo.Task_Archive_Event @wldate, @Action = 'delete'
		WAITFOR DELAY '00:00:05'
		SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 4   EXEC DB02.bodb02.dbo.Task_Archive_Event @wldate, @Action = 'delete'
		WAITFOR DELAY '00:01:05'
		SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 5   EXEC DB02.bodb02.dbo.Task_Archive_Event @wldate, @Action = 'delete'
		WAITFOR DELAY '00:00:05'
		SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 6   EXEC DB02.bodb02.dbo.Task_Archive_Event @wldate, @Action = 'delete'
		WAITFOR DELAY '00:01:05'
		SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 7   EXEC DB02.bodb02.dbo.Task_Archive_Event @wldate, @Action = 'delete'
	END

	WAITFOR DELAY '00:01:10'

	SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 1
	EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = 'betParlayResult'
	WAITFOR DELAY '00:00:30'
	EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = 'betParlayDetail'
	WAITFOR DELAY '00:01:00'

	SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 2
	EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = 'betParlayResult'
	WAITFOR DELAY '00:00:30'
	EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = 'betParlayDetail'
	WAITFOR DELAY '00:01:00'

	SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 3
	EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = 'betParlayResult'
	WAITFOR DELAY '00:00:30'
	EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = 'betParlayDetail'
	WAITFOR DELAY '00:01:00'

	SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 4
	EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = 'betParlayResult'
	WAITFOR DELAY '00:00:30'
	EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = 'betParlayDetail'
	WAITFOR DELAY '00:01:00'

	SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 5
	EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = 'betParlayResult'
	WAITFOR DELAY '00:00:30'
	EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = 'betParlayDetail'
	WAITFOR DELAY '00:01:00'

	SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 6
	EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = 'betParlayResult'
	WAITFOR DELAY '00:00:30'
	EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = 'betParlayDetail'
	WAITFOR DELAY '00:01:00'

	SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = 7
	EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = 'betParlayResult'
	WAITFOR DELAY '00:00:30'
	EXEC Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = 'betParlayDetail'

	WAITFOR DELAY '00:01:30'

	SELECT @wldate = MAX(winlostdate) FROM @archiveDate;
	EXECUTE dbo.Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = 'Task_bettrans14_IP2Country'
	WAITFOR DELAY '00:00:30';
	EXECUTE dbo.Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = 'Task_bettransRNG14_IP2Country'
	WAITFOR DELAY '00:00:30';
	EXECUTE dbo.Task_Archive_Bet @winlostdate = @wldate, @DeletedTarget = 'Task_bettransLC14_IP2Country'
	WAITFOR DELAY '00:00:30';

	--- delete old data for NG2
	SELECT @wldate = MAX(winlostdate)
	FROM @archiveDate 

	DELETE b 
	FROM dbo.bettrans_Staging b 
		INNER JOIN SettlementNG2_Message m WITH(NOLOCK) ON b.SeqId = m.SeqID
	WHERE
		m.EventDate <= @wldate
	WAITFOR DELAY '00:01:20'

	DELETE FROM SettlementNG2_Message
	WHERE EventDate <= @wldate

	WAITFOR DELAY '00:01:30'
END
GO
