/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_Aff_Member_Ins]
	@AffId			INT = NULL,
	@CreatedDate	DATETIME = NULL
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Import member info from deposit DB

	Revisions:
		- 20180601@Percy: Initiliaze SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @FromCreatedDate DATETIME, @ToCreatedDate DATETIME
	SELECT  @FromCreatedDate = ISNULL(@CreatedDate, DATEADD(DAY, -1, CONVERT(DATE, GETDATE())))
	SELECT  @ToCreatedDate	 = DATEADD(DAY, 1, @FromCreatedDate)

	CREATE TABLE #MemberInfo
	(
		IBCCustId INT PRIMARY KEY, DepositCustId INT, AffId INT, UserName NVARCHAR(50), IBCUserName NVARCHAR(50),
		FirstName NVARCHAR(50), LastName NVARCHAR(50), Currency INT, recommend INT, Email NVARCHAR(100),
		RegisteredDate SMALLDATETIME, ClickId BIGINT
	)
	
	-- Get member info from Deposit DB
	IF ISNULL(@AffId, 0) = 0
	BEGIN
		INSERT INTO #MemberInfo
		(
			IBCCustId, DepositCustId, AffId, UserName, IBCUserName,
			FirstName, LastName, Currency, recommend, Email,
			RegisteredDate, ClickId
		)
		SELECT
			IBCCustId, CustId, AffiliateId, UserName, IBCUserName,
			FirstName, LastName, Currency, IBCAgentID, Email,
			creatdate, ClickId
		FROM DBDeposit.Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
		WHERE creatdate >= @FromCreatedDate AND creatdate < @ToCreatedDate
			AND AffiliateId > 0
			AND ActStatus IN (2, 9)
			AND IBCCustId IS NOT NULL
	END
	ELSE
	BEGIN
		INSERT INTO #MemberInfo
		(
			IBCCustId, DepositCustId, AffId, UserName, IBCUserName,
			FirstName, LastName, Currency, recommend, Email,
			RegisteredDate, ClickId
		)
		SELECT
			IBCCustId, CustId, AffiliateId, UserName, IBCUserName,
			FirstName, LastName, Currency, IBCAgentID, Email,
			creatdate, ClickId
		FROM DBDeposit.Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
		WHERE creatdate >= @FromCreatedDate AND creatdate < @ToCreatedDate
			AND AffiliateId = @AffId
			AND ActStatus IN (2, 9)
			AND IBCCustId IS NOT NULL
	END

	-- Remove exists members
	DELETE m
	FROM #MemberInfo m
		INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON m.IBCCustId = mi.IBCCustId

	-- Import data
	IF EXISTS(SELECT 1 FROM #MemberInfo)
	BEGIN
		-- MemberInfo
		INSERT INTO dbo.MemberInfo
		(
			IBCCustId,AffId,UserName,IBCUserName,CreatedDate,RegisteredDate,IsRemoved,
			DepositCustId,FirstName,LastName,Currency,Email,recommend,ClickId
		)
		SELECT
			m.IBCCustId,m.AffId,'12bet$' + m.UserName,m.IBCUserName,c.creatdate,m.RegisteredDate,0,
			m.DepositCustId,m.FirstName,m.LastName,m.Currency,m.Email,m.recommend,m.ClickId
		FROM #MemberInfo m
			LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON m.IBCCustId = c.custid

		DELETE #MemberInfo
		WHERE ISNULL(ClickId, 0) = 0
	
		-- MemberClickDetail
		MERGE dbo.MemberClickDetail AS TARGET
		USING
		(
			SELECT
				m.DepositCustId,m.ClickId,ISNULL(c.DomainReferrer, 'none') AS DomainReferrer,c.LanguageCode,c.SportCode,
				c.RedirectURL,c.URLReferrer,ISNULL(c.DeviceType, 0) AS DeviceType,m.AffId,m.RegisteredDate,m.IBCCustId
			FROM #MemberInfo m
				LEFT JOIN dbo.ClickStatistics1 c WITH (NOLOCK) ON m.ClickId = c.ClickId
		) AS SOURCE
			ON TARGET.DepositCustId = SOURCE.DepositCustId
		WHEN MATCHED THEN UPDATE
			SET IBCCustId = SOURCE.IBCCustId
		WHEN NOT MATCHED BY TARGET THEN INSERT
			(
				DepositCustId,ClickId,DomainReferrer,LanguageCode,SportCode,
				URLRedirect,URLReferrer,DeviceType,AffId,CreatedDate,IBCCustId
			)
			VALUES
			(
				DepositCustId,ClickId,DomainReferrer,LanguageCode,SportCode,
				RedirectURL,URLReferrer,DeviceType,AffId,RegisteredDate,IBCCustId
			);
	END

	DROP TABLE #MemberInfo
END
GO