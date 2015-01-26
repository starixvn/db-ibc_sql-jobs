USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_DailySummary_IP2Country]    Script Date: 01/26/2015 04:48:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_DailySummary_IP2Country]
	@winlostdate smalldatetime
AS

CREATE TABLE #tmp1 (transid bigint PRIMARY KEY, winlostdate smalldatetime, IP varchar(15))
CREATE TABLE #tmp2 (IP varchar(15) PRIMARY KEY, IPKey tinyint default 0, IPLong bigint default 0, countryShort varchar(2) default NULL)
CREATE INDEX IX_cs ON #tmp2 (countryShort)
CREATE INDEX IX_key ON #tmp2 (IPKey)
CREATE TABLE #tmp3 (IPKey tinyint PRIMARY KEY)

INSERT INTO #tmp1
SELECT transid, winlostdate, IP
FROM dbo.bettrans14 with (nolock)
WHERE winlostdate = @winlostdate

INSERT INTO #tmp2 (IP)
SELECT DISTINCT IP FROM #tmp1

UPDATE #tmp2 
SET ipKey = IPDB.dbo.ipKey(IP),
	ipLong = IPDB.dbo.ipconvert(IP)
WHERE
	IP NOT LIKE '%:%' AND IP not like 'unknown'

INSERT INTO #tmp3
SELECT DISTINCT ipKey FROM #tmp2

Declare @ipKey tinyint

Cont:

SELECT TOP 1 @ipKey = ipKey FROM #tmp3
IF @@ROWCOUNT > 0
BEGIN
	DELETE FROM #tmp3 WHERE IPKey = @ipKey

	UPDATE #tmp2
	SET countryShort = ip.countryShort
	FROM IPDB.dbo.IPTable ip with (nolock)
	INNER JOIN #tmp2
		ON #tmp2.IPKey = ip.ipKeyFrom
		AND #tmp2.IPLong BETWEEN ip.ipFROM AND ip.ipTO
	WHERE
		ip.ipKeyFrom = @ipKey
		AND #tmp2.IPKey = @ipKey
		AND #tmp2.countryShort IS NULL

	GOTO Cont
END

UPDATE #tmp2
SET countryShort = ip.countryShort
FROM IPDB.dbo.IPTable ip with (nolock)
INNER JOIN #tmp2
	ON #tmp2.IPKey BETWEEN ip.ipKeyFrom AND ip.ipKeyTO
	AND #tmp2.IPLong BETWEEN ip.ipFROM AND ip.ipTO
WHERE
	#tmp2.countryShort IS NULL


DELETE FROM dbo.Task_bettrans14_IP2Country WHERE winlostdate = @winlostdate

INSERT INTO dbo.Task_bettrans14_IP2Country (transid, winlostdate, CountryShort)
SELECT t1.transid, t1.winlostdate, t2.countryShort
FROM #tmp1 t1 INNER JOIN #tmp2 t2 ON t1.IP = t2.IP

DROP TABLE #tmp2
DROP TABLE #tmp3
DROP TABLE #tmp1

GO


