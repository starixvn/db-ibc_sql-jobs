/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Task_CS_HeadlineBalance_CheckAndCorrect_Job]	
AS
/*
	Creator: 20191011@Sophia 
	Remark: Daily Check and correct CN88 Headline balance after Movebet
	DB: DBTXN-bodb02

	Revisions:
		- 20191011@Sophia: initial SP [Redmine: #117863]
 

	 
*/

BEGIN 
	SET NOCOUNT ON

	DECLARE @MoveBetSchedule TABLE (RowId TINYINT IDENTITY(1,1), ScheduleId TINYINT, MoveBetsDay DATE)
	INSERT INTO @MoveBetSchedule (ScheduleId, MoveBetsDay)
	EXEC bodb02.dbo.Task_MoveBetsDayByScheduleSel
	
	DECLARE @tblErrMsg TABLE (WinlostDate SMALLDATETIME, ErrMsg VARCHAR(1000))

	DECLARE @RowId TINYINT, @WinlostDate SMALLDATETIME
	SELECT  @RowId = 1, @WinlostDate = MoveBetsDay FROM @MoveBetSchedule WHERE RowId = 1

	WHILE @WinlostDate IS NOT NULL
	BEGIN
		BEGIN TRY
			EXEC dbo.Task_CS_HeadlineBalance_CheckAndCorrect @WinlostDate = @WinlostDate, @IsCheckDataOnly = 0
		END TRY
		BEGIN CATCH
			INSERT INTO @tblErrMsg (WinlostDate, ErrMsg)
			SELECT @WinlostDate,  ERROR_MESSAGE()
		END CATCH
		
		SELECT @RowId = @RowId + 1, @WinlostDate = NULL
		SELECT @WinlostDate = MoveBetsDay FROM @MoveBetSchedule WHERE RowId = @RowId
	END

	IF EXISTS (SELECT 1 FROM @tblErrMsg)
	BEGIN
		DECLARE @ErrMsg VARCHAR(2000) = 'Failed to check and correct data'
		SELECT	@ErrMsg = @ErrMsg + CHAR(13) + CONVERT(VARCHAR(10), WinlostDate, 120) + ' - Headline Balance - ' + ErrMsg
		FROM @tblErrMsg

		RAISERROR (@ErrMsg, 16, 1)
	END
END
GO