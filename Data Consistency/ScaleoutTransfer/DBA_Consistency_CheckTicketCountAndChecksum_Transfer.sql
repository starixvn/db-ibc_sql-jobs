/*<info serverAlias="DBCONSISTENCY-bodb_Consistency,DBACC-bodb02,DBAGE-bodb02" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_CheckTicketCountAndChecksum_Transfer]
(
	@SiteDBGroupID SMALLINT,
	@TransferLastTransId BIGINT,
	@NewTransferLastTransId BIGINT
)
AS
/*
	Created: 20220823@Sol
	Task: Data consistency - Rule 46
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20220823@Sol: Scale out DBTrans - Detect data consistency SiteDB and CentralDB 
						- Check total ticket and checksum between SiteDB and central DB - [Redmine:#175881]
		- 20221102@Evan: Enhancement convert data type float to decimal - [Redmine:#178864] 
		- 20231114@Evan: Deploy sp on DBACC, DBAGE to detect data consistency - [Redmine:#196690] 

	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON
	CREATE TABLE #tmp_TransferCheckSum 
	(
		TableName VARCHAR(50),
		SiteDBGroupID SMALLINT,
		Recommend INT,
		TicketCount INT,
		TotalCheckSum BIGINT
	)

	---get total ticket by recommend
	INSERT INTO #tmp_TransferCheckSum (TableName, SiteDBGroupID, Recommend, TicketCount, TotalCheckSum)
	SELECT 
		'Transfer' AS TableName,
		@SiteDBGroupID AS SiteDBGroupID, 
		t.Recommend,
		COUNT(1) AS TicketCount,
		CHECKSUM_AGG(
					CHECKSUM(
						t.CustId,TransDate,WinlostDate,Bettype,Stake,Actual_Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm
						,Comm,AComm,SComm,StatusId,RefNo,TransDesc,t.Recommend,t.MRecommend,t.SRecommend,t.Username,t.Currency,
						CurrencyName,CAST(ActualRate AS DECIMAL(19,8)),t.Creator,Balance,[IP],CheckTime,SerialNo,TransId
						)
				) AS TotalCheckSum
	FROM bodb02.dbo.Transfer t WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Customer c WITH(NOLOCK)
			ON t.CustId = c.custid
		INNER JOIN bodb02.dbo.Site s WITH(NOLOCK)
			ON s.site = c.site
	WHERE t.TransId > @TransferLastTransId
		AND t.TransId <= @NewTransferLastTransId
		AND s.SiteDBGroupID = @SiteDBGroupID
		AND t.Bettype NOT IN (19999, 20000)
	GROUP BY t.Recommend 
			
	UNION ALL

	SELECT
		'TransferInfo' AS TableName,
		@SiteDBGroupID AS SiteDBGroupID, 
		t.Recommend, 
		COUNT(1) AS TicketCount,
		CHECKSUM_AGG(
					CHECKSUM(
						ti.TransId,APositiontaking,MPositiontaking,SPositiontaking,EPositiontaking,PlayerDiscount,Discount
						,ADiscount,SDiscount,WalletType,BonusID,Amount,CheckerId,CheckerName,IsCollection,IsDel
						)
				) AS TotalCheckSum
	FROM bodb02.dbo.TransferInfo ti WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Transfer t WITH(NOLOCK)
			ON ti.TransId = t.TransId
		INNER JOIN bodb02.dbo.Customer c WITH(NOLOCK)
			ON t.CustId = c.custid
		INNER JOIN bodb02.dbo.Site s WITH(NOLOCK)
			ON s.site = c.site
	WHERE ti.TransId > @TransferLastTransId
		AND ti.TransId <= @NewTransferLastTransId
		AND s.SiteDBGroupID = @SiteDBGroupID
		AND t.Bettype NOT IN (19999, 20000)
	GROUP BY t.Recommend 
	
	-- Transfer_Coll not exists in DB053/DB052
	IF @@SERVERNAME NOT IN ('DB052', 'DB053', 'SITDB052', 'TESTDB053')
	BEGIN
		INSERT INTO #tmp_TransferCheckSum (TableName, SiteDBGroupID, Recommend, TicketCount, TotalCheckSum)
		SELECT
			'Transfer_Coll' AS TableName,
			@SiteDBGroupID AS SiteDBGroupID, 
			tc.Recommend, 
			COUNT(1) AS TicketCount,
			CHECKSUM_AGG(
						CHECKSUM(
							tc.CustId,WinlostDate,TransDate,Bettype,Debit,Credit,tc.Currency,CAST(ActualRate AS DECIMAL(19,8)),TransID,RefNo,tc.Username
							,tc.Recommend,tc.MRecommend,tc.SRecommend,tc.Creator,TransDesc,[IP]
							)
					) AS TotalCheckSum
		FROM bodb02.dbo.Transfer_Coll tc WITH (NOLOCK)
			INNER JOIN bodb02.dbo.Customer c WITH(NOLOCK)
				ON tc.CustId = c.custid
			INNER JOIN bodb02.dbo.Site s WITH(NOLOCK)
				ON s.site = c.site
		WHERE tc.TransId > @TransferLastTransId
			AND tc.TransID <= @NewTransferLastTransId
			AND s.SiteDBGroupID = @SiteDBGroupID
			AND tc.Bettype NOT IN (19999, 20000)
		GROUP BY tc.Recommend 
	END
	
	SELECT TableName
		 , SiteDBGroupID
		 , Recommend
		 , TicketCount
		 , TotalCheckSum
	FROM #tmp_TransferCheckSum 

END
GO