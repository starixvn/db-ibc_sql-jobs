/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_BalanceCheck]
	@winlostdate smalldatetime,
	@InitStepNo tinyint = 1
AS
/*
	Revision:
		- 20131108@Elodie: Splitting bodb02 into CustDB (Call CustInfo, Exchange by link database)
		- 20211214@Kathy: Separate Transfer Tickets[Redmine:#164197]
*/

INSERT INTO dbo.Task_BalanceRecord (step, winlostdate, SPCode, TotalAmt, TotalSum)
--exec companybalance2
SELECT @InitStepNo, @winlostdate, 0, sum(totalamt) as totalamt, sum(totalSum) As totalSUM
FROM 
(
SELECT
	sum((winlost-actual_stake+awinlost+mwinlost+swinlost +scomm)*e.actualrate) totalamt,
	sum((winlost-actual_stake+awinlost+mwinlost+swinlost +scomm)) TotalSUM
from bettrans with (nolock) INNER JOIN CustDB.dbo.exchange e with (nolock) ON bettrans.currency=e.exchangeid
where	ruben = 1 and winlostdate <= @winlostdate
UNION ALL
SELECT sum((t.winlost - actual_Stake + awinlost + mwinlost + swinlost + scomm)*e.actualrate) totalamt
		,sum((t.winlost-t.actual_stake+t.awinlost+t.mwinlost+t.swinlost +t.scomm)) TotalSUM
FROM	dbo.Transfer t with(nolock)
	INNER JOIN CustDB.dbo.exchange e with(nolock)
		ON t.Currency = e.ExchangeId
where winlostdate <= @winlostdate
) b

INSERT INTO dbo.Task_BalanceRecord (step, winlostdate, SPCode, TotalAmt, TotalSum)
--exec admin_rpt_sabalance
SELECT @InitStepNo + 1, @winlostdate, 1,
	SUM(e.actualrate * IsNull(bal,0)) bal,
	SUM( IsNull(bal,0)) bal2
FROM CustDB.dbo.custinfo c (nolock)
LEFT OUTER JOIN (
SELECT b.srecommend, SUM(b.Bal) Bal
FROM (
	SELECT b.srecommend,
	  IsNull(sum(case when custid=srecommend then winlost-actual_stake else swinlost+scomm-acomm end),0)
	+ IsNull(sum(case when custid=mrecommend then winlost-actual_stake else mwinlost+acomm-comm end),0)
	+ IsNull(sum(case when custid=recommend  then winlost-actual_stake else awinlost+comm-playercomm end),0)
	+ IsNull(sum(case when custid <> recommend and custid <> mrecommend and custid <> srecommend and ruben=1 then winlost-actual_stake+playercomm else 0 end),0) Bal
	FROM bettrans b (nolock) 
	WHERE b.winlostdate <= @winlostdate 
	GROUP BY b.srecommend
	UNION ALL
	SELECT srecommend,
	  IsNull(sum(case when custid=srecommend then winlost-actual_stake else swinlost+scomm-acomm end),0)
	+ IsNull(sum(case when custid=mrecommend then winlost-actual_stake else mwinlost+acomm-comm end),0)
	+ IsNull(sum(case when custid=recommend  then winlost-actual_stake else awinlost+comm-playercomm end),0)
	+ IsNull(sum(case when custid <> recommend and custid <> mrecommend and custid <> srecommend then winlost-actual_stake+playercomm else 0 end),0) Bal
	FROM dbo.transfer (nolock) 
	WHERE winlostdate <= @winlostdate 
	GROUP BY srecommend
) b
GROUP BY b.srecommend
) bal ON c.custid = bal.srecommend
INNER JOIN CustDB.dbo.exchange e (nolock) ON c.currency = e.exchangeid
WHERE c.roleid = 4
GO
