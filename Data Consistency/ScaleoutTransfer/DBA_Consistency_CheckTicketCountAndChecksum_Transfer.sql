/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_CheckTicketCountAndChecksum_Transfer]
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

	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	---get total ticket by recommend
	SELECT 
		'Transfer' AS TableName,
		@SiteDBGroupID AS SiteDBGroupID, 
		t.Recommend,
		COUNT(1) AS TicketCount,
		CHECKSUM_AGG(
					CHECKSUM(
						t.CustId,TransDate,WinlostDate,Bettype,Stake,Actual_Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm
						,Comm,AComm,SComm,StatusId,RefNo,TransDesc,t.Recommend,t.MRecommend,t.SRecommend,t.Username,t.Currency,
						CurrencyName,ActualRate,t.Creator,Balance,[IP],CheckTime,SerialNo,TransId
						)
				) AS TotalCheckSum
	FROM bodb02.dbo.Transfer t WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Dep_CustSuper s WITH(NOLOCK)
			ON t.SRecommend = s.custid
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
		INNER JOIN bodb02.dbo.Dep_CustSuper s WITH(NOLOCK)
			ON t.SRecommend = s.custid
	WHERE ti.TransId > @TransferLastTransId
		AND ti.TransId <= @NewTransferLastTransId
		AND s.SiteDBGroupID = @SiteDBGroupID
	GROUP BY t.Recommend 

	UNION ALL

	SELECT
		'Transfer_Coll' AS TableName,
		@SiteDBGroupID AS SiteDBGroupID, 
		tc.Recommend, 
		COUNT(1) AS TicketCount,
		CHECKSUM_AGG(
					CHECKSUM(
						tc.CustId,WinlostDate,TransDate,Bettype,Debit,Credit,tc.Currency,ActualRate,TransID,RefNo,tc.Username
						,tc.Recommend,tc.MRecommend,tc.SRecommend,tc.Creator,TransDesc,[IP]
						)
				) AS TotalCheckSum
	FROM bodb02.dbo.Transfer_Coll tc WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Dep_CustSuper s WITH(NOLOCK)
			ON tc.SRecommend = s.custid
	WHERE tc.TransId > @TransferLastTransId
		AND tc.TransID <= @NewTransferLastTransId
		AND s.SiteDBGroupID = @SiteDBGroupID
		AND tc.Bettype NOT IN (19999, 20000)
	GROUP BY tc.Recommend 

END
GO