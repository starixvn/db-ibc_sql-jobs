/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DailySummaryLicPromotion_CheckData_Job]
AS
/*
	Created: 20191203@Bobby
	Task: Implement Job to check and Correct Promotion data
	DB: DBLIC.bodb_LicenseeReport

	Revisions:
		- 20191203@Bobby: Initialize [Redmine: #119538]

	Param's Explanation:

	Sample execution:
		- EXEC [dbo].[Task_DailySummaryLicPromotion_CheckData_Job]
*/
BEGIN
	DECLARE @CurrentBU_Date SMALLDATETIME
		,@CurrentMB_Date	SMALLDATETIME
		,@Winlostdate		DATE

	DECLARE @BalanceUpDays AS TABLE (BalanceUpDay DATE, MoveBetDay DATE)
	
	-- GET BU & MB Dates
	INSERT INTO @BalanceUpDays (BalanceUpDay, MoveBetDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @CurrentBU_Date	= BalanceUpDay
		,@CurrentMB_Date	= MoveBetDay
	FROM @BalanceUpDays

	-- INIT from BU day
	SELECT @Winlostdate = @CurrentBU_Date

	-- START Process
	WHILE @Winlostdate <= @CurrentMB_Date
	BEGIN
		SELECT @Winlostdate AS [@Winlostdate]
		EXEC [dbo].[Task_DailySummaryLicPromotion_CheckData] 
			@Winlostdate		= @Winlostdate,
			@TimeZone			= 8,
			@IsCheckDataOnly	= 0

		SET @Winlostdate = DATEADD(DD, 1, @Winlostdate)
	END
END
GO