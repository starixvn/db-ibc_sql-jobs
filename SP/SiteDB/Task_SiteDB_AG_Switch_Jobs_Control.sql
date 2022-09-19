/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Task_SiteDB_AG_Switch_Jobs_Control
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
	DECLARE @__startTime DATETIME
	SET @__startTime = GETDATE()
	
	WHILE DATEDIFF(MINUTE, @__startTime, GETDATE()) < 10
	BEGIN
		EXEC dbo.Task_SiteDB_AG_Switch_Jobs
		WAITFOR DELAY '00:00:00:010'
	END

END
GO