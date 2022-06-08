/*<info serverAlias="DBTXN-bodb02" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].ExecRep_NAP_Admin_10 
(
	@Environment VARCHAR(20) = 'LocalDev',
	@Alias VARCHAR(100) = '',
	@Spname VARCHAR(200),
	@Params VARCHAR(MAX),
	@DoNotRunInServer VARCHAR(1000),
	@PriorityOrder TINYINT = 2, --default for daily
	@Remark VARCHAR(4000)
)
AS
/*
	Created: 20220603@Sol
	Task: Database - Sync-up Standby Server data - [Redmine:167261]
	Database: DBTXN-bodb02
	
	Revision:
		- 20220603@Sol: Database - Sync-up Standby Server data - [Redmine:167261]
		
	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @ServerName VARCHAR(100) = @@servername

	--check if this sp is called in dbtrans than do nothing  
	IF @ServerName IN (@doNotRunInServer) --'DB-60\DEVDBTRANS' 
	BEGIN
		RETURN
	END
	ELSE -- this block code is used when this sp is executed at replication server  
	BEGIN

		DECLARE @tblMapping TABLE (Alias VARCHAR(100), SpName VARCHAR(500))

		---create table mapping between alias and sp
		INSERT INTO @tblMapping (Alias, SpName)
		VALUES 
			('DBSUM', 'bodb_summary.dbo.Task_CS_SumWinloss_14'),
			('DBSUM', 'bodb_summary.dbo.Task_CS_SumCancelled_14'),
			('DBACC', 'bodb02.dbo.Task_CS_HeadlineBalance14'),
			('DBACC', 'bodb02.dbo.Acc_ResetWinning_SelByDate14'),
			('DBACC', 'bodb02.dbo.Task_ResetWinning_ExtraPT14'),
			('DBACC', 'bodb02.dbo.Task_rptWinLost_UpdateTable'),
			('DBRPT', 'bodb_report.dbo.Task_rptStatement_14'),
			('DBLIC', 'bodb_LicenseeReport.dbo.Task_PrepareStaging'),
			('DBLIC', 'bodb_LicenseeReport.dbo.Task_rptBetting_CheckData'),
			('DBLIC', 'bodb_LicenseeReport.dbo.Task_PostStaging'),
			('DBLIC', 'bodb_LicenseeReport.dbo.Task_rptBettingBySport_CheckData'),
			('DBLIC', 'bodb_LicenseeReport.dbo.Task_DailyRptLicWinloss2'),
			('DBLIC', 'bodb_LicenseeReport.dbo.Task_rptCustomerTurnOver_Bettrans14'),
			('DBLIC', 'bodb_LicenseeReport.dbo.Task_rptWinlostbyleague_Bettrans14'),
			('DBLIC', 'bodb_LicenseeReport.dbo.Task_rptCustomerMatch_Bettrans14'),
			('DBLIC', 'bodb_LicenseeReport.dbo.GEN_rptBetting_Parlay14'),
			('DBLIC', 'bodb_LicenseeReport.dbo.Task_DailyRptLicWinlossGMT_Bettrans14'),
			('DBLIC', 'bodb_LicenseeReport.dbo.Task_DailySummaryLicPromotion_Bettrans14'),
			('DBFS', 'bodb_FraudSensor.dbo.FS_Task_MatchDailyDataCapture'),
			('DBTGRS', 'bodb_TGRS.dbo.Task_RegenerateTGRSData')

		IF EXISTS 
		(
			SELECT 1
			FROM @tblMapping t
			WHERE T.SpName = @Spname
				AND EXISTS (SELECT 1 FROM dbo.f_Get_ServerName_By_Alias(@Alias, @Environment) f WHERE T.Alias = f.Alias AND f.ServerName = @ServerName)
		)
		BEGIN
        	INSERT INTO JobExecutionQueue (SpName, Params, ExecStatus, PriorityOrder, CreatedDate, CompletedDate, ModifiedDate, Remark)
			VALUES (@spname, @params, 'Waiting', @PriorityOrder, GETDATE(), NULL, NULL, @Remark);
        END

	END
END