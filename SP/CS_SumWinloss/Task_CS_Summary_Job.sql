/*<info serverAlias="DBSUM-bodb_Summary" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_CS_Summary_Job]
AS

/*
	Created: 20190809@Percy
	Task: Gen data for CS_SumCancelled/CS_SumWinloss - Job
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20190809@Percy: Initialize SP [RedmineID: #116925]
*/

BEGIN 
	SET NOCOUNT ON

	DECLARE @tblErrMsg TABLE (WinlostDate SMALLDATETIME, TableName VARCHAR(30), ErrMsg VARCHAR(1000))

	DECLARE @MBBU TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	INSERT INTO @MBBU (BalanceUpDay, MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay
	
	DECLARE @WinlostDate SMALLDATETIME, @Yesterday SMALLDATETIME
	SELECT  @WinlostDate = DATEADD(DAY, 1, MoveBetsDay), @Yesterday = DATEADD(DAY, -1, CONVERT(SMALLDATETIME, GETDATE())) FROM @MBBU

	WHILE @WinlostDate <= @Yesterday
	BEGIN
		BEGIN TRY
			EXEC dbo.Task_CS_SumCancelled @WinlostDate = @WinlostDate
		END TRY
		BEGIN CATCH
			INSERT INTO @tblErrMsg (WinlostDate, TableName, ErrMsg)
			SELECT @WinlostDate, 'CS_SumCancelled', ERROR_MESSAGE()
		END CATCH

		BEGIN TRY
			EXEC dbo.Task_CS_SumWinloss @WinlostDate = @WinlostDate
		END TRY
		BEGIN CATCH
			INSERT INTO @tblErrMsg (WinlostDate, TableName, ErrMsg)
			SELECT @WinlostDate, 'CS_SumWinloss', ERROR_MESSAGE()
		END CATCH

		SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
	END

	IF EXISTS (SELECT 1 FROM @tblErrMsg)
	BEGIN
		DECLARE @ErrMsg VARCHAR(2000) = 'Failed to generate data'
		SELECT	@ErrMsg = @ErrMsg + CHAR(13) + CONVERT(VARCHAR(10), WinlostDate, 120) + ' - ' + TableName + ' - ' + ErrMsg
		FROM @tblErrMsg

		RAISERROR (@ErrMsg, 16, 1)
	END
END
GO