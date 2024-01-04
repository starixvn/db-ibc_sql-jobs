use bodb02
go

---update site dbgroupid on bet
--can run many windows to save time
--active
exec dbo.DBA_Task_DR_Reset_SiteDBGroupId @NewSiteDBGroupId = 0
	, @TableName = 'bettrans'
exec dbo.DBA_Task_DR_Reset_SiteDBGroupId @NewSiteDBGroupId = 0
	, @TableName = 'bettransG'
exec dbo.DBA_Task_DR_Reset_SiteDBGroupId @NewSiteDBGroupId = 0
	, @TableName = 'bettransM'
exec dbo.DBA_Task_DR_Reset_SiteDBGroupId @NewSiteDBGroupId = 0
	, @TableName = 'bettransLC'
exec dbo.DBA_Task_DR_Reset_SiteDBGroupId @NewSiteDBGroupId = 0
	, @TableName = 'bettransRnG'
exec dbo.DBA_Task_DR_Reset_SiteDBGroupId @NewSiteDBGroupId = 0
	, @TableName = 'translog'

--14
exec dbo.DBA_Task_DR_Reset_SiteDBGroupId @NewSiteDBGroupId = 0
	, @TableName = 'bettrans14'
exec dbo.DBA_Task_DR_Reset_SiteDBGroupId @NewSiteDBGroupId = 0
	, @TableName = 'bettransG14'
exec dbo.DBA_Task_DR_Reset_SiteDBGroupId @NewSiteDBGroupId = 0
	, @TableName = 'bettransM14'
exec dbo.DBA_Task_DR_Reset_SiteDBGroupId @NewSiteDBGroupId = 0
	, @TableName = 'bettransLC14'
exec dbo.DBA_Task_DR_Reset_SiteDBGroupId @NewSiteDBGroupId = 0
	, @TableName = 'bettransRnG14'
exec dbo.DBA_Task_DR_Reset_SiteDBGroupId @NewSiteDBGroupId = 0
	, @TableName = 'translog14'