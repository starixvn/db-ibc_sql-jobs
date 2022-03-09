/*<info serverAlias="DBSSIS-SSISDB"></info>*/
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBSSIS.SSISDB
*/
use master;
go

-- add SSIS Folder
Declare @folder_id bigint
EXEC [SSISDB].[catalog].[create_folder] @folder_name=N'Thursday-routine', @folder_id=@folder_id OUTPUT
Select @folder_id
EXEC [SSISDB].[catalog].[set_folder_description] @folder_name=N'Thursday-routine', @folder_description=N'SSIS - Thursday-routine'

-- add ENV variables
GO
EXEC [SSISDB].[catalog].[create_environment] @environment_name=N'PROD', @environment_description=N'SSIS - PROD Variables', @folder_name=N'Thursday-routine'

GO

DECLARE @var sql_variant = N'PROD'
EXEC [SSISDB].[catalog].[create_environment_variable] @variable_name=N'Environment', @sensitive=False, @description=N'', @environment_name=N'PROD', @folder_name=N'Thursday-routine', @value=@var, @data_type=N'String'
GO
DECLARE @var sql_variant = N'SSISDB'
EXEC [SSISDB].[catalog].[create_environment_variable] @variable_name=N'HostDB', @sensitive=False, @description=N'', @environment_name=N'PROD', @folder_name=N'Thursday-routine', @value=@var, @data_type=N'String'
GO
DECLARE @var sql_variant = N'DBDW2'
EXEC [SSISDB].[catalog].[create_environment_variable] @variable_name=N'HostServer', @sensitive=False, @description=N'', @environment_name=N'PROD', @folder_name=N'Thursday-routine', @value=@var, @data_type=N'String'
GO
DECLARE @var sql_variant = N'G:\\SSISProject\\Output'
EXEC [SSISDB].[catalog].[create_environment_variable] @variable_name=N'OutputDirectory', @sensitive=False, @description=N'', @environment_name=N'PROD', @folder_name=N'Thursday-routine', @value=@var, @data_type=N'String'
GO
DECLARE @var sql_variant = N'sqllink'
EXEC [SSISDB].[catalog].[create_environment_variable] @variable_name=N'UserID', @sensitive=False, @description=N'', @environment_name=N'PROD', @folder_name=N'Thursday-routine', @value=@var, @data_type=N'String'
GO
DECLARE @var sql_variant = N'##########'
EXEC [SSISDB].[catalog].[create_environment_variable] @variable_name=N'UserSecret', @sensitive=False, @description=N'', @environment_name=N'PROD', @folder_name=N'Thursday-routine', @value=@var, @data_type=N'String'
GO
-- deploy Project by isac file

-- add Proj-ENV references
Declare @reference_id bigint
EXEC [SSISDB].[catalog].[create_environment_reference] @environment_name=N'PROD', @reference_id=@reference_id OUTPUT, @project_name=N'DBA_SSIS_Automation_ObjectMapping', @folder_name=N'Thursday-routine', @reference_type=R
Select @reference_id

GO
EXEC [SSISDB].[catalog].[set_object_parameter_value] @object_type=20, @parameter_name=N'Environment', @object_name=N'DBA_SSIS_Automation_ObjectMapping', @folder_name=N'Thursday-routine', @project_name=N'DBA_SSIS_Automation_ObjectMapping', @value_type=R, @parameter_value=N'Environment'
GO
EXEC [SSISDB].[catalog].[set_object_parameter_value] @object_type=20, @parameter_name=N'HostDB', @object_name=N'DBA_SSIS_Automation_ObjectMapping', @folder_name=N'Thursday-routine', @project_name=N'DBA_SSIS_Automation_ObjectMapping', @value_type=R, @parameter_value=N'HostDB'
GO
EXEC [SSISDB].[catalog].[set_object_parameter_value] @object_type=20, @parameter_name=N'HostServer', @object_name=N'DBA_SSIS_Automation_ObjectMapping', @folder_name=N'Thursday-routine', @project_name=N'DBA_SSIS_Automation_ObjectMapping', @value_type=R, @parameter_value=N'HostServer'
GO
EXEC [SSISDB].[catalog].[set_object_parameter_value] @object_type=20, @parameter_name=N'OutputDirectory', @object_name=N'DBA_SSIS_Automation_ObjectMapping', @folder_name=N'Thursday-routine', @project_name=N'DBA_SSIS_Automation_ObjectMapping', @value_type=R, @parameter_value=N'OutputDirectory'
GO
EXEC [SSISDB].[catalog].[set_object_parameter_value] @object_type=20, @parameter_name=N'UserID', @object_name=N'DBA_SSIS_Automation_ObjectMapping', @folder_name=N'Thursday-routine', @project_name=N'DBA_SSIS_Automation_ObjectMapping', @value_type=R, @parameter_value=N'UserID'
GO
EXEC [SSISDB].[catalog].[set_object_parameter_value] @object_type=20, @parameter_name=N'UserSecret', @object_name=N'DBA_SSIS_Automation_ObjectMapping', @folder_name=N'Thursday-routine', @project_name=N'DBA_SSIS_Automation_ObjectMapping', @value_type=R, @parameter_value=N'UserSecret'
GO

GO




