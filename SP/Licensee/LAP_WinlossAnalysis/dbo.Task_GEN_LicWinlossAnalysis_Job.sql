/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_LicenseeReport]
GO

ALTER PROCEDURE [dbo].[Task_GEN_LicWinlossAnalysis_Job]
AS
/*
	Created: 20230209@Bobby
	Task: 172604 - LAP - Winloss Analysis - GEN Bettrans
	DB: DBEXT.bodb02

	Revisions:
		- 20230209@Bobby: Created [RedmineID: #172604]
		
*/
BEGIN  
	SET NOCOUNT ON

	DECLARE @MoveBetSchedule TABLE(RowId TINYINT IDENTITY(1,1), ScheduleId TINYINT, MoveBetDay SMALLDATETIME)
	DECLARE @RowId TINYINT, @WinlostDate SMALLDATETIME

	SELECT @RowId = 1

	INSERT INTO @MoveBetSchedule(ScheduleId, MoveBetDay)
	EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel

	IF NOT EXISTS (SELECT 1 FROM @MoveBetSchedule)
		RETURN --do not move bet on this day

	WHILE EXISTS (SELECT 1 FROM @MoveBetSchedule WHERE RowId = @RowId)
	BEGIN
		SELECT @WinlostDate = MoveBetDay FROM @MoveBetSchedule WHERE RowId = @RowId
		SELECT @RowId = @RowId + 1
		
		PRINT 'WinlostDate: ' + CONVERT(VARCHAR(10), @WinlostDate, 112)
		
		EXEC dbo.Task_GEN_LicWinlossAnalysis_Bettrans @winlostdate = @WinlostDate;
	END
END
GO