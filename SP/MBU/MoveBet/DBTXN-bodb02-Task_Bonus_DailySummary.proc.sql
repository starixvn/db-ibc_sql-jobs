/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/

ALTER PROCEDURE [dbo].[Task_Bonus_DailySummary]
(
	@WinlostDate SMALLDATETIME
)
AS
/*
	Created: 20170929@Patrick
	Task: Create a daily sum for wallettype = 1
	DB: DBTXN/bodb02
	Revisions:	
		- 20180326@Patrick: Changes bettype from 22026, 22027 to 22200, 22201
		- 20210706@Patrick: Only insert data with amount > 0 - Redmine: [#149927]
		- 20211214@Kathy: Separate Transfer Tickets[Redmine:#164197]
		
*/
BEGIN
	SET NOCOUNT ON

	INSERT INTO dbo.Bonus_sum_winloss(custId, bonusId, winlostDate, Amount)
	SELECT t.custid, t.BonusID, @WinlostDate AS winlostDate, SUM(t.bonusAmt)  bonusAmt
	FROM (
		SELECT	custid
				,BonusID
				,(CASE WHEN WalletType = 1 AND bettype NOT IN (22200, 22201) THEN winlost - actual_stake + playercomm ELSE 0 END) AS bonusAmt
		FROM	dbo.bettrans WITH(NOLOCK)
		WHERE	winlostdate = @WinlostDate 
				AND BonusID > 0
				AND statusID NOT IN (101,102) --('VOID', 'REJECT')
		UNION ALL
		SELECT	t.custid
				,ti.BonusID
				,(CASE WHEN ISNULL(ti.WalletType,2) = 1 AND t.bettype NOT IN (22200, 22201) THEN t.winlost - t.actual_stake + t.playercomm ELSE 0 END) AS bonusAmt
		FROM	dbo.Transfer t WITH(NOLOCK)
			LEFT JOIN dbo.TransferInfo ti WITH(NOLOCK)
				ON t.TransId = ti.TransId
		WHERE	t.winlostdate = @WinlostDate 
				AND ti.BonusID > 0
	) t
	GROUP BY t.custid, t.BonusID
	HAVING SUM(t.bonusAmt) <> 0
END
GO
