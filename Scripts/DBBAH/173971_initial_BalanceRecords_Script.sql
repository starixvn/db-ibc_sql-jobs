/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
    Created: 20220629@Helen
	Task: BalanceRecord -> wrong capture balance change and new balance when resettle tickets AE-Sexy product [Redmine:#173971]
	DB:DBBAH/bodb02

Step 1 - enable flag to stop job bodb02 : Task_BalanceRecord_Insert on DBBAH
Step 2 - run sp init new row in balanceRecord by batch (2000 customers) by srecommend, recommend
	2.1 - check data in table BalanceTrigger_ProcessData
	2.2 - insert balancerecord
	2.3 - delete balancetrigger
Step 3 - script verify balance of member manually (SAS, DBA, QC)

*/
USE bodb02
GO

DECLARE @maxcustid INT = 0, @maxcust_recommend INT = 0

DECLARE @srecommend_input  INT = xxxx -- if run by specific srecommend
SELECT @maxcustid = max(custid) FROM customer ci WITH (NOLOCK)
SELECT @maxcustid AS [@maxcustid], @srecommend_input AS [@srecommend]

--------------DECLARE temporary tables ------------------
CREATE TABLE #temp_srecommend_recommend(
	id INT IDENTITY (1,1) PRIMARY KEY,
	srecommend INT,
	recommend INT,
	isFinish BIT
)

CREATE TABLE #tempMemberPerRecommend (custid INT PRIMARY KEY, ID INT IDENTITY (1,1))
CREATE TABLE #tempMember_batch (custid INT PRIMARY KEY)
--------------GET srecommend/recommend needs to process ------------------
IF @srecommend_input IS NULL
BEGIN
	INSERT INTO #temp_srecommend_recommend (srecommend, recommend)
	SELECT srecommend, recommend
	FROM customer ci WITH (NOLOCK)
	WHERE ci.roleid IN (4,2) AND custid <= @maxcustid
	ORDER BY srecommend, recommend
END
ELSE
BEGIN
	INSERT INTO #temp_srecommend_recommend (srecommend, recommend)
	SELECT srecommend, recommend
	FROM customer ci WITH (NOLOCK)
	WHERE ci.roleid IN (4,2)
		AND srecommend = @srecommend_input
	ORDER BY srecommend, recommend
END
------ info for deployer
DECLARE @debug_message VARCHAR(MAX)

--------------LOOP BY srecommend/recommend ------------------
DECLARE @srecommend INT, @recommend INT, @rid INT = 1, @rid_max INT
SET @rid_max = (SELECT MAX(ID) FROM #temp_srecommend_recommend)

-- param to process when loop by recommend
DECLARE @StartRow INT = 1
		, @StopRow INT 
		, @MaxRow INT = 1 -- Keep the total row of your data
		, @Threshold INT = 500 -- the number of each batch

WHILE (@rid <= @rid_max)
BEGIN
	-- reset params for each recommend
	TRUNCATE TABLE #tempMemberPerRecommend
	SELECT @StartRow = 1, @StopRow = @Threshold

	SELECT @srecommend = srecommend, @recommend = recommend 
	FROM #temp_srecommend_recommend WHERE id = @rid
	
	INSERT INTO #tempMemberPerRecommend (custid)
	SELECT custid
	FROM customer c WITH (NOLOCK)
	WHERE recommend = @recommend AND roleid = 1 
		AND custid <= @maxcustid 
	
	IF @@ROWCOUNT > 0
	BEGIN 
		SET @MaxRow = (SELECT MAX(ID) FROM #tempMemberPerRecommend)

		SET @debug_message = CONCAT(CONVERT(VARCHAR(50), GETDATE(), 121), ', processing for srecommend:',  @srecommend ,', recommend:', @recommend)
		RAISERROR (@debug_message, 0, 1) WITH NOWAIT
		-- process by recommend, 500 customers per batch
	
		IF @Threshold >= @MaxRow
			SET @Threshold = @MaxRow

		WHILE (1=1)
		BEGIN
			TRUNCATE TABLE #tempMember_batch

			INSERT INTO #tempMember_batch (custid)
			SELECT custid
			FROM #tempMemberPerRecommend 
			WHERE ID BETWEEN @StartRow AND @StopRow
		
			IF @@ROWCOUNT = 0 BREAK

			SET @maxcust_recommend = (SELECT MAX(custid) FROM #tempMemberPerRecommend)
		
			-- step 1: check BalanceTrigger_ProcessData before insert balancerecord
			/*
			WHILE (1=1)
			BEGIN
				SELECT TOP 1 1 
				FROM BalanceTrigger_ProcessData bt WITH (NOLOCK) 
					INNER JOIN #tempMember t ON bt.custid = t.custid
			
				IF @@ROWCOUNT = 0 BREAK
				ELSE
				BEGIN
					WAITFOR DELAY '00:00:00.200'
				END
			END
			*/
			--- step 2 insert balance record to re-init
			INSERT INTO BalanceRecord (custid, transid, bettype, actual_stake, winlost, playercomm, balancechanged, newbalance, actionDate, actionID, [action])
			SELECT	m.custid, 0, 0, 0, 0, 0, 0, bal.Balance,CURRENT_TIMESTAMP, 255, 'Balance : Re-Init'
			FROM #tempMember_batch m
				CROSS APPLY (
					SELECT TOP 1 Balance 
					FROM DBTRANS.bodb02.dbo.v_BalanceTable b WITH(NOLOCK) -- v_BalanceTable: this is a view, get data from 8 balance tables
					WHERE b.custid = m.custid
				) AS bal
		
			-- step 3: delete balance trigger if exists
			DELETE b
			FROM BalanceTrigger b
				INNER JOIN #tempMember_batch m ON b.custid = m.custid

			TRUNCATE TABLE #tempMember_batch

			WAITFOR DELAY '00:00:00.50'

			SET @StartRow = @StopRow + 1
			SET @StopRow = 1 + @StopRow + @Threshold
		
			IF @StopRow >= @MaxRow
				SET @StopRow = @MaxRow

		END	
	END
	SET @rid = @rid + 1
END

--EXEC msdb.dbo.sp_update_job @job_name='bodb02 : Task_BalanceRecord_Insert',@enabled = 1

DROP TABLE #temp_srecommend_recommend
DROP TABLE #tempMemberPerRecommend
DROP TABLE #tempMember_batch

