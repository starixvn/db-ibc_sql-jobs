/*<info serverAlias="DBAFFN88-Affiliate_N88" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_ImportData_Job]
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Job - Import data for rptMemberDaily

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN 
	SET NOCOUNT ON

	DECLARE	@FromDate		SMALLDATETIME
			,@ToDate		SMALLDATETIME
			,@CurrentDate	SMALLDATETIME = CONVERT(DATE, GETDATE())
			,@WinlostDate	SMALLDATETIME
			,@Retry			TINYINT = 1
			,@IsErr			BIT
			,@ErrMsg		NVARCHAR(2000)

	-- Gen data whole month, if the date in 1,2,3,4 --> start from last month
	IF DAY(@CurrentDate) IN (1, 2, 3, 4)
		SELECT @FromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDate) - 1, 0)
	ELSE
		SELECT @FromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDate), 0)

	SELECT @ToDate = CONVERT(DATE, GETDATE())

	SELECT @WinlostDate = @FromDate
	WHILE  @WinlostDate <= @ToDate
	BEGIN
		-- 3rd products
		SELECT @Retry = 1, @IsErr = 1
		WHILE  @Retry <= 3
		BEGIN
			BEGIN TRY
				EXEC dbo.Task_Aff_ImportData @WinlostDate = @WinlostDate
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
			SELECT @ErrMsg = 'SQL Server Job System: ''' + DB_NAME() + ': Generate Data Daily'' failed on ' + @@SERVERNAME
						+ ' with @WinlostDate = ' + CONVERT(VARCHAR(10), @WinlostDate, 120)
			RAISERROR (@ErrMsg, 16, 1)
		END

		-- next winlostdate
		SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
	END
END
GO