/*<info serverAlias="DBCUST-CustDB" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustCategoryHistory_Delete]		
AS
/*
	Created: 20210426@Johnson
	Task : Delete data table CustCategoryHistory 
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20210428@Johnson: Initial sp [redmine:#153059]
*/
BEGIN
	DECLARE @Todate DATE
	
	SELECT @todate	= DATEADD(MONTH,-1,GETDATE())
	SELECT @todate	= DATEADD(DAY,-7,@todate)	
			
	WHILE(1=1)
	BEGIN
		DELETE TOP (5000) c
		FROM dbo.CustCategoryHistory c WITH(ROWLOCK)
		WHERE CreatedDate < @todate
		
		IF @@ROWCOUNT < 5000
			BREAK;
		
		WAITFOR DELAY '0:0:0.5'	
	END
END
GO

