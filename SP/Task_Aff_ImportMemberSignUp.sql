USE [Affiliate_12bet]
GO

/****** Object:  StoredProcedure [dbo].[Task_Aff_ImportMemberSignUp]    Script Date: 01/19/2015 23:22:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_Aff_ImportMemberSignUp    Script Date: 8/6/2014 10:44:39 AM ******/
CREATE PROCEDURE [dbo].[Task_Aff_ImportMemberSignUp]
AS
/*
  Task: Import Member SignUp
  Author : Bobby
  Date : 2014-08-01
  DB: DB052.Affiliate_12BET
  Revisions:    
	- 20140801@Bobby: Add SP
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @CalculateTime SMALLDATETIME --Subtract 7 days

	SELECT @CalculateTime = DATEADD(DD, - 7, CURRENT_TIMESTAMP);

	WITH depCustByTime
	AS (
		SELECT DepositCustID AS custid
		FROM dbo.[MemberClickDetail](NOLOCK)
		WHERE CreatedDate > = @CalculateTime
		)
		,MemberSingup
	AS (
		SELECT d.AffiliateId AS AffID
			,d.CreatDate AS CreatedDate
			,d.custid AS DepositCustID
			,d.IBCCustID
			,d.ClickId
			,ISNULL(c.DomainReferrer, 'none') AS DomainReferrer
			,c.LanguageCode
			,c.SportCode
			,c.RedirectURL AS URLRedirect
			,c.URLReferrer
			,c.DeviceType
		FROM [DBDeposit].deposit_db.dbo.Deposit_Customer d WITH (NOLOCK) --For live code
			INNER JOIN dbo.ClickStatistics1 c WITH(NOLOCK) 
			ON d.AffiliateId = c.AffID	AND d.ClickId = c.ClickId
			LEFT JOIN depCustByTime dep 
			ON d.custid = dep.custid
		WHERE d.AffiliateId > 0
			AND d.ClickId > 0
			AND d.CreatDate >= @CalculateTime
			AND c.[Date] >= @CalculateTime
			AND dep.custid IS NULL
		)
	INSERT INTO [dbo].[MemberClickDetail] ([DepositCustID]
		,[ClickId]
		,[DomainReferrer]
		,[LanguageCode]
		,[SportCode]
		,[URLRedirect]
		,[URLReferrer]
		,[DeviceType]
		,[AffID]
		,[CreatedDate]
		,[IBCCustID]
		)
	SELECT s.[DepositCustID]
		,s.[ClickId]
		,s.[DomainReferrer]
		,s.[LanguageCode]
		,s.[SportCode]
		,s.[URLRedirect]
		,s.[URLReferrer]
		,s.[DeviceType]
		,s.[AffID]
		,s.[CreatedDate]
		,s.[IBCCustID]
		FROM MemberSingup s;
			
END
GO

GRANT EXECUTE ON [dbo].[Task_Aff_ImportMemberSignUp] TO [Dot_Member] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_ImportMemberSignUp] TO [vnteam] AS [dbo]
GO


