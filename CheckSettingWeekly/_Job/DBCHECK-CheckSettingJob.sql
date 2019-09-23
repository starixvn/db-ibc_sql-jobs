/*
	Creator:	@Billy
	Job Name:	[vnDBA : Automation Check CustDB]
	Server:		DBDWCSS
	Revision:
		- 20180727@Billy:	Initiate on GIT - [Redmine: #98673]
		- 20180802@Billy:	Add clean up table Commission result step - [Redmine: #99249]
		- 20180906@Billy:	Add prepare Keno data - [Redmine: #101011]
*/

SET NOCOUNT ON;

USE msdb;
GO

BEGIN TRANSACTION;

DECLARE @ReturnCode		INT
	,	@jobId			BINARY(16)
	,	@steps			INT
	,	@loop			INT
	,	@stepname		NVARCHAR(128)
	,	@msg			NVARCHAR(MAX)
	;

SELECT	@ReturnCode		= 0;

-- Add category --
IF	NOT EXISTS (
		SELECT	ctg.name
		FROM	msdb.dbo.syscategories AS ctg WITH (NOLOCK)
		WHERE	ctg.name = N'Data Consistency'
			AND	ctg.category_class = 1
	)
BEGIN;
	EXECUTE	@ReturnCode	= msdb.dbo.sp_add_category
							@class	= N'JOB'
						,	@type	= N'LOCAL'
						,	@name	= N'Data Consistency'
						;
	
	IF	@@ERROR <> 0 OR	@ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'CATEGORY ADDED';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

-- Add job --
BEGIN;
	EXECUTE	@ReturnCode	= msdb.dbo.sp_add_job
							@job_name					= N'vnDBA : Automation Check CustDB'
						,	@enabled					= 1
						,	@notify_level_eventlog		= 0
						,	@notify_level_email			= 2
						,	@notify_level_netsend		= 0
						,	@notify_level_page			= 0
						,	@delete_level				= 0
						,	@description				= N'No description available.'
						,	@category_name				= N'Data Consistency'
						,	@owner_login_name			= N'sa'
						,	@notify_email_operator_name	= N'VNDBA'
						,	@job_id						= @jobId OUTPUT
						;

	IF	@@ERROR <> 0 OR @ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'JOB ADDED';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

-- Init job steps --
BEGIN;
	SELECT	@steps	= 7
		,	@loop	= 1
		;

	WHILE	@loop <= @steps
	BEGIN;
		SELECT	@stepname	= N'Step ' + CAST(@loop AS NVARCHAR);

		EXECUTE	@ReturnCode	= msdb.dbo.sp_add_jobstep
								@job_id						= @jobId
							,	@step_name					= @stepname
							,	@step_id					= @loop
							;
					
		IF	@@ERROR <> 0 OR @ReturnCode <> 0
			GOTO QuitWithRollback;

		SELECT	@loop = @loop + 1;
	END;

	SELECT	@msg = N'INITIATED ' + CAST(@steps AS NVARCHAR) + N' STEPS';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

-- Define job steps --
---- Step 1 ----
BEGIN;
	EXECUTE	@ReturnCode	= msdb.dbo.sp_update_jobstep
							@job_id						= @jobId
						,	@step_name					= N'Copy Backup'
						,	@step_id					= 1
						,	@cmdexec_success_code		= 0
						,	@on_success_action			= 3
						,	@on_success_step_id			= 0
						,	@on_fail_action				= 2
						,	@on_fail_step_id			= 0
						,	@retry_attempts				= 0
						,	@retry_interval				= 0
						,	@os_run_priority			= 0
						,	@subsystem					= N'CmdExec'
						,	@flags						= 0
						,	@proxy_name					= N'vnTaskProxy'
						,	@command					= N'
powershell.exe -ExecutionPolicy ByPass "M:\BackupForCheckCustDB\Script\CopyBackup.ps1 ''\\DBBACKUP\MidTerm\SB'' ''M:\BackupForCheckCustDB'' ''CustDB'' 1"
';

	IF	@@ERROR <> 0 OR @ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'STEP 1 ADDED';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

