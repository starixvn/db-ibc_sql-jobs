/*<info serverAlias="DBTP-bodb02" executers="" viewers="" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_AWS_CheckBalance_Verify_One]
	@custid int
AS
/*
	Created: unknow
	Task : Verify data for balance check @aws
	DB: DBTP.bodb02
	Original:

	Revisions:
		- 20230106@Patrick: Balance-Up support transfer 247 [RedmineID: #182882]
		
		
	Param's Explanation:
*/
SET NOCOUNT ON
Declare @FromBettrans money, @FromTransLog money
	, @FromBettransRNG money, @FromBettransLC money
	, @FromAdjustmentTransfer money, @FromBalNetPosition money
	, @FromTransfer money

DECLARE @__movebetdate SMALLDATETIME
EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @__movebetdate OUTPUT

DECLARE @__balanceupdate SMALLDATETIME
EXEC dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @__balanceupdate OUTPUT


SELECT @FromBettrans = SUM(winlost-actual_stake+playercomm)	
FROM dbo.bettrans WITH (NOLOCK, INDEX=IX_custid) 
WHERE custid = @custid
	AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @__movebetdate THEN 0 --> new sum
				 WHEN bettype < 19999 AND winlostdate <= @__movebetdate THEN 0 --> old bet
				 ELSE 1 END

SELECT @FromTransfer = SUM(winlost-actual_stake+playercomm)	
	FROM dbo.Transfer WITH (NOLOCK, INDEX=IX_custid) 
	WHERE custid = @custid
		AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @__movebetdate THEN 0 --> new sum
					 WHEN bettype = 20000 AND winlostdate > @__balanceupdate THEN 0 --> new bal
					 WHEN winlostdate < @__balanceupdate THEN 0 --> old data
					 ELSE 1 END
		
SELECT @FromAdjustmentTransfer = SUM(Amount)
FROM dbo.BonusAdjustmentTransfer WITH(NOLOCK)
WHERE isTransferred = 0 AND custid = @custid

SELECT @FromTransLog = SUM(actual_stake)
FROM dbo.translog WITH(NOLOCK, INDEX=IX_custid) 
WHERE custid = @custid and statusID IN (0,1) 

SELECT @FromBettransRNG = SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) 
FROM dbo.bettransRNG WITH(NOLOCK, INDEX=IX_custid)
WHERE IsSum = 0 AND custid = @custid
		
SELECT @FromBettransLC = SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) 
FROM dbo.bettransLC WITH(NOLOCK, INDEX=IX_custid)
WHERE IsSum = 0 AND custid = @custid

SELECT @FromBalNetPosition = ISNULL(SUM(Credit-Debit),0)
FROM BalNetPosition b WITH(NOLOCK)
WHERE custid = @custid
				
SELECT IsNull(@FromBettrans, 0) + IsNull(@FromTransfer, 0) - IsNull(@FromTransLog, 0) + IsNull(@FromBettransRNG, 0) + IsNull(@FromBettransLC, 0) + IsNull(@FromAdjustmentTransfer, 0) + ISNULL(@FromBalNetPosition, 0) as '@balance'
	, IsNull(@FromBettrans, 0) as '@FromBettrans', IsNull(@FromTransLog, 0) as '@FromTransLog'
	, IsNull(@FromBettransRNG, 0) as '@FromBettransRNG', IsNull(@FromBettransLC, 0) as '@FromBettransLC'
	, IsNull(@FromAdjustmentTransfer, 0) as '@FromAdjustmentTransfer',  ISNULL(@FromBalNetPosition, 0) as '@FromBalNetPosition'
	, IsNull(@FromTransfer, 0) as '@FromTransfer'
