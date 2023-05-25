/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_DailySummary_IP2Country_BettransRnG14]
(
	@winlostdate SMALLDATETIME,
	@isdebug BIT = 0
)
AS

/*
	Create By: Unknow
	Task: Archive bet data for IP country
	DB: DBTXN/bodb02
	Revisions:
		- 20190523@Patrick: Convert NULL IP value to empty [RedmineId: #113997]
		- 20211004@Helen:	Support IPv6 Phase 1 - change datatype first - [Redmine: #160390]
		- 20230524@Patrick: Enhance code to avoid log growth [Redmine: #188699]

	Para's explaination
*/
BEGIN
	SET NOCOUNT ON
	CREATE TABLE #tmp1 (transid BIGINT PRIMARY KEY, IP VARCHAR(45))
	CREATE TABLE #tmp2 (rowId INT IDENTITY(1,1) PRIMARY KEY, IP VARCHAR(45)
		, IPvX    TINYINT DEFAULT 0, IPArchive VARCHAR(45)
		, v4IPKey TINYINT DEFAULT 0, v4IPLong BIGINT DEFAULT 0
		, v6KeyValue BINARY(2), v6IPValue BINARY(16)
		, countryShort VARCHAR(2) DEFAULT NULL
		)
	CREATE INDEX IX_IP ON #tmp2 (IP) INCLUDE (CountryShort, IPArchive)
	CREATE INDEX IX_IPvX ON #tmp2 (IPvX) INCLUDE (v4IPKey, v6KeyValue)

	CREATE TABLE #tmp4 (IPKey TINYINT PRIMARY KEY)
	CREATE TABLE #tmp6 (KeyValue BINARY(2) PRIMARY KEY)

	DECLARE @ipKey TINYINT, @KeyValue BINARY(2)
	DECLARE @IPFull VARCHAR(45), @IPvX TINYINT, @IPArchive VARCHAR(16)
	DECLARE @__skip INT = 0, @__fetch INT = 500000, @__rowId INT = 1
		, @__messageInfo VARCHAR(200), @__totalIp INT = 0

	CREATE TABLE #tmpIds (IP VARCHAR(45), transId BIGINT)

	SELECT @__skip = 0, @__rowId = 1
	--remove old data if exists
	WHILE 1 = 1
	BEGIN
		DELETE TOP(@__fetch) 
		FROM dbo.Task_bettransRNG14_IP2Country WHERE winlostdate = @winlostdate

		IF @@ROWCOUNT = 0
			BREAK

	END

	--get all ip by @winlostdate
	WHILE 1 = 1
	BEGIN

		INSERT INTO #tmp1 (transid, IP)
		SELECT transid, ISNULL(IP, '') AS IP
		FROM dbo.bettransRnG14 WITH (NOLOCK)
		WHERE winlostdate = @winlostdate
		ORDER BY transid
		OFFSET @__skip ROWS FETCH NEXT @__fetch ROWS ONLY

		IF @@ROWCOUNT = 0
			BREAK

		SET @__skip += @__fetch

		IF @isdebug = 1
		BEGIN
			SET @__messageInfo = '#01: curdt: ' + convert(varchar(50), getdate(), 121) + ' - @__skip: ' + cast(@__skip as varchar(50))
			RAISERROR(@__messageInfo, 0, 1) with nowait
		END
	END

	INSERT INTO #tmp2 (IP)
	SELECT DISTINCT IP FROM #tmp1

	SET @__totalIp = @@ROWCOUNT

	IF @isdebug = 1
	BEGIN
		SET @__messageInfo = '#02: curdt: ' + convert(varchar(50), getdate(), 121) + ' - @__totalIp: ' + cast(@__totalIp as varchar(50))
		RAISERROR(@__messageInfo, 0, 1) with nowait
	END

	WHILE @__rowId <= @__totalIp
	BEGIN
			
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
				v6KeyValue = CASE @IPvX WHEN 6 THEN CONVERT(binary(2), LEFT(@IPFull,4), 2) END,
				v6IPValue  = CASE @IPvX WHEN 6 THEN CONVERT(binary(16), @IPFull, 2) END
		FROM #tmp2 t
			CROSS APPLY (SELECT FullForm FROM dbo.f_IP_FullForm (t.IP)) AS fIP
		WHERE IP NOT LIKE 'unknown' AND IP <> ''
			AND rowId = @__rowId

		SET @__rowId += 1

		IF @isdebug = 1
		BEGIN
			SET @__messageInfo = '#03: curdt: ' + convert(varchar(50), getdate(), 121) + ' - @__rowId: ' + cast(@__rowId as varchar(50))
			RAISERROR(@__messageInfo, 0, 1) with nowait
		END
	END

	INSERT INTO #tmp4
	SELECT DISTINCT v4IPKey FROM #tmp2 WHERE IPvX = 4

	WHILE EXISTS(SELECT 1 FROM #tmp4)
	BEGIN
		SELECT TOP 1 @ipKey = ipKey FROM #tmp4

		UPDATE #tmp2
		SET countryShort = ip.countryShort
		FROM IPDB.dbo.IPTable_Mini ip WITH (NOLOCK)
			INNER JOIN #tmp2 ON #tmp2.v4IPKey = ip.ipKey AND #tmp2.v4IPLong BETWEEN ip.ipFrom AND ip.ipTo
		WHERE #tmp2.IPvX = 4 AND v4IPKey = @ipKey

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
		WHERE #tmp2.IPvX = 6 AND v6KeyValue = @KeyValue

		DELETE FROM #tmp6 WHERE KeyValue = @KeyValue
	END

	WHILE 1 = 1
	BEGIN
		TRUNCATE TABLE #tmpIds

		DELETE TOP(@__fetch) FROM #tmp1 OUTPUT deleted.IP, deleted.transid
		INTO #tmpIds(IP, transId)

		IF @@ROWCOUNT = 0
			BREAK

		INSERT INTO dbo.Task_bettransRNG14_IP2Country (transid, winlostdate, CountryShort, IPArchive)
		SELECT t1.transId, @winlostdate, t2.countryShort, ISNULL(t2.IPArchive,'') 
		FROM #tmpIds t1
			INNER JOIN #tmp2 t2 ON t1.IP = t2.IP

		IF @isdebug = 1
		BEGIN
			SET @__messageInfo = '#04: curdt: ' + convert(varchar(50), getdate(), 121)
			RAISERROR(@__messageInfo, 0, 1) with nowait
		END
	END

	DROP TABLE #tmp1
	DROP TABLE #tmp2
	DROP TABLE #tmp4
	DROP TABLE #tmp6
	DROP TABLE #tmpIds
END