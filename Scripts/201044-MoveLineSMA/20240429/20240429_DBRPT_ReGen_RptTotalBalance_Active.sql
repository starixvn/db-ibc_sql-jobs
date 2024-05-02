/*<info serverAlias="DBRPT-bodb_Report" isNested="1"></info>*/
/*
	Created by: 20240429@Bobby
	Task: 201044 - Move SMA lines
	DB: DBTXN.bodb02
		
*/

--TODO: Run script after moving SMA done on bettrans, transfer COMPLETED
USE bodb_Report;
GO
BEGIN

	SET NOCOUNT ON;

	DECLARE @CurrentBU_Date SMALLDATETIME
		,@CurrentMB_Date	SMALLDATETIME
		,@tmpWinlostDate	SMALLDATETIME
		,@Today				SMALLDATETIME
		,@startTime			DATETIME;

		
	-- GET BU & MB Dates
	DECLARE @BalanceUpDays AS TABLE (BalanceUpDay DATE, MoveBetDay DATE)
	INSERT INTO @BalanceUpDays (BalanceUpDay, MoveBetDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @CurrentBU_Date	= BalanceUpDay
		,@CurrentMB_Date	= MoveBetDay
	FROM @BalanceUpDays

	
	--TODO: ReGen RptTotalBalance_Active
	SELECT @Today			= CAST(GETDATE() AS DATE)
		,@tmpWinlostDate	= @CurrentMB_Date

	WHILE @tmpWinlostDate <= @Today
	BEGIN
		SET @startTime = GETDATE();
		EXEC dbo.[Task_DailyRptTotalBalance_Active]
			@Winlostdate = @tmpWinlostDate

		PRINT CONCAT('running RptTotalBalance_Active------> @tmpWinlostDate=', FORMAT(@tmpWinlostDate, 'yyyy-MM-dd'), ', @Duration=', DATEDIFF(SECOND, @startTime, GETDATE()));
		SELECT @tmpWinlostDate = DATEADD(DAY, 1, @tmpWinlostDate)
	END
END
GO