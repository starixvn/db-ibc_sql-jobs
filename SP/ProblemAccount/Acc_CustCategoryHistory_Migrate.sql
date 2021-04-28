/*<info serverAlias="DBCUST-CustDB" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustCategoryHistory_Migrate]		
AS
/*
	Created: 20210426@Johnson
	Task : Migrate data table CustCategoryHistory from DBCUST to DBLOG
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20210426@Johnson: Initial sp [redmine:#153059]
*/
BEGIN
	DECLARE @LogID_Min BIGINT,
			@LogID_Max BIGINT,
			@Todate DATE
	
	SELECT @todate	= DATEADD(MONTH,-1,GETDATE())	
	
	SELECT @LogID_Min = MAX(LogID)
	FROM DBLOG.bodb_CustomerLog.dbo.CustCategoryHistory_Old WITH(NOLOCK)
	
	SELECT @LogID_Max = MAX(LogID)
	FROM dbo.CustCategoryHistory WITH(NOLOCK)
	WHERE CreatedDate < @todate
	
	SELECT @LogID_Min = ISNULL(@LogID_Min,0),
			@LogID_Max = ISNULL(@LogID_Max,0)
			
	DECLARE @fromID BIGINT,
			@toID	BIGINT
	
	SELECT @fromID = @LogID_Min + 1,
			@toID = @LogID_Min + 5000
	
	IF @toID > @LogID_Max
		SET @toID = @LogID_Max
	
	WHILE(1=1)
	BEGIN
		IF @fromID > @LogID_Max 
			BREAK;
			
		INSERT INTO DBLOG.[bodb_CustomerLog].[dbo].[CustCategoryHistory_Old]
			   ([LogID]
			   ,[custid]
			   ,[CategoryID]
			   ,[CustomerClass]
			   ,[CreatedDate]
			   ,[UpdatedTime])
		SELECT [LogID]
			   ,[custid]
			   ,[CategoryID]
			   ,[CustomerClass]
			   ,[CreatedDate]
			   ,GETDATE()
		FROM dbo.CustCategoryHistory WITH(NOLOCK)
		WHERE LogID BETWEEN @fromID AND @toID
		
		IF @@ERROR > 0
			BREAK;
			
		SELECT @fromID = @toID + 1
			,@toID = @toID + 5000
		
		IF @toID > @LogID_Max
			SET @toID = @LogID_Max
	END
END