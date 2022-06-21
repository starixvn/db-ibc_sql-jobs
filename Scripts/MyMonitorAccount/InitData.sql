/*<info serverAlias="DBAGE-bodb02" executers="" viewers="" isFunction="0"></info>*/

USE [bodb02]
GO

INSERT INTO dbo.WLMonitored_Service_GlobalSetting (ServiceName, SettingName, SettingValue)
VALUES ('WLMonitoredAccount', 'LastId',0)
INSERT INTO dbo.WLMonitored_Service_GlobalSetting (ServiceName, SettingName, SettingValue)
VALUES ('UAT-WLMonitoredAccount', 'LastId',0)
GO

INSERT INTO dbo.WLMonitored_Service_GlobalSetting (ServiceName, SettingName, SettingValue)
VALUES ('WLMonitoredAccount', 'SuperUUS','')

INSERT INTO dbo.WLMonitored_Service_GlobalSetting (ServiceName, SettingName, SettingValue)
VALUES ('Dep_WLMonitoredAccount', 'SuperUUS','')

GO
INSERT INTO dbo.WLMonitored_Service_GlobalSetting (ServiceName, SettingName, SettingValue)
VALUES ('WLMonitoredAccount','LastCheckTime', CONVERT(varchar(50), GETDATE(), 121))
	, ('Dep_WLMonitoredAccount', 'LastCheckTime', CONVERT(varchar(50), GETDATE(), 121))

INSERT INTO dbo.WLMonitored_Service_GlobalSetting (ServiceName, SettingName, SettingValue)
VALUES ('UAT-WLMonitoredAccount','LastCheckTime', CONVERT(varchar(50), GETDATE(), 121))
	, ('UAT-Dep_WLMonitoredAccount', 'LastCheckTime', CONVERT(varchar(50), GETDATE(), 121))
GO
INSERT INTO dbo.WLMonitored_Service_GlobalSetting (ServiceName, SettingName, SettingValue)
VALUES ('WLMonitoredAccount','LastScanSettingDate', CONVERT(varchar(50), GETDATE(), 121))
	, ('Dep_WLMonitoredAccount', 'LastScanSettingDate', CONVERT(varchar(50), GETDATE(), 121))

INSERT INTO dbo.WLMonitored_Service_GlobalSetting (ServiceName, SettingName, SettingValue)
VALUES ('UAT-WLMonitoredAccount','LastScanSettingDate', CONVERT(varchar(50), GETDATE(), 121))
	, ('UAT-Dep_WLMonitoredAccount', 'LastScanSettingDate', CONVERT(varchar(50), GETDATE(), 121))
GO

INSERT INTO dbo.WLMonitored_Service_GlobalSetting (ServiceName, SettingName, SettingValue)
VALUES 
	('WLMonitoredAccount','AccumulateWinLossJob', 1)
	, ('WLMonitoredAccount', 'ChangeAccumulatedWinLossJob', 1)
	, ('WLMonitoredAccount', 'ChangeThresholdWinLossJob', 1)
	,('Dep_WLMonitoredAccount', 'ChangeAccumulatedWinLossJob', 1)
	, ('Dep_WLMonitoredAccount', 'ChangeThresholdWinLossJob', 1)


INSERT INTO dbo.WLMonitored_Service_GlobalSetting (ServiceName, SettingName, SettingValue)
VALUES 
	('UAT-WLMonitoredAccount','AccumulateWinLossJob', 1)
	, ('UAT-WLMonitoredAccount', 'ChangeAccumulatedWinLossJob', 1)
	, ('UAT-WLMonitoredAccount', 'ChangeThresholdWinLossJob', 1)
	,('UAT-Dep_WLMonitoredAccount', 'ChangeAccumulatedWinLossJob', 1)
	, ('UAT-Dep_WLMonitoredAccount', 'ChangeThresholdWinLossJob', 1)




	select *
	from WLMonitored_Service_GlobalSetting
	order by ServiceName

