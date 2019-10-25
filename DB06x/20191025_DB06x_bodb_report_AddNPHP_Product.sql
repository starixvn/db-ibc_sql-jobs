use bodb_report
go

/*
	Created: 20191025@Bobby
	DB: DB06x.bodb_report
	Task: Add column promotion into  [rptDepWinlost_Trans],[rptDepWinlost_bk],[rptDepwinlost_SUM] - [RedmineID #120333]
*/

ALTER TABLE [dbo].[rptDepWinlost_Trans]
ADD Promotion MONEY NULL DEFAULT(0)
GO

ALTER TABLE [dbo].[rptDepWinlost_bk]
ADD Promotion MONEY NULL DEFAULT(0)


GO
ALTER TABLE [dbo].[rptDepwinlost_SUM]
ADD Promotion MONEY NULL DEFAULT(0)

GO
ALTER VIEW [dbo].[rptDepWinlost]
AS
	SELECT m.Winlostdate
		, m.CustID
		, m.currency
		, m.OpeningBalance
		, ISNULL(t.Deposit, 0) Deposit
		, ISNULL(t.Withdrawal, 0) Withdrawal
		, ISNULL(t.Aff2MemTransfer, 0) Aff2MemTransfer
		, ISNULL(t.Bonus, 0) Bonus
		, ISNULL(t.Adjustment, 0) Adjustment
		, ISNULL(Turnover, 0) Turnover
		, ISNULL(t.Outstanding, 0) Outstanding
		, ISNULL(t.Winloss, 0) Winloss
		, (m.OpeningBalance + ISNULL(t.Deposit, 0) + ISNULL(t.Aff2MemTransfer, 0) - ISNULL(t.Withdrawal, 0) + ISNULL(t.Bonus, 0) + ISNULL(t.Adjustment, 0) - ISNULL(t.Outstanding, 0) + ISNULL(t.Winloss, 0) + ISNULL(t.playercomm, 0) + ISNULL(t.Transfer3rd, 0) + ISNULL(t.Transfer3rdOthers, 0) - ISNULL(t.Comm_BetTrade_Full, 0)) ClosingBalance
		, m.recommend
		, m.mrecommend
		, m.srecommend
		, m.actualrate
		, ISNULL(t.Transfer3rd, 0) Transfer3rd
		, ISNULL(t.DrawGame, 0) DrawGame
		, ISNULL(t.Turnover_BA, 0) Turnover_BA
		, ISNULL(t.Comm_BA, 0) Comm_BA
		, ISNULL(t.AmountDueTo_BA, 0) AmountDueTo_BA
		, ISNULL(t.playercomm, 0) playercomm
		, ISNULL(t.Transfer3rdOthers, 0) Transfer3rdOthers
		, ISNULL(t.Comm_BetTrade, 0) Comm_BetTrade
		, ISNULL(t.AmountDueTo_BetTrade, 0) AmountDueTo_BetTrade
		, ISNULL(t.Promotion, 0) Promotion
	FROM dbo.rptDepWinlost_Main m WITH (NOLOCK)
	LEFT JOIN dbo.rptDepWinlost_Trans t WITH (NOLOCK)
		ON m.CustID = t.CustID
			AND m.Winlostdate = t.Winlostdate
			AND t.SportType = - 1
			AND t.PartnerID = - 1
GO