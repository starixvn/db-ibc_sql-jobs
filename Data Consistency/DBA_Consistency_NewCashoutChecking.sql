/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_NewCashoutChecking]
	@ProductId		INT		
	,@ErrCode		INT			 = 0	OUTPUT
	,@ErrMsg		VARCHAR(MAX) = ''	OUTPUT 
	,@SampleData	VARCHAR(MAX) = ''	OUTPUT
AS
/*
	Created: 20220112@July
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20220112@July: Detect Cashout ticket with WinLoseDate > today [Redmine:#167311]
		- 20220328@July: Update WinloseDate > current date+ 1 [Redmine:#170612]

	Param's Expanation:
		+ @ProductId = 1 (Offer to Cashout of sportbook product)
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @transId		VARCHAR(MAX)
			,@Today			SMALLDATETIME

	SET @transId = ''
	SET @Today = DATEADD(DAY,1,CAST(GETDATE() AS DATE))
		
	IF @ProductId = 1
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM bodb02.dbo.bettrans WITH(NOLOCK) 
		WHERE ISNULL(betdaqid,0) = -2 
			AND winlostdate > @Today
	END

	IF @transId <> ''
	BEGIN
		SELECT	 @transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'Detect Cashout ticket (with Betdaqid = -2) and WinloseDate > current day on product' + CAST(@ProductId AS VARCHAR)
				,@SampleData = 'bettrans.TransId in (' + @transId + ')'
	END

END
GO
