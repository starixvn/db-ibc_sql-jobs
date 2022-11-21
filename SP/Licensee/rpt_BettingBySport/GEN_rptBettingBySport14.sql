/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[GEN_rptBettingBySport14]
	@Date SMALLDATETIME
AS

/*
	Created: 20170930@Harper
	Task: Generate data for bodb_LicenseeReport.dbo.rpt_BettingBySport (for Muay Thai)
	DB: DBLIC.bodb_LicenseeReport

	Revisions:
		- 20170930@Harper: Get more info for MuayThai Parlay [Redmine: #82827]
		- 20171114@Harper: Fix Date Range when get detail ticket
		- 20180412@Percy: Expand Sportsbook bettype range - ESports [RedmineID: #100721]
		- 20210315@Hogan: Integrate Cricket AIO [RedmineID: #150386]
		- 20211121@Danny: Enhance performance [RedmineID: #180726]

	GEN_rptBettingBySport14 '2017-10-13'
*/

BEGIN
	DELETE FROM dbo.rpt_BettingBySport
	WHERE rptDate = @Date

	
	INSERT INTO dbo.rpt_BettingBySport (
		rptDate 
		, SiteID 
		, ProductID
		, SportType 
		, CurrencyId
		, StatusId	
		, LicenseeWL
		, AdjustedLicenseeWL
		, CustomerWL
		, AdjustedCustomerWL
		, Turnover
		, BetCount
		, WLShare
		, CommissionS
		, AdjustedCommissionS
		, CommShare
		, AdjustedCommShare
		, CustomerCategory
		, IsParlay
	)	
	EXEC DBARC.bodb_archive.dbo.GEN_rptBettingBySport14_getData @Date = @Date
END
GO