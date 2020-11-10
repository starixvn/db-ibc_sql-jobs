/*<info serverAlias="DBAFF12BET-Affiliate_12BET" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_ImportData_CheckData_Job]
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Job - Import data of IBC's Products from bettrans (MoveBetsDays)

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20190116@Percy: Send mail if data has mismatch [RedmineID: #107623]
		- 20190716@Percy: Do not run if MB does not run [RedmineID: #116964]
		- 20191206@Percy: Check data 1 time per day [RedmineID: #117197]
*/

BEGIN 
	SET NOCOUNT ON

	DECLARE @checkDate SMALLDATETIME
	SELECT  @checkDate = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CheckData_Bettrans'

	IF @checkDate = CONVERT(DATE, CURRENT_TIMESTAMP) -- check 1 time per day
		RETURN

	-- Check today MB run or not
	DECLARE @MoveBetSchedule TABLE(ScheduleId TINYINT, MoveBetDay DATE)
	
	INSERT INTO @MoveBetSchedule(ScheduleId, MoveBetDay)
	EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel

	IF NOT EXISTS (SELECT TOP 1 1 FROM @MoveBetSchedule)
	BEGIN
		RETURN
	END

	DECLARE @IsMatched BIT = 0, @ProductList VARCHAR(50) = ''
	DECLARE @ErrTable TABLE (WinlostDate SMALLDATETIME, ProductId INT)
	
	DECLARE @winlostdate SMALLDATETIME, @MoveBetsDay SMALLDATETIME, @BalanceUpDay SMALLDATETIME
	DECLARE @MBBUDate TABLE (MoveBetsDay SMALLDATETIME, BalanceUpDay SMALLDATETIME)
	
	INSERT INTO @MBBUDate (MoveBetsDay, BalanceUpDay)
	EXEC bodb02.dbo.Lrf_SelBalanceUpDay
		
	SELECT @MoveBetsDay = MoveBetsDay, @BalanceUpDay = BalanceUpDay
	FROM @MBBUDate
		
	SELECT @winlostdate = @BalanceUpDay
		
	WHILE(@winlostdate <= @MoveBetsDay)
	BEGIN
		SELECT @IsMatched = 0, @ProductList = NULL
		
		EXEC dbo.Task_Aff_ImportData_CheckData @winlostdate = @winlostdate, @isCheckOnly = 0, @IsMatched = @IsMatched OUTPUT, @ProductList = @ProductList OUTPUT

		IF @IsMatched = 0
		BEGIN
			INSERT INTO @ErrTable (WinlostDate, ProductId)
			SELECT @winlostdate, CONVERT(INT, val)
			FROM dbo.Aff_f_StringSplit(@ProductList, ',')
		END

		SELECT @winlostdate = DATEADD(DAY, 1, @winlostdate)
	END

	UPDATE dbo.SystemSettings WITH (ROWLOCK)
	SET SValue = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)
	WHERE SName = 'AFF_CheckData_Bettrans'
END
GO