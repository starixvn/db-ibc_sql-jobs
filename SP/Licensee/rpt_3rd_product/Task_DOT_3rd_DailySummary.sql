/*<info serverAlias="DBLIC-bodb_3rdProduct,DBBAL-bodb_3rdProduct" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DOT_3rd_DailySummary]
	@winlostdate datetime
AS

/*	
	Create: 20150323@Patrick
	Task: Daily summary for 3rd products
	DB: DBLIC.bodb_3rdProduct,DBBAL-bodb_3rdProduct
	Param's Explanation:
		• @winlostdate: The date need to summary

	Revisions:	
	- 20150327@Winnie Add GoldDeluxe_DailySummary
	- 20180102@Harper: Add separate product Exchange_DailySummary [RedmineID: #86640]
	- 20181129@Percy: Remove linked-server DBPTCS [RedmineID: #105520]
	- 20210816@Sophia: add DBBAL [Redmine: #154300]
	- 2022831@Sol: Deposit - AWS - Modify jobs of separated wallet - Move table rptDepWinlost_AGCasino to DB05x - [RedmineID: #176479]

*/
BEGIN
	SET NOCOUNT ON	

	-- Execute SP to insert data for GD
	EXEC bodb_PlaytechCS.dbo.Task_DOT_GoldDeluxe_DailySummary @winlostdate = @winlostdate

	EXEC bodb_3rdproduct.dbo.Task_DOT_Exchange_DailySummary @winlostdate = @winlostdate

	--data for AG
	EXEC bodb_3rdproduct.dbo.Task_DOT_AGCasino_DailySummary @winlostdate = @winlostdate

	--add more 3rd product at here
END
GO