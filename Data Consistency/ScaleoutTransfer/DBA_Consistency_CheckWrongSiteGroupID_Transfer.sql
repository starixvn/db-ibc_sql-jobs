/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_CheckWrongSiteGroupID_Transfer]
(
	@SiteDBGroupID SMALLINT,
	@TransferLastTransId BIGINT,
	@NewTransferLastTransId BIGINT
)
AS
/*
	Created: 20220823@Sol
	Task: Data consistency - check insert wrong server
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20220823@Sol: Scale out DBTrans - Detect data consistency SiteDB and CentralDB 
						- Check ticket that inserted into wrong server - [Redmine:#175881]

	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	SELECT 
		t.TransId
		,t.CustId
		,@SiteDBGroupID AS CustomerSiteGroupId
		,r.SiteDBGroupID AS TicketSiteGroupId
	FROM bodb02.dbo.Transfer t WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Dep_CustSuper s WITH(NOLOCK)
			ON t.SRecommend = s.custid
		CROSS APPLY 
		(
			SELECT f.SiteDBGroupID
			FROM bodb02.dbo.f_dba_transid_revert(t.TransId, 0) f
		) r
	WHERE 
		t.TransId > @TransferLastTransId 
		AND t.TransId <= @NewTransferLastTransId 
		AND s.SiteDBGroupID = @SiteDBGroupID 
		AND 1 = CASE WHEN r.SiteDBGroupID <> @SiteDBGroupID THEN 1 ELSE 0 END
	ORDER BY t.TransId

END
GO