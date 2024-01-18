/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_MemberInfo_Upd]
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Job - Update member info

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SiteId INT, @SiteName VARCHAR(30), @LastUpdatedTime DATETIME, @TimeZone INT
	SELECT  @SiteName = dbo.Aff_f_GetSetting('SiteName'), @LastUpdatedTime = dbo.Aff_f_GetSetting('MemberInfoLastUpdatedTime'), @TimeZone = dbo.Aff_f_GetSetting('TimeZone')
	SELECT  @SiteId = SiteId FROM bodb_YashBet.dbo.ServerInfo WITH (NOLOCK) WHERE LicenseeName = @SiteName

	SELECT @LastUpdatedTime = ISNULL(CONVERT(DATE, DATEADD(DAY, -7, @LastUpdatedTime)), '2021-01-01')

	CREATE TABLE #Customer
	(
		CustId				INT
		,IBCUsername		VARCHAR(50)
		,ActStatus			TINYINT
		,Status				TINYINT
		,FirstDepositDate	DATETIME
		,FirstDepositAmount	MONEY
		,UpdatedTime		DATETIME
	)

	INSERT INTO #Customer (CustId, IBCUsername, ActStatus, Status, FirstDepositDate, FirstDepositAmount, UpdatedTime)
	SELECT CustId, TpSystemUserName, ActStatus, Status, FirstDepositDate, FirstDepositAmount, UpdatedTime
	FROM bodb_YashBet.dbo.Customer WITH (NOLOCK)
	WHERE SiteId = @SiteId
		AND UpdatedTime >= @LastUpdatedTime

	IF EXISTS (SELECT 1 FROM #Customer)
	BEGIN
		UPDATE m WITH (ROWLOCK)
		SET	m.IBCUserName = c.IBCUsername
			,m.ActStatus = c.ActStatus
			,m.Status = c.Status
			,m.FirstDepositDate = DATEADD(HOUR, @TimeZone, c.FirstDepositDate)
			,m.FirstDepositAmount = c.FirstDepositAmount * 1.0 / CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END
		FROM dbo.MemberInfo m
			INNER JOIN #Customer c ON m.CustId = c.CustId
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON t.TpExchangeId = m.Currency
			INNER JOIN dbo.Exchange e WITH (NOLOCK) ON ISNULL(t.ExchangeId, m.Currency) = e.ExchangeId

		SELECT @LastUpdatedTime = MAX(UpdatedTime) FROM #Customer

		UPDATE dbo.SystemSettings WITH (ROWLOCK)
		SET SValue = CONVERT(VARCHAR(20), @LastUpdatedTime, 120)
		WHERE SName = 'MemberInfoLastUpdatedTime'
	END

	DROP TABLE #Customer
END
GO