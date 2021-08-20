/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_MemberInfo_Upd]
AS

/*
	Created: 20201111@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Job - Update member info

	Revisions:
		- 20201111@Percy: Initialize SP [RedmineID: #145020]
		- 20210323@Percy: Convert timezone [RedmineID: #151391]
		- 20210819@Percy: Get System Name [RedmineID: #160414]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SiteId INT, @SiteName VARCHAR(30), @LastUpdatedTime DATETIME, @TimeZone INT
	SELECT  @SiteName = dbo.Aff_f_GetSetting('SiteName'), @LastUpdatedTime = dbo.Aff_f_GetSetting('MemberInfoLastUpdatedTime'), @TimeZone = dbo.Aff_f_GetSetting('TimeZone')
	SELECT  @SiteId = SiteId FROM bodb_N88.dbo.ServerInfo WITH (NOLOCK) WHERE LicenseeName = @SiteName

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
	FROM bodb_N88.dbo.Customer WITH (NOLOCK)
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
			INNER JOIN dbo.Exchange e WITH (NOLOCK) ON m.Currency = e.ExchangeId

		SELECT @LastUpdatedTime = MAX(UpdatedTime) FROM #Customer

		UPDATE dbo.SystemSettings WITH (ROWLOCK)
		SET SValue = CONVERT(VARCHAR(20), @LastUpdatedTime, 120)
		WHERE SName = 'MemberInfoLastUpdatedTime'
	END

	DROP TABLE #Customer
END
GO