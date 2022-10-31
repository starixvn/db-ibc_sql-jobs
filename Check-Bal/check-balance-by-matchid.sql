use bodb02
go

--check balance by matchid

SET NOCOUNT ON

DECLARE @__matchid INT = 59620784

DROP TABLE IF EXISTS #__custList
CREATE TABLE #__custList (rowId INT IDENTITY(1,1) PRIMARY KEY, custid INT, betXAmt MONEY, tableBalAmt MONEY, roundNo INT, remark VARCHAR(200))

DECLARE @__rowId INT = 1, @__custid INT, @__siteDBGroupId SMALLINT
	, @__fromBettrans MONEY, @__fromTransLog MONEY, @__fromBettransRNG MONEY, @__fromBettransLC MONEY
	, @__fromAdjustmentTransfer MONEY, @__fromTransfer MONEY, @__infoMessage VARCHAR(200)
	, @__roundNo INT, @__diffAmt MONEY, @__movebetdate SMALLDATETIME

SELECT @__siteDBGroupId = dbo.f_Get_SiteDBGroupID()
EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @__movebetdate OUTPUT

INSERT INTO #__custList(custid, betXAmt, tableBalAmt, roundNo)
SELECT custid, 0, 0, 0
FROM dbo.bettrans WITH(NOLOCK)
WHERE matchid = @__matchid AND SiteDBGroupID = @__siteDBGroupId
GROUP BY custid

