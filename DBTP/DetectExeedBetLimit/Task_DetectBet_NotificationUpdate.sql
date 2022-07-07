/*<info serverAlias="DBTP-bodb02" executers="bodbAdminNet" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DetectBet_NotificationUpdate]
(
	@CustList			VARCHAR(MAX) = NULL,
	@ErrorCode			INT = 0 OUTPUT,
	@ErrorMessage		NVARCHAR(200) = '' OUTPUT
)
AS
/*	
	Created by: Max
	Date : 20220525
	Task: Detect player exceeded the bet limit of the Agent's setting [Redmine: #170739]
	DB: DBTP/bodb02
	
	Revisions: 
		- 20220525@Max: Create SP [Redmine: #170739]
	
	Param's explanation:
	- @CustList:
		<root>
			<r custid="123" transid="789654" />
		</root>
*/
BEGIN
	SET NOCOUNT ON 
	DECLARE @xml XML = NULL

	DECLARE @CustTransId_Batch AS TABLE (
		CustId INT
		, transid BIGINT
	) 

	CREATE TABLE #CustTransId_tmp (
		CustId INT
		, transid BIGINT
	)
	
	SET @xml = CONVERT(XML, @CustList)

	INSERT INTO #CustTransId_tmp(CustId, transid)        
	SELECT t.c.value('@custid','int') AS custid
		,t.c.value('@transid','BIGINT') AS transid
	FROM @xml.nodes('root/r') t(c)
	OPTION (OPTIMIZE FOR (@xml = NULL))

	WHILE(1=1)
	BEGIN
		DELETE @CustTransId_Batch

		DELETE TOP (1000) t
			OUTPUT DELETED.CustId, DELETED.transid
			INTO @CustTransId_Batch
		FROM #CustTransId_tmp t

		IF @@ROWCOUNT = 0 BREAK

		UPDATE t SET t.IsSendLetstalk = 1, t.IsSendLetstalkTest = 1
		FROM dbo.CustMaxBet_Invalid t WITH (ROWLOCK, UPDLOCK)
			INNER JOIN @CustTransId_Batch tmp ON tmp.transid = t.TransID and tmp.CustId = t.CustID
	END
	
	IF @@ERROR <> 0
	BEGIN
		SELECT	@ErrorCode = 101,
				@ErrorMessage  = 'Update does not successfully.'
	END

	DROP TABLE #CustTransId_tmp
END
GO

