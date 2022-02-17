/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_Statement_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: Task_Archive_SelectStatement 
	
	Revisions:
		- 20130831@Bobby: Init
*/
BEGIN
	SET NOCOUNT ON;
	--DECLARE	@BU_Date		DATETIME -- Next BalanceUp Date
	--	,	@CurrentBU_Date	DATETIME
	--	;

	--SELECT	@BU_Date		= DATEADD(DAY, 1, MAX(winlostdate))
	--	,	@CurrentBU_Date	= MIN(winlostdate)
	--FROM	dbo.Task_ArchiveDate;

-- OpenBalance & Transfer for Statement
	SELECT	[custid]	= b.custid
		,	[accdate]	= b.transdate
		,	[totalamt]	= SUM(b.winlost - b.actual_stake)
		,	[transtype]	= cast(CASE WHEN b.OddsId = 1 THEN CONVERT(VARCHAR(128), 'COLL') ELSE bt.typenamee END as varchar(128))
		,	[transdesc]	= CAST(transdesc as varchar(1000))
	FROM	dbo.bettrans AS b WITH (ROWLOCK, INDEX = CIX_matchid_bettype)
	INNER JOIN	dbo.bettype AS bt WITH (NOLOCK)
			ON	b.bettype = bt.typeid
	WHERE	b.ruben = 1
		AND	b.matchid = 0
		AND	b.bettype >= 20000
		AND	b.winlostdate = @winlostdate 
		AND custid <> 0
	GROUP BY b.custid, bt.typenamee, b.transdesc, b.transdate, b.transid, CASE WHEN b.OddsId = 1 THEN CONVERT (NVARCHAR(128), 'COLL') ELSE bt.typenamee END
	HAVING SUM(winlost - actual_stake) <> 0;
END
GO
