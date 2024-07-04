USE bodb02
GO
truncate table odds
truncate table Single_Calculate_Queue
truncate table oddsES
truncate table odds14
truncate table SiteDB_SettlementService_CalculationLog
truncate table SiteDB_SettlementService_CalculationLog_3rd
truncate table SiteDB_SettlementService_LastLog
truncate table SiteDB_SettlementService_LastLog_3rd
truncate table TVS_UserActionLog
truncate table MarkedTransaction
truncate table ParlayLockingHistory
truncate table Parlay_Calculate_Queue


DECLARE @batchNo INT = 10000DECLARE @todate SMALLDATETIME = DATEADD(MONTH, -3, GETDATE())
-- transfer
BEGIN	 while (1=1)	 begin		 DELETE top (@batchNo)FROM transfer WHERE winlostdate < @todate		 if @@rowcount <> @batchNo			break	endEND-- bettrans
BEGIN	 while (1=1)	 begin		 DELETE top (@batchNo)FROM bettrans WHERE winlostdate < @todate		 if @@rowcount <> @batchNo			break	endEND
-- bettrans14
BEGIN
	while (1=1)	 begin		 DELETE top (@batchNo)FROM bettrans14 WHERE winlostdate < @todate		 if @@rowcount <> @batchNo			break	endEND
-- bettransM, betparlaydetail
BEGIN	SELECT	refno	into #tmprefno	FROM	dbo.bettrans b 	WHERE	b.matchid = 29	SELECT	bm.transid	into #tmpSubTransId	FROM	dbo.bettransm bm WITH(NOLOCK)		LEFT JOIN #tmprefno r			ON bm.refno = r.refno	WHERE	r.refno IS NULL	 while (1=1)	 begin		 DELETE top (@batchNo) bm		 FROM bettransm bm			inner join #tmpSubTransId t				ON bm.transid = t.transid		 		 if @@rowcount <> @batchNo			break	end	DROP TABLE #tmpSubTransId	SELECT refno	into #tmpDeletedRefnoBetParlayDetail	FROM	betparlaydetail p WITH(NOLOCK)	WHERE	not exists (SELECT refno from #tmprefno t WHERE t.refno = p.refno)	 while (1=1)	 begin		 DELETE top (@batchNo) p		 FROM betparlaydetail p			inner join #tmpDeletedRefnoBetParlayDetail t				ON p.refno = t.refno		 		 if @@rowcount <> @batchNo			break	end	DROP TABLE #tmpDeletedRefnoBetParlayDetail	DROP TABLE #tmprefno	END-- translog
BEGIN	 while (1=1)	 begin		 DELETE top (@batchNo)FROM translog WHERE winlostdate < @todate		 if @@rowcount <> @batchNo			break	endEND-- translog14
BEGIN	 while (1=1)	 begin		 DELETE top (@batchNo)FROM translog14 WHERE winlostdate < @todate		 if @@rowcount <> @batchNo			break	endEND-- zzzbettrans
BEGIN	 while (1=1)	 begin		 DELETE top (@batchNo)FROM zzzbettrans WHERE transdate < @todate		 if @@rowcount <> @batchNo			break	endEND