/*<info serverAlias="DBTXN-bodb02" isNested="1"></info>*/
/*
	Created by: 20240429@Bobby
	Task: 201044 - Move SMA lines
	DB: DBTXN.bodb02
		
*/

--TODO: Run script after moving SMA done on bettrans14 COMPLETED
USE bodb02;
GO
BEGIN
	DECLARE @CurrentBU_Date SMALLDATETIME
		,@CurrentMB_Date	SMALLDATETIME
		,@_Winlostdate		SMALLDATETIME
		,@_CustIds			VARCHAR(MAX)
		,@startTime			DATETIME;

	-- GET BU & MB Dates
	DECLARE @BalanceUpDays AS TABLE (BalanceUpDay DATE, MoveBetDay DATE)
	INSERT INTO @BalanceUpDays (BalanceUpDay, MoveBetDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @CurrentBU_Date	= BalanceUpDay
		,@CurrentMB_Date	= MoveBetDay
	FROM @BalanceUpDays

	SELECT @_CustIds = STRING_AGG(t.custid, ',')
	FROM (
		SELECT DISTINCT c.custid
		FROM CustDB.dbo.Customer c WITH(NOLOCK)
		WHERE username IN ('USTM','MUSDT','XYZUSDT','231')
	) AS t;

	SET @_Winlostdate = @CurrentBU_Date;
	WHILE (@_Winlostdate <= @CurrentMB_Date)
	BEGIN
		SET @startTime = GETDATE();

		EXEC [dbo].[Task_sum_winloss_14]
			@WinlostDate	= @_Winlostdate
			,@CustIds		= @_CustIds


		PRINT CONCAT('running sum_winloss ------> @_Winlostdate=', FORMAT(@_Winlostdate, 'yyyy-MM-dd'), ', @Duration=', DATEDIFF(SECOND, @startTime, GETDATE()));
		SET @_Winlostdate = DATEADD(DAY, 1, @_Winlostdate);
	END
END