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
		- 20220317@Bobby: Update SplitTransfer tables - [Redmine: #166146]	
*/
BEGIN
	SET NOCOUNT ON;
	
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
	WHERE	t.WinlostDate = @winlostdate
			AND	t.bettype >= 20000
			AND custid <> 0
	GROUP BY t.CustId, t.TransDesc, t.TransDate, t.TransId
		,CASE WHEN ti.IsCollection = 1 THEN CONVERT(NVARCHAR(128), 'COLL') ELSE bt.typenamee END
	HAVING SUM(t.winlost - t.actual_stake) <> 0;
END
GO
