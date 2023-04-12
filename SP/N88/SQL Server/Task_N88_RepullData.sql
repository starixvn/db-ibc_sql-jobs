/*<info serverAlias="DBN88-bodb_N88" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
USE bodb_N88
GO

ALTER PROCEDURE [dbo].[Task_N88_RepullData]
	@WinlostDate	DATE = NULL
	,@DataSource	VARCHAR(200) = ''
	,@IsManually	BIT = 0
	,@ErrCode		INT = 0
	,@ErrMsg		VARCHAR(1000) = ''
AS

/*
	Created: 20200525@Percy
	DB: DBN88-bodb_N88
	Task: Daily repull data

	Revisions:
		- 20200525@Percy: Initialize SP [RedmineID: #155230]
		- 20210909@Percy: Re-pull data every 6 hours [RedmineID: #155230]
		- 20211028@Percy: Add AdjustmentInfo, DrawLog, LogAdminAdjustWallet [RedmineID: #161048]
		- 20211118@Percy: Add LogAdminAdjustWallet [RedmineID: #161048]
		- 20220412@Percy: Add ReferralMLog [RedmineID: #171245]
		- 20220606@Percy: Fix Re-pull data every 6 hours [RedmineID: #172501]
		- 20230206@Malolm: Increase the KeyValue length to 200, change keyvalue of DepositInfo [RedmineID: #183319]
*/

BEGIN
	SET NOCOUNT ON

	IF @WinlostDate IS NULL
		SET @WinlostDate = GETDATE()

	DECLARE @RepullDate DATETIME

	IF @IsManually = 0
	BEGIN
		SELECT @RepullDate = CONVERT(DATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'RepullData_Date'

		IF DATEDIFF(HOUR, @RepullDate, GETDATE()) >= 6
			RETURN
	END

	IF DAY(@WinlostDate) BETWEEN 1 AND 7
		SELECT @WinlostDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) - 1, 0) -- first day of last month
	ELSE
		SELECT @WinlostDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate), 0) -- first day of month

	DECLARE @Id TINYINT, @KeyValue VARCHAR(200)
	DECLARE @tblDataSource TABLE (Id TINYINT, DataSource VARCHAR(200), KeyValue VARCHAR(50))

	-- DepositInfo
	INSERT INTO @tblDataSource (DataSource, KeyValue)
	SELECT 'DepositInfo', '{"Id":' + CONVERT(VARCHAR(50), MIN(DepositId)) + ',"UpdateTime":"' + CONVERT(VARCHAR(20),MIN(UpdateTime), 120) + '"}' 
	FROM dbo.DepositInfo WITH (NOLOCK) WHERE WinlostDate >= @WinlostDate

	-- WithdrawalInfo
	INSERT INTO @tblDataSource (DataSource, KeyValue)
	SELECT 'WithdrawalInfo', CONVERT(VARCHAR(50), MIN(WithdrawalId)) FROM dbo.WithdrawalInfo WITH (NOLOCK) WHERE WinlostDate >= @WinlostDate

	-- TpTransferInfo
	INSERT INTO @tblDataSource (DataSource, KeyValue)
	SELECT 'TpTransferInfo', CONVERT(VARCHAR(50), MIN(TransferId)) FROM dbo.TpTransferInfo WITH (NOLOCK) WHERE WinlostDate >= @WinlostDate

	-- BonusInfo
	INSERT INTO @tblDataSource (DataSource, KeyValue)
	SELECT 'BonusInfo', CONVERT(VARCHAR(50), MIN(BonusId)) FROM dbo.BonusInfo WITH (NOLOCK) WHERE WinlostDate >= @WinlostDate

	-- RebateMLog
	INSERT INTO @tblDataSource (DataSource, KeyValue)
	SELECT 'RebateMLog', CONVERT(VARCHAR(50), MIN(Id)) FROM dbo.RebateMLog WITH (NOLOCK) WHERE WinlostDate >= @WinlostDate

	-- AdjustmentInfo
	INSERT INTO @tblDataSource (DataSource, KeyValue)
	SELECT 'AdjustmentInfo', CONVERT(VARCHAR(50), MIN(AdjustId)) FROM dbo.AdjustmentInfo WITH (NOLOCK) WHERE WinlostDate >= @WinlostDate

	-- DrawLog
	INSERT INTO @tblDataSource (DataSource, KeyValue)
	SELECT 'DrawLog', CONVERT(VARCHAR(50), MIN(Id)) FROM dbo.DrawLog WITH (NOLOCK) WHERE WinlostDate >= @WinlostDate

	-- LogAdminAdjustWallet
	INSERT INTO @tblDataSource (DataSource, KeyValue)
	SELECT 'LogAdminAdjustWallet', CONVERT(VARCHAR(50), MIN(TransferId)) FROM dbo.LogAdminAdjustWallet WITH (NOLOCK) WHERE WinlostDate >= @WinlostDate

	-- ReferralMLog
	INSERT INTO @tblDataSource (DataSource, KeyValue)
	SELECT 'ReferralMLog', CONVERT(VARCHAR(50), MIN(Id)) FROM dbo.ReferralMLog WITH (NOLOCK) WHERE WinlostDate >= @WinlostDate

	DELETE @tblDataSource WHERE KeyValue IS NULL OR DataSource <> @DataSource

	;WITH CTE_Id AS (
		SELECT DataSource, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS Id
		FROM @tblDataSource
	)
	UPDATE t
	SET t.Id = i.Id
	FROM @tblDataSource t
		INNER JOIN CTE_Id i ON t.DataSource = i.DataSource

	SET @Id = 1
	WHILE EXISTS (SELECT 1 FROM @tblDataSource WHERE Id = @Id)
	BEGIN
		SELECT @DataSource = DataSource, @KeyValue = KeyValue FROM @tblDataSource WHERE Id = @Id
		EXEC dbo.Task_API_TimeTracker_Import @DataSource = @DataSource, @CalledTime = @WinlostDate, @KeyValue = @KeyValue, @IsReset = 1, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		SET @Id = @Id + 1
	END

	IF @IsManually = 0
		UPDATE dbo.SystemSettings WITH (ROWLOCK)
		SET SValue = CONVERT(VARCHAR(20), GETDATE(), 120)
		WHERE SName = 'RepullData_Date'
END
GO