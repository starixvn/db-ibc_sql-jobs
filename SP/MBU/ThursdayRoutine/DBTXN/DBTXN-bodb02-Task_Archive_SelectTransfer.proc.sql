/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE	dbo.Task_Archive_SelectTransfer
	@WinlostDate DATETIME
AS
/*
	Created: 
	Task:	Process will archive
			- DB06.bodb_Archive.dbo.Transfer_BK
	Database: DBTXN.bodb02

	Revisions:
		- 20110516@Henry:	change bettype to new range
		- 20150514@Viet:	adding lock type
		- 20190827@Billy:	Fix duplicated transfer cause by unhandled transfer ticket - [Redmine: #119258]
		- 20210210@Brice:	add column balance [Redmine: #119258]
		- 20211214@Kathy:	Separate Transfer Tickets[Redmine:#164197]
*/
BEGIN;
	-- Transfer Archive
	SELECT	[transid]		= transid
		,	[custid]		= custid
		,	[transdate]		= transdate
		,	[Debit]			= actual_stake
		,	[Credit]		= winlost
		,	[TransDesc]		= TransDesc
		,	[winlostdate]	= winlostdate
		,	[recommend]		= recommend
		,	[mrecommend]	= mrecommend
		,	[srecommend]	= srecommend
		,	[bettype]		= bettype
		,	[currency]		= currency
		,	[refno]			= refno
		,	[creator]		= creator
		,	[balance]		= balance
	FROM	dbo.Transfer WITH(NOLOCK)
	WHERE	bettype > 20000
			AND	winlostdate = @WinlostDate
			AND	custid <> 0
			AND	(winlost + actual_stake) <> 0;
END;
GO
