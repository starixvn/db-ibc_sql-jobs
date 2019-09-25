SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_SelectTransfer
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
*/
BEGIN;
	DECLARE	@BU_Date		DATETIME -- Next BalanceUp Date
		,	@CurrentBU_Date	DATETIME
		;

	SELECT	@BU_Date		= DATEADD(DAY, 1, MAX(winlostdate))
		,	@CurrentBU_Date	= MIN(winlostdate)
	FROM	dbo.Task_ArchiveDate;

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
	FROM	dbo.bettrans WITH(NOLOCK)
	WHERE	ruben = 1
		AND	matchid = 0
		AND	bettype > 20000
		AND	winlostdate >= @CurrentBU_Date
		AND	winlostdate < @BU_Date
		AND	custid <> 0
		AND	(winlost + actual_stake) <> 0;
END;
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/