/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_CleanDataFor12bet]
AS

/*
	Created: 20221202@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Clean Data 

	Revisions:
		- 20221202@Malcolm: Initialize SP [RedmineID: #180311]
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @CurrentTime DATETIME = DATEADD(MONTH, -2, GETDATE())

	WHILE 1 = 1
	BEGIN
		DELETE TOP(2000) dbo.APIProduct_ImportQueue WITH(ROWLOCK, UPDLOCK)
		WHERE CheckInTime < @CurrentTime
		
		IF @@ROWCOUNT < 2000
			BREAK
		
		WAITFOR DELAY '00:00:00.280'
	END
END
GO