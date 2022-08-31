/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[SiteDB_DBA_Consistency_R47_ChecksumTicket]
(
	@SiteDBGroupID SMALLINT,
	@TransferLastTransId BIGINT,
	@TransferCollLastTransId BIGINT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(MAX) = '' OUTPUT 
)
AS
/*
	Created: 20220823@Sol
	Task: Data consistency
	DB: DBSIG-bodb02

	Revisions: 
		- 20220823@Sol: Scale out DBTrans - Detect data consistency SiteDB and CentralDB 
						- Checksum ticket between SiteDB and central DB - [Redmine:#175881]

	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	--parameters
	DECLARE 
		@rowPerCall INT = 5000
		,@transferKey VARCHAR(50) = 'SiteDB_CheckConsistency_Transfer_LastTransId'
		,@transferCollKey VARCHAR(50) = 'SiteDB_CheckConsistency_TransferColl_LastTransId'
		,@internalSiteDBGroupID SMALLINT

	---get site group id
	SELECT @internalSiteDBGroupID = dbo.f_Get_SiteDBGroupID()

	---validate data
	IF (@SiteDBGroupID <> @internalSiteDBGroupID) -- invalid site group id, return error
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Invalid SiteDBGroupID!'
		RETURN
	END

	IF (ISNULL(@TransferLastTransId, 0) = 0 OR ISNULL(@TransferCollLastTransId, 0) = 0)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid LastTransID!'
		RETURN
	END

	---get total ticket by recommend
	BEGIN
		
		SELECT --TOP(@rowPerCall)
			'Transfer' AS TableName,
			@SiteDBGroupID AS SiteDBGroupID, 
			Recommend,
			CHECKSUM_AGG(
					CHECKSUM(
						CustId,TransDate,WinlostDate,Bettype,Stake,Actual_Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm
						,Comm,AComm,SComm,StatusId,RefNo,TransDesc,Recommend,MRecommend,SRecommend,Username,Currency,CurrencyName
						,ActualRate,Creator,Balance,[IP],CheckTime,SerialNo,TransId
						)
				) AS Total_CheckSum_Agg
		FROM dbo.Transfer t WITH (NOLOCK)
		WHERE t.TransId > @TransferLastTransId
		GROUP BY Recommend 
			
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
		FROM dbo.TransferInfo ti WITH (NOLOCK)
			INNER JOIN Transfer t with(nolock)
				ON ti.TransId = t.TransId
		WHERE	t.TransId > @TransferLastTransId
		GROUP BY t.Recommend 

		UNION ALL

		SELECT --TOP(@rowPerCall)
			'Transfer_Coll' AS TableName,
			@SiteDBGroupID AS SiteDBGroupID, 
			tc.Recommend, 
			CHECKSUM_AGG(
					CHECKSUM(
						CustId,WinlostDate,TransDate,Bettype,Debit,Credit,Currency,ActualRate,TransID,RefNo,Username
						,Recommend,MRecommend,SRecommend,Creator,TransDesc,[IP]
						)
				) AS Total_CheckSum_Agg
		FROM dbo.Transfer_Coll tc WITH (NOLOCK)
		WHERE	tc.TransId > @TransferCollLastTransId
		GROUP BY tc.Recommend 

	END
END
GO