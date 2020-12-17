/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_MemberInfo_Import]
	@XmlData	XML
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	VARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Job (web call) - Import member info

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20201117@Percy: Rescan member from last 2 hours [RedmineID: #145506]
		- 20201118@Percy: Get AffId from AffCode [RedmineID: #143852]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @ErrCode = 0, @ErrMsg = ''

	DECLARE @SiteName VARCHAR(30), @BrandName VARCHAR(30), @TimeZone INT
	SELECT  @SiteName = dbo.Aff_f_GetSetting('SiteName'), @BrandName = dbo.Aff_f_GetSetting('BrandName'), @TimeZone = dbo.Aff_f_GetSetting('TimeZone')

	CREATE TABLE #MemberInfo
	(
		CustId		INT
		,UserName	VARCHAR(30)
		,CurrencyId	INT
		,ActStatus	TINYINT
		,AffId		INT
		,AffCode	VARCHAR(20)
		,RegTime	DATETIME
		,Status		TINYINT
		,IsTest		BIT
		,IsValid	BIT DEFAULT(0)
	)

	BEGIN TRY
		INSERT INTO #MemberInfo
		(
			CustId
			,UserName
			,CurrencyId
			,ActStatus
			,AffId
			,AffCode
			,RegTime
			,Status
			,IsTest
		)
		SELECT
			CustId		= t.c.value('@custid', 'INT')
			,UserName	= t.c.value('@username', 'VARCHAR(30)')
			,CurrencyId	= t.c.value('@currencyid', 'INT')
			,ActStatus	= t.c.value('@actstatus', 'TINYINT')
			,AffId		= t.c.value('@affid', 'INT')
			,AffCode	= t.c.value('@affcode', 'VARCHAR(20)')
			,RegTime	= DATEADD(HOUR, @TimeZone, NULLIF(t.c.value('@regtime', 'DATETIME'), ''))
			,Status		= t.c.value('@status', 'TINYINT')
			,IsTest		= t.c.value('@istest', 'BIT')
		FROM @XmlData.nodes('root/row') AS t(c)
		OPTION (OPTIMIZE FOR (@XmlData = NULL))
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 100, @ErrMsg = 'Failed Parse XML data: ' + ERROR_MESSAGE()
		RETURN
	END CATCH

	CREATE CLUSTERED INDEX CIX_CustId ON #MemberInfo (CustId)

	BEGIN
		UPDATE m
		SET m.AffId = ai.AffId, m.IsValid = 1
		FROM #MemberInfo m
			INNER JOIN dbo.AffiliateCode ac WITH (NOLOCK) ON ac.AffCode = m.AffCode
			INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ai.AffId = ac.AffId
		WHERE m.RegTime >= ai.ApprovedDate

		IF EXISTS (SELECT 1 FROM #MemberInfo WHERE AffId IS NOT NULL AND IsValid = 0)
			UPDATE m
			SET m.IsValid = 1
			FROM #MemberInfo m
				INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ai.AffId = m.AffId
			WHERE m.RegTime >= ai.ApprovedDate
				AND m.IsValid = 0

		DELETE #MemberInfo WHERE IsValid = 0

		UPDATE #MemberInfo SET CurrencyId = 20 WHERE IsTest = 1
	END

	-- Insert/update data
	BEGIN
		IF EXISTS (
			SELECT 1
			FROM dbo.MemberInfo mi WITH (NOLOCK)
			WHERE EXISTS (SELECT 1 FROM #MemberInfo m WHERE mi.CustId = m.CustId)
		)
		BEGIN
			UPDATE mi WITH (ROWLOCK)
			SET mi.CustId			= m.CustId
				,mi.UserName		= m.UserName
				,mi.Currency		= m.CurrencyId
				,mi.ActStatus		= m.ActStatus
				,mi.Status			= m.Status
				,mi.RegisteredDate	= m.RegTime
				,mi.AffId			= m.AffId
			FROM dbo.MemberInfo mi
				INNER JOIN #MemberInfo m ON mi.CustId = m.CustId
		END

		INSERT INTO dbo.MemberInfo
		(
			CustId
			,UserName
			,Currency
			,ActStatus
			,Status
			,RegisteredDate
			,AffId
			,IsRemoved
		)
		SELECT
			CustId
			,UserName
			,CurrencyId
			,ActStatus
			,Status
			,RegTime
			,AffId
			,0 AS IsRemoved
		FROM #MemberInfo m
		WHERE NOT EXISTS (SELECT 1 FROM dbo.MemberInfo mi WITH (NOLOCK) WHERE m.CustId = mi.CustId)
	END

	DECLARE @MemberInfoLastImportedTime DATETIME
	SELECT  @MemberInfoLastImportedTime = MAX(RegTime) FROM #MemberInfo
	SELECT  @MemberInfoLastImportedTime = DATEADD(HOUR, -@TimeZone-2, @MemberInfoLastImportedTime)

	IF @MemberInfoLastImportedTime IS NOT NULL
		UPDATE dbo.SystemSettings WITH (ROWLOCK)
		SET SValue = CONVERT(VARCHAR(20), @MemberInfoLastImportedTime, 120)
		WHERE SName = 'MemberInfoLastImportedTime'

	DROP TABLE #MemberInfo
END
GO