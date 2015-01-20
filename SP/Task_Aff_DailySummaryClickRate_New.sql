USE [Affiliate_12bet]
GO

/****** Object:  StoredProcedure [dbo].[Task_Aff_DailySummaryClickRate_New]    Script Date: 01/19/2015 23:51:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_Aff_DailySummaryClickRate_New    Script Date: 7/30/2014 5:39:21 PM ******/
CREATE PROCEDURE [dbo].[Task_Aff_DailySummaryClickRate_New] 
@date SMALLDATETIME = NULL
AS
/*
Created: 20120109@Johnny
Task:	Task to summary Click Statistics daily
DB: DBAFF12BET/Affiliate_12BET
Revisions:	
	- @20140214: optimize performance (to use index)
	- 20140613@Bobby: Update @date to 7 days (date backup)
	- 20140708@Bobby: Apply DeviceType to SUM table
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @fromDate SMALLDATETIME
		,@toDate SMALLDATETIME

	SET @date = convert(VARCHAR(10), ISNULL(@date, dateAdd(DD, - 7, current_timestamp)), 120)

	SELECT @fromDate = @date
		,@toDate = DATEADD(DD, 1, @fromdate)

	IF (
			EXISTS (
				SELECT 1
				FROM ClickStatistics1Sum(NOLOCK)
				WHERE @date = [Date]
				)
			)
	BEGIN
		RETURN
	END
			/* 
	--Store Total number of deposit user
	Declare @TmpDeposit as table(AffId int, TotalDeposit int)
	insert into @TmpDeposit(AffId, TotalDeposit)
	Select AffId, Sum(1) as TotalDeposit
	From MemberInfo nolock
	where datediff(d, CreatedDate, @date) = 0
	Group by AffId 
	 */

	--Summary for Daily by Domain and Date
	;WITH clickStats
	AS (
		SELECT AffID
			,DomainReferrer
			,@date AS [Date]
			,DeviceType
			,SportCode
			,LanguageCode
			,sum(1) AS TotalClick
			,count(DISTINCT IP) AS UniqueClick
		FROM ClickStatistics1 c WITH (NOLOCK)
		WHERE [Date] = @date
		GROUP BY AffID
			,DomainReferrer
			,DeviceType
			,SportCode
			,LanguageCode
	)
	INSERT INTO ClickStatistics1Sum (
		AffID
		,[DomainReferrer]
		,[Date]
		,[DeviceType]
		,[SportCode]
		,[LanguageCode]
		,TotalClick
		,UniqueClick
		)
	SELECT c.AffID
		,c.DomainReferrer
		,c.[Date]
		,c.DeviceType
		,c.SportCode
		,c.LanguageCode
		,c.TotalClick
		,c.UniqueClick
	FROM clickStats c

	-- Archive to ClickStatistics1_bk table
	INSERT INTO ClickStatistics1_bk (
		[ClickID]
		,[AffID]
		,[UpdatedTime]
		,[IP]
		,[Date]
		,[Browser]
		,[URLReferrer]
		,[DomainReferrer]
		,[OS]
		,[Device]
		,[BrowserVersion]
		,[BrowserResolution]
		,[BrowserLanguage]
		,[UserAgent]
		,[Country]
		,[LanguageCode]
		,[SportCode]
		,[RedirectURL]
		,[Status]
		,[DeviceType]
		)
	SELECT [ClickID]
		,[AffID]
		,[UpdatedTime]
		,[IP]
		,[Date]
		,[Browser]
		,[URLReferrer]
		,[DomainReferrer]
		,[OS]
		,[Device]
		,[BrowserVersion]
		,[BrowserResolution]
		,[BrowserLanguage]
		,[UserAgent]
		,[Country]
		,[LanguageCode]
		,[SportCode]
		,[RedirectURL]
		,[Status]
		,[DeviceType]
	FROM ClickStatistics1 WITH (NOLOCK)
	WHERE [Date] = @date

	-- remove data from ClickStatistics1
	DELETE ClickStatistics1 WITH (ROWLOCK)
	WHERE [Date] = @date
END
GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_DailySummaryClickRate_New] TO [vnAffiliate] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_DailySummaryClickRate_New] TO [vnteam] AS [dbo]
GO


