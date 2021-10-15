/*<info serverAlias="DBCUST-CustDB" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustDangerLevelInfo_Delete]		
AS
/*
	Created: 20211015@Johnson
	Task : Delete old data for table CustDangerLevelInfo & CustDangerWinlossInfo
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20211015@Johnson: Initial sp [redmine:#161351]		
	Param's Explanation:		
		
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Todate DATE
	
	SELECT @todate	= DATEADD(MONTH,-1,GETDATE())
				
	WHILE(1=1)
	BEGIN
		DELETE TOP (5000) c
		FROM dbo.CustDangerWinlossInfo c WITH(ROWLOCK)
		WHERE CreatedDate < @todate
		
		IF @@ROWCOUNT < 5000
			BREAK;
		
		WAITFOR DELAY '0:0:0.5'	
	END
	
	WHILE(1=1)
	BEGIN
		DELETE TOP (5000) c
		FROM dbo.CustDangerLevelInfo c WITH(ROWLOCK)
		WHERE CreatedDate < @todate
		
		IF @@ROWCOUNT < 5000
			BREAK;
		
		WAITFOR DELAY '0:0:0.5'	
	END
END	