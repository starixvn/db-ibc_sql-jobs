/*<info serverAlias="DBTP-bodb02" executers="" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_RNG_Check_Data_Consistency_Job] @FromDate SMALLDATETIME
	, @ToDate SMALLDATETIME
	, @ErrMessage NVARCHAR(MAX) = '' OUTPUT
AS
/*
	Created: 20160517@Patrick
	Task: Check data between bettrans & bettransRNG for RNG Game (Run on DB06/DBTP)
	Revision:
		2016-10-10@Patrick: Allbet integration
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
	
	--For Allbet
	SET @ErrorTmp = ''
	EXEC dbo.Task_LC_DataConsistency_Check @FromDate = @FromDate
		, @ToDate = @ToDate
		, @ProductId = 211

		, @ErrMessage = @ErrorTmp OUTPUT

	IF ISNULL(@ErrorTmp, '') <> ''
	BEGIN
		INSERT INTO @ErrorsTmp(ProductId, ProductName, ErrMessage)
		VALUES(211, 'Allbet', @ErrorTmp)	
	END

	--Fishing World
	SET @ErrorTmp = ''
	EXEC dbo.Task_RNG_DataConsistency_Check @FromDate = @FromDate
		, @ToDate = @ToDate
		, @ProductId = 219

		, @ErrMessage = @ErrorTmp OUTPUT

	IF ISNULL(@ErrorTmp, '') <> ''
	BEGIN
		INSERT INTO @ErrorsTmp(ProductId, ProductName, ErrMessage)
		VALUES(219, 'Fishing World', @ErrorTmp)	
	END

	--RNG - RNG Game
	SET @ErrorTmp = ''
	EXEC dbo.Task_RNG_DataConsistency_Check @FromDate = @FromDate
		, @ToDate = @ToDate
		, @ProductId = 208

		, @ErrMessage = @ErrorTmp OUTPUT

	IF ISNULL(@ErrorTmp, '') <> ''
	BEGIN
		INSERT INTO @ErrorsTmp(ProductId, ProductName, ErrMessage)
		VALUES(208, 'RNG - RNG Game', @ErrorTmp)	
	END

	--RNG - Mini Games
	SET @ErrorTmp = ''
	EXEC dbo.Task_RNG_DataConsistency_Check @FromDate = @FromDate
		, @ToDate = @ToDate
		, @ProductId = 209

		, @ErrMessage = @ErrorTmp OUTPUT

	IF ISNULL(@ErrorTmp, '') <> ''
	BEGIN
		INSERT INTO @ErrorsTmp(ProductId, ProductName, ErrMessage)
		VALUES(209, 'RNG - Mini Games', @ErrorTmp)	
	END

	--RNG - Mobile
	SET @ErrorTmp = ''
	EXEC dbo.Task_RNG_DataConsistency_Check @FromDate = @FromDate
		, @ToDate = @ToDate
		, @ProductId = 210

		, @ErrMessage = @ErrorTmp OUTPUT

	IF ISNULL(@ErrorTmp, '') <> ''
	BEGIN
		INSERT INTO @ErrorsTmp(ProductId, ProductName, ErrMessage)
		VALUES(210, 'RNG - Mobile', @ErrorTmp)	
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