/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Task_SiteDB_AG_Switch_Monitor_Jobs
AS
/*
	Created@Patrick
	Task: AG - Switch job monitor
	DB: DBSIG.bodb02
	Revisions:
		- 20220915@Patrick:	Init [Redmine: #176760]
		
*/
BEGIN
	SET NOCOUNT ON
	IF EXISTS (
		SELECT TOP 1 1
		FROM msdb.dbo.sysjobs j WITH(NOLOCK)
			LEFT JOIN dbo.Task_DBA_AG_Jobs_List l WITH(NOLOCK) ON j.name = l.JobName
		WHERE l.JobName IS NULL
	)
	BEGIN
		RAISERROR('Missing data in Task_DBA_AG_Jobs_List table. Please take a look.', 16, 1)
		RETURN
	END

	--only run at primary
	IF sys.fn_hadr_is_primary_replica('bodb02') = 1
	BEGIN
		--remove redandunt data in Task_DBA_AG_Jobs_List
		DELETE l
		FROM dbo.Task_DBA_AG_Jobs_List l WITH(ROWLOCK)
		WHERE JobName NOT IN (SELECT name FROM msdb.dbo.sysjobs j WITH(NOLOCK))

	END
END