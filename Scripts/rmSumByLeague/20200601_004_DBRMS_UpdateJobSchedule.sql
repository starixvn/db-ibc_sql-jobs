/*<info serverAlias="DBRMS-bodb_RMS"></info>*/
/*	
	Created: 20200601@Percy
	DB: DBRMS-bodb_RMS
	Task: New table rmSumByLeague/rmSumByBettype

	Step 4: Update job setting/schedule
*/

-- Job Setting
USE bodb_RMS
GO

INSERT INTO dbo.rmSettings (VName, VValue)
VALUES
	('rmCopyData', '2020-06-17'),
	('rmSumData', '2020-06-17')
GO

-- Job Schedule
USE [msdb]
GO

EXEC sp_update_schedule
	@schedule_id = 240, -- DB052
	@new_name = 'Every 30 minutes',
	@freq_type=4, 
	@freq_interval=1, 
	@freq_subday_type=8, 
	@freq_subday_interval=1, 
	@freq_relative_interval=0, 
	@freq_recurrence_factor=0, 
	@active_start_date=20200512, 
	@active_end_date=99991231, 
	@active_start_time=0, 
	@active_end_time=235959