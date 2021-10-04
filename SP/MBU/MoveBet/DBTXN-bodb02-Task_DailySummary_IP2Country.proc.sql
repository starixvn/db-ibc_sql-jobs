ALTER PROCEDURE [dbo].[Task_DailySummary_IP2Country]
	@winlostdate smalldatetime,
	@target varchar(20) = 'all'
AS

/*
	Create By: Unknow
	Task: Archive bet data for IP country
	DB: DBTXN/bodb02
	Revisions:
		- 20190523@Patrick: Convert NULL IP value to empty [RedmineId: #113997]
		- 20211004@Helen:	Support IPv6 Phase 1 - change datatype first - [Redmine: #160390]

	Para's explaination
*/

CREATE TABLE #tmp1 (transid bigint PRIMARY KEY, winlostdate smalldatetime, IP varchar(45))
CREATE TABLE #tmp2 (IP varchar(45) PRIMARY KEY, IPKey tinyint default 0, IPLong bigint default 0, countryShort varchar(2) default NULL)
CREATE INDEX IX_cs ON #tmp2 (countryShort)
CREATE INDEX IX_key ON #tmp2 (IPKey)
CREATE TABLE #tmp3 (IPKey tinyint PRIMARY KEY)

Declare @ipKey tinyint


IF @target NOT IN ('all', 'bettrans14') GOTO End_Bettrans14

INSERT INTO #tmp1
SELECT transid, winlostdate, ISNULL(IP, '') AS IP
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


Cont1:

SELECT TOP 1 @ipKey = ipKey FROM #tmp3
IF @@ROWCOUNT > 0
BEGIN
	DELETE FROM #tmp3 WHERE IPKey = @ipKey

	UPDATE #tmp2
	SET countryShort = ip.countryShort
	FROM IPDB.dbo.IPTable_Mini ip with (nolock)
	INNER JOIN #tmp2
		ON #tmp2.IPKey = ip.ipKey
		AND #tmp2.IPLong BETWEEN ip.ipFROM AND ip.ipTO
	WHERE
		ip.ipKey = @ipKey
		AND #tmp2.IPKey = @ipKey
		AND #tmp2.countryShort IS NULL

	GOTO Cont1
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

End_Bettrans14:



IF @target NOT IN ('all', 'bettransRNG14') GOTO End_BettransRNG14

TRUNCATE TABLE #tmp1
TRUNCATE TABLE #tmp2
TRUNCATE TABLE #tmp3

INSERT INTO #tmp1
SELECT transid, winlostdate, ISNULL(IP, '') AS IP
FROM dbo.bettransRNG14 with (nolock)
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

Cont_bettransRNG:

SELECT TOP 1 @ipKey = ipKey FROM #tmp3
IF @@ROWCOUNT > 0
BEGIN
	DELETE FROM #tmp3 WHERE IPKey = @ipKey

	UPDATE #tmp2
	SET countryShort = ip.countryShort
	FROM IPDB.dbo.IPTable_Mini ip with (nolock)
	INNER JOIN #tmp2
		ON #tmp2.IPKey = ip.ipKey
		AND #tmp2.IPLong BETWEEN ip.ipFROM AND ip.ipTO
	WHERE
		ip.ipKey = @ipKey
		AND #tmp2.IPKey = @ipKey
		AND #tmp2.countryShort IS NULL

	GOTO Cont_bettransRNG
END

UPDATE #tmp2
SET countryShort = ip.countryShort
FROM IPDB.dbo.IPTable ip with (nolock)
INNER JOIN #tmp2
	ON #tmp2.IPKey BETWEEN ip.ipKeyFrom AND ip.ipKeyTO
	AND #tmp2.IPLong BETWEEN ip.ipFROM AND ip.ipTO
WHERE
	#tmp2.countryShort IS NULL


DELETE FROM dbo.Task_bettransRNG14_IP2Country WHERE winlostdate = @winlostdate

INSERT INTO dbo.Task_bettransRNG14_IP2Country (transid, winlostdate, CountryShort)
SELECT t1.transid, t1.winlostdate, t2.countryShort
FROM #tmp1 t1 INNER JOIN #tmp2 t2 ON t1.IP = t2.IP

End_bettransRNG14:



IF @target NOT IN ('all', 'bettransLC14') GOTO End_bettransLC14

TRUNCATE TABLE #tmp1
TRUNCATE TABLE #tmp2
TRUNCATE TABLE #tmp3

INSERT INTO #tmp1
SELECT transid, winlostdate, ISNULL(IP, '') AS IP
FROM dbo.bettransLC14 with (nolock)
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

Cont_bettransLC:

SELECT TOP 1 @ipKey = ipKey FROM #tmp3
IF @@ROWCOUNT > 0
BEGIN
	DELETE FROM #tmp3 WHERE IPKey = @ipKey

	UPDATE #tmp2
	SET countryShort = ip.countryShort
	FROM IPDB.dbo.IPTable_Mini ip with (nolock)
	INNER JOIN #tmp2
		ON #tmp2.IPKey = ip.ipKey
		AND #tmp2.IPLong BETWEEN ip.ipFROM AND ip.ipTO
	WHERE
		ip.ipKey = @ipKey
		AND #tmp2.IPKey = @ipKey
		AND #tmp2.countryShort IS NULL

	GOTO Cont_bettransLC
END

UPDATE #tmp2
SET countryShort = ip.countryShort
FROM IPDB.dbo.IPTable ip with (nolock)
INNER JOIN #tmp2
	ON #tmp2.IPKey BETWEEN ip.ipKeyFrom AND ip.ipKeyTO
	AND #tmp2.IPLong BETWEEN ip.ipFROM AND ip.ipTO
WHERE
	#tmp2.countryShort IS NULL


DELETE FROM dbo.Task_bettransLC14_IP2Country WHERE winlostdate = @winlostdate

INSERT INTO dbo.Task_bettransLC14_IP2Country (transid, winlostdate, CountryShort)
SELECT t1.transid, t1.winlostdate, t2.countryShort
FROM #tmp1 t1 INNER JOIN #tmp2 t2 ON t1.IP = t2.IP

End_bettransLC14:



DROP TABLE #tmp2
DROP TABLE #tmp3
DROP TABLE #tmp1

GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/