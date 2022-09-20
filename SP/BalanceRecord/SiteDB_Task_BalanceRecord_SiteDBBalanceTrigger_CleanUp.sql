/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/  
ALTER PROCEDURE [dbo].[SiteDB_Task_BalanceRecord_SiteDBBalanceTrigger_CleanUp] 
(
	@MaxID BIGINT
)
AS
/*
    Created: 20220913@Helen
    Task: 
    DB: DBSIG/bodb02
    Revisions:
		- 20220912@Helen: scaleout project [176932]
		
*/
BEGIN

	SET NOCOUNT ON

	WHILE EXISTS (SELECT 1 FROM dbo.BalanceTrigger WITH (NOLOCK) WHERE rowid < @MaxID) --To avoid TABLOCK escalation
	BEGIN
		DELETE TOP (4500)
		FROM dbo.BalanceTrigger WITH (UPDLOCK, ROWLOCK)
		WHERE rowid < @MaxID
	END		

END




