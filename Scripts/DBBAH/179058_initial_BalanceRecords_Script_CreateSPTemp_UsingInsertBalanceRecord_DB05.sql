/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/  
ALTER PROCEDURE [dbo].[SiteDB_BalanceRecord_InsertBalanceRecord_tmp] 
(
	@CustidBalanceList VARCHAR(MAX) = ''
)
AS
/*
    Created: 20221013@Helen
	Task: init data for sitedb1,2 due to trigger insert on bettransRnG not captured data[Redmine:#179058]
	DB:DBBAH/bodb02

*/
BEGIN
	
	SET NOCOUNT ON
	DECLARE @xml XML = NULL
	SET @xml = CONVERT(XML, @CustidBalanceList)

	INSERT INTO BalanceRecord (custid, transid, bettype, actual_stake, winlost, playercomm, balancechanged, newbalance, actionDate, actionID, [action])
	SELECT	t.c.value('@c','int') AS custid, 0, 0, 0, 0, 0, 0, t.c.value('@b','MONEY') AS balance,CURRENT_TIMESTAMP, 255, 'Balance : Re-Init'
	FROM @xml.nodes('root/r') t(c)
	OPTION (OPTIMIZE FOR (@xml = NULL))	

END




