/*<info serverAlias="DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[SiteDB_DBA_Consistency_CheckTicketCountAndChecksum_Transfer]
(
	@SiteDBGroupID SMALLINT OUTPUT,
	@TransferLastTransId BIGINT OUTPUT,
	@NewTransferLastTransId BIGINT OUTPUT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(MAX)= '' OUTPUT 
)
AS
/*
	Created: 20220823@Sol
	Task: Data consistency - rule 46
	DB: DBSIG-bodb02

	Revisions: 
		- 20220823@Sol: Scale out DBTrans - Detect data consistency SiteDB and CentralDB 
						- Check total ticket and checksum between SiteDB and central DB - [Redmine:#175881]

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
		@ErrMsg = @ErrMsg OUTPUT 

	IF (@ErrCode <> 0)
	BEGIN
		RETURN
	END

	---get total ticket by recommend
	BEGIN
		
		SELECT
			'Transfer' AS TableName,
			@SiteDBGroupID AS SiteDBGroupID, 
			Recommend,
			COUNT(1) AS TicketCount,
			CHECKSUM_AGG(
					CHECKSUM(
						CustId,TransDate,WinlostDate,Bettype,Stake,Actual_Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm
						,Comm,AComm,SComm,StatusId,RefNo,TransDesc,Recommend,MRecommend,SRecommend,Username,Currency,CurrencyName
						,ActualRate,Creator,Balance,[IP],CheckTime,SerialNo,TransId
						)
				) AS TotalCheckSum
		FROM dbo.Transfer t WITH (NOLOCK)
		WHERE t.TransId > @transferLastTransId
			AND t.TransId <= @NewTransferLastTransId
			AND t.Bettype NOT IN (19999, 20000)
		GROUP BY Recommend 
			
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
		FROM dbo.TransferInfo ti WITH (NOLOCK)
			INNER JOIN Transfer t with(nolock)
				on ti.TransId = t.TransId
		WHERE ti.TransId > @transferLastTransId
			AND ti.TransId <= @NewTransferLastTransId
			AND t.Bettype NOT IN (19999, 20000)
		GROUP BY t.Recommend 

		UNION ALL

		SELECT
			'Transfer_Coll' AS TableName,
			@SiteDBGroupID AS SiteDBGroupID, 
			tc.Recommend, 
			COUNT(1) AS TicketCount,
			CHECKSUM_AGG(
					CHECKSUM(
						CustId,WinlostDate,TransDate,Bettype,Debit,Credit,Currency,ActualRate,TransID,RefNo,Username
						,Recommend,MRecommend,SRecommend,Creator,TransDesc,[IP]
						)
				) AS TotalCheckSum
		FROM dbo.Transfer_Coll tc WITH (NOLOCK)
		WHERE tc.TransId > @transferLastTransId
			AND tc.TransId <= @NewTransferLastTransId
			AND tc.Bettype NOT IN (19999, 20000)
		GROUP BY tc.Recommend 

	END
END
GO