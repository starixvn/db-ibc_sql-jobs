/*<info serverAlias="DBCUST-CUSTDB" executers="" viewers="" isFunction="0"></info>*/

ALTER  PROCEDURE [dbo].[Task_ClearCredit_ClearData]	
AS
/*
	Created: 20190509@Elodie
	Task : Clear data in CustomerClearCredit
	DB: DBCust/CustDB

	Revisions:    
		- 20190509@Elodie: Initial SP [Redmine:#112458]

	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @RowCount INT
	SELECT @RowCount = COUNT(1) FROM dbo.CustomerClearCredit WITH (NOLOCK) 

	IF @RowCount > 10000
		DELETE FROM CustomerClearCredit

END
