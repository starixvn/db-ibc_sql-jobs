/*<info serverAlias="DBSUM-bodb_Summary" executers="" isFunction="0" isNested="0"></info>*/
USE [bodb_Summary]
GO

ALTER PROCEDURE [dbo].[Task_CS_Summary_CheckAndCorrect_Job]
AS

/*
	Created: 20190809@Percy
	Task: Check and Correct data for CS_SumCancelled/CS_SumWinloss - Job
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20190809@Percy: Initialize SP [RedmineID: #116925]
*/

BEGIN 
	SET NOCOUNT ON

	DECLARE @MoveBetSchedule TABLE (RowId TINYINT IDENTITY(1,1), ScheduleId TINYINT, MoveBetsDay DATE)
	INSERT INTO @MoveBetSchedule (ScheduleId, MoveBetsDay)
	EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel
	
	DECLARE @tblErrMsg TABLE (WinlostDate SMALLDATETIME, TableName VARCHAR(30), ErrMsg VARCHAR(1000))

	DECLARE @RowId TINYINT, @WinlostDate SMALLDATETIME
	SELECT  @RowId = 1, @WinlostDate = MoveBetsDay FROM @MoveBetSchedule WHERE RowId = 1

	WHILE @WinlostDate IS NOT NULL
	BEGIN
		BEGIN TRY
			EXEC dbo.Task_CS_SumCancelled_CheckAndCorrect @WinlostDate = @WinlostDate, @IsCheckDataOnly = 0
		END TRY
		BEGIN CATCH
			INSERT INTO @tblErrMsg (WinlostDate, TableName, ErrMsg)
			SELECT @WinlostDate, 'CS_SumCancelled', ERROR_MESSAGE()
		END CATCH

		BEGIN TRY
			EXEC dbo.Task_CS_SumWinloss_CheckAndCorrect @WinlostDate = @WinlostDate, @IsCheckDataOnly = 0
		END TRY
		BEGIN CATCH
			INSERT INTO @tblErrMsg (WinlostDate, TableName, ErrMsg)
			SELECT @WinlostDate, 'CS_SumWinloss', ERROR_MESSAGE()
		END CATCH

		SELECT @RowId = @RowId + 1, @WinlostDate = NULL
		SELECT @WinlostDate = MoveBetsDay FROM @MoveBetSchedule WHERE RowId = @RowId
	END

	IF EXISTS (SELECT 1 FROM @tblErrMsg)
	BEGIN
		DECLARE @ErrMsg VARCHAR(2000) = 'Failed to check and correct data'
		SELECT	@ErrMsg = @ErrMsg + CHAR(13) + CONVERT(VARCHAR(10), WinlostDate, 120) + ' - ' + TableName + ' - ' + ErrMsg
		FROM @tblErrMsg

		RAISERROR (@ErrMsg, 16, 1)
	END
END
GO