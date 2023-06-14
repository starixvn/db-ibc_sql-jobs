/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_UserLog_Settle_WriteLog]
	@MessageBody XML
AS
/*	
	Created: 20230421@Aries
	Task: Use Service Broker to Write Log to DB Log
	DB: DBLOG-bodb_CustomerLog

	Revisions: 
        - 20230214@Aries: Created [Redmine: #187252]
		
	Param's Explanation:

*/
	SET NOCOUNT ON

	INSERT INTO dbo.UserLog_Settle(	
		UserID,
		MatchID,
		ActionID,
		[finalhomescore],
		[finalawayscore],  
		[hthomescore],
		[htawayscore],
		[GoalRecord],
		[betstatus],
		[Remark],
		[IP],
		LogDate
	) 
	SELECT   t.c.value('@u','INT')							AS UserID,
			 t.c.value('@m','INT')							AS MatchID,
			 t.c.value('@a','INT')							AS ActionID,
			 t.c.value('@fth','INT')						AS [finalhomescore],
			 t.c.value('@fta','INT')						AS [finalawayscore],
			 t.c.value('@hth','INT')						AS [hthomescore],
			 t.c.value('@hta','INT')						AS [htawayscore],
			 t.c.value('@g','VARCHAR(50)')					AS [GoalRecord],
			 t.c.value('@b','VARCHAR(50)')					AS [betstatus],
			 t.c.value('@r','VARCHAR(MAX)')					AS [Remark],
			 t.c.value('@i','VARCHAR(15)')					AS IP,
			 ISNULL(t.c.value('@l','DATETIME'),GETDATE())	AS LogDate
	FROM @MessageBody.nodes('UserLog_Settle/row') t(c)
	OPTION (OPTIMIZE FOR (@MessageBody = NULL))


GO