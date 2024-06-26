/*<info serverAlias="DBSIG-bodb02" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[SiteDB_DBA_Consistency_CheckTicketCountAndChecksum_Transfer]
(
	@SiteDBGroupID SMALLINT OUTPUT,
	@TransferLastTransId BIGINT OUTPUT,
	@NewTransferLastTransId BIGINT OUTPUT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(MAX)= '' OUTPUT,
	@CurrentTime DATETIME OUTPUT
)
AS
/*
	Created: 20220823@Sol
	Task: Data consistency - rule 46
	DB: DBSIG-bodb02

	Revisions: 
		- 20220823@Sol: Scale out DBTrans - Detect data consistency SiteDB and CentralDB 
						- Check total ticket and checksum between SiteDB and central DB - [Redmine:#175881]
		- 20221102@Evan: Enhancement convert data type float to decimal - [Redmine:#178864] 
		- 20221220@Evan: Check Data Consistency - Exclude custid = 0 - [Redmine:#181848] 
		- 20230706@Danny: deploy SP to SiteDB03 [Redmine: #181595]
		- 20231122@Evan: Check ignore archive account - [Redmine:#196690] 
		- 20240201@Lewis: Add @CurrentTime output [Redmine: #200766]
	
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	--parameters
	DECLARE 
		@transferKey VARCHAR(50) = 'SiteDB_CheckCons_Transfer_Count_LastTransId'
		
	---get last transid
	EXEC [dbo].SiteDB_DBA_Consistency_SystemSetting_Select
		@CheckConsistencyKeyName = @transferKey,
		@SiteDBGroupID = @SiteDBGroupID OUTPUT,
		@TransferLastTransId = @TransferLastTransId OUTPUT,
		@NewTransferLastTransId = @NewTransferLastTransId OUTPUT,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT,
		@CurrentTime = @CurrentTime OUTPUT

	IF (@ErrCode <> 0)
	BEGIN
		RETURN
	END

	---get total ticket by recommend
	BEGIN
		
		SELECT
			'Transfer' AS TableName,
			@SiteDBGroupID AS SiteDBGroupID, 
			t.Recommend,
			COUNT(1) AS TicketCount,
			CHECKSUM_AGG(
					CHECKSUM(
						t.CustId,t.TransDate,t.WinlostDate,t.Bettype,t.Stake,t.Actual_Stake,t.Winlost,t.AWinlost,t.MWinlost,t.SWinlost,t.PlayerComm
						,t.Comm,t.AComm,t.SComm,t.StatusId,t.RefNo,t.TransDesc,t.Recommend,t.MRecommend,t.SRecommend,t.Username,t.Currency,t.CurrencyName
						,CAST(t.ActualRate AS DECIMAL(19,8)),t.Creator,t.Balance,t.[IP],t.CheckTime,t.SerialNo,t.TransId
						)
				) AS TotalCheckSum
		FROM dbo.Transfer t WITH (NOLOCK)
			INNER JOIN custdb.dbo.Customer c WITH(NOLOCK) ON t.CustId = c.custid
		WHERE t.TransId > @transferLastTransId
			AND t.TransId <= @NewTransferLastTransId
			AND t.Bettype NOT IN (19999, 20000)
			AND t.CustId <> 0
		GROUP BY t.Recommend 
			
		UNION ALL

		SELECT
			'TransferInfo' AS TableName,
			@SiteDBGroupID AS SiteDBGroupID, 
			t.Recommend, 
			COUNT(1) AS TicketCount,
			CHECKSUM_AGG(
					CHECKSUM(
						ti.TransId,ti.APositiontaking,ti.MPositiontaking,ti.SPositiontaking,ti.EPositiontaking,ti.PlayerDiscount,ti.Discount
						,ti.ADiscount,ti.SDiscount,ti.WalletType,ti.BonusID,ti.Amount,ti.CheckerId,ti.CheckerName,ti.IsCollection,ti.IsDel
						)
				) AS TotalCheckSum
		FROM dbo.TransferInfo ti WITH (NOLOCK)
			INNER JOIN Transfer t with(nolock)
				ON ti.TransId = t.TransId
			INNER JOIN custdb.dbo.Customer c WITH(NOLOCK) 
				ON t.CustId = c.custid
		WHERE ti.TransId > @transferLastTransId
			AND ti.TransId <= @NewTransferLastTransId
			AND t.Bettype NOT IN (19999, 20000)
			AND t.CustId <> 0
		GROUP BY t.Recommend 

		UNION ALL

		SELECT
			'Transfer_Coll' AS TableName,
			@SiteDBGroupID AS SiteDBGroupID, 
			tc.Recommend, 
			COUNT(1) AS TicketCount,
			CHECKSUM_AGG(
					CHECKSUM(
						tc.CustId,tc.WinlostDate,tc.TransDate,tc.Bettype,tc.Debit,tc.Credit,tc.Currency,CAST(tc.ActualRate AS DECIMAL(19,8)),tc.TransID,tc.RefNo,tc.Username
						,tc.Recommend,tc.MRecommend,tc.SRecommend,tc.Creator,tc.TransDesc,tc.[IP]
						)
				) AS TotalCheckSum
		FROM dbo.Transfer_Coll tc WITH (NOLOCK)
			INNER JOIN custdb.dbo.Customer c WITH(NOLOCK) 
				ON tc.CustId = c.custid
		WHERE tc.TransId > @transferLastTransId
			AND tc.TransId <= @NewTransferLastTransId
			AND tc.Bettype NOT IN (19999, 20000)
			AND tc.CustId <> 0
		GROUP BY tc.Recommend 

		SELECT GETDATE() AS ExecutionTime
	END
END
GO