USE [Affiliate_12bet]
GO

/****** Object:  StoredProcedure [dbo].[Task_Aff_CustomerInsMember]    Script Date: 01/19/2015 23:54:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_Aff_CustomerInsMember    Script Date: 10/14/2014 9:51:10 AM ******/
CREATE PROCEDURE [dbo].[Task_Aff_CustomerInsMember] 
	@AffId 			INT				= NULL
	,@CreatedDate 	SMALLDATETIME 	= NULL
AS
/*  
Created: 20120704@Johnny
Task : Task Add members are missed in Deposit DB into MemberInfo table
DB: DB052.Affiliate_12BET
Revisions:    
	- 20140708@Bobby: Apply MemberClickDetail info
	- 20140801@Bobby: Update ins MemberClickDetail
	- 20141013@Bobby: Get CreatedDate (FDM) from bodb02

Params Explaination:
	-@CreatedDate: NULL = [current_timestamp]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @CreateToDate SMALLDATETIME;

	-- run to import yesterday missing members  
	SELECT @CreatedDate = ISNULL(@CreatedDate, CAST(DATEADD(DD, -1, CURRENT_TIMESTAMP) AS DATE))
		, @CreateToDate = DATEADD(DD, 1, @CreatedDate)
	
	-- Select member from deposit customer
	SELECT d.IBCCustID
		,AffiliateId AS AffId
		,d.UserName
		,d.IBCUserName
		,NULL AS CreatedDate
		,d.CustId AS DepositCustID
		,d.FirstName
		,d.LastName
		,d.Currency
		,d.IBCAgentID AS Recommend
		,d.Email
		,d.creatdate AS RegisteredDate
		,0 IsRemove
		,d.ClickId
		,ISNULL(c.DomainReferrer, 'none') AS DomainReferrer
		,c.RedirectURL AS URLRedirect
		,c.SportCode
		,c.LanguageCode
		,c.URLReferrer
		,ISNULL(c.DeviceType, 0) DeviceType
	INTO #depositMember
	FROM [DBDeposit].deposit_db.dbo.Deposit_Customer d WITH (NOLOCK)
		LEFT JOIN dbo.ClickStatistics1 c WITH (NOLOCK)
		ON d.ClickID = c.ClickID 
		LEFT JOIN dbo.MemberInfo m WITH (NOLOCK)
		ON d.IBCCustID = m.IBCCustID AND d.AffiliateID = m.AffID
	WHERE (d.CreatDate >= @CreatedDate AND d.creatdate < @CreateToDate)
		AND d.AffiliateId > 0
		AND (
			@Affid IS NULL
			OR d.AffiliateId = @Affid
			)
		AND d.ActStatus IN (2, 9)
		AND d.IBCCustID IS NOT NULL
		AND m.IBCCustID IS NULL

	/*
	Check to update/insert MemberInfo & MemberClickDetail
	*/
	IF EXISTS(SELECT TOP 1 1 FROM #depositMember)
	BEGIN
		-- MemberInfo
		INSERT INTO dbo.MemberInfo (
			[IBCCustID]
			,[AffID]
			,[UserName]
			,[IBCUserName]
			,[CreatedDate]
			,[RegisteredDate]
			,[IsRemoved]
			,[DepositCustID]
			,[FirstName]
			,[LastName]
			,[Currency]
			,[Email]
			,[Recommend]
			,[ClickId]
		)
		SELECT src.IBCCustID
			,src.AffID
			,'12bet$' + src.UserName AS UserName
			,src.IBCUserName
			,c.creatdate AS CreatedDate
			,src.RegisteredDate
			,src.IsRemove
			,src.DepositCustID
			,src.FirstName
			,src.LastName
			,src.Currency
			,src.Email
			,src.Recommend
			,src.ClickId
		FROM #depositMember src
		LEFT JOIN bodb02.dbo.Customer c WITH(NOLOCK)
			ON src.IBCCustID = c.custid
		
		DELETE d
		FROM #depositMember d
		WHERE d.ClickID IS NULL OR d.ClickID = 0
	
		--Ins MemberClickDetail
		MERGE INTO [dbo].[MemberClickDetail] AS t
		USING #depositMember AS s 
			ON t.DepositCustID = s.DepositCustID
				AND s.ClickID > 0
		WHEN MATCHED THEN
			UPDATE 
			SET IBCCustID = s.IBCCustID
		WHEN NOT MATCHED BY TARGET THEN
			INSERT ([DepositCustID]
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
			VALUES (s.[DepositCustID]
				,s.[ClickId]
				,s.[DomainReferrer]
				,s.[LanguageCode]
				,s.[SportCode]
				,s.[URLRedirect]
				,s.[URLReferrer]
				,s.[DeviceType]
				,s.[AffID]
				,s.[RegisteredDate]
				,s.[IBCCustID]
			);
	END

	DROP TABLE #depositMember;
	RETURN;

END
GO

GRANT EXECUTE ON [dbo].[Task_Aff_CustomerInsMember] TO [Dot_Member] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_CustomerInsMember] TO [vnAffiliate] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_CustomerInsMember] TO [vnteam] AS [dbo]
GO


