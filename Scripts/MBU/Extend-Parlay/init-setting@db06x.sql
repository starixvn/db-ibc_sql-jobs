/*<info serverAlias="DBACC-bodb02"></info>*/

--run this part on db061
IF NOT EXISTS (
	SELECT TOP 1 1 
	FROM dbo.SystemSettings WITH (NOLOCK) 
	WHERE VName = 'Task_Arc_Flag_Name'
)
BEGIN
	INSERT INTO dbo.SystemSettings(VName, VValue)
	VALUES('Task_Arc_Flag_Name', 'Task_Archive_Flag_61')
END
ELSE
BEGIN
	PRINT 'Error!!!'
END

GO
--run this part on db06
IF NOT EXISTS (
	SELECT TOP 1 1 
	FROM dbo.SystemSettings WITH (NOLOCK) 
	WHERE VName = 'Task_Arc_Flag_Name'
)
BEGIN
	INSERT INTO dbo.SystemSettings(VName, VValue)
	VALUES('Task_Arc_Flag_Name', 'Task_Archive_Flag_06')
END
ELSE
BEGIN
	PRINT 'Error!!!'
END

GO
