SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_SelectStatement
AS
/*
	Created:	Unknown
	Task:		Process will archive
				- DB06.bodb_Report.dbo.statement
	Database:	DBTXN.bodb02

	Revisions:
		- 20110516@Henry:	Change bettype to new range
		- 20181106@Sophia:	Add transtype Coll [Redmine: #98621]
		- 20190827@Billy:	Fix duplicated transfer cause by unhandled transfer ticket - [Redmine: #119258]
*/
BEGIN;
	DECLARE	@BU_Date		DATETIME -- Next BalanceUp Date
		,	@CurrentBU_Date	DATETIME
		;

	SELECT	@BU_Date		= DATEADD(DAY, 1, MAX(winlostdate))
		,	@CurrentBU_Date	= MIN(winlostdate)
	FROM	dbo.Task_ArchiveDate;

-- OpenBalance & Transfer for Statement
	SELECT	[custid]	= b.custid
		,	[accdate]	= b.transdate
		,	[totalamt]	= SUM(b.winlost - b.actual_stake)
		,	[transtype]	= CASE WHEN b.OddsId = 1 THEN CONVERT(NVARCHAR(128), 'COLL') ELSE bt.typenamee END
		,	[transdesc]	= transdesc
	FROM		dbo.bettrans AS b WITH (ROWLOCK, INDEX = CIX_matchid_bettype)
	INNER JOIN	dbo.bettype AS bt WITH (NOLOCK)
			ON	b.bettype = bt.typeid
	WHERE	b.ruben = 1
		AND	b.matchid = 0
		AND	b.bettype >= 20000
		AND	b.winlostdate >= @CurrentBU_Date 
		AND	b.winlostdate < @BU_Date
		AND custid <> 0
	GROUP BY b.custid, bt.typenamee, b.transdesc, b.transdate, b.transid, CASE WHEN b.OddsId = 1 THEN CONVERT (NVARCHAR(128), 'COLL') ELSE bt.typenamee END
	HAVING SUM(winlost - actual_stake) <> 0;
END;
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/