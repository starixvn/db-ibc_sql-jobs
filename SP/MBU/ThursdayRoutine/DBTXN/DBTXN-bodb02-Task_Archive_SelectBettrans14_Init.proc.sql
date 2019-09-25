SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE [dbo].[Task_Archive_SelectBettrans14_Init]
	@batchsize int = 0
AS
/*
Set of SP
	Task_Archive_SelectBettrans14_Init : prepare list of winlostdate/custid
	Task_Archive_SelectBettrans14
	Task_Archive_SelectBettrans14_Done

	Task_Archive_SelectbetParlayResult
*/
--clean up
DELETE FROM dbo.tmp_Task_Archive_Bettrans14


IF @batchsize = 0
	INSERT INTO dbo.tmp_Task_Archive_Bettrans14 (wldate)
	SELECT winlostdate FROM dbo.Task_ArchiveDate
	ORDER BY 1
ELSE
BEGIN

		DECLARE @max_custid TABLE (winlostdate DATETIME PRIMARY KEY, custid int)

		INSERT INTO @max_custid (winlostdate, custid)
		SELECT b.winlostdate, MAX(custid) custid
		FROM dbo.bettrans14 b WITH (NOLOCK)
		INNER JOIN dbo.Task_ArchiveDate t WITH (NOLOCK) ON b.winlostdate = t.winlostdate
		GROUP BY b.winlostdate

	;WITH CTE AS (
		SELECT b.winlostdate, custid, ROW_NUMBER() OVER (PARTITION BY b.winlostdate ORDER BY custid) RN
		FROM dbo.bettrans14 b WITH (NOLOCK)
		INNER JOIN dbo.Task_ArchiveDate t WITH (NOLOCK) ON b.winlostdate = t.winlostdate
	)
	INSERT INTO dbo.tmp_Task_Archive_Bettrans14 (wldate, c1)
	SELECT DISTINCT winlostdate, custid
	FROM CTE
	WHERE RN%@batchsize = 1
	ORDER BY winlostdate, custid

	UPDATE x
	SET c2 = y.c1 - 1
	FROM dbo.tmp_Task_Archive_Bettrans14 x
		INNER JOIN dbo.tmp_Task_Archive_Bettrans14 y ON x.rn+1 = y.rn

	;WITH maxrn AS (SELECT wldate, MAX(rn) RN FROM dbo.tmp_Task_Archive_Bettrans14 GROUP BY wldate)
	UPDATE t
	SET c2 = x.custid
	FROM dbo.tmp_Task_Archive_Bettrans14 t
		INNER JOIN maxrn ON t.rn = maxrn.RN
		INNER JOIN @max_custid x ON t.wldate = x.winlostdate

END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/