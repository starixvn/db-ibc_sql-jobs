/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_DailySummary_IP2Country]
(
	@winlostdate SMALLDATETIME,
	@target VARCHAR(20) = 'all'
)
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
BEGIN
	CREATE TABLE #tmp1 (transid BIGINT PRIMARY KEY, winlostdate SMALLDATETIME, IP VARCHAR(45))
	CREATE TABLE #tmp2 (IP VARCHAR(45) PRIMARY KEY
		, IPvX    TINYINT DEFAULT 0, IPArchive VARCHAR(45)
		, v4IPKey TINYINT DEFAULT 0, v4IPLong BIGINT DEFAULT 0
		, v6KeyValue BINARY(2), v6IPValue BINARY(16)
		, countryShort VARCHAR(2) DEFAULT NULL
		)
	CREATE INDEX IX_cs    ON #tmp2 (countryShort)
	CREATE INDEX IX_IPvX  ON #tmp2 (IPvX)
	CREATE INDEX IX_v4key ON #tmp2 (IPvX, v4IPKey) --WHERE IPvX = 4
	CREATE INDEX IX_v6key ON #tmp2 (IPvX, v6KeyValue) --WHERE IPvX = 6

	CREATE TABLE #tmp4 (IPKey TINYINT PRIMARY KEY)
	CREATE TABLE #tmp6 (KeyValue BINARY(2) PRIMARY KEY)

	DECLARE @ipKey TINYINT, @KeyValue BINARY(2)
	DECLARE @IPFull varchar(45), @IPvX TINYINT, @IPArchive varchar(16)

	IF @target NOT IN ('all', 'bettrans14') GOTO End_Bettrans14

	INSERT INTO #tmp1 (transid, winlostdate, IP)
	SELECT transid, winlostdate, ISNULL(IP, '') AS IP
	FROM dbo.bettrans14 with (nolock)
	WHERE winlostdate = @winlostdate 

	INSERT INTO #tmp2 (IP)
	SELECT DISTINCT IP FROM #tmp1

	UPDATE t 
		SET @IPFull    = fIP.FullForm,
			@IPvX      = CASE WHEN LEFT(@IPFull,24) = '00000000000000000000FFFF' THEN 4 ELSE 6 END,
			IPArchive  = CASE @IPvX
				WHEN 6 THEN CONVERT(varchar(16), CONVERT(binary(16), @IPFull, 2))
				WHEN 4 THEN CONVERT(varchar(16), CONVERT(binary(4) , RIGHT(@IPFull,8), 2))
				END,
			IPvX       = @IPvX,
			v4IPKey    = CASE @IPvX WHEN 4 THEN CONVERT(tinyint, CONVERT(binary(1), SUBSTRING(@IPFull,25,2), 2)) END,
			v4IPLong   = CASE @IPvX WHEN 4 THEN CONVERT(bigint , CONVERT(binary(4), SUBSTRING(@IPFull,25,8), 2)) END,
			v6KeyValue = CASE @IPvX WHEN 6 THEN CONVERT(binary(2) , LEFT(@IPFull,4), 2) END,
			v6IPValue  = CASE @IPvX WHEN 6 THEN CONVERT(binary(16), @IPFull, 2) END
	FROM #tmp2 t
		CROSS APPLY (SELECT FullForm FROM dbo.f_IP_FullForm (t.IP)) AS fIP
	WHERE
		IP not like 'unknown'
		AND IP <> ''

	INSERT INTO #tmp4
	SELECT DISTINCT v4IPKey FROM #tmp2 WHERE IPvX = 4

	WHILE EXISTS(SELECT 1 FROM #tmp4)
	BEGIN
		SELECT TOP 1 @ipKey = ipKey FROM #tmp4

		UPDATE #tmp2
		SET countryShort = ip.countryShort
		FROM IPDB.dbo.IPTable_Mini ip WITH (NOLOCK)
			INNER JOIN #tmp2 ON #tmp2.v4IPKey = ip.ipKey AND #tmp2.v4IPLong BETWEEN ip.ipFrom AND ip.ipTo
		WHERE
			#tmp2.IPvX = 4 AND v4IPKey = @ipKey

		DELETE FROM #tmp4 WHERE IPKey = @ipKey
	END


	INSERT INTO #tmp6
	SELECT DISTINCT v6KeyValue FROM #tmp2 WHERE IPvX = 6

	WHILE EXISTS(SELECT 1 FROM #tmp6)
	BEGIN
		SELECT TOP 1 @KeyValue = KeyValue FROM #tmp6

		UPDATE #tmp2
		SET countryShort = ip.country_code
		FROM IPDB.dbo.KeyMap_IPv6_DB1 aux WITH (NOLOCK)
			INNER JOIN IPDB.dbo.IPv6_DB1 ip WITH (NOLOCK) ON aux.ipKey = ip.ipKey
			INNER JOIN #tmp2 ON #tmp2.v6KeyValue = aux.KeyValue AND #tmp2.v6IPValue BETWEEN ip.ipFROM AND ip.ipTo
		WHERE
			#tmp2.IPvX = 6 AND v6KeyValue = @KeyValue

		DELETE FROM #tmp6 WHERE KeyValue = @KeyValue
	END

	DELETE FROM dbo.Task_bettrans14_IP2Country WHERE winlostdate = @winlostdate

	INSERT INTO dbo.Task_bettrans14_IP2Country (transid, winlostdate, CountryShort, IPArchive)
	SELECT t1.transid, t1.winlostdate, t2.countryShort, ISNULL(t2.IPArchive,'') AS IPArchive 
	FROM #tmp1 t1 INNER JOIN #tmp2 t2 ON t1.IP = t2.IP

	End_Bettrans14:

	TRUNCATE TABLE #tmp1
	TRUNCATE TABLE #tmp2
	TRUNCATE TABLE #tmp4
	TRUNCATE TABLE #tmp6

	IF @target NOT IN ('all', 'bettransRNG14') GOTO End_BettransRNG14

	INSERT INTO #tmp1 (transid, winlostdate, IP)
	SELECT transid, winlostdate, ISNULL(IP, '') AS IP
	FROM dbo.bettransRNG14 with (nolock)
	WHERE winlostdate = @winlostdate
		
	INSERT INTO #tmp2 (IP)
	SELECT DISTINCT IP FROM #tmp1

	UPDATE t 
	SET @IPFull    = fIP.FullForm,
		@IPvX      = CASE WHEN LEFT(@IPFull,24) = '00000000000000000000FFFF' THEN 4 ELSE 6 END,
		IPArchive  = CASE @IPvX
			WHEN 6 THEN CONVERT(varchar(16), CONVERT(binary(16), @IPFull, 2))
			WHEN 4 THEN CONVERT(varchar(16), CONVERT(binary(4) , RIGHT(@IPFull,8), 2))
			END,
		IPvX       = @IPvX,
		v4IPKey    = CASE @IPvX WHEN 4 THEN CONVERT(tinyint, CONVERT(binary(1), SUBSTRING(@IPFull,25,2), 2)) END,
		v4IPLong   = CASE @IPvX WHEN 4 THEN CONVERT(bigint , CONVERT(binary(4), SUBSTRING(@IPFull,25,8), 2)) END,
		v6KeyValue = CASE @IPvX WHEN 6 THEN CONVERT(binary(2) , LEFT(@IPFull,4), 2) END,
		v6IPValue  = CASE @IPvX WHEN 6 THEN CONVERT(binary(16), @IPFull, 2) END
	FROM #tmp2 t
		CROSS APPLY (SELECT FullForm FROM dbo.f_IP_FullForm (t.IP)) AS fIP
	WHERE
		IP not like 'unknown'
		AND IP <> ''

	INSERT INTO #tmp4
	SELECT DISTINCT v4IPKey FROM #tmp2 WHERE IPvX = 4

	WHILE EXISTS(SELECT 1 FROM #tmp4)
	BEGIN
		SELECT TOP 1 @ipKey = ipKey FROM #tmp4

		UPDATE #tmp2
		SET countryShort = ip.countryShort
		FROM IPDB.dbo.IPTable_Mini ip WITH (NOLOCK)
			INNER JOIN #tmp2 ON #tmp2.v4IPKey = ip.ipKey AND #tmp2.v4IPLong BETWEEN ip.ipFrom AND ip.ipTo
		WHERE
			#tmp2.IPvX = 4 AND v4IPKey = @ipKey

		DELETE FROM #tmp4 WHERE IPKey = @ipKey
	END


	INSERT INTO #tmp6
	SELECT DISTINCT v6KeyValue FROM #tmp2 WHERE IPvX = 6

	WHILE EXISTS(SELECT 1 FROM #tmp6)
	BEGIN
		SELECT TOP 1 @KeyValue = KeyValue FROM #tmp6

		UPDATE #tmp2
		SET countryShort = ip.country_code
		FROM IPDB.dbo.KeyMap_IPv6_DB1 aux WITH (NOLOCK)
			INNER JOIN IPDB.dbo.IPv6_DB1 ip WITH (NOLOCK) ON aux.ipKey = ip.ipKey
			INNER JOIN #tmp2 ON #tmp2.v6KeyValue = aux.KeyValue AND #tmp2.v6IPValue BETWEEN ip.ipFROM AND ip.ipTo
		WHERE
			#tmp2.IPvX = 6 AND v6KeyValue = @KeyValue

		DELETE FROM #tmp6 WHERE KeyValue = @KeyValue
	END

	DELETE FROM dbo.Task_bettransRNG14_IP2Country WHERE winlostdate = @winlostdate

	INSERT INTO dbo.Task_bettransRNG14_IP2Country (transid, winlostdate, CountryShort, IPArchive)
	SELECT t1.transid, t1.winlostdate, t2.countryShort, t2.IPArchive
	FROM #tmp1 t1 INNER JOIN #tmp2 t2 ON t1.IP = t2.IP

	End_bettransRNG14:

	TRUNCATE TABLE #tmp1
	TRUNCATE TABLE #tmp2
	TRUNCATE TABLE #tmp4
	TRUNCATE TABLE #tmp6


	IF @target NOT IN ('all', 'bettransLC14') GOTO End_bettransLC14

	INSERT INTO #tmp1 (transid, winlostdate, IP)
	SELECT transid, winlostdate, ISNULL(IP, '') AS IP
	FROM dbo.bettransLC14 with (nolock)
	WHERE winlostdate = @winlostdate
		
	INSERT INTO #tmp2 (IP)
	SELECT DISTINCT IP FROM #tmp1

	UPDATE t
	SET @IPFull    = fIP.FullForm,
		@IPvX      = CASE WHEN LEFT(@IPFull,24) = '00000000000000000000FFFF' THEN 4 ELSE 6 END,
		IPArchive  = CASE @IPvX
			WHEN 6 THEN CONVERT(varchar(16), CONVERT(binary(16), @IPFull, 2))
			WHEN 4 THEN CONVERT(varchar(16), CONVERT(binary(4) , RIGHT(@IPFull,8), 2))
			END,
		IPvX       = @IPvX,
		v4IPKey    = CASE @IPvX WHEN 4 THEN CONVERT(tinyint, CONVERT(binary(1), SUBSTRING(@IPFull,25,2), 2)) END,
		v4IPLong   = CASE @IPvX WHEN 4 THEN CONVERT(bigint , CONVERT(binary(4), SUBSTRING(@IPFull,25,8), 2)) END,
		v6KeyValue = CASE @IPvX WHEN 6 THEN CONVERT(binary(2) , LEFT(@IPFull,4), 2) END,
		v6IPValue  = CASE @IPvX WHEN 6 THEN CONVERT(binary(16), @IPFull, 2) END
	
	FROM #tmp2 t
		CROSS APPLY (SELECT FullForm FROM dbo.f_IP_FullForm (t.IP)) AS fIP
	WHERE
		IP not like 'unknown'
		AND IP <> ''

	INSERT INTO #tmp4
	SELECT DISTINCT v4IPKey FROM #tmp2 WHERE IPvX = 4

	WHILE EXISTS(SELECT 1 FROM #tmp4)
	BEGIN
		SELECT TOP 1 @ipKey = ipKey FROM #tmp4

		UPDATE #tmp2
		SET countryShort = ip.countryShort
		FROM IPDB.dbo.IPTable_Mini ip WITH (NOLOCK)
			INNER JOIN #tmp2 ON #tmp2.v4IPKey = ip.ipKey AND #tmp2.v4IPLong BETWEEN ip.ipFrom AND ip.ipTo
		WHERE
			#tmp2.IPvX = 4 AND v4IPKey = @ipKey

		DELETE FROM #tmp4 WHERE IPKey = @ipKey
	END


	INSERT INTO #tmp6
	SELECT DISTINCT v6KeyValue FROM #tmp2 WHERE IPvX = 6

	WHILE EXISTS(SELECT 1 FROM #tmp6)
	BEGIN
		SELECT TOP 1 @KeyValue = KeyValue FROM #tmp6

		UPDATE #tmp2
		SET countryShort = ip.country_code
		FROM IPDB.dbo.KeyMap_IPv6_DB1 aux WITH (NOLOCK)
			INNER JOIN IPDB.dbo.IPv6_DB1 ip WITH (NOLOCK) ON aux.ipKey = ip.ipKey
			INNER JOIN #tmp2 ON #tmp2.v6KeyValue = aux.KeyValue AND #tmp2.v6IPValue BETWEEN ip.ipFROM AND ip.ipTo
		WHERE
			#tmp2.IPvX = 6 AND v6KeyValue = @KeyValue

		DELETE FROM #tmp6 WHERE KeyValue = @KeyValue
	END

	DELETE FROM dbo.Task_bettransLC14_IP2Country WHERE winlostdate = @winlostdate

	INSERT INTO dbo.Task_bettransLC14_IP2Country (transid, winlostdate, CountryShort, IPArchive)
	SELECT t1.transid, t1.winlostdate, t2.countryShort, t2.IPArchive
	FROM #tmp1 t1 INNER JOIN #tmp2 t2 ON t1.IP = t2.IP

	End_bettransLC14:

	DROP TABLE #tmp1
	DROP TABLE #tmp2
	DROP TABLE #tmp4
	DROP TABLE #tmp6
END
GO

