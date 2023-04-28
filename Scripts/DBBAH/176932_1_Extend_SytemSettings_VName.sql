/*<info serverAlias="DBBAH-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/  

/*
	Created: 20220426@Louisa
    DB: DBBAH/bodb02
   
    Revisions:
		- 20220426@Louisa: Extend data len for SystemSetting.VName DB05/DB05BK1 [Redmine:#176932]
	
	Param's explaination:
*/

USE bodb02
GO

ALTER TABLE dbo.SystemSettings ALTER COLUMN VName NVARCHAR(50)
GO

