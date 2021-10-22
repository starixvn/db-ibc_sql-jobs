
/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" executers="" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[Task_ImportQueue_CheckReady]   
AS  
/*
Created: Danny@2021011
Task: Check data separate wallet 
DB: DBLIC.bodb_LicenseeReport, DBBAL-bodb_LicenseeReport

Revisions:
    - 20211011@Danny: Init SP for data checking in Product3rd_ImportQueue table [Redmine: #162947]
	
Explanation: Current data flow: pull data via API -> bodb_PlaytechCS.dbo.Product3rd_ImportQueue ->(job) bodb_PlaytechCS.dbo.bettrans_AGCasino -> (job) rptBettingByProduct
			 In the case of UM, after UM finish,  (job) rptBettingByProduct start without the data checking in Product3rd_ImportQueue, =>  some separate wallet products in rptBettingByProduct
			 have incorrect data.

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @i TINYINT = 15
	DECLARE @MaxFinishedTime	DATE
	DECLARE @today				DATE = GETDATE()
	
	WHILE @i > 0
	BEGIN
		SELECT	@MaxFinishedTime = MAX(FinishedTime)
		FROM	bodb_PlaytechCS.dbo.Product3rd_ImportQueue t WITH(NOLOCK) 
		
		IF  EXISTS( 
					SELECT	1 
					FROM	bodb_PlaytechCS.dbo.Product3rd_ImportQueue t WITH(NOLOCK) 
					WHERE	FinishedTime IS NULL
			)
			OR @MaxFinishedTime < @today
		BEGIN
			WAITFOR DELAY '00:01:00.000'
			SELECT @i = @i - 1
		END
		ELSE
		BEGIN
			BREAK
		END
	END

END
