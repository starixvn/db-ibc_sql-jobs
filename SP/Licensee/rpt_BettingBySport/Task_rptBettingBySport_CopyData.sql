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
*/ 
BEGIN
	SET NOCOUNT ON

	IF @Date IS NULL
		RETURN

	DECLARE @sql VARCHAR(MAX)
	DECLARE @IndexTable TABLE (RowIndex INT IDENTITY(1,1), rptDate DATE)	
	
	INSERT INTO @IndexTable(rptDate)
	SELECT rptDate
	FROM OPENQUERY(DBARC, 'SELECT rptDate 
						FROM ##rpt_BettingBySport_Temp				
						GROUP BY rptDate OPTION (MAXDOP 1)')
	WHERE rptDate = @Date

	IF NOT EXISTS (SELECT TOP 1 1 FROM @IndexTable )
		RETURN

	DECLARE @rptDate DATE	
	SELECT @rptDate = rptDate FROM @IndexTable WHERE RowIndex = 1		

	SELECT @sql = 'SELECT rptDate, SiteID, ProductID, SportType, CurrencyId, StatusId, LicenseeWL, AdjustedLicenseeWL, CustomerWL, AdjustedCustomerWL
						, Turnover, BetCount, WLShare, CommissionS, AdjustedCommissionS, CommShare, AdjustedCommShare, CustomerCategory, IsParlay
					FROM OPENQUERY(DBARC, ''SELECT rptDate, SiteID, ProductID, SportType, CurrencyId, StatusId, LicenseeWL, AdjustedLicenseeWL, CustomerWL, AdjustedCustomerWL
												, Turnover, BetCount, WLShare, CommissionS, AdjustedCommissionS, CommShare, AdjustedCommShare, CustomerCategory, IsParlay
											FROM ##rpt_BettingBySport_Temp	 
											WHERE rptDate = ''''' + CAST(@rptDate AS VARCHAR(20)) + '''''
					OPTION (MAXDOP 1)'')'
		
	IF EXISTS ( SELECT TOP 1 1 FROM dbo.rpt_BettingBySport WITH (NOLOCK) WHERE RptDate = @rptDate)
	BEGIN
		DELETE dbo.rpt_BettingBySport WITH (ROWLOCK, UPDLOCK)
		WHERE RptDate = @rptDate
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
		
	WAITFOR DELAY '00:00:00.280'

	DELETE OPENQUERY(DBARC, 'SELECT * FROM ##rpt_BettingBySport_Temp')
END

GO
GRANT VIEW DEFINITION ON [dbo].[Task_rptBettingBySport_CopyData] TO [vnteam] AS [dbo]
GO