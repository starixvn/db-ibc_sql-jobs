/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Task_SiteDB_AG_Switch_Jobs
AS
/*
	Created@Patrick
	Task: AG - Switch jobs
	DB: DBSIG.bodb02
	Revisions:
		- 20220915@Patrick:	Init [Redmine: #176760]
		
*/
BEGIN
	SET NOCOUNT ON
	--hardcode for bodb02
	DECLARE @__currentValue BIT = 0
		, @__dbName VARCHAR(128) = 'bodb02'

	SET @__currentValue = sys.fn_hadr_is_primary_replica(@__dbName)

	--//start check and enable/disable jobs
	--get list jobs
	DECLARE @__jobList TABLE(rowId INT IDENTITY(1,1) PRIMARY KEY, jobName VARCHAR(128))
	DECLARE @__rowId INT = 1, @__jobName VARCHAR(128)
		, @__hasError BIT = 0, @__errorMessage VARCHAR(4000) = ''

	INSERT INTO @__jobList(jobName)
	SELECT JobName
	FROM dbo.Task_DBA_AG_Jobs_List WITH(NOLOCK)
	WHERE Ignore = 0
	ORDER BY PriorityLevel

	WHILE EXISTS (
		SELECT TOP 1 1 FROM @__jobList WHERE rowId = @__rowId
	)
	BEGIN
		SELECT @__jobName = jobName 
		FROM @__jobList WHERE rowId = @__rowId
		
		--check exist job and then enable or not
		IF EXISTS (
			SELECT TOP 1 1 FROM msdb.dbo.sysjobs WITH(NOLOCK)
			WHERE name = @__jobName AND enabled <> @__currentValue
		)
		BEGIN
			BEGIN TRY
				EXEC msdb.dbo.sp_update_job @job_name = @__jobName, @enabled = @__currentValue 
			END TRY
			BEGIN CATCH
				SELECT @__hasError = 1, @__errorMessage = CONCAT(@__errorMessage, ERROR_MESSAGE())
			END CATCH
		END
		
		SET @__rowId += 1
	END
	
	--//having error then throw out error message
	IF @__hasError = 1
	BEGIN
		RAISERROR(@__errorMessage, 16, 1)
		RETURN
	END
END
