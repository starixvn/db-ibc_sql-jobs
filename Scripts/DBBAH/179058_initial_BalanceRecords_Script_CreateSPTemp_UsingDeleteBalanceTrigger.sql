/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/  
ALTER PROCEDURE [dbo].[SiteDB_BalanceRecord_DeleteBalanceTrigger_tmp] 
(
	@CustidList VARCHAR(MAX) = ''
)
AS
/*
    Created: 20221013@Helen
	Task: init data for sitedb1,2 due to trigger insert on bettransRnG not captured data[Redmine:#179058]
	DB:DBBAH/bodb02

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




