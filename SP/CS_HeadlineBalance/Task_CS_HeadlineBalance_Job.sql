/*<info serverAlias="DBACC-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Task_CS_HeadlineBalance_Job]	
AS
/*
	Creator: 20190826@Sophia 
	Remark: Daily Auto add transfer ticket for CN88 Headline balance (like reset winning Extra PT for CN88) 
	DB: DBACC-bodb02

	Revisions:
		- 20190826@Sophia: initial SP [Redmine: #117863]
 

	 
*/
BEGIN
 
	SET NOCOUNT ON

	DECLARE @tblErrMsg TABLE (WinlostDate SMALLDATETIME, ErrMsg VARCHAR(1000))

	DECLARE @MBBU TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	INSERT INTO @MBBU (BalanceUpDay, MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay
	
	DECLARE @WinlostDate SMALLDATETIME, @Yesterday SMALLDATETIME
	DECLARE @CutDate SMALLDATETIME = '2019-11-06'
	
	SELECT  @WinlostDate = DATEADD(DAY, 1, MoveBetsDay), 
			@Yesterday = DATEADD(DAY, -1, CONVERT(SMALLDATETIME, GETDATE())) 
	FROM @MBBU
	
	IF @WinlostDate < @CutDate
	BEGIN 
		SELECT @WinlostDate = @CutDate
	END	
	
	WHILE @WinlostDate <= @Yesterday
	BEGIN
		BEGIN TRY
			EXEC dbo.Task_CS_HeadlineBalance @WinlostDate = @WinlostDate, @IsCheckDataOnly = 0
		END TRY
		BEGIN CATCH
			INSERT INTO @tblErrMsg (WinlostDate, ErrMsg)
			SELECT @WinlostDate, ERROR_MESSAGE()
		END CATCH

		SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
	END

	IF EXISTS (SELECT 1 FROM @tblErrMsg)
	BEGIN
		DECLARE @ErrMsg VARCHAR(2000) = 'Failed to generate data'
		SELECT	@ErrMsg = @ErrMsg + CHAR(13) + CONVERT(VARCHAR(10), WinlostDate, 120) + ' - Headline Balance - '  + ErrMsg
		FROM @tblErrMsg

		RAISERROR (@ErrMsg, 16, 1)
	END
END
GO