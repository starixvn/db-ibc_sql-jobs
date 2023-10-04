/*<info serverAlias="DBCUST-CustDB"></info>*/
/*
	Created: 20230828@Bobby
	Task: 182071 - Alpha - AutoJob ClearBalance - Enhancement
	DB: DBCUST.CustDB
	Remark: Run on DBCUST
*/

--DBCUST
USE CustDB;
--MsgError
UPDATE MsgError WITH(ROWLOCK, UPDLOCK)
SET MsgNameEN = N'The Auto Transfer has been enabled for this account. However, this process is taking place, and the account will be queued for Auto Transfer at the next scheduled time based on its transfer conditions.'
WHERE MsgID = 50018
GO

UPDATE MsgError WITH(ROWLOCK, UPDLOCK)
SET MsgNameJP = MsgNameEN
	,MsgNameKO = MsgNameEN
WHERE MsgID = 50018
GO

