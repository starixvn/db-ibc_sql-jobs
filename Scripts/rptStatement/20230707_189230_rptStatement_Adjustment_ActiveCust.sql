/*<info serverAlias="DBRPT-bodb_report"></info>*/

/*
	Created: 20230707@Bobby
	DB: DBRPT-bodb_report
	Task: rptStatement Adjustment [RedmineID: #189230]
	Remark: Run on DB062 Only
*/

USE bodb_report
GO
 /**
DB062: Update rptStatement_Old
**/
DROP TABLE IF EXISTS #tmpRptStatement_Old;

CREATE TABLE #tmpRptStatement_Old(
	rIdx [int] IDENTITY (1,1) PRIMARY KEY,
	[WinlostDate] [date] NOT NULL,
	[Custid] [int] NOT NULL,
	[OpeningBalance] [money] NULL,
	[VoidAmt] [money] NULL,
	[Turnover] [money] NULL,
	[NetTurnover] [money] NULL,
	[TransferAmt] [money] NULL,
	[Winlost] [money] NULL,
	[Comm] [money] NULL,
	[ClosingBalance] [money] NULL,
	[GrandPrize] [money] NULL,
	[OpeningTotalBalance] [money] NULL
);

DECLARE @batch INT = 5000, @nCount INT = 0, @totalRows INT, @nLoop INT = 1, @RowCount INT;

--14199 rows
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
		VALUES 
		(6630793, CAST(''2019-06-05'' AS DATE)),
		(14616559,''2019-06-06''),
		(28779564,''2019-06-10''),
		(4044289,''2020-06-12''),
		(4044290,''2020-06-12''),
		(7213817,''2013-02-08''),
		(7213821,''2013-02-02''),
		(7213885,''2013-02-08''),
		(10228568,''2019-12-13''),
		(10396739,''2019-12-13''),
		(13084910,''2019-06-08''),
		(17657639,''2020-06-19''),
		(19866673,''2020-02-14''),
		(21944911,''2019-06-08''),
		(29471064,''2020-04-24''),
		(32644985,''2020-06-19'')
	) AS t (DiffCust, DiffFrom)
	CROSS APPLY (
		SELECT * FROM bodb_Report.dbo.rptStatement_Old rpt WITH(NOLOCK)
		WHERE rpt.Custid = t.DiffCust AND rpt.WinlostDate >= t.DiffFrom

	) AS rpt') AS rpt
)
INSERT INTO #tmpRptStatement_Old (Custid
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
		  ,[OpeningTotalBalance])
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
FROM cte_061
ORDER BY Winlostdate, CustId;


SELECT @totalRows = COUNT(1) FROM #tmpRptStatement_Old;

select @totalRows AS [@totalRows]
--TODO: Update batch by batch
WHILE (@nCount <= @totalRows)
BEGIN
	WITH cte_061 AS (
		SELECT TOP(@batch) *
		FROM #tmpRptStatement_Old 
		WHERE rIdx > @nCount
		ORDER BY rIdx ASC
	)
	UPDATE TOP(@batch) rpt 
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
	FROM bodb_Report.[dbo].[rptStatement_Old] rpt WITH(ROWLOCK, UPDLOCK)
	INNER JOIN cte_061 ON cte_061.CustId = rpt.Custid and cte_061.WinlostDate = rpt.WinlostDate

	SET @RowCount = @@ROWCOUNT;

	SELECT @RowCount AS [@RowCount], @nCount AS [@nCount], @nLoop AS [@nLoop]

	SELECT @nCount += @batch, @nLoop += 1;
	WAITFOR DELAY '00:00:00.250';
END

/**
DB062: Update rptStatement
**/
use bodb_Report;
go
---70 rows
with cte_061 AS (
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
		VALUES 
		(6630793, CAST(''2019-06-05'' AS DATE)),
		(14616559,''2019-06-06''),
		(28779564,''2019-06-10''),
		(4044289,''2020-06-12''),
		(4044290,''2020-06-12''),
		(7213817,''2013-02-08''),
		(7213821,''2013-02-02''),
		(7213885,''2013-02-08''),
		(10228568,''2019-12-13''),
		(10396739,''2019-12-13''),
		(13084910,''2019-06-08''),
		(17657639,''2020-06-19''),
		(19866673,''2020-02-14''),
		(21944911,''2019-06-08''),
		(29471064,''2020-04-24''),
		(32644985,''2020-06-19'')
	) AS t (DiffCust, DiffFrom)
	CROSS APPLY (
		SELECT * FROM bodb_Report.dbo.rptStatement rpt WITH(NOLOCK)
		WHERE rpt.Custid = t.DiffCust AND rpt.WinlostDate >= t.DiffFrom

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