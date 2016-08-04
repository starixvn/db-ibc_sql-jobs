USE [bodb_Licensee]
GO
/****** Object:  StoredProcedure [dbo].[GET_DepositDataToValidate_DW]    Script Date: 03/10/2014 01:33:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.GET_DepositDataToValidate_DW    Script Date: 3/26/2013 4:34:06 PM ******/

ALTER PROCEDURE [dbo].[GET_DepositDataToValidate_DW] 
    @Date smalldatetime
    ,@DrawFilter tinyint = 1
AS
/*
Created: 20111208@Don
Task : Get deposit data from table DBWH.bodb_Account.dbo.rptLeague

DB: bodb_Licensee
Original:

Revisions:	
	20131101@daniel: add param sniff to solve wrong plan
	20140310@daniel: exclude currency C & H
	
Param's Explanation:
    @DrawFilter, 1:Normal - 2:No Draws - 3:No Draws For Turnover Only


Examples:

DECLARE @DateChecking SMALLDATETIME
SELECT @DateChecking =DATEADD(day, -10, GETDATE())
exec [GET_DepositDataToValidate_DW] @Date=@DateChecking,@DrawFilter=1
*/

SET NOCOUNT ON

declare @_Date smalldatetime

select @_Date = @Date


DECLARE @SbBaTurnover MONEY
       ,@SbBaCustomerWl MONEY
       ,@SbBaBetCount MONEY,
		@SbTurnover MONEY
       ,@SbCustomerWl MONEY
       ,@SbBetCount MONEY
       ,@RbTurnover MONEY
       ,@RbCustomerWl MONEY
       ,@RbBetCount MONEY
       ,@NgTurnover MONEY
       ,@NgCustomerWl MONEY
       ,@NgBetCount MONEY
       ,@BaTurnover MONEY
       ,@BaCustomerWl MONEY
       ,@BaBetCount MONEY
       ,@CsTurnover MONEY
       ,@CsCustomerWl MONEY
       ,@CsBetCount MONEY
       

-- Ba
SELECT @BaTurnover = SUM(CASE 
                    WHEN @DrawFilter IN (2,3) THEN 
                        CASE WHEN statuslist.StatusID = 111 THEN 0 WHEN statuslist.StatusID IN (114,115) THEN 0.5 ELSE 1 END
                    ELSE 1
                END * b.stake/c.Rate )
    ,@BaCustomerWl=-SUM(  (  WinlostIBC-(WinlostS+WinlostM+WinlostA+Commission)  )/c.Rate  ) 
    ,@BaBetCount=SUM(CASE WHEN @DrawFilter=2 AND statuslist.StatusID=111 THEN 0 ELSE b.BetCount END) 
FROM DBWH.bodb_Account.dbo.rptLeague_BA b WITH(NOLOCK)
    INNER JOIN dbo.view_site_list_dw s (NOLOCK) ON b.division=s.DwSiteID
    INNER JOIN dbo.Licensees lic (NOLOCK) ON s.SiteID=lic.LicenseeID AND IsDeposit=CONVERT(bit,1)
    INNER JOIN DBWH.bodb_Account.dbo.tbl_Currency_Daily c WITH(NOLOCK) ON b.currency=c.Currency AND b.rptDate=c.ExchangeDate
    LEFT JOIN dbo.view_status_list statuslist (NOLOCK) ON b.Status=statuslist.DwStatusID
WHERE b.rptDate=@_date
    AND statuslist.StatusID IN (111,112,113,114,115)
    AND b.currency NOT IN(20,27,28)

SELECT @BaTurnover = ISNULL (@BaTurnover, 0),
	   @BaCustomerWl = ISNULL (@BaCustomerWl, 0),
	   @BaBetCount = ISNULL (@BaBetCount, 0)

-- Sportsbook
-- Sportsbook + Ba
SELECT @SbBaTurnover=SUM(CASE 
                    WHEN @DrawFilter IN (2,3) THEN 
                        CASE WHEN statuslist.StatusID = 111 THEN 0 WHEN statuslist.StatusID IN (114,115) THEN 0.5 ELSE 1 END
                    ELSE 1
                END * b.stake/c.Rate)
    ,@SbBaCustomerWl=-SUM(  (  WinlostIBC-(WinlostS+WinlostM+WinlostA+Commission)  )/c.Rate  )
    ,@SbBaBetCount=SUM(CASE WHEN @DrawFilter=2 AND statuslist.StatusID=111 THEN 0 ELSE b.BetCount END)
FROM DBWH.bodb_Account.dbo.rptLeague b WITH(NOLOCK)
    INNER JOIN dbo.view_site_list_dw s (NOLOCK) ON b.division=s.DwSiteID
    INNER JOIN dbo.Licensees lic (NOLOCK) ON s.SiteID=lic.LicenseeID AND IsDeposit=CONVERT(bit,1)
    INNER JOIN DBWH.bodb_Account.dbo.tbl_Currency_Daily c WITH(NOLOCK) ON b.currency=c.Currency AND b.rptDate=c.ExchangeDate
    LEFT JOIN dbo.view_status_list statuslist (NOLOCK) ON b.Status=statuslist.DwStatusID
WHERE b.rptDate=@_date
    AND ( (b.bettype<31) OR (b.bettype>=121 and b.bettype<1000) OR (b.bettype=18999) )
    AND statuslist.StatusID IN (111,112,113,114,115)
    AND b.currency NOT IN(20,27,28)

