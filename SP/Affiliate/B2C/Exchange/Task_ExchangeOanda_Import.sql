/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_ExchangeOanda_Import]
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Import Exchange data from ExchangeDailyOanda

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20210317@Percy: Keep Exchange data last day of month [RedmineID: #151391]
*/

BEGIN
	DECLARE @LastImportedTime DATETIME
	SELECT  @LastImportedTime = CONVERT(DATETIME, SValue)
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'LastImportedTime_ExchangeOanda'

	IF DATEDIFF(HOUR, @LastImportedTime, GETDATE()) < 6
		RETURN

	DECLARE @CurrentDate SMALLDATETIME = CONVERT(DATE, GETDATE())
	DECLARE @CurrentMonth SMALLDATETIME = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDate) + 1, 0))
	DECLARE @FromMonth SMALLDATETIME
	
	IF DAY(@LastImportedTime) < 5
		SELECT @FromMonth = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @LastImportedTime), 0))
	ELSE
		SELECT @FromMonth = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @LastImportedTime) + 1, 0))
	
	DECLARE @tblExchange TABLE (ExchangeDate SMALLDATETIME, ExchangeId INT, Code VARCHAR(5), ActualRate FLOAT, VND FLOAT, EUR FLOAT, USD FLOAT, CNY FLOAT, MYR FLOAT, THB FLOAT, IDR FLOAT)
	;WITH CTE_MonthDate AS
	(
		SELECT @FromMonth AS MonthDate
		UNION ALL
		SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
		FROM CTE_MonthDate
		WHERE MonthDate < @CurrentMonth
	)
	INSERT INTO @tblExchange (ExchangeDate, ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR, THB, IDR)
	SELECT e.ExchangeDate, e.ExchangeId, e.Code, e.ActualRate, e.VND, e.EUR, e.USD, e.CNY, e.MYR, e.THB, e.IDR
	FROM bodb02.dbo.ExchangeDailyOanda e WITH (NOLOCK)
		INNER JOIN CTE_MonthDate m ON e.ExchangeDate = m.MonthDate

	IF NOT EXISTS (SELECT 1 FROM @tblExchange WHERE ExchangeDate = @CurrentMonth)
		INSERT INTO @tblExchange (ExchangeDate, ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR, THB, IDR)
		SELECT @CurrentMonth, e.ExchangeId, e.Code, e.ActualRate, e.VND, e.EUR, e.USD, e.CNY, e.MYR, e.THB, e.IDR
		FROM bodb02.dbo.ExchangeDailyOanda e WITH (NOLOCK)
		WHERE e.ExchangeDate = @CurrentDate

	DELETE dbo.ExchangeOanda WITH (ROWLOCK, UPDLOCK)
	WHERE ExchangeDate >= @FromMonth

	INSERT INTO dbo.ExchangeOanda (ExchangeDate, ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR, THB, IDR)
	SELECT ExchangeDate, ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR, THB, IDR FROM @tblExchange

	-- Update SystemSettings
	UPDATE dbo.SystemSettings WITH (ROWLOCK)
	SET SValue = CONVERT(VARCHAR(20), GETDATE(), 120)
	WHERE SName = 'LastImportedTime_ExchangeOanda'
END
GO