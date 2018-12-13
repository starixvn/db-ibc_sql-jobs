/*
	Created by: 20181212@Helen
	Task: https://nexdev.net/issues/70177
	DB: DBTP/bodb_Consistency
*/
-- Remove redundant data for Pocker Game
USE bodb_Consistency
GO
DELETE DBA_JobActivity WHERE jobid >=12 and jobid<= 20 AND ScheduleId <= 11
GO