SELECT @SbBaTurnover = ISNULL (@SbBaTurnover, 0),
	   @SbBaCustomerWl = ISNULL (@SbBaCustomerWl, 0),
	   @SbBaBetCount = ISNULL (@SbBaBetCount, 0)

	   
SELECT @SbTurnover = @SbBaTurnover - @BaTurnover,
	   @SbCustomerWl = @SbBaCustomerWl - @BaCustomerWl ,
	   @SbBetCount = @SbBaBetCount - @BaBetCount

-- Racing

SELECT @RbTurnover = ISNULL(SUM(Turnover),0)
    ,@RbCustomerWl = ISNULL(SUM(WinlossP),0)
    ,@RbBetCount = ISNULL(SUM(BetCount),0)
FROM DBWH.bodb_Account.dbo.mcDailyRacing b WITH(NOLOCK)
    INNER JOIN dbo.view_site_list_dw s (NOLOCK) ON b.SiteID=s.DwSiteID
    INNER JOIN dbo.Licensees lic (NOLOCK) ON s.SiteID=lic.LicenseeID AND IsDeposit=CONVERT(bit,1)
WHERE b.rptDate=@_date
    AND b.CurrencyID<>20

SELECT @RbTurnover = ISNULL (@RbTurnover, 0),
	   @RbCustomerWl = ISNULL (@RbCustomerWl, 0),
	   @RbBetCount = ISNULL (@RbBetCount, 0)
        
-- Number Game
SELECT @NgTurnover= SUM(CASE WHEN @DrawFilter IN (2,3) AND statuslist.StatusID=111 THEN 0 ELSE b.stake/c.Rate END)
    ,@NgCustomerWl= -SUM(  (  WinlostIBC-(WinlostS+WinlostM+WinlostA+Commission)  )/c.Rate  )
    ,@NgBetCount= SUM(CASE WHEN @DrawFilter=2 AND statuslist.StatusID=111 THEN 0 ELSE b.BetCount END)
FROM DBWH.bodb_Account.dbo.rptLeague b WITH(NOLOCK)
    INNER JOIN dbo.view_site_list_dw s (NOLOCK) ON b.division=s.DwSiteID
    INNER JOIN dbo.Licensees lic (NOLOCK) ON s.SiteID=lic.LicenseeID AND IsDeposit=CONVERT(bit,1)
    INNER JOIN DBWH.bodb_Account.dbo.tbl_Currency_Daily c WITH(NOLOCK) ON b.currency=c.Currency AND b.rptDate=c.ExchangeDate
    LEFT JOIN dbo.view_status_list statuslist (NOLOCK) ON b.Status=statuslist.DwStatusID
WHERE b.rptDate=@_date
    AND b.bettype BETWEEN 81 AND 120
    AND statuslist.StatusID IN (111,112,113,114,115)
    AND b.currency NOT IN(20,27,28)

SELECT @NgTurnover = ISNULL (@NgTurnover, 0),
	   @NgCustomerWl = ISNULL (@NgCustomerWl, 0),
	   @NgBetCount = ISNULL (@NgBetCount, 0)

-- Live Casino

SELECT @CsTurnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND statuslist.StatusID=111 THEN 0 ELSE b.stake/c.Rate END)
    ,@CsCustomerWl = -SUM(  (  WinlostIBC-(WinlostS+WinlostM+WinlostA+Commission)  )/c.Rate  )
    ,@CsBetCount = SUM(CASE WHEN @DrawFilter=2 AND statuslist.StatusID=111 THEN 0 ELSE b.BetCount END)
FROM DBWH.bodb_Account.dbo.rptLeague b WITH(NOLOCK)
    INNER JOIN dbo.view_site_list_dw s (NOLOCK) ON b.division=s.DwSiteID
    INNER JOIN dbo.Licensees lic (NOLOCK) ON s.SiteID=lic.LicenseeID AND IsDeposit=CONVERT(bit,1)
    INNER JOIN DBWH.bodb_Account.dbo.tbl_Currency_Daily c WITH(NOLOCK) ON b.currency=c.Currency AND b.rptDate=c.ExchangeDate
    LEFT JOIN dbo.view_status_list statuslist (NOLOCK) ON b.Status=statuslist.DwStatusID
WHERE b.rptDate=@_date
    AND b.bettype between 1101 and 1199
    AND statuslist.StatusID IN (111,112,113,114,115)
    AND b.currency NOT IN(20,27,28)

SELECT @CsTurnover = ISNULL (@CsTurnover, 0),
	   @CsCustomerWl = ISNULL (@CsCustomerWl, 0),
	   @CsBetCount = ISNULL (@CsBetCount, 0)


-- Result

SELECT 1 AS Id, @SbTurnover AS Sb, @RbTurnover AS Rb, @NgTurnover AS Ng, @BaTurnover AS Ba, @CsTurnover AS Cs
UNION
SELECT 2, @SbCustomerWl, @RbCustomerWl, @NgCustomerWl, @BaCustomerWl, @CsCustomerWl
UNION
SELECT 3, @SbBetCount, @RbBetCount, @NgBetCount, @BaBetCount, @CsBetCount

SET NOCOUNT OFF

