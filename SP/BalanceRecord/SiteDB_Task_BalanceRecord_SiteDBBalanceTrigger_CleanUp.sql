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
		- 20221110@July: Scale out DBTrans - Enhance Job clean BalanceTrigger [180331]
		
	Notes: Keep data within 15 minus in the table
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Today			DATETIME
		   ,@MaxID_DBSIG	BIGINT

	SET @Today = DATEADD(MINUTE,-15,GETDATE())

	SELECT @MaxID_DBSIG = MAX(RowId)
	FROM dbo.BalanceTrigger WITH (NOLOCK) 
	WHERE ActionDate <= @Today

	IF @MaxID > @MaxID_DBSIG
		SET @MaxID = @MaxID_DBSIG

	WHILE EXISTS (SELECT 1 FROM dbo.BalanceTrigger WITH (NOLOCK) WHERE rowid < @MaxID) --To avoid TABLOCK escalation
	BEGIN
		DELETE TOP (4500)
		FROM dbo.BalanceTrigger WITH (UPDLOCK, ROWLOCK)
		WHERE rowid < @MaxID
	END		
END