WHILE EXISTS (
	SELECT TOP 1 1 FROM #__custList WHERE rowId = @__rowId
)
BEGIN

	SELECT @__custid = custid, @__roundNo = roundNo, @__diffAmt = 0
		, @__fromBettrans = 0, @__fromTransLog = 0, @__fromBettransRNG = 0, @__fromBettransLC = 0
		, @__fromAdjustmentTransfer = 0, @__fromTransfer = 0, @__diffAmt = 0
	FROM #__custList WHERE rowId = @__rowId
	
	IF @@ROWCOUNT = 0
		BREAK

	--check 3 rounds
	WHILE @__roundNo < 3
	BEGIN
		SELECT @__infoMessage = ''

		--check exist under settle or not
		IF EXISTS(
			SELECT TOP 1 1 
			FROM dbo.bettrans WITH (NOLOCK) 
			WHERE custid = @__custid 
				AND matchid IN (SELECT KeyValue FROM dbo.TempVariableNumber WITH(NOLOCK) WHERE KeyID IN (1,2,3,4)))
		BEGIN

			SET @__infoMessage = 'custid: ' + CAST(@__custid AS INT) + ' is under settlement. Wait 500 ms then continue check.'
			RAISERROR(@__infoMessage, 0, 1) WITH NOWAIT

			WAITFOR DELAY '00:00:00:500' --waitfor settlement completed
			CONTINUE
		END

		--check exist in pending or not
		IF	EXISTS (SELECT 1 FROM dbo.BalCreditSportsPending WITH(NOLOCK) WHERE custid = @__custid) OR
			EXISTS (SELECT 1 FROM dbo.BalCreditCasinoPending  WITH(NOLOCK) WHERE custid = @__custid) OR
			EXISTS (SELECT 1 FROM dbo.BalCreditOthersPending  WITH(NOLOCK) WHERE custid = @__custid) OR
			EXISTS (SELECT 1 FROM dbo.BalDebitSportsPending  WITH(NOLOCK) WHERE custid = @__custid) OR
			EXISTS (SELECT 1 FROM dbo.BalDebitCasinoPending  WITH(NOLOCK) WHERE custid = @__custid) OR
			EXISTS (SELECT 1 FROM dbo.BalDebitOthersPending  WITH(NOLOCK) WHERE custid = @__custid)		
		BEGIN
			SET @__infoMessage = 'custid: ' + CAST(@__custid AS INT) + ' is having pending data. Wait 100 ms then continue check.'
			RAISERROR(@__infoMessage, 0, 1) WITH NOWAIT

			WAITFOR DELAY '00:00:00:100' --waitfor pending completed
			CONTINUE
		END

		--start collect data in betX
		SELECT @__fromBettrans = SUM(winlost-actual_stake+playercomm)	
		FROM dbo.bettrans WITH (NOLOCK) 
		WHERE custid = @__custid
			AND 1 = CASE WHEN bettype >= 19999 THEN 0 --> get from transfer table
						WHEN bettype < 19999 AND winlostdate <= @__movebetdate THEN 0 --> old bet
						ELSE 1 END
			AND ISNULL(SiteDBGroupID, 0) = @__siteDBGroupId

		SELECT @__fromTransfer = SUM(winlost-actual_stake+playercomm)	
		FROM dbo.Transfer t WITH (NOLOCK) 
			LEFT JOIN custdb.dbo.Dep_CustSuper c WITH(NOLOCK) ON t.SRecommend = c.custid
		WHERE t.custid = @__custid
			AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @__movebetdate THEN 0 --> new sum
						ELSE 1 END
			AND ISNULL(c.SiteDBGroupID, 0) = @__siteDBGroupId

		SELECT @__fromAdjustmentTransfer = SUM(Amount)
		FROM dbo.BonusAdjustmentTransfer WITH(NOLOCK)
		WHERE isTransferred = 0 AND custid = @__custid

		SELECT @__fromTransLog = SUM(actual_stake) 
		FROM dbo.translog WITH (NOLOCK) WHERE custid = @__custid and statusID IN (0,1) AND ISNULL(SiteDBGroupID, 0) = @__siteDBGroupId

		SELECT @__fromBettransRNG = SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) 
		FROM dbo.bettransRNG WITH(NOLOCK)
		WHERE IsSum = 0 AND custid = @__custid AND ISNULL(SiteDBGroupID, 0) = @__siteDBGroupId
		
		SELECT @__fromBettransLC = SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) 
		FROM dbo.bettransLC WITH(NOLOCK)
		WHERE IsSum = 0 AND custid = @__custid AND ISNULL(SiteDBGroupID, 0) = @__siteDBGroupId
			
		DECLARE @__balanceBettrans MONEY, @__balanceTableBal MONEY
		SET @__balanceBettrans = IsNull(@__fromBettrans, 0) + IsNull(@__fromTransfer, 0) - IsNull(@__fromTransLog, 0) + IsNull(@__fromBettransRNG, 0) + IsNull(@__fromBettransLC, 0) - IsNull(@__fromAdjustmentTransfer, 0)
		
		--start collect data in balance Table
		SELECT @__balanceTableBal = (cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance)
		FROM dbo.BalCreditTransfer cd1 WITH (NOLOCK)
			INNER JOIN dbo.BalCreditSports cd2 WITH (NOLOCK) ON cd1.custid = cd2.custid
			INNER JOIN dbo.BalCreditCasino cd3 WITH (NOLOCK) ON cd1.custid = cd3.custid
			INNER JOIN dbo.BalCreditOthers cd4 WITH (NOLOCK) ON cd1.custid = cd4.custid
			INNER JOIN dbo.BalDebitTransfer db1 WITH (NOLOCK) ON cd1.custid = db1.custid
			INNER JOIN dbo.BalDebitSports db2 WITH (NOLOCK) ON cd1.custid = db2.custid
			INNER JOIN dbo.BalDebitCasino db3 WITH (NOLOCK) ON cd1.custid = db3.custid
			INNER JOIN dbo.BalDebitOthers db4 WITH (NOLOCK) ON cd1.custid = db4.custid	
		WHERE cd1.custid = @__custid

		IF @__diffAmt <> ISNULL(@__balanceBettrans, 0) - ISNULL(@__balanceTableBal, 0)
		BEGIN
			--reset round check
			SELECT @__diffAmt = ISNULL(@__balanceBettrans, 0) - ISNULL(@__balanceTableBal, 0)
				, @__roundNo = 1
			
			SET @__infoMessage = 'custid: ' + CAST(@__custid AS INT) + ' diff amt was change with last round then reset round check to continue.'
			RAISERROR(@__infoMessage, 0, 1) WITH NOWAIT

			CONTINUE
		END
		
		SET @__roundNo += 1
	
	END
	
	UPDATE #__custList 
	SET betXAmt = ISNULL(@__balanceBettrans, 0)
		, tableBalAmt = ISNULL(@__balanceTableBal, 0)
		, roundNo = @__roundNo
		, remark = CASE WHEN @__diffAmt = 0 THEN 'okay' ELSE 'Wrong balance, diffAmt: ' + CAST(@__diffAmt AS VARCHAR(50)) END
	WHERE rowId = @__rowId

	SET @__rowId += 1

END

---output result -- okay
SELECT * FROM #__custList where remark = 'okay'
---output result -- wrong balance
SELECT * FROM #__custList where remark like 'Wrong balance%'