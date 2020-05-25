/*<info serverAlias="DBRMS-bodb_RMS" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_RMS_SumData_Job]
AS

/*
	Created: 20200512@Percy
	DB: DBRMS-bodb_RMS
	Task: RMS - Sum data

	Revisions:
		- 20200512@Percy: Initialize SP [RedmineID: #130275]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @FromDate SMALLDATETIME, @ToDate SMALLDATETIME
	DECLARE @winlostdate SMALLDATETIME, @ErrCode INT, @ErrMsg NVARCHAR(4000)
	DECLARE @tblErrMsg TABLE (TableName VARCHAR(300), ErrMsg VARCHAR(4000))

	-- rmSum_Winloss
	BEGIN
		SELECT @FromDate = NULL, @ToDate = NULL, @winlostdate = NULL, @ErrCode = 0, @ErrMsg = ''

		DECLARE @MBSchedule TABLE (winlostdate SMALLDATETIME)
		INSERT INTO @MBSchedule (winlostdate)
		EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel

		SELECT @FromDate = MIN(winlostdate), @ToDate = MAX(winlostdate) FROM @MBSchedule
		
		SELECT @winlostdate = @FromDate
		WHILE  @winlostdate <= @ToDate
		BEGIN
			SELECT @ErrCode = 0, @ErrMsg = ''

			EXEC dbo.Task_RMS_SumData_rmSumWinloss @winlostdate = @winlostdate, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

			IF @ErrCode > 0
			BEGIN
				INSERT INTO @tblErrMsg (TableName, ErrMsg)
				SELECT 'rmSumWinloss', 'From winlostdate = ''''' + CONVERT(VARCHAR(10), @winlostdate, 120) + '''' + ' - ' + ISNULL(@ErrMsg , '')

				BREAK
			END

			SELECT @winlostdate = DATEADD(DAY, 1, @winlostdate)
		END
	END

	-- rmSumByEventBettype
	BEGIN
		SELECT @FromDate = NULL, @ToDate = NULL, @winlostdate = NULL, @ErrCode = 0, @ErrMsg = ''

		DECLARE @MBBU TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
		INSERT INTO @MBBU (BalanceUpDay, MoveBetsDay)
		EXEC bodb02.dbo.Age_SelBalanceUpDay

		DECLARE @BalanceUpDay SMALLDATETIME, @MoveBetsDay SMALLDATETIME
		SELECT  @BalanceUpDay = BalanceUpDay, @MoveBetsDay = MoveBetsDay FROM @MBBU

		SELECT  @FromDate = @BalanceUpDay, @ToDate = CONVERT(DATE, GETDATE())

		IF DATEPART(DAY, @ToDate) = 7
			SELECT @winlostdate = DATEADD(DAY, -8, @winlostdate)

		SELECT @winlostdate = @FromDate
		WHILE  @winlostdate <= @ToDate
		BEGIN
			SELECT @ErrCode = 0, @ErrMsg = ''

			EXEC dbo.Task_RMS_SumData_rmSumByEventBettype @winlostdate = @winlostdate, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
			
			IF @ErrCode > 0
			BEGIN
				INSERT INTO @tblErrMsg (TableName, ErrMsg)
				SELECT 'rmSumByEventBettype', 'From winlostdate = ''''' + CONVERT(VARCHAR(10), @winlostdate, 120) + '''' + ' - ' + ISNULL(@ErrMsg , '')

				BREAK
			END

			SELECT @winlostdate = DATEADD(DAY, 1, @winlostdate)
		END
	END

	IF EXISTS (SELECT 1 FROM @tblErrMsg)
	BEGIN
		SELECT @ErrMsg = NULL
		SELECT @ErrMsg = COALESCE(@ErrMsg + CHAR(13), '') + TableName + ' - ' + ErrMsg
		FROM @tblErrMsg

		SELECT @ErrMsg = 'Failed to SUM data' + CHAR(13) + @ErrMsg

		RAISERROR (@ErrMsg, 16, 1)
		RETURN
	END
END
GO