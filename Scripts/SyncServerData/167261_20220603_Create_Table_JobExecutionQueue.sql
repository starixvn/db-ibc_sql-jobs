/*<info serverAlias="DBSUM-bodb02,DBACC-bodb02,DBRPT-bodb02,DBLIC-bodb02,DBFS-bodb02,DBTGRS-bodb02" isFunction="1" isNested="0"></info>*/
/*
	Created: 20220603@Sol
	Task: Database - Sync-up Standby Server data - [Redmine:167261]
	Database: DBSUM-bodb02,DBACC-bodb02,DBRPT-bodb02,DBLIC-bodb02,DBFS-bodb02,DBTGRS-bodb02
	
	Revision:
		- 20220603@Sol: Database - Sync-up Standby Server data - Create tabe - [Redmine:167261]
		
*/

USE bodb02;

GO

CREATE TABLE JobExecutionQueue
(
	QueueId INT IDENTITY PRIMARY KEY,
	SpName VARCHAR(200),
	Params VARCHAR(MAX),
	ExecStatus VARCHAR(50),
	PriorityOrder TINYINT,
	CreatedDate DATETIME,
	CompletedDate DATETIME,
	ModifiedDate DATETIME,
	Remark VARCHAR(4000)
)

GO