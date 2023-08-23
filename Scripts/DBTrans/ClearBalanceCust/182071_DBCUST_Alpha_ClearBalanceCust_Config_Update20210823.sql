/*<info serverAlias="DBCUST-CustDB"></info>*/
/*
	Created: 20230823@Bobby
	Task: 182071 - Alpha - AutoJob ClearBalance
	DB: DBCUST.CustDB
	Remark: Run on DBCUST
*/

--DBCUST
USE CustDB;
-- TODO: SET MsgNameJP, MsgNameKO as ActionNameEN by default
--MsgError
UPDATE MsgError WITH(ROWLOCK, UPDLOCK)
SET MsgNameJP = MsgNameEN,
	MsgNameKO =	MsgNameEN
WHERE MsgID BETWEEN 50018 AND 50032
GO
