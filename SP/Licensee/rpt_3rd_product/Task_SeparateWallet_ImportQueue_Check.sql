
/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" executers="" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[Task_SeparateWallet_ImportQueue_Check]     
AS  
/*
Created: Danny@2021011
Task: Check data separate wallet 
DB: DBLIC.bodb_LicenseeReport, DBBAL-bodb_LicenseeReport

Revisions:
    - 20211011@Danny: Step1 Check data in Product3rd_ImportQueue table [Redmine: #162947]
	
Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @i TINYINT = 3
	DECLARE @today		SMALLDATETIME = CAST(GETDATE() AS DATE)
	DECLARE @yesterday	SMALLDATETIME 
	SELECT @yesterday = DATEADD(DAY, -1, @today)

	WHILE @i > 0
	BEGIN
		IF  EXISTS( 
					SELECT	1 
					FROM	bodb_PlaytechCS.dbo.Product3rd_ImportQueue t WITH(NOLOCK) 
					WHERE	ProductID IN (10,11,31) AND Winlostdate = @yesterday
							AND CAST(CheckInTime AS DATE) = @today 
							AND FinishedTime IS NULL
			)
			OR 
			NOT EXISTS (
					SELECT	1 
					FROM	bodb_PlaytechCS.dbo.Product3rd_ImportQueue t WITH(NOLOCK) 
					WHERE	ProductID IN (10,11,31) AND Winlostdate = @yesterday
							AND CAST(CheckInTime AS DATE) = @today 
			)
		BEGIN
			WAITFOR DELAY '00:05:00.000'
			SELECT @i = @i - 1
		END
		ELSE
		BEGIN
			BREAK
		END
	END

END
