/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

USE [bodb_LicenseeReport]
GO

ALTER PROCEDURE [dbo].[Task_rptBettingBySport_CopyData]
	@Date	DATE	
AS
/*
    Created: 20171016@Harper
    Task: Generate data for bodb_LicenseeReport.dbo.rpt_BettingBySport (for Muay Thai)
    DB: DBLIC.bodb_LicenseeReport

    Revisions:	
		- 20171016@Harper: Get more info for MuayThai Parlay [Redmine: #82827]	

	Task_rptBettingBySport_CopyData '2017-09-30'
*/ 
BEGIN
	SET NOCOUNT ON

	IF @Date IS NULL
		RETURN
		--DECLARE @Date SMALLDATETIME = '2017-09-30'
	DECLARE @sql VARCHAR(MAX)
	
	SELECT @sql = 'SELECT rptDate, SiteID, ProductID, SportType, CurrencyId, StatusId, LicenseeWL, AdjustedLicenseeWL, CustomerWL, AdjustedCustomerWL
						, Turnover, BetCount, WLShare, CommissionS, AdjustedCommissionS, CommShare, AdjustedCommShare, CustomerCategory, IsParlay
					FROM OPENQUERY(DBARC, ''SELECT rptDate, SiteID, ProductID, SportType, CurrencyId, StatusId, LicenseeWL, AdjustedLicenseeWL, CustomerWL, AdjustedCustomerWL
												, Turnover, BetCount, WLShare, CommissionS, AdjustedCommissionS, CommShare, AdjustedCommShare, CustomerCategory, IsParlay
											FROM ##rpt_BettingBySport_Temp	 
											WHERE rptDate = ''''' + CAST(@Date AS VARCHAR(20)) + '''''
					OPTION (MAXDOP 1)'')'
	--EXECUTE (@sql)
	IF EXISTS ( SELECT TOP 1 1 FROM dbo.rpt_BettingBySport WITH (NOLOCK) WHERE RptDate = @Date)
	BEGIN
		DELETE dbo.rpt_BettingBySport WITH (ROWLOCK, UPDLOCK)
		WHERE RptDate = @Date
	END
		
	INSERT INTO dbo.rpt_BettingBySport( rptDate 
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
	EXECUTE (@sql)	

	SELECT @sql = ''
	SELECT @sql = 'DELETE OPENQUERY(DBARC, ''SELECT * FROM ##rpt_BettingBySport_Temp WHERE rptDate = ''''' + CAST(@Date AS VARCHAR(20)) + ''''''')'
	EXECUTE (@sql)

END

GO
GRANT VIEW DEFINITION ON [dbo].[Task_rptBettingBySport_CopyData] TO [vnteam] AS [dbo]
GO
