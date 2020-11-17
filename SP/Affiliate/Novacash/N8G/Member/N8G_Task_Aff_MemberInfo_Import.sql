/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_MemberInfo_Import]
	@XmlData	XML
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	VARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Job (web call) - Import member info

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20201117@Percy: Rescan member from last 2 hours [RedmineID: #145506]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @ErrCode = 0, @ErrMsg = ''

	DECLARE @SiteName VARCHAR(30), @BrandName VARCHAR(30)
	SELECT  @SiteName = dbo.Aff_f_GetSetting('SiteName'), @BrandName = dbo.Aff_f_GetSetting('BrandName')

	CREATE TABLE #Customer
	(
		CustId				INT
		,UserName			VARCHAR(30)
		,CurrencyId			INT
		,ActStatus			TINYINT
		,AffId				INT
		,RegTime			DATETIME
		,FirstDepositDate	DATETIME
		,Status				TINYINT
		,IsTest				BIT
	)

	CREATE TABLE #MemberInfo
	(
		CustId			INT
		,UserName		VARCHAR(30)
		,FirstName		VARCHAR(50)
		,LastName		VARCHAR(50)
		,Email			VARCHAR(50)
		,Currency		INT
		,ActStatus		TINYINT
		,Status			TINYINT
		,RegisteredDate	DATETIME
		,AffId			INT
		,IBCCustId		INT
		,IBCUserName	VARCHAR(30)
		,CreatedDate	DATETIME
		,recommend		INT
	)
	CREATE CLUSTERED INDEX CIX_CustId ON #MemberInfo (CustId)

	BEGIN TRY
		INSERT INTO #Customer
		(
			CustId
			,UserName
			,CurrencyId
			,ActStatus
			,AffId
			,RegTime
			,FirstDepositDate
			,Status
			,IsTest
		)
		SELECT
			CustId				= t.c.value('@custid', 'INT')
			,UserName			= t.c.value('@username', 'VARCHAR(30)')
			,CurrencyId			= t.c.value('@currencyid', 'INT')
			,ActStatus			= t.c.value('@actstatus', 'TINYINT')
			,AffId				= t.c.value('@affid', 'INT')
			,RegTime			= NULLIF(t.c.value('@regtime', 'DATETIME'), '')
			,FirstDepositDate	= NULLIF(t.c.value('@firstdepositdate', 'DATETIME'), '')
			,Status				= t.c.value('@status', 'TINYINT')
			,IsTest				= t.c.value('@istest', 'BIT')
		FROM @XmlData.nodes('root/row') AS t(c)
		OPTION (OPTIMIZE FOR (@XmlData = NULL))
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 100, @ErrMsg = 'Failed Parse XML data: ' + ERROR_MESSAGE()
		RETURN
	END CATCH

	CREATE CLUSTERED INDEX CIX_CustId ON #Customer (CustId)

	BEGIN
		INSERT INTO #MemberInfo
		(
			CustId
			,UserName
			,FirstName
			,LastName
			,Email
			,Currency
			,ActStatus
			,Status
			,RegisteredDate
			,AffId
			,IBCCustId
			,IBCUserName
			,CreatedDate
			,recommend
		)
		SELECT
			c.CustId
			,c.UserName
			,cu.FirstName
			,cu.LastName
			,cu.Email
			,CASE WHEN c.IsTest = 1 THEN 20 ELSE c.CurrencyId END AS Currency
			,c.ActStatus
			,c.Status
			,c.RegTime			AS RegisteredDate
			,c.AffId
			,cu.CustId			AS IBCCustId
			,cu.username		AS IBCUserName
			,c.FirstDepositDate	AS CreatedDate
			,cu.recommend
		FROM #Customer c
			LEFT JOIN bodb02.dbo.Customer cu WITH (NOLOCK) ON @SiteName + '$' + @BrandName + '_' + CONVERT(VARCHAR(20), c.CustId) = cu.username2

		DROP TABLE #Customer
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
				,mi.FirstName		= m.FirstName
				,mi.LastName		= m.LastName
				,mi.Email			= m.Email
				,mi.Currency		= m.Currency
				,mi.ActStatus		= m.ActStatus
				,mi.Status			= m.Status
				,mi.RegisteredDate	= m.RegisteredDate
				,mi.AffId			= m.AffId
				,mi.IBCCustId		= m.IBCCustId
				,mi.IBCUserName		= m.IBCUserName
				,mi.CreatedDate		= m.CreatedDate
				,mi.recommend		= m.recommend
			FROM dbo.MemberInfo mi
				INNER JOIN #MemberInfo m ON mi.CustId = m.CustId
		END

		INSERT INTO dbo.MemberInfo
		(
			CustId
			,UserName
			,FirstName
			,LastName
			,Email
			,Currency
			,ActStatus
			,Status
			,RegisteredDate
			,AffId
			,IBCCustId
			,IBCUserName
			,CreatedDate
			,recommend
			,IsRemoved
		)
		SELECT
			CustId
			,UserName
			,FirstName
			,LastName
			,Email
			,Currency
			,ActStatus
			,Status
			,RegisteredDate
			,AffId
			,IBCCustId
			,IBCUserName
			,CreatedDate
			,recommend
			,0 AS IsRemoved
		FROM #MemberInfo m
		WHERE NOT EXISTS (SELECT 1 FROM dbo.MemberInfo mi WITH (NOLOCK) WHERE m.CustId = mi.CustId)
	END

	DECLARE @MaxRegisteredDate DATETIME, @MaxCreatedDate DATETIME
	SELECT	@MaxRegisteredDate = MAX(RegisteredDate), @MaxCreatedDate = MAX(CreatedDate) FROM #MemberInfo

	DECLARE @MemberInfoLastImportedTime DATETIME
	SELECT  @MemberInfoLastImportedTime = CASE WHEN @MaxRegisteredDate > @MaxCreatedDate THEN @MaxRegisteredDate ELSE @MaxCreatedDate END
	SELECT  @MemberInfoLastImportedTime = DATEADD(HOUR, -2, @MemberInfoLastImportedTime)

	IF @MemberInfoLastImportedTime IS NOT NULL
		UPDATE dbo.SystemSettings WITH (ROWLOCK)
		SET SValue = CONVERT(VARCHAR(20), @MemberInfoLastImportedTime, 120)
		WHERE SName = 'MemberInfoLastImportedTime'

	DROP TABLE #MemberInfo
END
GO