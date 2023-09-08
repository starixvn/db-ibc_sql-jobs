/*<info serverAlias="DBARC-bodb_archive" executers="" viewers="" isFunction="0"></info>*/
/*
    Created by: 20230908@July
	Task: Check ticket data consistency -  xóa archive ticket transfer [Redmine:#193763]
	DB: DBARC-bodb_archive
	Revisions:
	
*/

USE bodb_archive
GO

DELETE FROM dbo.Transfer_bk 
WHERE transid = 157122792892923951 AND winlostdate = '2023-08-28'