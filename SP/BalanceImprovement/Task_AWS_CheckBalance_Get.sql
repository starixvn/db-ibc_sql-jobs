/*<info serverAlias="DBTP-bodb02,DBBAL-bodb02" executers="" viewers="" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_AWS_CheckBalance_Get]
AS
/*
	Task: Check balance between DBTP & DBBAL
	Location: DBTP.bodb02 | DBBAL.bodb02
	Revision:
		- 20211231@Patrick: Split bettype >= 19999 out bettrans Redmine: [#164197]
*/
BEGIN
	SET NOCOUNT ON

	;WITH q2 AS (
		-- translog
		SELECT tl.custid, SUM(actual_stake) AS Outstanding
		FROM dbo.translog tl with (nolock)
			INNER JOIN dbo.Task_AWS_Balance_Check t ON tl.custid = t.custid
		WHERE tl.statusID IN (0,1) --summary running tickets only
			AND tl.translogid <= (SELECT MAX(Id) FROM dbo.Task_AWS_Balance_Check_MaxIdList WHERE tableName = 'translog')
		GROUP BY tl.custid
	),
	q3 AS (
		SELECT b.custid, SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) BalRNG
		FROM dbo.bettransRNG b WITH(NOLOCK)
			INNER JOIN dbo.Task_AWS_Balance_Check t ON b.custid = t.custid
		WHERE IsSum = 0
			AND b.transid <= (SELECT MAX(Id) FROM dbo.Task_AWS_Balance_Check_MaxIdList WHERE tableName = 'bettransRNG')
		GROUP BY b.custid
	),
	q4 AS (
		SELECT b.custid, SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) BalLC
		FROM dbo.bettransLC b WITH(NOLOCK)
			INNER JOIN dbo.Task_AWS_Balance_Check t ON b.custid = t.custid
		WHERE IsSum = 0
			AND b.transid <= (SELECT MAX(Id) FROM dbo.Task_AWS_Balance_Check_MaxIdList WHERE tableName = 'bettransLC')
		GROUP BY b.custid
	), 
	t AS (
		SELECT b.custid, SUM(Amount) AS adjustWinlostAmt
		FROM dbo.BonusAdjustmentTransfer b WITH(NOLOCK)
			INNER JOIN dbo.Task_AWS_Balance_Check t ON b.custid = t.custid
		WHERE isTransferred = 0
		GROUP BY b.custid
	),
	q5 AS (
		SELECT b.custid, ISNULL(SUM(Credit-Debit),0) balNetPosition
		FROM BalNetPosition b WITH(NOLOCK)
			INNER JOIN dbo.Task_AWS_Balance_Check t ON b.custid = t.custid
		GROUP BY b.custid
	)
	SELECT DISTINCT ISNULL(q2.custid, ISNULL(q3.custid, ISNULL(q4.custid, t.CustId))) custid, ISNULL(Outstanding, 0) Outstanding
		, ISNULL(BalRNG, 0) BalRNG, ISNULL(BalLC, 0) BalLC, ISNULL(adjustWinlostAmt, 0) adjustWinlostAmt
		, ISNULL(balNetPosition, 0) balNetPosition
	INTO #tmpCal
	FROM q2 FULL OUTER JOIN q3 ON q2.custid = q3.custid
	FULL OUTER JOIN q4 ON q2.custid = q4.custid
	FULL OUTER JOIN t ON q2.custid = t.CustID
	FULL OUTER JOIN q5 ON q2.custid = q5.CustID

	CREATE CLUSTERED INDEX CIX_t ON #tmpCal (custid)

	DECLARE @__movebetdate SMALLDATETIME
	EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @__movebetdate OUTPUT

	;WITH
	cb AS (
		SELECT b.custid, SUM(winlost-actual_stake+playercomm) Balance
		FROM dbo.bettrans b with (nolock, index=IX_custid)
			INNER JOIN dbo.Task_AWS_Balance_Check t ON b.custid = t.custid
		WHERE b.transid <= (SELECT MAX(Id) FROM dbo.Task_AWS_Balance_Check_MaxIdList WHERE tableName = 'bettrans')
			AND 1 =  WHEN bettype >= 19999 THEN 0 --> get from transfer table
					 WHEN bettype < 19999 AND winlostdate <= @__movebetdate THEN 0 --> old bet
					 ELSE 1 END
		GROUP BY b.custid
	),
	ct AS (
		SELECT b.custid, SUM(winlost-actual_stake+playercomm) Balance
		FROM dbo.Transfer b with (nolock)
			INNER JOIN dbo.Task_AWS_Balance_Check t ON b.custid = t.custid
		WHERE b.transid <= (SELECT MAX(Id) FROM dbo.Task_AWS_Balance_Check_MaxIdList WHERE tableName = 'transfer')
			AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @__movebetdate THEN 0 --> new sum
					 ELSE 1 END
		GROUP BY b.custid
	)

	SELECT cb.custid, cb.Balance - ISNULL(qq.Outstanding,0) + ISNULL(qq.BalRNG, 0) + ISNULL(qq.BalLC, 0) + ISNULL(adjustWinlostAmt, 0)  + ISNULL(balNetPosition, 0) as balance
	FROM (
		SELECT ISNULL(cb.custid, ct.CustId) custid, SUM(ISNULL(cb.balance, 0) + ISNULL(ct.balance, 0)) balance
		FROM cb FULL OUTER JOIN ct ON cb.custid = ct.CustId
		GROUP BY ISNULL(cb.custid, ct.CustId)
	)cb	
		LEFT OUTER JOIN #tmpCal qq ON cb.custid = qq.custid

	DROP TABLE #tmpCal
END