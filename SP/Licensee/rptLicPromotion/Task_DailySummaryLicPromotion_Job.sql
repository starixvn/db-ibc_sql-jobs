/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DailySummaryLicPromotion_Job]
AS
/*
	Created: 20191203@Bobby
	Task: Implement Job to check and Correct Promotion data
	DB: DBLIC.bodb_LicenseeReport

	Revisions:
		- 20191203@Bobby: Initialize [Redmine: #119538]

	Param's Explanation:

	Sample execution:
		- EXEC [dbo].[Task_DailySummaryLicPromotion_Job]
*/
BEGIN
	DECLARE @CurrentBU_Date SMALLDATETIME
		,@CurrentMB_Date	SMALLDATETIME
		,@Today				DATE
		,@PromoDate			DATE
		,@Error				INT
		,@Message			VARCHAR(200)

	DECLARE @BalanceUpDays AS TABLE (BalanceUpDay DATE, MoveBetDay DATE)
	
	-- GET BU & MB Dates
	INSERT INTO @BalanceUpDays (BalanceUpDay, MoveBetDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @CurrentBU_Date	= BalanceUpDay
		,@CurrentMB_Date	= MoveBetDay
	FROM @BalanceUpDays

	-- INIT from BU day
	SELECT @Today		= GETDATE() 
		, @PromoDate	= DATEADD(DD, 1, CAST(@CurrentMB_Date AS DATETIME))

	-- START Process
	WHILE @PromoDate < @Today
	BEGIN
		SELECT @PromoDate AS [@PromoDate]
		EXEC [dbo].[Task_DailySummaryLicPromotion] 
			@PromoDate			= @PromoDate,
			@TimeZone			= 8,
			@IsCheckDataOnly	= 0,
			@Error				= @Error OUTPUT,
			@Message			= @Message OUTPUT

		IF (@Error > 0)
		BEGIN 
			SET @Message = 'Summary promotion data FAILED: ' + @Message
			RAISERROR(@Message, 16, 1)
			RETURN
		END
		SET @PromoDate = DATEADD(DD, 1, @PromoDate)
	END

	EXEC [dbo].[Task_DailySummaryLicPromotion_CheckData] 
		@TimeZone			= 8,
		@IsCheckDataOnly	= 0,
		@Error				= @Error OUTPUT,
		@Message			= @Message OUTPUT

	IF (@Error > 0)
	BEGIN 
		SET @Message = 'Checking promotion data FAILED: ' + @Message
		RAISERROR(@Message, 16, 1)
		RETURN
	END
END
GO