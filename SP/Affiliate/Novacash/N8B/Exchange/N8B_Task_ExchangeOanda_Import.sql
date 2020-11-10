/*<info serverAlias="DBAFFN8B-Affiliate_N8B" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_ExchangeOanda_Import]
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Import Exchange data from ExchangeDailyOanda

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	DECLARE @LastImportedTime DATETIME
	SELECT  @LastImportedTime = CONVERT(DATETIME, SValue)
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'LastImportedTime_ExchangeOanda'

	IF DATEDIFF(HOUR, @LastImportedTime, GETDATE()) < 6
		RETURN

	DECLARE @CurrentDate SMALLDATETIME, @Yesterday SMALLDATETIME
	SELECT  @CurrentDate	= CONVERT(DATE, GETDATE())
	SELECT  @Yesterday		= DATEADD(DAY, -1, @CurrentDate)

	DECLARE @tblExchange TABLE (ExchangeDate SMALLDATETIME, ExchangeId INT, Code VARCHAR(5), ActualRate FLOAT, VND FLOAT, EUR FLOAT, USD FLOAT, CNY FLOAT, MYR FLOAT, THB FLOAT, IDR FLOAT, MultipliedBy INT)
	
	-- Exchange: keep yesterday data
	BEGIN
		DELETE @tblExchange

		INSERT INTO @tblExchange (ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR, THB, IDR, MultipliedBy)
		SELECT o.ExchangeId, o.Code, o.ActualRate, o.VND, o.EUR, o.USD, o.CNY, o.MYR, o.THB, o.IDR, e.MultipliedBy
		FROM bodb02.dbo.ExchangeDailyOanda o WITH (NOLOCK)
			INNER JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON o.ExchangeId = e.ExchangeId
		WHERE o.ExchangeDate = @Yesterday

		MERGE dbo.Exchange AS t
		USING @tblExchange AS s
			ON t.ExchangeId = s.ExchangeId
		WHEN MATCHED THEN UPDATE
			SET  t.Code			= s.Code
				,t.ActualRate	= s.ActualRate
				,t.VND			= s.VND
				,t.EUR			= s.EUR
				,t.USD			= s.USD
				,t.CNY			= s.CNY
				,t.MYR			= s.MYR
				,t.THB			= s.THB
				,t.IDR			= s.IDR
				,t.MultipliedBy	= s.MultipliedBy
		WHEN NOT MATCHED BY TARGET THEN INSERT
			(ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR, THB, IDR, MultipliedBy)
			VALUES
			(ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR, THB, IDR, MultipliedBy)
		WHEN NOT MATCHED BY SOURCE THEN DELETE;
	END

	-- ExchangeOanda
	BEGIN
		-- Today & Tomorrow data
		DELETE dbo.ExchangeOanda WITH (ROWLOCK, UPDLOCK) WHERE ExchangeDate >= @CurrentDate

		INSERT INTO dbo.ExchangeOanda (ExchangeDate, ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR, THB, IDR)
		SELECT o.ExchangeDate, o.ExchangeId, o.Code, o.ActualRate, o.VND, o.EUR, o.USD, o.CNY, o.MYR, o.THB, o.IDR
		FROM bodb02.dbo.ExchangeDailyOanda o WITH (NOLOCK)
			LEFT JOIN dbo.Exchange e WITH (NOLOCK) ON o.ExchangeId = e.ExchangeId
		WHERE o.ExchangeDate >= @CurrentDate
			AND (
				e.ExchangeId IS NULL
				OR ISNULL(o.Code, '')		<> ISNULL(e.Code, '')
				OR ISNULL(o.ActualRate, 0)	<> ISNULL(e.ActualRate, 0)
				OR ISNULL(o.VND, 0)			<> ISNULL(e.VND, 0)
				OR ISNULL(o.EUR, 0)			<> ISNULL(e.EUR, 0)
				OR ISNULL(o.USD, 0)			<> ISNULL(e.USD, 0)
				OR ISNULL(o.CNY, 0)			<> ISNULL(e.CNY, 0)
				OR ISNULL(o.MYR, 0)			<> ISNULL(e.MYR, 0)
				OR ISNULL(o.THB, 0)			<> ISNULL(e.THB, 0)
				OR ISNULL(o.IDR, 0)			<> ISNULL(e.IDR, 0)
			)
	END

	-- Update SystemSettings
	UPDATE dbo.SystemSettings WITH (ROWLOCK)
	SET SValue = CONVERT(VARCHAR(20), GETDATE(), 120)
	WHERE SName = 'LastImportedTime_ExchangeOanda'
END
GO