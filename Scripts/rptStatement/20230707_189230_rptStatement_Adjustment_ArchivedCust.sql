/*<info serverAlias="DBRPT-bodb_report"></info>*/

/*
	Created: 20230707@Bobby
	DB: DBRPT-bodb_report
	Task: rptStatement Adjustment [RedmineID: #189230]
	Remark: Run on DB062 only
*/

USE bodb_report
GO
/**
DB062: Update rptStatement_Old
**/
use bodb_Report;
go
-- 9339 rows
WITH cte_061 AS (
	SELECT *
		FROM OPENQUERY(DB061, N'
			SELECT Custid
			  ,WinlostDate
			  ,[OpeningBalance]
			  ,[VoidAmt]
			  ,[Turnover]
			  ,[NetTurnover]
			  ,[TransferAmt]
			  ,[Winlost]
			  ,[Comm]
			  ,[ClosingBalance]
			  ,[GrandPrize]
			  ,[OpeningTotalBalance]
		FROM (
			VALUES (23417075),
			(32611672),
			(32614918),
			(33870411),
			(33870473),
			(37067554),
			(37115682),
			(38820599),
			(38848389),
			(39083931),
			(39084032),
			(39122442),
			(39404734),
			(39418396),
			(39479637),
			(39583616),
			(39647343),
			(39683446),
			(39689818),
			(39697994),
			(39707993),
			(39713156),
			(39726193),
			(39726961),
			(39727924),
			(39728889),
			(39729166),
			(39730390),
			(39732647),
			(39735469),
			(39737496),
			(39739980),
			(39741676),
			(42079271)
	) AS t (DiffCust)
	OUTER APPLY (
		SELECT * FROM bodb_Report.dbo.rptStatement_Old rpt WITH(NOLOCK)
		WHERE rpt.Custid = t.DiffCust and rpt.WinlostDate >= ''2020-01-01''
	) AS rpt') AS rpt
)
UPDATE rpt WITH(ROWLOCK, UPDLOCK)
SET [OpeningBalance] = cte_061.OpeningBalance
    ,[VoidAmt] = cte_061.VoidAmt
    ,[Turnover] = cte_061.Turnover
    ,[NetTurnover] = cte_061.NetTurnover
    ,[TransferAmt] = cte_061.TransferAmt
    ,[Winlost] = cte_061.Winlost
    ,[Comm] = cte_061.Comm
    ,[ClosingBalance] = cte_061.ClosingBalance
    ,[GrandPrize] = cte_061.GrandPrize
    ,[OpeningTotalBalance] = cte_061.OpeningTotalBalance
 FROM bodb_Report.[dbo].[rptStatement_Old] rpt
 INNER JOIN cte_061 ON cte_061.CustId = rpt.Custid and cte_061.WinlostDate = rpt.WinlostDate


/**
DB062: Update rptStatement
**/
use bodb_Report;
go

-- 68 rows
WITH cte_061 AS (
	SELECT *
	FROM OPENQUERY(DB061, N'
		SELECT Custid
			,WinlostDate
			,[OpeningBalance]
			,[VoidAmt]
			,[Turnover]
			,[NetTurnover]
			,[TransferAmt]
			,[Winlost]
			,[Comm]
			,[ClosingBalance]
			,[GrandPrize]
			,[OpeningTotalBalance]
		FROM (
			VALUES (23417075),
			(32611672),
			(32614918),
			(33870411),
			(33870473),
			(37067554),
			(37115682),
			(38820599),
			(38848389),
			(39083931),
			(39084032),
			(39122442),
			(39404734),
			(39418396),
			(39479637),
			(39583616),
			(39647343),
			(39683446),
			(39689818),
			(39697994),
			(39707993),
			(39713156),
			(39726193),
			(39726961),
			(39727924),
			(39728889),
			(39729166),
			(39730390),
			(39732647),
			(39735469),
			(39737496),
			(39739980),
			(39741676),
			(42079271)
	) AS t (DiffCust)
	OUTER APPLY (
		SELECT * FROM bodb_Report.dbo.rptStatement rpt WITH(NOLOCK)
		WHERE rpt.Custid = t.DiffCust and rpt.WinlostDate >= ''2020-01-01''
	) AS rpt') AS rpt
)
UPDATE rpt WITH(ROWLOCK, UPDLOCK)
SET [OpeningBalance] = cte_061.OpeningBalance
    ,[VoidAmt] = cte_061.VoidAmt
    ,[Turnover] = cte_061.Turnover
    ,[NetTurnover] = cte_061.NetTurnover
    ,[TransferAmt] = cte_061.TransferAmt
    ,[Winlost] = cte_061.Winlost
    ,[Comm] = cte_061.Comm
    ,[ClosingBalance] = cte_061.ClosingBalance
    ,[GrandPrize] = cte_061.GrandPrize
    ,[OpeningTotalBalance] = cte_061.OpeningTotalBalance
 FROM bodb_Report.[dbo].[rptStatement] rpt
 INNER JOIN cte_061 ON cte_061.CustId = rpt.Custid and cte_061.WinlostDate = rpt.WinlostDate

