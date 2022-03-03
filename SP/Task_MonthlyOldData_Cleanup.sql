/*<info serverAlias="DBBAL-bodb_LicenseeReport" executers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Task_MonthlyOldData_Cleanup]  
AS  
/*  
	Created: 20220303@Evan
	Task: Remove monthly data on DBBAL -[169074]
	DB: DBBAL-bodb_LicenseeReport

	Revisions:	
	- 20220303@Evan: Initialize SPs [RedmineID : #169074]
*/  
 
BEGIN  
declare @CutOffDate smalldatetime 
-- Keep data of 3 months
Select @CutOffDate =  dateadd(MONTH, -3,dateadd(DAY, -day(getdate())+1, cast(getdate() as date)))
declare @BatchSize INT = 5000
declare @batch table (recommend int primary key);

-- rptCustomerTurnover
select distinct recommend 
into #tmpRecc
from dbo.rptCustomerTurnover with(nolock) where winlostdate < @CutOffDate
while exists(select 1 from #tmpRecc)
begin 
	delete top(100) d
	output deleted.recommend into @batch
	from #tmpRecc d
	while 1 = 1
	begin
		delete top(@BatchSize) rpt
		from dbo.rptCustomerTurnover rpt
		inner join @batch b on b.recommend = rpt.recommend
		where rpt.winlostdate < @CutOffDate
		IF @@ROWCOUNT < @BatchSize
			break
	end
	DELETE FROM @batch;
end

-- rptCasinoTurnover
insert into #tmpRecc
select distinct recommend from dbo.rptCasinoTurnover with(nolock) where WinlostDate < @CutOffDate
while exists(select 1 from #tmpRecc)
begin 
	delete top(100) d
	output deleted.recommend into @batch
	from #tmpRecc d
	while 1 = 1
	begin
		delete top(@BatchSize) rpt
		from dbo.rptCasinoTurnover rpt
		inner join @batch b on b.recommend = rpt.recommend
		where rpt.WinlostDate < @CutOffDate
		IF @@ROWCOUNT < @BatchSize
			break
	end
	DELETE FROM @batch;
end
DROP TABLE #tmpRecc

-- rpt_BettingParlay
CREATE TABLE #tempBettingParlay(
	RecordID BIGINT PRIMARY KEY,
	Isfinished BIT
)
CREATE TABLE #BettingParlay_batch(
	RecordID BIGINT PRIMARY KEY
)
INSERT INTO #tempBettingParlay (RecordID)
SELECT RecordID FROM dbo.rpt_BettingParlay WITH (NOLOCK) where rptDate < @CutOffDate
while 1 = 1
begin
	UPDATE TOP (@BatchSize) R
		SET Isfinished = 1	
	OUTPUT DELETED.RecordID
		INTO #BettingParlay_batch (RecordID)		
	FROM #tempBettingParlay r
	WHERE r.Isfinished IS NULL
	
	IF @@ROWCOUNT = 0
		BREAK
	DELETE s 
	FROM dbo.rpt_BettingParlay s 
		INNER JOIN #BettingParlay_batch t ON t.RecordID = s.RecordID
	TRUNCATE TABLE #BettingParlay_batch
end
DROP TABLE #tempBettingParlay
DROP TABLE #BettingParlay_batch

-- match
CREATE TABLE #tempmatch(
	matchid BIGINT PRIMARY KEY,
	Isfinished BIT
)
CREATE TABLE #match_batch(
	matchid BIGINT PRIMARY KEY
)
INSERT INTO #tempmatch (matchid)
SELECT matchid FROM dbo.match WITH (NOLOCK) where eventdate < @CutOffDate
while 1 = 1
begin
	UPDATE TOP (@BatchSize) R
		SET Isfinished = 1	
	OUTPUT DELETED.matchid
		INTO #match_batch (matchid)		
	FROM #tempmatch r
	WHERE r.Isfinished IS NULL
	
	IF @@ROWCOUNT = 0
		BREAK
	DELETE s 
	FROM dbo.match s 
		INNER JOIN #match_batch t ON t.matchid = s.matchid
	TRUNCATE TABLE #match_batch
end
DROP TABLE #tempmatch
DROP TABLE #match_batch

-- rptCustomerMatch
while 1 = 1
begin
	delete top(@BatchSize) from dbo.rptCustomerMatch where winlostdate < @CutOffDate
	IF @@ROWCOUNT < @BatchSize
			break
