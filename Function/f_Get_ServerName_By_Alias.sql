/*<info serverAlias="DBTXN-bodb02,DBSUM-bodb02,DBACC-bodb02,DBRPT-bodb02,DBLIC-bodb02,DBFS-bodb02,DBTGRS-bodb02" isFunction="1" isNested="0"></info>*/
ALTER FUNCTION dbo.f_Get_ServerName_By_Alias
(
	@Alias VARCHAR(50)  = '',
	@Environment VARCHAR(20) = 'LocalDev'
)
RETURNS TABLE
AS
/*
	Created: 20220603@Sol
	Task: Database - Sync-up Standby Server data - [Redmine:167261]
	Database: DBTXN-bodb02,DBSUM-bodb02,DBACC-bodb02,DBRPT-bodb02,DBLIC-bodb02,DBFS-bodb02,DBTGRS-bodb02
	
	Revision:
		- 20220603@Sol: Database - Sync-up Standby Server data - [Redmine:167261]
		
	Param's Explanation:
*/
RETURN
(
	SELECT tbl.Alias, tbl.ServerName
	FROM 
	(
		VALUES 
			--PROD/UAT
			('PROD','DBSUM', 'DB052'),
			('PROD','DBSUM', 'DB053'),
			('PROD','DBACC', 'DB061'),
			('PROD','DBACC', 'DB062'),
			('PROD','DBRPT', 'DB061'),
			('PROD','DBRPT', 'DB062'),
			('PROD','DBLIC', 'DB052'),
			('PROD','DBLIC', 'DB053'),
			('PROD','DBFS', 'DB052'),
			('PROD','DBFS', 'DB053'),
			('PROD','DBTGRS', 'DB061'),
			('PROD','DBTGRS', 'DB062'),
			('PROD','DBTXN', 'DBTRANS'),

			--LocalDev
			('LocalDev','DBSUM', 'DB-61\DevDB053'),
			('LocalDev','DBACC', 'DB232'),
			('LocalDev','DBRPT', 'DB232'),
			('LocalDev','DBLIC', 'DB-61\DevDB053'),
			('LocalDev','DBFS', 'DB-61\DevDB053'),
			('LocalDev','DBTGRS', 'DB232'),
			('LocalDev','DBTXN', 'DB-60\DevDBTrans'),

			--LocalTest
			('LocalTest','DBSUM', 'TESTDB053'),
			('LocalTest','DBACC', 'TESTDB061'),
			('LocalTest','DBRPT', 'TESTDB061'),
			('LocalTest','DBLIC', 'TESTDB053'),
			('LocalTest','DBFS', 'TESTDB053'),
			('LocalTest','DBTGRS', 'TESTDB061'),
			('LocalTest','DBTXN', 'TESTDBTRANS'),

			--SIT
			('SIT','DBSUM', 'SITDB052'),
			('SIT','DBACC', 'SITDB06'),
			('SIT','DBRPT', 'SITDB06'),
			('SIT','DBLIC', 'SITDB052'),
			('SIT','DBFS', ''),
			('SIT','DBTGRS', 'SITDB06'),
			('SIT','DBTXN', 'SITDBTRANS')
	) tbl(Environment, Alias, ServerName)
	WHERE tbl.Alias = @Alias AND tbl.Environment = @Environment
)
GO