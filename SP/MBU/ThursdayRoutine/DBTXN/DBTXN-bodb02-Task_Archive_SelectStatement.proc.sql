/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE	dbo.Task_Archive_SelectStatement
	@WinlostDate DATETIME
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
		- 20211214@Kathy:	Separate Transfer Tickets[Redmine:#164197]
*/
BEGIN;
	-- OpenBalance & Transfer for Statement
	SELECT	t.CustId AS custid
			,t.TransDate AS accdate
			,SUM(t.winlost - t.actual_stake) AS totalamt
			,CASE WHEN ti.IsCollection = 1 THEN CONVERT(NVARCHAR(128), 'COLL') ELSE bt.typenamee END AS transtype
			,TransDesc AS transdesc
	FROM	dbo.Transfer t WITH(ROWLOCK)
		LEFT JOIN dbo.TransferInfo ti WITH(NOLOCK)
			ON t.TransId = ti.TransId
		INNER JOIN dbo.bettype bt WITH(NOLOCK)
			ON t.Bettype = bt.typeid
	WHERE	t.WinlostDate = @WinlostDate
			AND	t.bettype >= 20000
	GROUP BY t.CustId, t.TransDesc, t.TransDate, t.TransId
		,CASE WHEN ti.IsCollection = 1 THEN CONVERT(NVARCHAR(128), 'COLL') ELSE bt.typenamee END
END;
GO
