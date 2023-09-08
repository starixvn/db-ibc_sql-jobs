/*<info serverAlias="DBCTG-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
    Created by: 20230908@July
	Task: Check ticket data consistency -  update 20000 trên dbtran, get data từ sitedb1 [Redmine:#193763]
	DB: DBCTG-bodb02
	Revisions:
	
*/

USE [bodb02]
GO

UPDATE Transfer WITH(ROWLOCK,UPDLOCK)
SET Actual_Stake = 31806.5850
WHERE bettype = 20000
AND custid = 11889113
