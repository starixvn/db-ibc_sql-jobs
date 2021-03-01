/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_N88_SumWinloss_Job]
AS

/*
	Created: 20210218@Percy
	DB: DBN88-bodb_N88
	Task: Job - Import data for N88_SumWinloss

	Revisions:
		- 20210218@Percy: Initialize SP [RedmineID: #150398]
*/

BEGIN 

	SET NOCOUNT ON

	DECLARE	@FromDate		SMALLDATETIME
			,@ToDate		SMALLDATETIME
			,@CurrentDate	SMALLDATETIME = CONVERT(DATE, GETDATE())
			,@WinlostDate	SMALLDATETIME
			,@Retry			TINYINT = 1
			,@MaxRetry		TINYINT = 3
			,@IsErr			BIT
			,@ErrMsg		NVARCHAR(2000)

	-- Gen data whole month, if the date in 1,2,3,4 --> start from last month
	IF DAY(@CurrentDate) IN (1, 2, 3, 4)
		SELECT @FromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDate) - 1, 0)
	ELSE
		SELECT @FromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDate), 0)

	SELECT @ToDate = @CurrentDate

	SELECT @WinlostDate = @FromDate
	WHILE  @WinlostDate <= @ToDate
	BEGIN
		SELECT @ErrMsg = 'SQL Server Job System: ''bodb_N88: Generate daily data for N88_SumWinloss'' failed on' + @@SERVERNAME
						+ ' with @WinlostDate = ' + CONVERT(VARCHAR(10), @WinlostDate, 120)
		
		SELECT @Retry = 1, @IsErr = 1
		WHILE  @Retry <= @MaxRetry
		BEGIN
			BEGIN TRY
				EXEC dbo.Task_N88_SumWinloss @WinlostDate = @WinlostDate
				SELECT @IsErr = 0
				BREAK
			END TRY
			BEGIN CATCH
				SELECT @Retry = @Retry + 1
				WAITFOR DELAY '000:00:05.280'
			END CATCH
		END

		IF @IsErr = 1
		BEGIN
			SELECT @ErrMsg = @ErrMsg
			RAISERROR (@ErrMsg, 16, 1)
		END

		SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
	END
END
GO