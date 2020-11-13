/*<info serverAlias="DBAFFN88-Affiliate_N88" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_MemberInfo_Upd]
AS

/*
	Created: 20201111@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Job - Update member info

	Revisions:
		- 20201111@Percy: Initialize SP [RedmineID: #145020]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SiteId INT, @SiteName VARCHAR(30), @LastUpdatedTime DATETIME
	SELECT  @SiteName = dbo.Aff_f_GetSetting('SiteName'), @LastUpdatedTime = dbo.Aff_f_GetSetting('MemberInfoLastUpdatedTime')
	SELECT  @SiteId = SiteId FROM bodb_N88.dbo.ServerInfo WITH (NOLOCK) WHERE LicenseeName = @SiteName

	CREATE TABLE #Customer
	(
		CustId				INT
		,ActStatus			TINYINT
		,Status				TINYINT
		,FirstDepositDate	DATETIME
		,FirstDepositAmount	MONEY
		,UpdatedTime		DATETIME
	)

	INSERT INTO #Customer (CustId, ActStatus, Status, FirstDepositDate, FirstDepositAmount, UpdatedTime)
	SELECT CustId, ActStatus, Status, FirstDepositDate, FirstDepositAmount, UpdatedTime
	FROM bodb_N88.dbo.Customer WITH (NOLOCK)
	WHERE SiteId = @SiteId
		AND UpdatedTime >= @LastUpdatedTime

	IF EXISTS (SELECT 1 FROM #Customer)
	BEGIN
		UPDATE m WITH (ROWLOCK)
		SET m.ActStatus = c.ActStatus
			,m.Status = c.Status
			,m.FirstDepositDate = c.FirstDepositDate
			,m.FirstDepositAmount = c.FirstDepositAmount
		FROM dbo.MemberInfo m
			INNER JOIN #Customer c ON m.CustId = c.CustId

		SELECT @LastUpdatedTime = MAX(UpdatedTime) FROM #Customer

		UPDATE dbo.SystemSettings WITH (ROWLOCK)
		SET SValue = CONVERT(VARCHAR(20), @LastUpdatedTime, 120)
		WHERE SName = 'MemberInfoLastUpdatedTime'
	END

	DROP TABLE #Customer
END
GO