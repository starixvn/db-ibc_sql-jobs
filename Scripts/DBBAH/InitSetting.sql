/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/


IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.SystemSettings WITH(NOLOCK) WHERE VName = 'JobDeploymentDate')
	INSERT INTO dbo.SystemSettings (vName, VValue) VALUES ('JobDeploymentDate', GETDATE())