/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
    Created by: 20230908@July
	Task: Check ticket data consistency - Delete ticket 20K Transfer [Redmine:#193763]
	DB: DBSIG-bodb02
	Revisions:
	
*/
--Only SITEBD02 : Delete ticket 20K Transfer
USE [bodb02]
GO

DELETE FROM dbo.Transfer WHERE transid = 161001517728400362
