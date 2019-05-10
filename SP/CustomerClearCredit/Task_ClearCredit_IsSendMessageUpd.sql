/*<info serverAlias="DBCUST-CUSTDB" executers="" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Task_ClearCredit_IsSendMessageUpd]	
	@CustId INT,
	@RoleId TINYINT
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
	DECLARE @Today DATETIME = CONVERT(date, GETDATE())

	UPDATE c 
	SET IsSend = 1
	FROM dbo.CustomerClearCredit c WITH (ROWLOCK) 
	WHERE c.LogDate >= @Today AND @CustID = CASE WHEN @RoleId = 4 THEN c.srecommend WHEN @RoleId = 3 THEN c.mrecommend END
END
