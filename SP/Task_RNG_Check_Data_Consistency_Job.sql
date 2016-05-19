USE bodb02
GO
ALTER PROCEDURE Task_RNG_Check_Data_Consistency_Job @FromDate SMALLDATETIME
	, @ToDate SMALLDATETIME
	, @ErrMessage VARCHAR(1024) = '' OUTPUT
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
	--MGC
	EXEC dbo.Task_MicroGamingRNG_DataConsistency_Check @FDate = @FromDate
		, @TDate = @ToDate
		, @ErrMessage = @ErrorTmp OUTPUT


	IF ISNULL(@ErrorTmp, '') <> ''
		SET @ErrMessage = @ErrMessage + @ErrorTmp + '</br>'
	
	--VB
	SET @ErrorTmp = ''
	EXEC dbo.Task_RNG_DataConsistency_Check @FromDate = @FromDate
		, @ToDate = @ToDate
		, @ProductId = 212

		, @ErrMessage = @ErrorTmp OUTPUT
	
	IF ISNULL(@ErrorTmp, '') <> ''
		SET @ErrMessage = @ErrMessage + @ErrorTmp + '</br>'

END

GO
