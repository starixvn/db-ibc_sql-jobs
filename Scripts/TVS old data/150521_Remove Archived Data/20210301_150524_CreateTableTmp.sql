/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
/*
	Created:	20210301@Max
	Task:		[TVS] Remove archived data [Redmine: #150524]
	Database:	DBTXN-bodb02
*/
USE bodb02
GO
BEGIN
	CREATE TABLE TicketVoiding_VoidedTransaction_Archived (id INT PRIMARY KEY CLUSTERED)	
	CREATE TABLE zzzbettrans_Archived (id INT PRIMARY KEY CLUSTERED)
END
GO

