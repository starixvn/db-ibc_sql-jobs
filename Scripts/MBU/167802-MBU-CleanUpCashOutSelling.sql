/*<info serverAlias="DBTXN-bodb02" executers="" selecters="" viewers="" isFunction="0" isNested="0"></info>*/
/*
    Created: 20220209@Max
	Task: MBU - Clean up Cash Out Selling - [Redmine: #167802]
	DB: DBTXN/bodb02

	Notes:
		- Clean up data on CashOutSelling tables has exceeded archive date
*/

USE [bodb02]
GO

BEGIN
	DELETE s
	FROM CashOutSelling s WITH (ROWLOCK)
	WHERE NOT EXISTS (SELECT transid FROM bettrans b WITH (NOLOCK) WHERE b.transid = s.TransID)
		AND NOT EXISTS (SELECT transid from bettrans14 b14 WITH (NOLOCK) WHERE b14.transid = s.TransID)
END

