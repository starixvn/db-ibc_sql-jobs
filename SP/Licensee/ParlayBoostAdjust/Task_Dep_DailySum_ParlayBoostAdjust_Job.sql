/*<info serverAlias="DBTXN-bodb02" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Dep_DailySum_ParlayBoostAdjust_Job]
AS
/*
	Created: 20230822@Evan
	DB: DBTXN.bodb02
	Task: LAP - Licensee Parlay Boost - Generate new trans for bettype 998 (Parlay Boost Adjustment)

	Revisions:
		- 20230822@Evan: Initialize SP - [RedmineID: #192238]
*/
BEGIN

	SET NOCOUNT ON

	DECLARE @tblErrMsg TABLE (WinlostDate SMALLDATETIME, TableName VARCHAR(30), ErrMsg VARCHAR(1000))

	DECLARE @MBBU TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	INSERT INTO @MBBU (BalanceUpDay, MoveBetsDay)
	EXEC dbo.Age_SelBalanceUpDay
	
	DECLARE @WinlostDate SMALLDATETIME, @Yesterday SMALLDATETIME
	SELECT  @WinlostDate = DATEADD(DAY, 1, MoveBetsDay), @Yesterday = DATEADD(DAY, -1, CONVERT(SMALLDATETIME, GETDATE())) FROM @MBBU

	WHILE @WinlostDate <= @Yesterday
	BEGIN

		BEGIN TRY
			EXEC dbo.Task_Dep_DailySum_ParlayBoostAdjust @WinlostDate = @WinlostDate
		END TRY
		BEGIN CATCH
			INSERT INTO @tblErrMsg (WinlostDate, TableName, ErrMsg)
			SELECT @WinlostDate, 'bettrans', ERROR_MESSAGE()
		END CATCH

		SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)

	END

	IF EXISTS (SELECT 1 FROM @tblErrMsg)
	BEGIN
		DECLARE @ErrMsg VARCHAR(2000) = 'Failed to generate transaction data.'
		SELECT	@ErrMsg = @ErrMsg + CHAR(13) + CONVERT(VARCHAR(10), WinlostDate, 120) + ' - ' + TableName + ' - ' + ErrMsg
		FROM @tblErrMsg

		RAISERROR (@ErrMsg, 16, 1)
	END
END
GO