/*<info serverAlias="DBCUST-CustDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_RobotAccountsIBO_Sel_Wrapper]		
AS
/*
	Created: 20210510@Eden
	Task : get On_User_Agent.LoginTime
	DB: DBCUST/CustDB

	Revisions:
		- 20210510@Eden: Enhancement for not relying on DB On_User [redmine: #154507]
	Param's Explanation:

*/

BEGIN
	BEGIN TRY --on DBONUSER
		EXEC DBONUSER.ON_USER.dbo.Task_RobotAccountsIBO_Sel
	END TRY
	BEGIN CATCH --on DBCUST
		BEGIN TRY
			EXEC ON_USER.dbo.Task_RobotAccountsIBO_Sel
		END TRY
		BEGIN CATCH
			SELECT CAST(NULL AS INT) AS CustID WHERE 1 <> 1
		END CATCH
	END CATCH
END
GO