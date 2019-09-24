SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE [dbo].[Task_Bonus_DailySummary]
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
		
*/
BEGIN
	SET NOCOUNT ON

	INSERT INTO dbo.Bonus_sum_winloss(custId, bonusId, winlostDate, Amount)
	SELECT custid, BonusID, @WinlostDate AS winlostDate
		, SUM(CASE WHEN WalletType = 1 AND bettype NOT IN (22200, 22201) THEN winlost - actual_stake + playercomm ELSE 0 END) AS bonusAmt
	FROM dbo.bettrans WITH(NOLOCK)
	WHERE winlostdate = @WinlostDate AND BonusID > 0
		AND statusID NOT IN (101,102) --('VOID', 'REJECT')
	GROUP BY custid, BonusID
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/