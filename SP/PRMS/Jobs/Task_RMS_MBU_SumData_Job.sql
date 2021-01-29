/*<info serverAlias="DBRMS-bodb_RMS" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_RMS_MBU_SumData_Job]
AS

/*
	Created: 20200512@Percy
	DB: DBRMS-bodb_RMS
	Task: RMS - Sum data

	Revisions:
		- 20200512@Percy: Initialize SP [RedmineID: #130275]
		- 20200601@Percy: Add rmSumByLeague & rmSumByBettype [RedmineID: #135326]
		- 20201214@Danny: Separate Data of Virtual Soccer & Virtual Basketball [RedmineID: #145926]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @FromDate SMALLDATETIME, @ToDate SMALLDATETIME
	DECLARE @winlostdate SMALLDATETIME, @ErrCode INT, @ErrMsg NVARCHAR(4000)
	DECLARE @tblErrMsg TABLE (TableName VARCHAR(300), ErrMsg VARCHAR(4000))
	
	-- Run every 30s
	-- rmSumByLeague/rmSumByBettype
	BEGIN
		SELECT @FromDate = NULL, @ToDate = NULL, @winlostdate = NULL, @ErrCode = 0, @ErrMsg = ''

		DECLARE @MBBU TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
		INSERT INTO @MBBU (BalanceUpDay, MoveBetsDay)
		EXEC bodb02.dbo.Age_SelBalanceUpDay

		DECLARE @BalanceUpDay SMALLDATETIME, @MoveBetsDay SMALLDATETIME
		SELECT  @BalanceUpDay = BalanceUpDay, @MoveBetsDay = MoveBetsDay FROM @MBBU

		-- rmSumByLeague
		SELECT  @FromDate = @BalanceUpDay, @ToDate = CONVERT(DATE, GETDATE())

		SELECT @winlostdate = @FromDate
		WHILE  @winlostdate <= @ToDate
		BEGIN
			SELECT @ErrCode = 0, @ErrMsg = ''

			EXEC dbo.Task_RMS_SumData_rmSumByLeague @winlostdate = @winlostdate, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
			
			IF @ErrCode > 0
			BEGIN
				INSERT INTO @tblErrMsg (TableName, ErrMsg)
				SELECT 'rmSumByLeague', 'From winlostdate = ''''' + CONVERT(VARCHAR(10), @winlostdate, 120) + '''' + ' - ' + ISNULL(@ErrMsg , '')

				BREAK
			END

			SELECT @winlostdate = DATEADD(DAY, 1, @winlostdate)
		END

		-- rmSumByBettype
		SELECT  @FromDate = @BalanceUpDay, @ToDate = CONVERT(DATE, GETDATE())

		SELECT @winlostdate = @FromDate
		WHILE  @winlostdate <= @ToDate
		BEGIN
			SELECT @ErrCode = 0, @ErrMsg = ''

			EXEC dbo.Task_RMS_SumData_rmSumByBettype @winlostdate = @winlostdate, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
			
			IF @ErrCode > 0
			BEGIN
				INSERT INTO @tblErrMsg (TableName, ErrMsg)
				SELECT 'rmSumByBettype', 'From winlostdate = ''''' + CONVERT(VARCHAR(10), @winlostdate, 120) + '''' + ' - ' + ISNULL(@ErrMsg , '')

				BREAK
			END

			SELECT @winlostdate = DATEADD(DAY, 1, @winlostdate)
		END
	END

	-- Run daily
	DECLARE @CurrentTime TIME = CONVERT(TIME, GETDATE())
	
	DECLARE @LastRunJob DATE, @IsUpdate BIT = 0
	SELECT  @LastRunJob = VValue FROM dbo.rmSettings WITH (NOLOCK) WHERE VName = 'rmSumDataMBU'

	IF @CurrentTime >= '05:30' AND @LastRunJob <> CONVERT(DATE, GETDATE())
	BEGIN
		SET @IsUpdate = 1

		-- rmSum_Winloss
		BEGIN
			SELECT @FromDate = NULL, @ToDate = NULL, @winlostdate = NULL, @ErrCode = 0, @ErrMsg = ''

			DECLARE @MBSchedule TABLE (Id TINYINT, winlostdate SMALLDATETIME)
			INSERT INTO @MBSchedule (Id, winlostdate)
			EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel

			SELECT @FromDate = MIN(winlostdate), @ToDate = MAX(winlostdate) FROM @MBSchedule
		
			SELECT @winlostdate = @FromDate
			WHILE  @winlostdate <= @ToDate
			BEGIN
				SELECT @ErrCode = 0, @ErrMsg = ''

				EXEC dbo.Task_RMS_MBU_SumData_rmSumWinloss @winlostdate = @winlostdate, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

				IF @ErrCode > 0
				BEGIN
					INSERT INTO @tblErrMsg (TableName, ErrMsg)
					SELECT 'rmSumWinloss', 'From winlostdate = ''''' + CONVERT(VARCHAR(10), @winlostdate, 120) + '''' + ' - ' + ISNULL(@ErrMsg , '')

					BREAK
				END

				SELECT @winlostdate = DATEADD(DAY, 1, @winlostdate)
			END
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
	ELSE IF @IsUpdate = 1
	BEGIN
		UPDATE dbo.rmSettings WITH (UPDLOCK)
		SET VValue = CONVERT(VARCHAR(10), GETDATE(), 120)
		WHERE VName = 'rmSumDataMBU'
	END
END
GO