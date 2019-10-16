/*  
	Created: 20190916@Bobby
	Task: Implement headline - Statement [Redmine: #119289] - UAT check data
	DB: DBRPT.bodb_Report
*/
BEGIN

	SET NOCOUNT ON

	DECLARE @BalanceUpDay DATE, @MoveBetDay DATE, @Saturday DATE, @i TINYINT
	
	-- GET the current BU & MB day
	SELECT @BalanceUpDay = MIN(eventdate), @MoveBetDay = MAX(eventdate)
	FROM bodb02.dbo.match14 WITH(NOLOCK) 

	SELECT @i = DATEPART (DW,@MoveBetDay) 
	SELECT @Saturday = DATEADD ( DD, -@i, @MoveBetDay)

	--DELETE [dbo].[rptStatement_test] WHERE [winlostdate] >= @Saturday
	-- INIT [dbo].[rptStatement_test]
	INSERT INTO [dbo].[rptStatement_test]
           ([winlostdate]
           ,[custid]
           ,[openingbalance]
           ,[voidamt]
           ,[turnover]
           ,[netturnover]
           ,[transferamt]
           ,[winlost]
           ,[comm]
           ,[closingbalance]
           ,[GrandPrize]
           ,[OpeningTotalBalance])
	SELECT [winlostdate]
           ,[custid]
           ,[openingbalance]
           ,[voidamt]
           ,[turnover]
           ,[netturnover]
           ,[transferamt]
           ,[winlost]
           ,[comm]
           ,[closingbalance]
           ,[GrandPrize]
           ,[OpeningTotalBalance]
	FROM [dbo].[rptStatement] WITH(NOLOCK)
	WHERE [winlostdate] >= @Saturday


	--DELETE [dbo].[rptTotalBalance_Active_test] WHERE [winlostdate] > @MoveBetDay
	-- INIT [dbo].[rptStatement_test]
	
	INSERT INTO [dbo].[rptTotalBalance_Active_test]
           ([CustID]
           ,[WinlostDate]
           ,[OpeningBalance]
           ,[OpeningTotalBalance])
     SELECT [CustID]
           ,[WinlostDate]
           ,[OpeningBalance]
           ,[OpeningTotalBalance]
	FROM [dbo].[rptTotalBalance_Active] WITH(NOLOCK)
	WHERE winlostdate > @MoveBetDay 

END
GO