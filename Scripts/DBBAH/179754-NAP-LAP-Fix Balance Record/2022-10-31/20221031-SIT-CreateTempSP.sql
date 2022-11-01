/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/  
ALTER PROCEDURE [dbo].[SiteDB_BalanceRecord_DeleteBalanceTrigger_tmp] 
(
	@CustidList VARCHAR(MAX) = ''
)
AS
/*
    Created: 20221031@Max
	Task: NAP/LAP - Wrong balance value shown for functions using BalanceRecord table [Redmine: #179754]
	DB:DBBAH/bodb02

	Notes: FOR SIT

*/
BEGIN
	
	SET NOCOUNT ON

	DECLARE @tmpcust AS TABLE (custid INT)

	INSERT INTO @tmpcust (custid)
	SELECT value 
	FROM STRING_SPLIT(@CustidList , ',')

	DELETE b
	FROM dbo.BalanceTrigger  b WITH (UPDLOCK, ROWLOCK)
		INNER JOIN @tmpcust c ON b.custid = c.custid

END




