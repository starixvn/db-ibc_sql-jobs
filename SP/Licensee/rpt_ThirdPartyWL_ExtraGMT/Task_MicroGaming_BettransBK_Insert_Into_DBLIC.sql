/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_MicroGaming_BettransBK_Insert_Into_DBLIC] 
	@FromDate SMALLDATETIME, 
	@ToDate SMALLDATETIME
AS
/*   
	Creator: 20200525@Parsons
	Task: Gen history data for 3rd product from bettrans_bk
	DB: DBLIC-bodb_LicenseeReport
	Revisions: 	
	- 20200525@Parsons: Integrate Sexy Gaming for deposit licensees [RedmineID: #132665]

	Param's Explanation:		
*/
BEGIN
	SET NOCOUNT ON

	IF @FromDate IS NULL OR @ToDate IS NULL
		RETURN

	DECLARE @ErrMsg VARCHAR(200)

	DECLARE @WinlostDate DATE = @FromDate

	WHILE (@Winlostdate <= @Todate)
	BEGIN
		SELECT @ErrMsg = 'WinlostDate=' + CONVERT(VARCHAR(20), @WinlostDate, 120)
		RAISERROR(@ErrMsg, 1, 0) WITH NOWAIT

		DELETE dbo.rpt_ThirdPartyWL_ExtraGMT WITH (ROWLOCK, UPDLOCK)
		WHERE RptDate = @Winlostdate
		
		INSERT INTO dbo.rpt_ThirdPartyWL_ExtraGMT (RptDate, RptDate3rd, SiteId, BetTypeId, CurrencyId, StatusId, BetCount, Turnover, Winloss, AComm, PComm, ProgressiveContribution, ProgressivePayout, ValidBetAmount)
		SELECT RptDate, RptDate3rd, SiteId, BetTypeId, CurrencyId, StatusId, BetCount, Turnover, Winloss, AComm, PComm, ProgressiveContribution, ProgressivePayout, ValidBetAmount
		FROM DBRPT.bodb_report.dbo.rpt_ThirdPartyWL_ExtraGMT
		WHERE rptDate = @WinlostDate
		
		--reset params
		SET @WinlostDate = DATEADD(DAY, 1, @WinlostDate)

		WAITFOR DELAY '00:00:00.280'
	END	
END
GO