/*<info serverAlias="DBBAH-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/  
ALTER PROCEDURE [dbo].[BalanceTriggerSiteDBConfig_Select] 
(
	@SiteDBGroupID		SMALLINT
	,@IsTest			BIT
	,@LastRowInserted	BIGINT OUTPUT 
)
AS
/*
	Created: 20220130@Louisa
    DB: DBBAH/bodb02
   
    Revisions:
		- 20220130@Louisa: Phase 2 - use Web Service to pull ticket from SiteDB to DB05/DB05BK1 [Redmine:#176932]
	
	Param's explaination:
	bettrans
*/
BEGIN
	SET NOCOUNT ON

	IF ISNULL(@SiteDBGroupID,0) = 0
	RETURN

	DECLARE @VNameLastRow VARCHAR(50)
			,@VNameStatus VARCHAR(50)
			,@Sufix		  VARCHAR(2)
			,@Sql		  VARCHAR(MAX)
	
	DECLARE @tblSetting TABLE (LastRowInserted VARCHAR(100), StatusID  VARCHAR(100)) 
	
	SET @Sufix = RIGHT ('0' + CAST(@SiteDBGroupID AS VARCHAR(2)),2)

	SELECT @VNameLastRow = CASE @IsTest WHEN 0 THEN 'BT_SiteDB' + @Sufix + '_Sync'
										ELSE 'BT_SiteDB' + @Sufix + '_Sync' + '_UAT'
										END

	SELECT @VNameStatus = CASE @IsTest WHEN 0 THEN 'BT_SiteDB' + @Sufix + '_InsStatus'
											  ELSE 'BT_SiteDB' + @Sufix + '_InsStatus_UAT'
											  END
	SET @Sql = '
	select '+@VNameLastRow + ',  '+ @VNameStatus +'
	from ( select VName, VValue FROM bodb02.dbo.SystemSettings WITH (NOLOCK) ) s
	PIVOT (
			MAX(vvalue) FOR vname in ([' + @VNameLastRow +'],[' + @VNameStatus +'])
		  ) pv'
	INSERT INTO @tblSetting (LastRowInserted, StatusID)
	EXEC ( @sql)

	SELECT @LastRowInserted  = LastRowInserted
	FROM @tblSetting
	WHERE StatusID = 2
END
GO



 