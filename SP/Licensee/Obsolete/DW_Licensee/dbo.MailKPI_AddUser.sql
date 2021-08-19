IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MailKPI_AddUser]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[MailKPI_AddUser]
GO

CREATE  PROCEDURE [dbo].[MailKPI_AddUser]
	@name varchar(50)
	,@email varchar(50)
AS
BEGIN	
/*
Created: 20110624@Elly.Nguyen
Task : Add new user
DB: DBDW2.bodb_KPI

Revisions:
    
Param's Explanation: 
*/
	SET NOCOUNT ON
	
	DECLARE @UserID int
	
	INSERT INTO dbo.MailKPI_Users(
			Name
			,Email)
	VALUES (@name
			,@email)

	SET @UserID = SCOPE_IDENTITY()
	
	INSERT INTO dbo.MailKPI_SendMailUsers(
			UserID
			,TaskID)
	SELECT @UserID, TaskID
	FROM dbo.MailKPI_Tasks WITH(NOLOCK)
	
	INSERT INTO dbo.MailKPI_ReportPermission(
			UserID
			,ReportID
			,SectionID
			,Permission)
	SELECT @UserID
			,ReportID
			,SectionID
			,1
	FROM dbo.MailKPI_ReportSections WITH(NOLOCK)
	
	select @UserID		
	SET NOCOUNT OFF
END
/*
EXEC dbo.MailKPI_AddUser @name ='new user 1', @email='email1@nexcel.vn'
*/
GO
GRANT EXECUTE ON [dbo].[MailKPI_AddUser] TO [bodbLicenseeNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[MailKPI_AddUser] TO [VNTeam]