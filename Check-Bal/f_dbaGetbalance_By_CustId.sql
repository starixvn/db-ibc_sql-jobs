USE [bodb02]
GO
ALTER FUNCTION [dbo].[f_dbaGetbalance_By_CustId] (@custid INT, @movebetDate SMALLDATETIME, @siteDBGroupId SMALLINT)
RETURNS TABLE
AS
RETURN (

	WITH __cte_BetX AS (
		SELECT @custid AS custid, SUM(winlost-actual_stake+playercomm)	bal
		FROM dbo.bettrans WITH (NOLOCK) 
		WHERE custid = @custid
			AND 1 = CASE WHEN bettype >= 19999 THEN 0 --> get from transfer table
						WHEN bettype < 19999 AND winlostdate <= @movebetDate THEN 0 --> old bet
						ELSE 1 END
			AND ISNULL(SiteDBGroupID, 0) = @siteDBGroupId

		UNION ALL
		SELECT @custid AS custid, SUM(winlost-actual_stake+playercomm)	
		FROM dbo.Transfer t WITH (NOLOCK) 
			LEFT JOIN custdb.dbo.Dep_CustSuper c WITH(NOLOCK) ON t.SRecommend = c.custid
		WHERE t.custid = @custid
			AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @movebetDate THEN 0 --> new sum
						ELSE 1 END
			AND ISNULL(c.SiteDBGroupID, 0) = @siteDBGroupId

		UNION ALL
		SELECT @custid AS custid, SUM(Amount)
		FROM dbo.BonusAdjustmentTransfer WITH(NOLOCK)
		WHERE isTransferred = 0 AND custid = @custid

		UNION ALL
		SELECT @custid AS custid, SUM(actual_stake) 
		FROM dbo.translog WITH (NOLOCK) 
		WHERE custid = @custid and statusID IN (0,1) AND ISNULL(SiteDBGroupID, 0) = @siteDBGroupId

		UNION ALL
		SELECT @custid AS custid, SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) 
		FROM dbo.bettransRNG WITH(NOLOCK)
		WHERE IsSum = 0 AND custid = @custid AND ISNULL(SiteDBGroupID, 0) = @siteDBGroupId

		UNION ALL
		SELECT @custid AS custid, SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) 
		FROM dbo.bettransLC WITH(NOLOCK)
		WHERE IsSum = 0 AND custid = @custid AND ISNULL(SiteDBGroupID, 0) = @siteDBGroupId
	), __cte_Bal_Table AS (
		SELECT @custid AS custid, (cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance) bal
		FROM dbo.BalCreditTransfer cd1 WITH (NOLOCK)
			INNER JOIN dbo.BalCreditSports cd2 WITH (NOLOCK) ON cd1.custid = cd2.custid
			INNER JOIN dbo.BalCreditCasino cd3 WITH (NOLOCK) ON cd1.custid = cd3.custid
			INNER JOIN dbo.BalCreditOthers cd4 WITH (NOLOCK) ON cd1.custid = cd4.custid
			INNER JOIN dbo.BalDebitTransfer db1 WITH (NOLOCK) ON cd1.custid = db1.custid
			INNER JOIN dbo.BalDebitSports db2 WITH (NOLOCK) ON cd1.custid = db2.custid
			INNER JOIN dbo.BalDebitCasino db3 WITH (NOLOCK) ON cd1.custid = db3.custid
			INNER JOIN dbo.BalDebitOthers db4 WITH (NOLOCK) ON cd1.custid = db4.custid	
		WHERE cd1.custid = @custid
	)

	SELECT b.custid, b.bal AS bal_BetX, ISNULL(t.bal, 0) AS bal_Table, b.bal - ISNULL(t.bal, 0) AS DiffAmt
	FROM (
		SELECT custid, SUM(ISNULL(b.bal, 0)) bal
		FROM __cte_BetX b GROUP BY custid
	) b LEFT JOIN __cte_Bal_Table t ON b.custid = t.custid
)
GO