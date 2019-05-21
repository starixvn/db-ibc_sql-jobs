/*<info serverAlias="DBPOL-NAP_UserControl" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_EAS_ClearLogin_Loop]   
AS  
/*
	Created:  20131324
	Task: Clear Login
	DB: DBPOL/NAP_UserControl
	Original SP:
	
	Revisions:
		- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
*/
BEGIN
	SET NOCOUNT ON
	
	Declare @start datetime  
	SELECT @start = CURRENT_TIMESTAMP  

	WHILE (1=1) AND (DATEDIFF(minute,@start, CURRENT_TIMESTAMP) < 20)  
	BEGIN  
		EXEC [Task_EAS_ClearLogin]  
		WAITFOR DELAY '00:00:30'  
	END
END

GO
