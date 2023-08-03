/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[BalanceCheck]
	@winlostdate smalldatetime = NULL,
	@step tinyint = NULL
AS
/*
	Revision: 
		-- 20131108@Elodie: Splitting bodb02 into CustDB (call custinfo, Exchange by link database)
		- 20211214@Kathy: Separate Transfer Tickets[Redmine:#164197]
		- 20220317@Kathy: Dont get data from bettrans [Redmine:#170113]
		- 20230803@Brice: scaleout site 3 - fix null value of totalamt if no transaction [Redmine:#191003]
*/
IF @winlostdate IS NULL
BEGIN
	select 0, IsNull(SUM(totalamt),0) AS totalamt
		,IsNull(sum(totalSum),0) AS totalSum
	FROM(
	SELECT 
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost +scomm)*e.actualrate) totalamt,
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost +scomm)) TotalSUM
	from bettrans with (nolock) inner join CustDB.dbo.exchange e with (nolock) ON bettrans.currency=e.exchangeid
	where ruben=1
	UNION ALL
	SELECT 
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost +scomm)*e.actualrate) totalamt,
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost +scomm)) TotalSUM
	from transfer t with (nolock) inner join CustDB.dbo.exchange e with (nolock) ON t.currency=e.exchangeid
	) b

	SELECT 1,
		IsNull(SUM(e.actualrate * IsNull(bal,0)),0) bal,
		IsNull(SUM( IsNull(bal,0)),0) bal2
	FROM CustDB.dbo.custinfo c (nolock)
	LEFT OUTER JOIN (
		SELECT bal.srecommend, SUM(bal.Bal) AS Bal
		FROM (
		SELECT srecommend,
		  IsNull(sum(case when custid=srecommend then winlost-actual_stake else swinlost+scomm-acomm end),0)
		+ IsNull(sum(case when custid=mrecommend then winlost-actual_stake else mwinlost+acomm-comm end),0)
		+ IsNull(sum(case when custid=recommend  then winlost-actual_stake else awinlost+comm-playercomm end),0)
		+ IsNull(sum(case when custid <> recommend and custid <> mrecommend and custid <> srecommend and ruben=1 then winlost-actual_stake+playercomm else 0 end),0) Bal
		FROM bettrans (nolock) GROUP BY bettrans.srecommend
		UNION ALL
		SELECT t.SRecommend,
		  IsNull(sum(case when custid=srecommend then winlost-actual_stake else swinlost+scomm-acomm end),0)
		+ IsNull(sum(case when custid=mrecommend then winlost-actual_stake else mwinlost+acomm-comm end),0)
		+ IsNull(sum(case when custid=recommend  then winlost-actual_stake else awinlost+comm-playercomm end),0)
		+ IsNull(sum(case when custid <> recommend and custid <> mrecommend and custid <> srecommend then winlost-actual_stake+playercomm else 0 end),0) Bal
		FROM dbo.transfer t (nolock) GROUP BY t.srecommend
		)bal
		GROUP BY bal.srecommend
	) bal ON c.custid = bal.srecommend
	INNER JOIN CustDB.dbo.exchange e (nolock) ON c.currency = e.exchangeid
	WHERE c.roleid = 4
END
ELSE
BEGIN
	INSERT INTO dbo.Task_BalanceRecord (step, winlostdate, SPCode, TotalAmt, TotalSum)
	--exec companybalance2
	SELECT @step,
		@winlostdate,
		0,
		IsNull(sum((winlost-actual_stake+awinlost+mwinlost+swinlost +scomm)*e.actualrate),0) totalamt,
		IsNull(sum((winlost-actual_stake+awinlost+mwinlost+swinlost +scomm)),0) TotalSUM
	from dbo.transfer t with (rowlock) 
		inner join CustDB.dbo.exchange e with (nolock) 
			ON t.currency=e.exchangeid
	where winlostdate <= @winlostdate

	INSERT INTO dbo.Task_BalanceRecord (step, winlostdate, SPCode, TotalAmt, TotalSum)
	--exec admin_rpt_sabalance
	SELECT @step+1, @winlostdate, 1,
		IsNull(SUM(e.actualrate * IsNull(bal,0)),0) bal,
		IsNull(SUM( IsNull(bal,0)),0) bal2
	FROM CustDB.dbo.custinfo c (nolock)
	LEFT OUTER JOIN (
		SELECT srecommend, SUM(Bal) AS Bal
		FROM (
			SELECT srecommend,
				IsNull(sum(case when custid=srecommend then winlost-actual_stake else swinlost+scomm-acomm end),0)
			+ IsNull(sum(case when custid=mrecommend then winlost-actual_stake else mwinlost+acomm-comm end),0)
			+ IsNull(sum(case when custid=recommend  then winlost-actual_stake else awinlost+comm-playercomm end),0)
			+ IsNull(sum(case when custid <> recommend and custid <> mrecommend and custid <> srecommend then winlost-actual_stake+playercomm else 0 end),0) Bal
			FROM dbo.transfer (rowlock) WHERE winlostdate <= @winlostdate 
			GROUP BY srecommend
		) b
		GROUP BY b.srecommend
	) bal 
		ON c.custid = bal.srecommend
	INNER JOIN CustDB.dbo.exchange e (nolock) ON c.currency = e.exchangeid
	WHERE c.roleid = 4
END
GO

