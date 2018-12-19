/*
	Created by: 20181212@Helen
	Task: https://nexdev.net/issues/70177
	DB: DBTP/bodb_Consistency
*/
USE bodb_Consistency
GO
-- Remove redundant data for Pocker Game
DELETE DBA_JobActivity WHERE jobid in (21,22) and ScheduleId in (11,10) 