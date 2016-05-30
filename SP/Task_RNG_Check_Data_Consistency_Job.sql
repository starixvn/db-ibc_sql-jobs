USE bodb02
GO
ALTER PROCEDURE Task_RNG_Check_Data_Consistency_Job @FromDate SMALLDATETIME
	, @ToDate SMALLDATETIME
	, @ErrMessage NVARCHAR(MAX) = '' OUTPUT
AS
/*
	Created: 20160517@Patrick
	Task: Check data between bettrans & bettransRNG for RNG Game (Run on DB06/DBTP)
	Revision:
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @ErrorTmp VARCHAR(512)
	SELECT @ErrMessage = '', @ErrorTmp = ''
	DECLARE @ErrorsTmp TABLE (ProductId INT, ProductName VARCHAR(100), ErrMessage VARCHAR(512))
	
	--For Microgaming RNG Casino
	EXEC dbo.Task_MicroGamingRNG_DataConsistency_Check @FDate = @FromDate
		, @TDate = @ToDate
		, @ErrMessage = @ErrorTmp OUTPUT
		
	IF ISNULL(@ErrorTmp, '') <> ''
	BEGIN
		--SET @ErrMessage = @ErrMessage + @ErrorTmp + '</br>'
		INSERT INTO @ErrorsTmp(ProductId, ProductName, ErrMessage)
		VALUES(205, 'Microgaming RNG Casino', @ErrorTmp)
	END
	
	--For Macau Games
	SET @ErrorTmp = ''
	EXEC dbo.Task_RNG_DataConsistency_Check @FromDate = @FromDate
		, @ToDate = @ToDate
		, @ProductId = 212

		, @ErrMessage = @ErrorTmp OUTPUT
	
	IF ISNULL(@ErrorTmp, '') <> ''
	BEGIN
		--SET @ErrMessage = @ErrMessage + @ErrorTmp + '</br>'
		INSERT INTO @ErrorsTmp(ProductId, ProductName, ErrMessage)
		VALUES(212, 'Macau Games', @ErrorTmp)
	END

	--For Microgaming Live Casino
	SET @ErrorTmp = ''
	EXEC dbo.Task_MicroGamingLC_DataConsistency_Check @FDate = @Fromdate
		, @TDate = @Todate
		, @ErrMessage =  @ErrorTmp OUTPUT

	IF ISNULL(@ErrorTmp, '') <> ''
	BEGIN
		--SET @ErrMessage = @ErrMessage + @ErrorTmp
		INSERT INTO @ErrorsTmp(ProductId, ProductName, ErrMessage)
		VALUES(203, 'Microgaming Live Casino', @ErrorTmp)
	END

	--will be sent mail if any error 
	IF EXISTS (SELECT TOP 1 1 FROM @ErrorsTmp)
	BEGIN

		SELECT @ErrMessage = N'<H3>Failed to check consistency of tickets from ['+ CAST(@FromDate AS VARCHAR) +'] to ['+ CAST(@ToDate AS VARCHAR) +']</H3>'
							 + N'<table border="1">'
							 + N'<tr><th>Product Name</th><th>Error Message</th></tr>'
							 + CAST(( SELECT --td = ProductId, '',
											 td = ProductName, '',
											 td = ErrMessage, ''
									FROM @ErrorsTmp
									FOR XML PATH('tr'), TYPE 
								) AS NVARCHAR(MAX) ) + N'</table>'

		
	END
		
END

GO
