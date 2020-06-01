/*<info serverAlias="DBLIC-bodb_LicenseeReport" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_rpt_CustomerWL_ExtraGMT]
	@WinlostDate SMALLDATETIME
AS

/*
	Created: 20200601@Percy
	DB: DBLIC-bodb_LicenseeReport
	Task: Gen data into rpt_CustomerWL_ExtraGMT

	Revisions:
		- 20200601@Percy: Initialize SP [RedmineID: #134867]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MoveBetsDay SMALLDATETIME
	SELECT  @MoveBetsDay = MAX(eventdate) FROM bodb02.dbo.match14 WITH (NOLOCK)

	DECLARE @tblBettype TABLE (ProductId INT, bettype SMALLINT, refTable TINYINT)
	INSERT INTO @tblBettype (ProductId, bettype, refTable)
	SELECT DISTINCT ProductId, bettype, refTable
	FROM bodb02.dbo.SportBettypeMatrix WITH (NOLOCK)
	WHERE ProductId = 21

	DECLARE @tblCustomer TABLE (custid INT, siteId INT)
	INSERT INTO @tblCustomer (custid, siteId)
	SELECT c.custid, ISNULL(s.SiteId, -1)
	FROM bodb02.dbo.Customer c WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Customer a WITH (NOLOCK) ON c.recommend = a.custid AND a.roleid = 2
		LEFT JOIN bodb_licensee.dbo.view_site_list s (NOLOCK) ON a.site = s.SiteName
	WHERE c.username IN ('BBS7777888', 'BBS7777777', 'BBS7777999')

	DECLARE @rptDate DATE
	SELECT  @rptDate = @WinlostDate

	DELETE dbo.rpt_CustomerWL_ExtraGMT WITH (ROWLOCK, UPDLOCK)
	WHERE RptDate = @rptDate 

	IF @WinlostDate > @MoveBetsDay
	BEGIN
		INSERT INTO dbo.rpt_CustomerWL_ExtraGMT
		(
			RptDate
			,RptDate3rd
			,CustId
			,SiteId
			,ProductId
			,BetTypeId
			,CurrencyId
			,StatusId
			,BetCount
			,Turnover
			,Winloss
			,AComm
			,PComm
			,ProgressiveContribution
			,ProgressivePayout
			,ValidBetAmount
		)
		SELECT
			RptDate		= @rptDate
			,RptDate3rd = CONVERT(DATE, b.Transdate3rd)
			,CustId		= b.custid
			,SiteId		= c.siteId
			,ProductId	= bt.ProductId
			,BetTypeId	= b.gameId
			,CurrencyId	= b.currency
			,StatusId	= b.statusId
			,BetCount	= COUNT(1)
			,Turnover	= SUM(ABS(b.stake))
			,Winloss	= SUM(b.winlost - b.actual_stake)
			,AComm		= SUM(b.comm)
			,PComm		= SUM(b.playercomm)
			,ProgressiveContribution	= 0
			,ProgressivePayout			= 0
			,ValidBetAmount				= SUM(b.NetStake)
		FROM bodb02.dbo.bettransLC b WITH (NOLOCK)
			INNER JOIN @tblBettype bt ON b.gameId = bt.bettype AND bt.refTable = 2
			INNER JOIN @tblCustomer c ON b.custid = c.custid
		WHERE b.winlostdate = @Winlostdate
			AND b.statusId IN (111, 112, 113)
		GROUP BY
			CONVERT(DATE, b.Transdate3rd)
			,b.custid
			,c.siteId
			,bt.ProductId
			,b.gameId
			,b.currency
			,b.statusId
	END
	ELSE
	BEGIN
		INSERT INTO dbo.rpt_CustomerWL_ExtraGMT
		(
			RptDate
			,RptDate3rd
			,CustId
			,SiteId
			,ProductId
			,BetTypeId
			,CurrencyId
			,StatusId
			,BetCount
			,Turnover
			,Winloss
			,AComm
			,PComm
			,ProgressiveContribution
			,ProgressivePayout
			,ValidBetAmount
		)
		SELECT
			RptDate		= @rptDate
			,RptDate3rd = CONVERT(DATE, b.Transdate3rd)
			,CustId		= b.custid
			,SiteId		= c.siteId
			,ProductId	= bt.ProductId
			,BetTypeId	= b.gameId
			,CurrencyId	= b.currency
			,StatusId	= b.statusId
			,BetCount	= COUNT(1)
			,Turnover	= SUM(ABS(b.stake))
			,Winloss	= SUM(b.winlost - b.actual_stake)
			,AComm		= SUM(b.comm)
			,PComm		= SUM(b.playercomm)
			,ProgressiveContribution	= 0
			,ProgressivePayout			= 0
			,ValidBetAmount				= SUM(b.NetStake)
		FROM bodb02.dbo.bettransLC14 b WITH (NOLOCK)
			INNER JOIN @tblBettype bt ON b.gameId = bt.bettype AND bt.refTable = 2
			INNER JOIN @tblCustomer c ON b.custid = c.custid
		WHERE b.winlostdate = @Winlostdate
			AND b.statusId IN (111, 112, 113)
		GROUP BY
			CONVERT(DATE, b.Transdate3rd)
			,b.custid
			,c.siteId
			,bt.ProductId
			,b.gameId
			,b.currency
			,b.statusId
	END
END
GO