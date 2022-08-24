/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_R47_ChecksumTicket]
(
	@SiteDBGroupID SMALLINT,
	@TransferLastTransId BIGINT,
	@TransferCollLastTransId BIGINT
)
AS
/*
	Created: 20220823@Sol
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20220823@Sol: Scale out DBTrans - Detect data consistency SiteDB and CentralDB 
						- Checksum ticket between SiteDB and central DB - [Redmine:#155714]

	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON
	
	--parameters
	DECLARE 
		@rowPerCall INT = 5000

	---get total ticket by recommend
	SELECT --TOP(@rowPerCall)
		'Transfer' AS TableName,
		@SiteDBGroupID AS SiteDBGroupID, 
		t.Recommend,
		CHECKSUM_AGG(
					CHECKSUM(
						t.CustId,TransDate,WinlostDate,Bettype,Stake,Actual_Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm
						,Comm,AComm,SComm,StatusId,RefNo,TransDesc,t.Recommend,t.MRecommend,t.SRecommend,t.Username,t.Currency,
						CurrencyName,ActualRate,t.Creator,Balance,[IP],CheckTime,SerialNo,TransId
						)
				) AS Total_CheckSum_Agg
	FROM bodb02.dbo.Transfer t WITH (NOLOCK)
		inner join bodb02.dbo.Customer c with(nolock)
			on t.CustId = c.custid
		inner join bodb02.dbo.Site s with(nolock)
			on s.site = c.site
	WHERE t.TransId > @transferLastTransId
		AND s.SiteDBGroupID = @SiteDBGroupID
	GROUP BY t.Recommend 
			
	UNION ALL

	SELECT --TOP(@rowPerCall)
		'TransferInfo' AS TableName,
		@SiteDBGroupID AS SiteDBGroupID, 
		t.Recommend, 
		CHECKSUM_AGG(
					CHECKSUM(
						ti.TransId,APositiontaking,MPositiontaking,SPositiontaking,EPositiontaking,PlayerDiscount,Discount
						,ADiscount,SDiscount,WalletType,BonusID,Amount,CheckerId,CheckerName,IsCollection,IsDel
						)
				) AS Total_CheckSum_Agg
	FROM bodb02.dbo.TransferInfo ti WITH (NOLOCK)
		inner join bodb02.dbo.Transfer t with(nolock)
			on ti.TransId = t.TransId
		inner join bodb02.dbo.Customer c with(nolock)
			on t.CustId = c.custid
		inner join bodb02.dbo.Site s with(nolock)
			on s.site = c.site
	WHERE	t.TransId > @transferLastTransId
	GROUP BY t.Recommend 

	UNION ALL

	SELECT --TOP(@rowPerCall)
		'Transfer_Coll' AS TableName,
		@SiteDBGroupID AS SiteDBGroupID, 
		tc.Recommend, 
		CHECKSUM_AGG(
					CHECKSUM(
						tc.CustId,WinlostDate,TransDate,Bettype,Debit,Credit,tc.Currency,ActualRate,TransID,RefNo,tc.Username
						,tc.Recommend,tc.MRecommend,tc.SRecommend,tc.Creator,TransDesc,[IP]
						)
				) AS Total_CheckSum_Agg
	FROM bodb02.dbo.Transfer_Coll tc WITH (NOLOCK)
		inner join bodb02.dbo.Customer c with(nolock)
			on tc.CustId = c.custid
		inner join bodb02.dbo.Site s with(nolock)
			on s.site = c.site
	WHERE	tc.TransId > @transferCollLastTransId
	GROUP BY tc.Recommend 

END
GO