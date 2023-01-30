/*<info serverAlias="DBTP-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Task_BalanceUp_Monitor_Pull_MBUSettings
/*
    Created by: 20220602@Patrick
    Task: Task_BalanceUp_Monitor_Pull_MBUSettings
    DB: DBTP/BODB02 

	Revisions:
		- 20220602@Patrick: Revise BalanceUp background to support 247 [Redmine:#173554]
*/
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @__serverName varchar(200), @__startPull datetime2
		, @__lasttime datetime2, @__batchSize int
		, @__defaultMinDate datetime2, @__lastId int

	SELECT @__startPull = dateadd(minute, -1, sysdatetime()), @__batchSize = 10
		, @__defaultMinDate = dateadd(day, -3, sysdatetime())

	BEGIN --dbtp
		SELECT @__serverName = 'DBTP', @__lasttime = null, @__lastId = 0
		SELECT @__lasttime = max(CreatedDateTime), @__lastId = max(Id) 
		FROM dbo.MBUSettingsMonitor WITH(NOLOCK) WHERE serverName = @__serverName

		IF @__lasttime is null
			SELECT @__lasttime = @__defaultMinDate, @__lastId = 0

		WHILE @__lasttime <= @__startPull
		BEGIN
			INSERT INTO dbo.MBUSettingsMonitor([Id], [VName], [VValue], [CreatedDateTime], [ActionType], [ServerName], [RecordTime])
			SELECT [Id], [VName], [VValue], [CreatedDateTime], [ActionType], @__serverName, sysdatetime()
			FROM dbo.MBUSettingsHistory WITH(NOLOCK)
			WHERE CreatedDateTime >= @__lasttime AND CreatedDateTime <= @__startPull AND Id > @__lastId
			ORDER BY CreatedDateTime

			SET @__lasttime = dateadd(minute, @__batchSize, @__lasttime)
			WAITFOR DELAY '00:00:00:100' -- pull MBUSettingsHistory - DBTP

		END
	END

	BEGIN --DB061
		SELECT @__serverName = 'DB061', @__lasttime = null, @__lastId = 0
		SELECT @__lasttime = max(CreatedDateTime), @__lastId = max(Id) 
		FROM dbo.MBUSettingsMonitor WITH(NOLOCK) WHERE serverName = @__serverName

		IF @__lasttime is null
			SELECT @__lasttime = @__defaultMinDate, @__lastId = 0

		WHILE @__lasttime <= @__startPull
		BEGIN
			INSERT INTO dbo.MBUSettingsMonitor([Id], [VName], [VValue], [CreatedDateTime], [ActionType], [ServerName], [RecordTime])
			SELECT [Id], [VName], [VValue], [CreatedDateTime], [ActionType], @__serverName, sysdatetime()
			FROM DB061.bodb02.dbo.MBUSettingsHistory WITH(NOLOCK)
			WHERE CreatedDateTime >= @__lasttime AND CreatedDateTime <= @__startPull AND Id > @__lastId
			ORDER BY CreatedDateTime

			SET @__lasttime = dateadd(minute, @__batchSize, @__lasttime)
			WAITFOR DELAY '00:00:00:100' -- pull MBUSettingsHistory - DB061

		END
	END

	BEGIN --DB062
		SELECT @__serverName = 'DB062', @__lasttime = null, @__lastId = 0
		SELECT @__lasttime = max(CreatedDateTime), @__lastId = max(Id) 
		FROM dbo.MBUSettingsMonitor WITH(NOLOCK) WHERE serverName = @__serverName

		IF @__lasttime is null
			SELECT @__lasttime = @__defaultMinDate, @__lastId = 0

		WHILE @__lasttime <= @__startPull
		BEGIN
			INSERT INTO dbo.MBUSettingsMonitor([Id], [VName], [VValue], [CreatedDateTime], [ActionType], [ServerName], [RecordTime])
			SELECT [Id], [VName], [VValue], [CreatedDateTime], [ActionType], @__serverName, sysdatetime()
			FROM DB062.bodb02.dbo.MBUSettingsHistory WITH(NOLOCK)
			WHERE CreatedDateTime >= @__lasttime AND CreatedDateTime <= @__startPull AND Id > @__lastId
			ORDER BY CreatedDateTime

			SET @__lasttime = dateadd(minute, @__batchSize, @__lasttime)
			WAITFOR DELAY '00:00:00:100' -- pull MBUSettingsHistory - DB062

		END
	END

	BEGIN --DB053
		SELECT @__serverName = 'DB053', @__lasttime = null, @__lastId = 0
		SELECT @__lasttime = max(CreatedDateTime), @__lastId = max(Id) 
		FROM dbo.MBUSettingsMonitor WITH(NOLOCK) WHERE serverName = @__serverName

		IF @__lasttime is null
			SELECT @__lasttime = @__defaultMinDate, @__lastId = 0

		WHILE @__lasttime <= @__startPull
		BEGIN
			INSERT INTO dbo.MBUSettingsMonitor([Id], [VName], [VValue], [CreatedDateTime], [ActionType], [ServerName], [RecordTime])
			SELECT [Id], [VName], [VValue], [CreatedDateTime], [ActionType], @__serverName, sysdatetime()
			FROM DB053.bodb02.dbo.MBUSettingsHistory WITH(NOLOCK)
			WHERE CreatedDateTime >= @__lasttime AND CreatedDateTime <= @__startPull AND Id > @__lastId
			ORDER BY CreatedDateTime

			SET @__lasttime = dateadd(minute, @__batchSize, @__lasttime)
			WAITFOR DELAY '00:00:00:100' -- pull MBUSettingsHistory - DB053

		END
	END

	BEGIN --DB052
		SELECT @__serverName = 'DB052', @__lasttime = null, @__lastId = 0
		SELECT @__lasttime = max(CreatedDateTime), @__lastId = max(Id) 
		FROM dbo.MBUSettingsMonitor WITH(NOLOCK) WHERE serverName = @__serverName

		IF @__lasttime is null
			SELECT @__lasttime = @__defaultMinDate, @__lastId = 0

		WHILE @__lasttime <= @__startPull
		BEGIN
			INSERT INTO dbo.MBUSettingsMonitor([Id], [VName], [VValue], [CreatedDateTime], [ActionType], [ServerName], [RecordTime])
			SELECT [Id], [VName], [VValue], [CreatedDateTime], [ActionType], @__serverName, sysdatetime()
			FROM DB052.bodb02.dbo.MBUSettingsHistory WITH(NOLOCK)
			WHERE CreatedDateTime >= @__lasttime AND CreatedDateTime <= @__startPull AND Id > @__lastId
			ORDER BY CreatedDateTime

			SET @__lasttime = dateadd(minute, @__batchSize, @__lasttime)
			WAITFOR DELAY '00:00:00:100' -- pull MBUSettingsHistory - DB052

		END
	END

	BEGIN --DB05
		SELECT @__serverName = 'DB05', @__lasttime = null, @__lastId = 0
		SELECT @__lasttime = max(CreatedDateTime), @__lastId = max(Id) 
		FROM dbo.MBUSettingsMonitor WITH(NOLOCK) WHERE serverName = @__serverName

		IF @__lasttime is null
			SELECT @__lasttime = @__defaultMinDate, @__lastId = 0

		WHILE @__lasttime <= @__startPull
		BEGIN
			INSERT INTO dbo.MBUSettingsMonitor([Id], [VName], [VValue], [CreatedDateTime], [ActionType], [ServerName], [RecordTime])
			SELECT [Id], [VName], [VValue], [CreatedDateTime], [ActionType], @__serverName, sysdatetime()
			FROM DB05.bodb02.dbo.MBUSettingsHistory WITH(NOLOCK)
			WHERE CreatedDateTime >= @__lasttime AND CreatedDateTime <= @__startPull AND Id > @__lastId
			ORDER BY CreatedDateTime

			SET @__lasttime = dateadd(minute, @__batchSize, @__lasttime)
			WAITFOR DELAY '00:00:00:100' -- pull MBUSettingsHistory - DB05

		END
	END

	BEGIN --DB05BK1
		SELECT @__serverName = 'DB05BK1', @__lasttime = null, @__lastId = 0
		SELECT @__lasttime = max(CreatedDateTime), @__lastId = max(Id) 
		FROM dbo.MBUSettingsMonitor WITH(NOLOCK) WHERE serverName = @__serverName

		IF @__lasttime is null
			SELECT @__lasttime = @__defaultMinDate, @__lastId = 0

		WHILE @__lasttime <= @__startPull
		BEGIN
			INSERT INTO dbo.MBUSettingsMonitor([Id], [VName], [VValue], [CreatedDateTime], [ActionType], [ServerName], [RecordTime])
			SELECT [Id], [VName], [VValue], [CreatedDateTime], [ActionType], @__serverName, sysdatetime()
			FROM DB05BK1.bodb02.dbo.MBUSettingsHistory WITH(NOLOCK)
			WHERE CreatedDateTime >= @__lasttime AND CreatedDateTime <= @__startPull AND Id > @__lastId
			ORDER BY CreatedDateTime

			SET @__lasttime = dateadd(minute, @__batchSize, @__lasttime)
			WAITFOR DELAY '00:00:00:100' -- pull MBUSettingsHistory - DB05BK1

		END
	END
END