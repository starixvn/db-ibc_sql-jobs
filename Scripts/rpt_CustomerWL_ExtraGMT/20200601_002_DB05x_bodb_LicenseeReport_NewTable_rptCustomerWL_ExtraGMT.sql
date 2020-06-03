/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/
/*	
	Created: 20200601@Percy
	DB: DBLIC-bodb_LicenseeReport
	Task: New table rpt_CustomerWL_ExtraGMT
	RedmineID: #134867 - Calculating pay to supplier for some special customers

	Step 2: Create new table
*/

USE bodb_LicenseeReport
GO

CREATE TABLE dbo.rpt_CustomerWL_ExtraGMT
(
	RptDate						date not null
	,RptDate3rd					date not null
	,CustId						int not null
	,SiteId						int not null
	,ProductId					int not null
	,BetTypeId					int not null
	,CurrencyId					int not null
	,StatusId					int not null
	,BetCount					int
	,Turnover					money
	,Winloss					money
	,AComm						money
	,PComm						money
	,ProgressiveContribution	money
	,ProgressivePayout			money
	,ValidBetAmount				money
) ON PS_rpt_CustomerWL_ExtraGMT_Monthly (RptDate)
GO

CREATE CLUSTERED INDEX CIX_rpt_CustomerWL_ExtraGMT ON dbo.rpt_CustomerWL_ExtraGMT
	(RptDate, RptDate3rd, SiteId, ProductId) ON PS_rpt_CustomerWL_ExtraGMT_Monthly (RptDate)
GO