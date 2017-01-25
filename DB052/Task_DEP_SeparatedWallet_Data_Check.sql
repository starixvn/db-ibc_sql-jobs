USE [bodb_licensee]
GO
ALTER PROCEDURE [dbo].[Task_DEP_SeparatedWallet_Data_Check] @WinlostDate SMALLDATETIME
        , @IsReady BIT = 0 OUTPUT
AS

/*
	Created:20170125@Patrick
	Task: Check data ready or not 
	DB: DBLIC/bodb_licensee
	Revisions:
   
 */
 BEGIN
    SET NOCOUNT ON
    SELECT @IsReady = 0

     --check data has ready yet?
    IF NOT EXISTS (SELECT TOP 1 1 
				FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH(NOLOCK)
				WHERE Winlostdate = @WinlostDate AND isSummarized = 0)
	   AND EXISTS (SELECT TOP 1 1
				FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH(NOLOCK)
				WHERE Winlostdate = @WinlostDate)
    BEGIN
	   SET @IsReady = 1
    END

 END