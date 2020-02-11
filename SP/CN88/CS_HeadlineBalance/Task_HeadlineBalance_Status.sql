/*<info serverAlias="DBTXN-bodb02" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_HeadlineBalance_Status]
	@StatusID TINYINT = 0 OUTPUT
AS

/*
	Created by 20191121@Percy
    Task: Headline Balance Check & Correct Job has done yet?
    DB: DBTXN.bodb02

	Revisions:
		- 20191121@Percy: Initialize SP [RedmineID: #119289]
	
	Parameters Explanations:
		@StatusID = 0 --> HLBal has commpleted
		@StatusID = 1 --> HLBal has not commpleted yet (is running)
		@StatusID = 2 --> HLBal does not start yet

*/

BEGIN
	SET NOCOUNT ON
	
	SET @StatusID = 1

	-- HLBal is running
	IF EXISTS (
		SELECT 1 FROM dbo.SystemSettings WITH(NOLOCK)
		WHERE VName = 'isCalculatingHeadlineBalance' AND VValue <> '0'
	)
	BEGIN
		SET @StatusID = 1

		RETURN
	END

	-- HLBal has completed
	DECLARE @currentDate VARCHAR(10)
	SELECT  @currentDate = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)
	
	IF EXISTS (
		SELECT 1 FROM dbo.SystemSettings WITH(NOLOCK) 
		WHERE VName = 'HeadlineBalanceDate' AND VValue = @currentDate
	)
	AND EXISTS (
		SELECT 1 FROM dbo.SystemSettings WITH(NOLOCK)
		WHERE VName = 'isCalculatingHeadlineBalance' AND VValue = '0'
	)
	BEGIN
		SET @StatusID = 0

		RETURN
	END

	-- HLBal does not start yet
	SET @StatusID = 2
END
GO