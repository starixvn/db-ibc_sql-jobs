/*<info serverAlias="DBTP-bodb02,DBBAL-bodb02" executers="" viewers="" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_AWS_CheckBalance_Check_One]
	@custid int,
	@balance money OUTPUT
AS
/*
	Task: Check balance between DBTP & DBBAL
	Location: DBTP.bodb02 | DBBAL.bodb02
	Revision:
		- 20211231@Patrick: Split bettype >= 19999 out bettrans Redmine: [#164197]
*/
BEGIN
	SET NOCOUNT ON
	Declare @FromBettrans money, @FromTransLog money
		, @FromBettransRNG money, @FromBettransLC money
		, @FromAdjustmentTransfer money, @FromBalNetPosition money
		, @FromTransfer money

	DECLARE @__movebetdate SMALLDATETIME
	EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @__movebetdate OUTPUT

	SELECT @FromBettrans = SUM(winlost-actual_stake+playercomm)	
	FROM dbo.bettrans WITH (NOLOCK, INDEX=IX_custid) 
	WHERE custid = @custid AND transid <= (SELECT MAX(Id) FROM dbo.Task_AWS_Balance_Check_MaxIdList WHERE tableName = 'bettrans')
		AND 1 = CASE WHEN bettype >= 19999 THEN 0 --> get from transfer table
					 WHEN bettype < 19999 AND winlostdate <= @__movebetdate THEN 0 --> old bet
					 ELSE 1 END

	SELECT @FromTransfer = SUM(winlost-actual_stake+playercomm)	
	FROM dbo.Transfer WITH (NOLOCK) 
	WHERE custid = @custid AND transid <= (SELECT MAX(Id) FROM dbo.Task_AWS_Balance_Check_MaxIdList WHERE tableName = 'transfer')
		AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @__movebetdate THEN 0 --> new sum
					 ELSE 1 END
		
	SELECT @FromAdjustmentTransfer = SUM(Amount)
	FROM dbo.BonusAdjustmentTransfer WITH(NOLOCK)
	WHERE isTransferred = 0 AND custid = @custid

	SELECT @FromTransLog = SUM(actual_stake)
	FROM dbo.translog WITH(NOLOCK, INDEX=IX_custid) 
	WHERE custid = @custid and statusID IN (0,1) 
		AND translogid <= (SELECT MAX(Id) FROM dbo.Task_AWS_Balance_Check_MaxIdList WHERE tableName = 'translog')

	SELECT @FromBettransRNG = SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) 
	FROM dbo.bettransRNG WITH(NOLOCK, INDEX=IX_custid)
	WHERE IsSum = 0 AND custid = @custid
		 AND transid <= (SELECT MAX(Id) FROM dbo.Task_AWS_Balance_Check_MaxIdList WHERE tableName = 'bettransRNG')
		
	SELECT @FromBettransLC = SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) 
	FROM dbo.bettransLC WITH(NOLOCK, INDEX=IX_custid)
	WHERE IsSum = 0 AND custid = @custid
		 AND transid <= (SELECT MAX(Id) FROM dbo.Task_AWS_Balance_Check_MaxIdList WHERE tableName = 'bettransLC')

	SELECT @FromBalNetPosition = ISNULL(SUM(Credit-Debit),0)
	FROM BalNetPosition b WITH(NOLOCK)
	WHERE custid = @custid
				
	SET @balance = IsNull(@FromBettrans, 0) + IsNull(@FromTransfer, 0) - IsNull(@FromTransLog, 0) + IsNull(@FromBettransRNG, 0) + IsNull(@FromBettransLC, 0) + IsNull(@FromAdjustmentTransfer, 0) + ISNULL(@FromBalNetPosition, 0)
			
END