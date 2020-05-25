/*<info serverAlias="DBRMS-bodb_RMS" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_RMS_CopyData_Job]	
AS

/*
	Created: 20200512@Percy
	DB: DBRMS-bodb_RMS
	Task: RMS - Copy data

	Revisions:
		- 20200512@Percy: Initialize SP [RedmineID: #130275]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @FromDate SMALLDATETIME, @ToDate SMALLDATETIME
	DECLARE @winlostdate SMALLDATETIME, @ErrCode INT, @ErrMsg VARCHAR(4000)
	DECLARE @tblErrMsg TABLE (TableName VARCHAR(300), ErrMsg VARCHAR(4000))

	-- rmBettrans --> rmBettrans_Old
	BEGIN
		SELECT @FromDate = NULL, @ToDate = NULL, @winlostdate = NULL, @ErrCode = 0, @ErrMsg = ''

		SELECT  @FromDate = MIN(winlostdate) FROM dbo.rmBettrans WITH (NOLOCK)
		SELECT  @ToDate = DATEADD(DAY, -1, CONVERT(DATE, GETDATE()))

		SELECT @winlostdate = @FromDate
		WHILE  @winlostdate <= @ToDate
		BEGIN
			EXEC dbo.Task_RMS_CopyData_rmBettrans @winlostdate = @winlostdate, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

			IF @ErrCode > 0
			BEGIN
				INSERT INTO @tblErrMsg (TableName, ErrMsg)
				SELECT 'rmBettrans_Old', 'From winlostdate = ''''' + CONVERT(VARCHAR(10), @winlostdate, 120) + '''' + ' - ' + ISNULL(@ErrMsg , '')

				BREAK
			END

			SELECT @winlostdate = DATEADD(DAY, 1, @winlostdate)
		END
	END

	-- rmSumWinloss --> rmSumWinloss_Old
	BEGIN
		SELECT @FromDate = NULL, @ToDate = NULL, @winlostdate = NULL, @ErrCode = 0, @ErrMsg = ''

		SELECT  @FromDate = MIN(winlostdate), @ToDate = MAX(winlostdate) FROM DBTXN.bodb02.dbo.Task_ArchiveDate WITH (NOLOCK)

		DECLARE @maxSumDate DATETIME
		SELECT	@maxSumDate = MAX(winlostdate) FROM bodb_RMS.dbo.rmSumWinloss_Old WITH (NOLOCK)
		SELECT  @maxSumDate = DATEADD(DAY, 1, @maxSumDate)

		SELECT @winlostdate = @FromDate
		WHILE  @winlostdate <= @ToDate
		BEGIN
			EXEC dbo.Task_RMS_CopyData_rmSumWinloss @winlostdate = @winlostdate, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

			IF @ErrCode > 0
			BEGIN
				INSERT INTO @tblErrMsg (TableName, ErrMsg)
				SELECT 'rmSumWinloss_Old', 'From winlostdate = ''''' + CONVERT(VARCHAR(10), @winlostdate, 120) + '''' + ' - ' + ISNULL(@ErrMsg , '')

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

		SELECT @ErrMsg = 'Failed to COPY data' + CHAR(13) + @ErrMsg

		RAISERROR (@ErrMsg, 16, 1)
		RETURN
	END
END
GO