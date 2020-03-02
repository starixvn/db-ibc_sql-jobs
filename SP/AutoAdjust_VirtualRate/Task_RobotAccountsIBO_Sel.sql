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
		- 20200302@Johnson: get site IBO from Dep_CustSuper [redmine:#129509]
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @fromdate DATE, @today DATE
	
	SELECT @today = GETDATE()
	SELECT @fromdate = DATEADD(DAY,-1,@today)
	
	SELECT r.custid
	FROM dbo.RobotUsers r WITH(NOLOCK)
		INNER JOIN bodb02.dbo.customer c WITH (NOLOCK) ON r.custid = c.custid
		INNER JOIN bodb02.dbo.Dep_CustSuper d WITH (NOLOCK) on d.custid = c.srecommend and d.site = 'IBO'
	WHERE RobotDate >= @fromdate AND RobotDate < @today		
END
GO