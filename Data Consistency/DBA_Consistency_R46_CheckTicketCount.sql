/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_R46_CheckTicketCount]
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
						- Check total ticket between SiteDB and central DB - [Redmine:#155714]

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
		COUNT(1) AS TicketCount
	FROM bodb02.dbo.Transfer t WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Customer c WITH(NOLOCK)
			ON t.CustId = c.custid
		INNER JOIN bodb02.dbo.Site s WITH(NOLOCK)
			ON s.site = c.site
	WHERE t.TransId > @transferLastTransId
		AND s.SiteDBGroupID = @SiteDBGroupID
	GROUP BY t.Recommend 
			
	UNION ALL

	SELECT --TOP(@rowPerCall)
		'TransferInfo' AS TableName,
		@SiteDBGroupID AS SiteDBGroupID, 
		t.Recommend, 
		COUNT(1) AS TicketCount
	FROM bodb02.dbo.TransferInfo ti WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Transfer t WITH(NOLOCK)
			ON ti.TransId = t.TransId
		INNER JOIN bodb02.dbo.Customer c WITH(NOLOCK)
			ON t.CustId = c.custid
		INNER JOIN bodb02.dbo.Site s WITH(NOLOCK)
			ON s.site = c.site
	WHERE t.TransId > @transferLastTransId
		AND s.SiteDBGroupID = @SiteDBGroupID
	GROUP BY t.Recommend 

	UNION ALL

	SELECT --TOP(@rowPerCall)
		'Transfer_Coll' AS TableName,
		@SiteDBGroupID AS SiteDBGroupID, 
		tc.Recommend, 
		COUNT(1) AS TicketCount
	FROM bodb02.dbo.Transfer_Coll tc WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Customer c WITH(NOLOCK)
			ON tc.CustId = c.custid
		INNER JOIN bodb02.dbo.Site s WITH(NOLOCK)
			ON s.site = c.site
	WHERE	tc.TransId > @transferCollLastTransId
		AND s.SiteDBGroupID = @SiteDBGroupID
	GROUP BY tc.Recommend 

END
GO