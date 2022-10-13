/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
    Created: 20221013@Helen
	Task: init data for sitedb1,2 due to trigger insert on bettransRnG not captured data[Redmine:#179058]
	DB:DBBAH/bodb02

*/
USE bodb02
GO
---------------------------------------------------------------------------------
DECLARE @maxcustid INT = 0

SELECT @maxcustid = MAX(custid) 
FROM customer ci WITH (NOLOCK)
	INNER JOIN site s WITH (NOLOCK) ON ci.site = s.site
WHERE s.SiteDBGroupID = 1

SELECT @maxcustid AS [@maxcustid]

--------------DECLARE temporary tables ------------------
CREATE TABLE #temp_MemberInput(
	ID INT IDENTITY (1,1) PRIMARY KEY,
	custid INT
)

CREATE TABLE #tempMember (custid INT PRIMARY KEY)
--------------GET members needs to process ------------------
INSERT INTO #temp_MemberInput (custid)
SELECT custid
from BalanceRecord_SiteDB1_tmp WITH (NOLOCK)

SELECT @@ROWCOUNT AS [custid_Count]

-- delete data [dbo].[BalanceTrigger_ProcessData] for customers will process to insert balancerecord for credit
DELETE b
FROM BalanceTrigger_ProcessData b
	INNER JOIN #temp_MemberInput m ON b.custid = m.custid

----------- get maxtransid: Run on DBTRans/bodb02----------------
select * from OPENQUERY(DBTXN, '
select *
from (
	select MAX(transid) from bodb02.dbo.bettrans with(nolock)
) as b(bettrans_transid)
outer apply (
	select MAX(transid) from bodb02.dbo.Transfer with(nolock)
) as b2(Transfer_transid)
outer apply (
	select MAX(translogid) from bodb02.dbo.translog with(nolock)
) as b3(translog_translogid)
outer apply (
	select MAX(transid) from bodb02.dbo.bettransLC with(nolock)
) as b4(bettransLC_transid)
outer apply (
	select MAX(transid) from bodb02.dbo.bettransRnG with(nolock)
) as b5(bettransRnG_transid)');

------ info for deployer 
DECLARE @debug_message VARCHAR(MAX) = ''

--------------LOOP BY batch 500 of customers ------------------
DECLARE @rid_loop INT, @rowCount int  =0, @batch int = 500, @loop_cnt int = 1
DECLARE @StartRow INT = 1
		, @StopRow INT 
		, @retrycnt INT = 0 
		, @isSuccess BIT = 0
DECLARE  @ExecuteSQL NVARCHAR(MAX) = ''
		, @query NVARCHAR(MAX) = ''
		, @SiteDBAlias VARCHAR(200) ='DBSIG01'
		, @CustidList VARCHAR(MAX) = ''
SET @rid_loop = ((SELECT MAX(ID) FROM #temp_MemberInput)/@batch) + 1
SET @StopRow = @batch

WHILE (@loop_cnt <= @rid_loop)
BEGIN
	
	TRUNCATE TABLE #tempMember

	SET @debug_message = CONCAT(CONVERT(VARCHAR(50), GETDATE(), 121), ', processing for round:',  @loop_cnt, '/', @rid_loop)
	RAISERROR (@debug_message, 0, 1) WITH NOWAIT

	-- process by recommend, 2000 customers per batch
	INSERT INTO #tempMember(custid)
	SELECT custid
	FROM #temp_MemberInput 
	WHERE ID BETWEEN @StartRow AND @StopRow

	IF @@ROWCOUNT = 0
		BREAK

	--- step 2 insert balance record to re-init
	INSERT INTO BalanceRecord (custid, transid, bettype, actual_stake, winlost, playercomm, balancechanged, newbalance, actionDate, actionID, [action])
	SELECT	m.custid, 0, 0, 0, 0, 0, 0, bal.Balance,CURRENT_TIMESTAMP, 255, 'Balance : Re-Init'
	FROM #tempMember m
		CROSS APPLY (
			SELECT TOP 1 Balance 
			FROM DBSIG01.bodb02.dbo.v_BalanceTable b WITH(NOLOCK) -- v_BalanceTable: this is a view, get data from 8 balance tables
			WHERE b.custid = m.custid
		) AS bal

	SET @rowCount += @@ROWCOUNT
	
	SET @CustidList = ''
	SET @CustidList = STUFF((SELECT ',' + CONVERT(VARCHAR(20), custid)
				 FROM #tempMember 
				 FOR XML PATH ('')
					),1,1,'')

	-- step 3: delete balance trigger if exists
	WHILE (@isSuccess = 0)
	BEGIN
		BEGIN TRY

			SELECT  @query = N''		
			SELECT	@query = @query + N'EXEC SiteDB_BalanceRecord_DeleteBalanceTrigger_tmp @CustidList'
	
			SELECT	@ExecuteSQL = N'EXECUTE '+ @SiteDBAlias +'.bodb02.dbo.sp_executesql @query, N''@CustidList VARCHAR(MAX)'',@CustidList'
	
			EXECUTE	sys.sp_executesql @ExecuteSQL, N'@query NVARCHAR(MAX), @CustidList VARCHAR(MAX)', @query, @CustidList

			SET @isSuccess = 1

		END TRY
		BEGIN CATCH
			SET @retrycnt = @retrycnt + 1
			PRINT @retrycnt

		END CATCH
	END

	WAITFOR DELAY '00:00:00.020' --optional

	SET @StartRow = @StopRow + 1
	SET @StopRow = @StopRow + @batch

	SELECT  @loop_cnt += 1

END

SELECT @rowCount

DROP TABLE #temp_MemberInput
DROP TABLE #tempMember



