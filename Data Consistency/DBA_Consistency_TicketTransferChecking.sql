/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_TicketTransferChecking]
	 @MaxTransID	BIGINT
	,@ErrCode		INT			 = 0	OUTPUT
	,@ErrMsg		VARCHAR(MAX) = ''	OUTPUT 
	,@SampleData	VARCHAR(MAX) = ''	OUTPUT
AS
/*
	Created: 20220127@July
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20220127@July: Data Consistency - Check ticket transfer is not in bettrans [Redmine:#167974]
		- 20230228@Sophia: Ignore CustID = 0 [RedmineId: 184425]
	
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @transId		VARCHAR(MAX) =''

	SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
	FROM bodb02.dbo.bettrans WITH(NOLOCK) 
	WHERE bettype >= 19999
		AND transid > @MaxTransID
		AND CustID <> 0

	IF @transId <> ''
	BEGIN
		SELECT	 @transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'Check ticket transfer is not in bettrans'
				,@SampleData = 'bettrans.TransId in (' + @transId + ')'
	END
END
GO