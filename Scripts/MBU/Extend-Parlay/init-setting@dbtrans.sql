/*<info serverAlias="DBTXN-bodb02"></info>*/
IF NOT EXISTS (
	SELECT TOP 1 1 
	FROM dbo.SystemSettings WITH (NOLOCK) 
	WHERE VName = 'Task_Archive_Flag_06'
)
BEGIN
	INSERT INTO dbo.SystemSettings(VName, VValue)
	VALUES('Task_Archive_Flag_06', '0')
END

IF NOT EXISTS (
	SELECT TOP 1 1 
	FROM dbo.SystemSettings WITH (NOLOCK) 
	WHERE VName = 'Task_Archive_Flag_61'
)
BEGIN
	INSERT INTO dbo.SystemSettings(VName, VValue)
	VALUES('Task_Archive_Flag_61', '0')
END

