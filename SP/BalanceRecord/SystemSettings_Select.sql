/*<info serverAlias="DBBAH-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/  
ALTER PROCEDURE [dbo].[SystemSettings_Select] 
(
	@VName		VARCHAR(50)
	,@VValue	VARCHAR(200) OUTPUT 
)
AS
/*
	Created: 20220130@Louisa
    DB: DBBAH/bodb02
   
    Revisions:
		- 20220130@Louisa: Phase 2 - use Web Service to pull ticket from SiteDB to DB05/DB05BK1 [Redmine:#176932]
	
	Param's explaination:
*/
BEGIN
	SET NOCOUNT ON

	SELECT s.VValue
	FROM bodb02.dbo.SystemSettings s WITH(NOLOCK)
	WHERE s.VName = @VName

END
GO

