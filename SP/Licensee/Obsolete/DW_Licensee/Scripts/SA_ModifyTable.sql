ALTER TABLE dbo.rpt_Betting
	ADD Comm money

ALTER TABLE dbo.rpt_Betting
	ADD Fee money
	
CREATE NONCLUSTERED INDEX nl_rpt_Betting_WinLoss
ON [dbo].[rpt_Betting] ([SiteID],[rptDate],[Bettype],leagueid,[IsLive])
INCLUDE ([CurrencyID],[BetCount],[Turnover],[WinLoss],[Comm],[Fee])

dbcc dbreindex ('rpt_Betting')