---- Step 2 ----
BEGIN;
	EXECUTE	@ReturnCode	= msdb.dbo.sp_update_jobstep
							@job_id						= @jobId
						,	@step_name					= N'Restore DB'
						,	@step_id					= 2
						,	@cmdexec_success_code		= 0
						,	@on_success_action			= 3
						,	@on_success_step_id			= 0
						,	@on_fail_action				= 2
						,	@on_fail_step_id			= 0
						,	@retry_attempts				= 0
						,	@retry_interval				= 0
						,	@os_run_priority			= 0
						,	@subsystem					= N'TSQL'
						,	@database_name				= N'StarixDB'
						,	@flags						= 0
						,	@command					= N'
DECLARE
  @backup NVARCHAR(MAX)
, @backup_diff NVARCHAR(MAX)
;

EXECUTE vnDBA_sp_Task_AutoRestore
  @server = ''DBCUST''
, @database = ''CustDB''
, @restore_name = ''CheckCustDB''
, @backup_path = @backup OUTPUT
, @backup_diff_path = @backup_diff OUTPUT
;

EXECUTE dbo.vnDBA_sp_Task_AutoRestore_Notification
  @to=''pontus@starixsoft.com;elodie.ho@starixsoft.com;winnie.vu@starixsoft.com;johnson.nguyen@starixsoft.com''
, @backup_path = @backup
, @backup_diff_path = @backup_diff
;
';

	IF	@@ERROR <> 0 OR @ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'STEP 2 ADDED';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

---- Step 3 ----
BEGIN;
	EXECUTE	@ReturnCode	= msdb.dbo.sp_update_jobstep
							@job_id						= @jobId
						,	@step_name					= N'Prepare CheckCustDB'
						,	@step_id					= 3
						,	@cmdexec_success_code		= 0
						,	@on_success_action			= 3
						,	@on_success_step_id			= 0
						,	@on_fail_action				= 2
						,	@on_fail_step_id			= 0
						,	@retry_attempts				= 0
						,	@retry_interval				= 0
						,	@os_run_priority			= 0
						,	@subsystem					= N'TSQL'
						,	@database_name				= N'CheckResultDB'
						,	@flags						= 0
						,	@command					= N'
EXECUTE dbo.vnDBA_sp_CheckSetting_PrepareCustDB;
EXECUTE dbo.DBA_PrepareKenoGameType;
';

	IF	@@ERROR <> 0 OR @ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'STEP 3 ADDED';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

---- Step 4 ----
BEGIN;
	EXECUTE	@ReturnCode	= msdb.dbo.sp_update_jobstep
							@job_id						= @jobId
						,	@step_name					= N'Select Supers'
						,	@step_id					= 4
						,	@cmdexec_success_code		= 0
						,	@on_success_action			= 3
						,	@on_success_step_id			= 0
						,	@on_fail_action				= 2
						,	@on_fail_step_id			= 0
						,	@retry_attempts				= 0
						,	@retry_interval				= 0
						,	@os_run_priority			= 0
						,	@subsystem					= N'TSQL'
						,	@database_name				= N'CheckResultDB'
						,	@flags						= 0
						,	@command					= N'
EXECUTE dbo.vnDBA_sp_CheckSetting_SelectSupers;
';

	IF	@@ERROR <> 0 OR @ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'STEP 4 ADDED';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

---- Step 5 ----
BEGIN;
	EXECUTE	@ReturnCode	= msdb.dbo.sp_update_jobstep
							@job_id						= @jobId
						,	@step_name					= N'Cleanup Result Table'
						,	@step_id					= 5
						,	@cmdexec_success_code		= 0
						,	@on_success_action			= 3
						,	@on_success_step_id			= 0
						,	@on_fail_action				= 2
						,	@on_fail_step_id			= 0
						,	@retry_attempts				= 0
						,	@retry_interval				= 0
						,	@os_run_priority			= 0
						,	@subsystem					= N'TSQL'
						,	@database_name				= N'CheckResultDB'
						,	@flags						= 0
						,	@command					= N'
