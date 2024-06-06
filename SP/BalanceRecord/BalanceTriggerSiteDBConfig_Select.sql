/*<info serverAlias="DBBAH-bodb02" executers="wsv_nap" viewers="" isFunction="0"></info>*/  
ALTER PROCEDURE [dbo].[BalanceTriggerSiteDBConfig_Select] 
(
	@SiteDBGroupID		SMALLINT
	,@IsTest			BIT
	,@Mode				TINYINT = 0
	,@LastRowInserted	BIGINT OUTPUT 
)
AS
/*
	Created: 20220130@Louisa
    DB: DBBAH/bodb02
   
    Revisions:
		- 20220130@Louisa: Phase 2 - use Web Service to pull ticket from SiteDB to DB05/DB05BK1 [Redmine:#176932]
		- 20240606@Louisa: Get data for Data consistency rule #61 [Redmine:#205573]

	Param's explaination:
		@Mode : 0 default value, use for service sync Balance Trigger
				1: Get data for Data consistency - Check Balance Trigger slowly
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
	from ( select VName, VValue FROM bodb02.dbo.SystemSettings WITH (NOLOCK) WHERE vname LIKE ''BT_SiteDB%'') s
	PIVOT (
			MAX(vvalue) FOR vname in ([' + @VNameLastRow +'],[' + @VNameStatus +'])
		  ) pv'
	INSERT INTO @tblSetting (LastRowInserted, StatusID)
	EXEC ( @sql)

	SELECT @LastRowInserted  = LastRowInserted
	FROM @tblSetting
	WHERE  1 = CASE WHEN @Mode = 0 AND StatusID = 2 THEN 1
					WHEN @Mode = 1 THEN 1
					ELSE 0
				END
END
GO



 