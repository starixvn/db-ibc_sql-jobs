USE [bodb_Invoice]
GO

/****** Object:  StoredProcedure [dbo].[IMS_Task_ExchangeDailyIns]    Script Date: 01/19/2015 02:47:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IMS_Task_ExchangeDailyIns]
	@exchangeDate SMALLDATETIME = NULL
AS
BEGIN
	/*  Created: Kevin
		Date: 20130610
		Task : Invoice/CreateInvoice
		DB: db052.bodb_Invoice
		Revisions:  
		Param's Explanation:  		
	*/  
	SET NOCOUNT ON
	
	IF ISNULL(@exchangeDate, '') = ''
		SET @exchangeDate = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)
	ELSE
		SET @exchangeDate = CONVERT(VARCHAR(10), @exchangeDate, 120)

	DECLARE @tempExchange TABLE([Year] SMALLINT, [Month] TINYINT, ExchangeID INT,  Code VARCHAR(3), 
								MYR FLOAT, USD FLOAT, EUR FLOAT, CNY FLOAT)
	INSERT INTO @tempExchange ([Year], [Month], ExchangeID, Code, MYR, USD, EUR, CNY)	
		SELECT YEAR(edo.ExchangeDate), MONTH(edo.ExchangeDate), 
			edo.ExchangeId, edo.Code, edo.MYR, edo.USD, edo.EUR, edo.CNY
		FROM bodb02.dbo.ExchangeDailyOanda edo  WITH(NOLOCK) WHERE edo.ExchangeDate = @exchangeDate

	DECLARE Exchange_Cursor CURSOR FOR
	SELECT [Year], [Month], ExchangeID, Code, MYR, USD, EUR, CNY FROM @tempExchange
	DECLARE @Year SMALLINT, @Month TINYINT, @ExchangeID INT, 
			@Code VARCHAR(3), @MYR FLOAT, @USD FLOAT, @EUR FLOAT, @CNY FLOAT

	OPEN Exchange_Cursor

	FETCH NEXT FROM	Exchange_Cursor INTO @Year, @Month, @ExchangeID, @Code, @MYR, @USD, @EUR, @CNY
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF EXISTS(SELECT 1 FROM Exchange e WITH(NOLOCK)
							WHERE e.Year = @Year AND e.Month = @Month AND e.Currency = @ExchangeID)
			BEGIN
				UPDATE Exchange
					SET MYR = @MYR, USD = @USD, EUR = @EUR, CNY = @CNY
				WHERE [Year] = @Year AND [Month] = @Month AND Currency = @ExchangeID
			END
		ELSE
			BEGIN
				INSERT INTO Exchange 
					(Currency, [Year], [Month], CurrencyCode, MYR, USD, EUR, CNY, [Description])
					 VALUES 
						(@ExchangeID, @Year, @Month, @Code, @MYR, @USD, @EUR, @CNY, '')
			END

		FETCH NEXT FROM Exchange_Cursor INTO @Year, @Month, @ExchangeID, @Code, @MYR, @USD, @EUR, @CNY
	END

	CLOSE Exchange_Cursor
	DEALLOCATE Exchange_Cursor

END


GO

GRANT EXECUTE ON [dbo].[IMS_Task_ExchangeDailyIns] TO [bodbAdminNet] AS [dbo]
GO


