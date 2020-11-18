/*<info serverAlias="DBCRM-bodb_CRM" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CRM_AutoFeedbackInfoDel]		
AS
/*
	Created: 20200520@Johnson
	Task : Delete old feedback info, keep data in one month
	DB: DBCRM/bodb_CRM
	Original:

	Revisions:
		- 20200520@Johnson: Initial sp [redmine:#134220]
		- 20200615@Johnson: check missing feedback [redmine:#135719]
		- 20201103@Johnson: add auto fb for company winlimit [redmine:#142194]
	Param's Explanation:		
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @fromdate DATETIME
	
	SELECT @fromdate = CAST(DATEADD(MONTH,-1,getdate()) as DATE)
	
	--Auto FB for voiding tickets
	CREATE TABLE #tblMsg (MessageID INT, CustID INT, isDeleted BIT DEFAULT 0)
	DECLARE @tmp TABLE (MessageID INT, CustID INT)
	
	INSERT INTO #tblMsg(MessageID,CustID)
	SELECT MessageID,CustID
	FROM dbo.crmAutoFeedbackInfo WITH(NOLOCK)
	WHERE CreatedDate < @fromdate
	
	WHILE(1=1)
	BEGIN
		UPDATE TOP (5000) t
		SET isDeleted = 1
		OUTPUT DELETED.MessageID, DELETED.CustID
		INTO @tmp(MessageID,Custid)
		FROM #tblMsg t
		WHERE isDeleted = 0
		
		IF @@ROWCOUNT = 0
			BREAK;
			
		DELETE c
		FROM crmAutoFeedbackInfo c WITH(UPDLOCK,ROWLOCK)
			INNER JOIN @tmp t ON c.MessageID = t.MessageID
								AND c.CustID = t.CustID
	END
	
	DELETE crmMessageImport WITH(UPDLOCK,ROWLOCK)
	WHERE CreatedDate < @fromdate
	
	--Auto fb for CWL
	WHILE(1=1)
	BEGIN
		DELETE TOP(5000) c
		FROM crmWinLimitFeedbackInfo c WITH(UPDLOCK,ROWLOCK)
		WHERE CreatedDate < @fromdate
		
		IF @@ROWCOUNT = 0
			BREAK;		
	END
END	