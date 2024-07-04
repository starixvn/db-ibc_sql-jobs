USE bodb02
GO
SET NOCOUNT ON

TRUNCATE TABLE sb.CalculationLogs
TRUNCATE TABLE SSB_SettlementLogs
TRUNCATE TABLE MarkedTransaction
TRUNCATE TABLE Odds
TRUNCATE TABLE Odds14
TRUNCATE TABLE oddsOS
TRUNCATE TABLE oddsES
TRUNCATE TABLE translog14


DECLARE @batchNo INT = 10000DECLARE @todate SMALLDATETIME = DATEADD(MONTH, -3, GETDATE())
-- bettrans
BEGIN	 while (1=1)	 begin		 DELETE top (@batchNo)FROM bettrans WHERE winlostdate < @todate		 if @@rowcount <> @batchNo			break	endEND
-- bettransM
BEGIN	SELECT	refno	into #tmprefno	FROM	dbo.bettrans b 	WHERE	b.matchid = 29	SELECT	bm.transid	into #tmpSubTransId	FROM	dbo.bettransm bm WITH(NOLOCK)		LEFT JOIN #tmprefno r			ON bm.refno = r.refno	WHERE	r.refno IS NULL	 while (1=1)	 begin		 DELETE top (@batchNo) bm		 FROM bettransm bm			inner join #tmpSubTransId t				ON bm.transid = t.transid		 		 if @@rowcount <> @batchNo			break	end	DROP TABLE #tmprefno	DROP TABLE #tmpSubTransIdEND-- zzzbettrans
BEGIN
	DECLARE @KeyId BIGINT		select top 1 @KeyId = keyid from zzzbettrans where transdate < @todate order by transdate desc	 while (1=1)	 begin		 DELETE top (@batchNo)FROM zzzbettrans WHERE keyid <= @keyid		 if @@rowcount <> @batchNo			break	endEND
-- bettrans14
BEGIN
	while (1=1)	 begin		 DELETE top (@batchNo)FROM bettrans14 WHERE winlostdate < @todate		 if @@rowcount <> @batchNo			break	endEND-- bettransRnG14
BEGIN
	while (1=1)	 begin		 DELETE top (@batchNo)FROM bettransRnG14 WHERE winlostdate < @todate		 if @@rowcount <> @batchNo			break	endEND-- bettransRnG
BEGIN	 while (1=1)	 begin		 DELETE top (@batchNo)FROM bettransRnG WHERE winlostdate < @todate		 if @@rowcount <> @batchNo			break	endEND