/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Archive_SelectTransfer_Fi]
AS
 /*
	Created by: 20190117@Sophia
	Task: Insert data for transfer_fi
	DB: DBTXN.bodb02 
	Original: Acc_StatementFinance at DB06.bodb02
	
	Revisions:
	    - 20190117@Sophia : Initial SP [redmine: 105415]
		- 20211214@Kathy:	Separate Transfer Tickets[Redmine:#164197]
		- 20230227@Evan:	Balance-Up support transfer 247 [Redmine: #173554]
	
 */
BEGIN
	SET NOCOUNT ON 

	DECLARE @Refno_temp AS TABLE ( refno BIGINT, winlostdate SMALLDATETIME) 

	DECLARE @BalanceUpDay SMALLDATETIME -- Next BalanceUp Date  

	SELECT @BalanceUpDay = DATEADD(DAY, 1, MAX(winlostdate))
	FROM dbo.Task_ArchiveDate

	DECLARE @InternalAccList AS TABLE (CustID INT, RoleID TINYINT)
	INSERT INTO @InternalAccList (CustID, RoleID)
	SELECT 	CustID, 2 
	FROM 	DBCUST.CustDB.dbo.custAgent c WITH (NOLOCK)
	WHERE 	c.isInternal = 1
	UNION ALL 
	SELECT 	CustID, 3
	FROM 	DBCUST.CustDB.dbo.CustMaster c WITH (NOLOCK)
	WHERE 	c.isInternal = 1
	UNION ALL
	SELECT 	CustID, 4 
	FROM 	DBCUST.CustDB.dbo.CustSuper c WITH (NOLOCK)
	WHERE 	c.isInternal = 1


	INSERT INTO @Refno_temp
	SELECT	t.refno, t.winlostdate 
	FROM dbo.Transfer t WITH (NOLOCK)
		INNER join @InternalAccList c 
			ON	t.recommend = c.custid
	WHERE	c.RoleID = 2 
			AND t.bettype > 20000 
			AND t.winlostdate < @BalanceUpDay
	UNION
	SELECT	refno, winlostdate 
	FROM	dbo.Transfer t WITH (NOLOCK)
		INNER join @InternalAccList c 
			ON	t.custid = c.custid
	WHERE	c.RoleID = 3 
			AND t.bettype > 20000 
			AND t.winlostdate < @BalanceUpDay
	UNION
	SELECT refno, winlostdate 
	FROM dbo.Transfer t WITH (NOLOCK)
		INNER join @InternalAccList c 
			ON t.custid = c.custid
	WHERE	c.RoleID = 4 
			AND t.bettype > 20000 
			AND t.winlostdate < @BalanceUpDay

	SELECT 
		t.transid, 
		t.custid, 
		t.transdate, 
		t.bettype, 
		t.actual_stake, 
		t.winlost, 
		t.ActualRate, 
		CONVERT (NVARCHAR(300),t.TransDesc) AS TransDesc, 
		t.winlostdate, 
		t.recommend, 
		t.mrecommend, 
		t.srecommend, 
		t.currency, 
		t.refno,
		t.creator,
		ti.CheckerID,
		ti.CheckerName,
		checkTime,
		ti.IsDel isReversal
	FROM dbo.Transfer t WITH (NOLOCK)
		LEFT JOIN dbo.TransferInfo ti WITH(NOLOCK)
			ON t.TransId = ti.TransId
		INNER JOIN @Refno_temp r 
			ON	t.refno = r.refno 
				AND t.winlostdate=r.winlostdate
	WHERE	t.bettype > 20000
    
END
GO



