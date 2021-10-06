/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_LicenseeReport]
GO

ALTER PROCEDURE [dbo].[Task_DailyRptLicWinloss2_Job]
	@TableName VARCHAR(300) = ''
AS
 
/*
	Created by: Henry   
	Date: 2011-09-20  
	Task: Jobs for sum up date for rptLicWinlost  
	DB: DBLIC.bodb_LicenseeReport,DBBAL-bodb_LicenseeReport
  
	Revision:   
		- 20140108@Don: Add step to generate data to [bodb_LicenseeReport.rptCustomerTurnover]  
		- 20140117@Don: Add step to generate data to [bodb_LicenseeReport.rptWinlostbyleague]  
		- 20140725@Don: Add step to generate data to [bodb_LicenseeReport.rpt_BettingParlay]  
		- 20150909@Patrick: Changes the way generate data from bettrans instead bettrans14
		- 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
		- 20161003@Jim: Add step to generate data to [bodb_LicenseeReport.rpt_BettingColossusBets]  [RedminID : #63785]
		- 20171130@Sophia: Add step gen data to rptLicWinlossGMT [Redmine: #84932]
		- 20180424@Percy: Add @tablename param to break step of job: process insert sum step by step [RedmineID: #94129]
		- 20181129@Joseph: Add step to generate data to [bodb_LicenseeReport.rptCasinoTurnover]   [RedmineID: #95178]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
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

		IF @TableName = 'rptLicWinloss2'
		BEGIN
			EXEC dbo.Task_DailyRptLicWinloss2_Bettrans @winlostdate = @WinlostDate
		END
		ELSE IF @TableName = 'rptCustomerTurnOver'
		BEGIN
			EXEC dbo.Task_rptCustomerTurnOver_Bettrans @Date = @WinlostDate
		END
		ELSE IF @TableName = 'rptWinlostbyLeague'
		BEGIN
			EXEC dbo.Task_rptWinlostbyleague_Bettrans @Date = @WinlostDate
		END
		ELSE IF @TableName = 'rptCustomerMatch'
		BEGIN
			EXEC dbo.Task_rptCustomerMatch_Bettrans @Date = @WinlostDate
		END
		ELSE IF @TableName = 'rpt_BettingParlay'
		BEGIN
			EXEC dbo.GEN_rptBetting_Parlay @date = @WinlostDate, @date2 = @WinlostDate
		END
		ELSE IF @TableName = 'rpt_BettingColossusBets'
		BEGIN
			EXEC dbo.GEN_rptBetting_ColossusBets @date = @WinlostDate, @date2 = @WinlostDate
		END
		ELSE IF @TableName = 'rptLicWinlossGMT'
		BEGIN
			EXEC dbo.Task_DailyRptLicWinlossGMT_Bettrans @FromDate = @WinlostDate
		END
		ELSE IF @TableName = 'rptCasinoTurnover'
		BEGIN
			EXEC dbo.Task_DailyRptCasinoTurnover_Bettrans @winlostdate = @WinlostDate
		END
	END
END
GO