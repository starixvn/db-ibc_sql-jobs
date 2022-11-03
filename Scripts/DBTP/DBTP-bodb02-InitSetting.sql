/*<info serverAlias="DBTP-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
    Created: 20221024@July
	Task: Modify job detect bet - [Redmine: #177701]
	DB: DBTP-bodb02
*/
IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.SystemSettings WITH(NOLOCK) WHERE VName = 'JobDeploymentDate')
	INSERT INTO dbo.SystemSettings (vName, VValue) VALUES ('JobDeploymentDate', GETDATE())