/*<info serverAlias="DBLIC-bodb_licensee" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DEP_SeparatedWallet_Data_Check] @WinlostDate SMALLDATETIME
        , @IsReady BIT = 0 OUTPUT
AS

/*
	Created:20170125@Patrick
	Task: Check data ready or not 
	DB: DBLIC/bodb_licensee
	Revisions:
		-20170412@Patrick: Fix bug for hotfix #74966
		-20170104@Sophia: Integrate Exchange Products [Redmine: #86640]
		-20180130@Sophia: remove the block code of Exchange for UAT Testing, will add later when releasing Exchange [redmine: #90213]
   
 */
 BEGIN
    SET NOCOUNT ON
    SELECT @IsReady = 0

     --check data has ready yet?
    IF NOT EXISTS (SELECT TOP 1 1 
				FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue q WITH(NOLOCK)
				WHERE ProductID IN (10,11,12) --- AGC, GD, Vegas Games
					  AND (
							Winlostdate IS NULL OR (Winlostdate = @WinlostDate AND FinishedTime IS NULL)) 
							)
	   AND EXISTS (SELECT TOP 1 1
				FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH(NOLOCK)
				WHERE ProductID IN (10,11,12) --- AGC, GD, Vegas Games
						AND Winlostdate = @WinlostDate)
		--AND EXISTS (SELECT TOP 1 1
		--			FROM bodb_3rdProduct.dbo.Product3rd_SummarizedDateHistory WITH (NOLOCK)
		--			WHERE ProductID = 31 AND Winlostdate = @WinlostDate
		--			)
						
    BEGIN
	   SET @IsReady = 1
	   WAITFOR DELAY '00:01:00:000'
    END

 END
 GO