end

-- rptLicWinloss2
while 1 = 1
begin
	delete top(@BatchSize) from dbo.rptLicWinloss2 where winlostdate < @CutOffDate
	IF @@ROWCOUNT < @BatchSize
			break
end

-- rptLicWinlossGMT
while 1 = 1
begin
	delete top(@BatchSize) from dbo.rptLicWinlossGMT where RptDate < @CutOffDate
	IF @@ROWCOUNT < @BatchSize
			break
end

-- rptWinlostbyLeague
while 1 = 1
begin
	delete top(@BatchSize) from dbo.rptWinlostbyLeague where winlostdate < @CutOffDate
	IF @@ROWCOUNT < @BatchSize
			break
end

-- rpt_Betting
while 1 = 1
begin
	delete top(@BatchSize) from dbo.rpt_Betting where rptDate < @CutOffDate
	IF @@ROWCOUNT < @BatchSize
			break
end

-- bettrans
while 1 = 1
begin
	delete top(@BatchSize) from dbo.bettrans where winlostdate < @CutOffDate
	IF @@ROWCOUNT < @BatchSize
			break
end

-- DataCheckingLog
while 1 = 1
begin
	delete top(@BatchSize) from dbo.DataCheckingLog where winlostdate < @CutOffDate
	IF @@ROWCOUNT < @BatchSize
			break
end
-- rpt_BettingByProduct
while 1 = 1
begin
	delete top(@BatchSize) from dbo.rpt_BettingByProduct where rptDate < @CutOffDate
	IF @@ROWCOUNT < @BatchSize
			break
end
-- rpt_ThirdPartyWL_ExtraGMT
while 1 = 1
begin
	delete top(@BatchSize) from dbo.rpt_ThirdPartyWL_ExtraGMT where rptDate < @CutOffDate
	IF @@ROWCOUNT < @BatchSize
			break
end

-- rpt_Betting_BA
while 1 = 1
begin
	delete top(@BatchSize) from dbo.rpt_Betting_BA where rptDate < @CutOffDate
	IF @@ROWCOUNT < @BatchSize
			break
end

-- rptLicCashoutSummary
while 1 = 1
begin
	delete top(@BatchSize) from dbo.rptLicCashoutSummary where Winlostdate < @CutOffDate
	IF @@ROWCOUNT < @BatchSize
			break
end

-- rpt_BettingBySport
while 1 = 1
begin
	delete top(@BatchSize) from dbo.rpt_BettingBySport where rptDate < @CutOffDate
	IF @@ROWCOUNT < @BatchSize
			break
end

-- rpt_BettingColossusBets
while 1 = 1
begin
	delete top(@BatchSize) from dbo.rpt_BettingColossusBets where rptDate < @CutOffDate
	IF @@ROWCOUNT < @BatchSize
			break
end

-- outright
while 1 = 1
begin
	delete top(@BatchSize) from dbo.outright where eventdate < @CutOffDate
	IF @@ROWCOUNT < @BatchSize
			break
end

-- rpt_CustomerWL_ExtraGMT
while 1 = 1
begin
	delete top(@BatchSize) from dbo.rpt_CustomerWL_ExtraGMT where RptDate < @CutOffDate
	IF @@ROWCOUNT < @BatchSize
			break
end

-- rptDepWinlost_ThirdParty
while 1 = 1
begin
	delete top(@BatchSize) from dbo.rptDepWinlost_ThirdParty where Winlostdate < @CutOffDate
	IF @@ROWCOUNT < @BatchSize
			break
end

-- rptDepWinlost_ThirdParty_Performance
while 1 = 1
begin
	delete top(@BatchSize) from dbo.rptDepWinlost_ThirdParty_Performance where Winlostdate < @CutOffDate
	IF @@ROWCOUNT < @BatchSize
			break
end

-- rptLicIPBetting
while 1 = 1
begin
	delete top(@BatchSize) from dbo.rptLicIPBetting where winlostdate < @CutOffDate
	IF @@ROWCOUNT < @BatchSize
			break
end

-- rptLicPromotion
while 1 = 1
begin
	delete top(@BatchSize) from dbo.rptLicPromotion where RptDate < @CutOffDate
	IF @@ROWCOUNT < @BatchSize
			break
end
end
GO
