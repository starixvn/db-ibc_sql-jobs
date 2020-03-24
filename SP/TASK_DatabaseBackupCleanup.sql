ALTER procedure [dbo].[TASK_DatabaseBackupCleanup]
	--@Path nvarchar(256),
	@Extention varchar(10) = 'bak',
	@Retention_months tinyint = 1
AS
/*
	Creator: Francis
	Created date: 2015/07/27
	Task: Cleanup old database backup
	DB: msdb
	Param Explanation:
	Input
		- @DatabaseName: Name of the database that is backed up
		- @Type: Backup type:
			+ FULL: Full backup
			+ DF: Differential backup
			+ LOG: Transaction Log backup
	Revision:
		- 20200324@Patrick: Add more server [RedmineId: #130961]
*/
begin
	set nocount on;

	declare @DeleteDate varchar(20)
	
	set @DeleteDate = convert(varchar,DATEADD(day,1,DATEADD(month, -@Retention_months, CURRENT_TIMESTAMP)),112)

	--delete backup media
	--execute master.dbo.xp_delete_file 0, @path, @extention, @DeleteDate, 1

	--delete backup history
	exec msdb.dbo.sp_delete_backuphistory @DeleteDate

	print 'Complete old backup cleaning before ' + @DeleteDate
end
GO
/*<info serverAlias="DBEXT-bodb02,DBAGE-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/

