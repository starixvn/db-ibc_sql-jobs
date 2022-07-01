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

DECLARE @maxcustid INT = xxxxx, @maxcust_recommend INT = 0

DECLARE @srecommend_input  INT = xxxxx -- if run by specific srecommend
--------------DECLARE temporary tables ------------------
CREATE TABLE #temp_srecommend_recommend(
	id INT IDENTITY (1,1) PRIMARY KEY,
	srecommend INT,
	recommend INT,
	isFinish BIT
)

CREATE TABLE #tempMember (custid INT PRIMARY KEY)
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

WHILE (@rid <= @rid_max)
BEGIN
	SELECT @srecommend = srecommend, @recommend = recommend FROM #temp_srecommend_recommend WHERE id = @rid

	SET @debug_message = CONVERT(VARCHAR(50), GETDATE(), 121) + ', processing for srecommend:' + @srecommend + ', recommend:'+ @recommend			
	RAISERROR (@debug_message, 0, 1) WITH NOWAIT
	-- process by recommend, 2000 customers per batch
	WHILE (1=1)
	BEGIN
		INSERT INTO #tempMember (custid)
		SELECT TOP (2000) custid
		FROM customer c WITH (NOLOCK)
		WHERE recommend = @recommend AND roleid = 1 AND custid > @maxcust_recommend
			AND custid <= @maxcustid 
		ORDER BY custid
		
		IF @@ROWCOUNT = 0 BREAK

		SET @maxcust_recommend = (SELECT MAX(custid) FROM #tempMember)
		
		-- step 1: check BalanceTrigger_ProcessData before insert balancerecord
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

		--- step 2 insert balance record to re-init
		INSERT INTO BalanceRecord (custid, transid, bettype, actual_stake, winlost, playercomm, balancechanged, newbalance, actionDate, actionID, [action])
		SELECT	m.custid, 0, 0, 0, 0, 0, 0, bal.Balance,CURRENT_TIMESTAMP, 255, 'Balance : Re-Init'
		FROM #tempMember m
			CROSS APPLY (
				SELECT TOP 1 Balance 
				FROM DBTRANS.bodb02.dbo.v_BalanceTable b WITH(NOLOCK) -- v_BalanceTable: this is a view, get data from 8 balance tables
				WHERE b.custid = m.custid
			) AS bal
		
		-- step 3: delete balance trigger if exists
		DELETE b
		FROM BalanceTrigger b
			INNER JOIN #tempMember m ON b.custid = m.custid

		TRUNCATE TABLE #tempMember

		WAITFOR DELAY '00:00:00.100'
	END
	
	SET @rid = @rid + 1
END

--DROP TABLE #temp_srecommend_recommend
--DROP TABLE #tempMember
