/*  
	Created: 20190916@Bobby
	Task: Implement headline - Statement [Redmine: #119289] - UAT check data
	DB: DBRPT.bodb_Report
*/

CREATE TABLE [dbo].[rptStatement_test](
	[winlostdate] [date] NOT NULL,
	[custid] [int] NOT NULL,
	[openingbalance] [money] NULL,
	[voidamt] [money] NULL,
	[turnover] [money] NULL,
	[netturnover] [money] NULL,
	[transferamt] [money] NULL,
	[winlost] [money] NULL,
	[comm] [money] NULL,
	[closingbalance] [money] NULL,
	[GrandPrize] [money] NULL,
	[OpeningTotalBalance] [money] NULL,
 CONSTRAINT [pk_rptStatement_xpre] PRIMARY KEY CLUSTERED 
(
	[winlostdate] ASC,
	[custid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [STATEMENT_V2]
) ON [STATEMENT_V2]
GO

CREATE TABLE [dbo].[rptTotalBalance_Active_test](
	[CustID] [int] NOT NULL,
	[WinlostDate] [date] NOT NULL,
	[OpeningBalance] [money] NULL,
	[OpeningTotalBalance] [money] NULL,
 CONSTRAINT [CIX_rptTotalBalance_Active_xpre] PRIMARY KEY CLUSTERED 
(
	[WinlostDate] ASC,
	[CustID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [rptStatement_New]
) ON [rptStatement_New]
GO

-- INIT DATA
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