/*<info serverAlias="DBONUSER-ON_USER" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_RobotAccountsIBO_Sel]		
AS
/*
	Created by: 20200114@Johnson	
	Task: get list robot accounts under IBO have created from yesterday for 
		auto adjust VR setting
	DB: DBONUSER/ON-USER
	
	Revisions:
		- 20200114@Johnson: initial sp [redmine:#126998]
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @fromdate DATE, @today DATE
	
	SELECT @today = GETDATE()
	SELECT @fromdate = DATEADD(DAY,-1,@today)
	
	SELECT custid
	FROM dbo.RobotUsers WITH(NOLOCK)
	WHERE RobotDate >= @fromdate AND RobotDate < @today
		AND site = 'IBO'		
END
GO