EXECUTE dbo.vnDBA_sp_CheckSetting_ClearResult;
';

	IF	@@ERROR <> 0 OR @ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'STEP 5 ADDED';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

---- Step 6 ----
BEGIN;
	EXECUTE	@ReturnCode	= msdb.dbo.sp_update_jobstep
							@job_id						= @jobId
						,	@step_name					= N'Check CustDB ServiceBroker'
						,	@step_id					= 6
						,	@cmdexec_success_code		= 0
						,	@on_success_action			= 3
						,	@on_success_step_id			= 0
						,	@on_fail_action				= 2
						,	@on_fail_step_id			= 0
						,	@retry_attempts				= 0
						,	@retry_interval				= 0
						,	@os_run_priority			= 0
						,	@subsystem					= N'TSQL'
						,	@database_name				= N'CheckResultDB'
						,	@flags						= 0
						,	@command					= N'
EXECUTE dbo.vnDBA_sp_CheckSetting_Initiator;
';

	IF	@@ERROR <> 0 OR @ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'STEP 6 ADDED';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

---- Step 7 ----
BEGIN;
	EXECUTE	@ReturnCode	= msdb.dbo.sp_update_jobstep
							@job_id						= @jobId
						,	@step_name					= N'Check CustDB Notification'
						,	@step_id					= 7
						,	@cmdexec_success_code		= 0
						,	@on_success_action			= 1
						,	@on_success_step_id			= 0
						,	@on_fail_action				= 2
						,	@on_fail_step_id			= 0
						,	@retry_attempts				= 0
						,	@retry_interval				= 0
						,	@os_run_priority			= 0
						,	@subsystem					= N'TSQL'
						,	@database_name				= N'CheckResultDB'
						,	@flags						= 0
						,	@command					= N'
EXECUTE dbo.vnDBA_sp_CheckSetting_ResultNotification
	@to = ''pontus@starixsoft.com;it@starixsoft.com;elodie.ho@starixsoft.com;winnie.vu@starixsoft.com;johnson.nguyen@starixsoft.com'';
';

	IF	@@ERROR <> 0 OR @ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'STEP 7 ADDED';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

---- Job start at step ----
BEGIN;
	EXECUTE	@ReturnCode	= msdb.dbo.sp_update_job
							@job_id						= @jobId
						,	@start_step_id				= 1
						;

	IF	@@ERROR <> 0 OR @ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'UPDATED START STEP';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

-- Job schedule --
BEGIN;
	EXECUTE	@ReturnCode	= msdb.dbo.sp_add_jobschedule
							@job_id						= @jobId
						,	@name						= N'CheckCustDB'
						,	@enabled					= 1
						,	@freq_type					= 8
						,	@freq_interval				= 9
						,	@freq_subday_type			= 1
						,	@freq_subday_interval		= 0
						,	@freq_relative_interval		= 0
						,	@freq_recurrence_factor		= 1
						,	@active_start_date			= 20170401
						,	@active_end_date			= 99991231
						,	@active_start_time			= 133000
						,	@active_end_time			= 235959
						;

	IF	@@ERROR <> 0 OR @ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'ADDED JOB SCHEDULE';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

-- Job server --
BEGIN;
	EXECUTE	@ReturnCode	= msdb.dbo.sp_add_jobserver
							@job_id						= @jobId
						,	@server_name				= N'(local)'
						;

	IF	@@ERROR <> 0 OR @ReturnCode <> 0
		GOTO QuitWithRollback;

	SELECT	@msg = N'JOB SERVER ADDED';
	RAISERROR(@msg, 0, 0) WITH NOWAIT;
END;

-- All success -- Commit changes --
COMMIT TRANSACTION;
SELECT	@msg = N'*** JOB CREATED SUCCESSFULLY ***';
RAISERROR(@msg, 0, 0) WITH NOWAIT;
GOTO EndSave;

-- Jump point -- Failure --
QuitWithRollback:
IF	@@TRANCOUNT > 0
	ROLLBACK TRANSACTION;

-- Jump point -- Finish --
EndSave:
GO