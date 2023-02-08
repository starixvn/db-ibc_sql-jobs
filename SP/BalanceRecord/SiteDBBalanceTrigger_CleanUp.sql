/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/  
ALTER PROCEDURE [dbo].[SiteDBBalanceTrigger_CleanUp]
(
	 @SiteDBAlias VARCHAR(100) = NULL
	,@VName VARCHAR(100) = NULL
)

AS
/*
    Created: 20220928@July
    Task: 
    DB: DBBAH/bodb02
    Revisions:
		- 20220928@July: scaleout project - Balance record [176932]
		- 20221110@July: Scale out DBTrans - Enhance Job clean BalanceTrigger [180331]
		- 20220130@Louisa: Phase 2 - use Web Service to pull ticket from SiteDB to DB05/DB05BK1 [Redmine:#176932]
		
*/
BEGIN
	
	SET NOCOUNT ON

	IF @@SERVERNAME NOT IN ('TESTDB053','DB05BK1','SITDB05')
	BEGIN
			RAISERROR ('EXEC dbo.Task_BalanceRecord_SiteDBBalanceTrigger_CleanUp failed due to wrong server!', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
			RETURN
	END

	DECLARE @MaxID BIGINT = 0 
			,@IsTestUAT VARCHAR(1)
			,@sqlCMD NVARCHAR(MAX)
			,@LinkedAlias VARCHAR(100)='DB05'
			,@MaxID_DB05 BIGINT 

	select @IsTestUAT =  (select vvalue from SystemSettings where VName = 'BT_SiteDB' + RIGHT(@SiteDBAlias, 2) +'_ServiceStatus_UAT')

	SELECT @MaxID = MIN( CAST (VValue AS BIGINT ) )
					FROM bodb02.dbo.SystemSettings WITH (NOLOCK)
					WHERE VName =  'BT_SiteDB' + RIGHT(@SiteDBAlias, 2) +'_Sync'
						OR  (Vname = 'BT_SiteDB' + RIGHT(@SiteDBAlias, 2) +'_Sync_UAT' and @IsTestUAT   ='1')

	SET @sqlCMD = '\
	SELECT @MaxID_DB05 = MIN(CAST (VValue AS BIGINT ) )
	FROM OPENQUERY('+@LinkedAlias+', ''\
	SELECT VValue
	FROM bodb02.dbo.SystemSettings WITH (NOLOCK)\
	WHERE VName =  ''''BT_SiteDB'''' + RIGHT('''''+@SiteDBAlias+''''', 2) +''''_Sync''''\
						OR  (Vname = ''''BT_SiteDB'''' + RIGHT('''''+@SiteDBAlias+''''', 2) +''''_Sync_UAT'''' and ''''' +@IsTestUAT + '''''  =''''1'''')\
	'')';
	
	BEGIN TRY
		EXEC sp_executesql @sqlCMD, N'@MaxID_DB05 BIGINT OUTPUT', @MaxID_DB05=@MaxID_DB05 OUTPUT
		
		IF @MaxID_DB05 IS NULL
		BEGIN
			RAISERROR ('EXEC dbo.Task_BalanceRecord_SiteDBBalanceTrigger_CleanUp failed to get sync value!', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
			RETURN
		END
		IF @MaxID > @MaxID_DB05
			SET @MaxID = @MaxID_DB05
	END TRY
	BEGIN CATCH
			RAISERROR ('EXEC dbo.Task_BalanceRecord_SiteDBBalanceTrigger_CleanUp failed to get sync value!', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
			RETURN
	END CATCH

	DECLARE  @ExecuteSQL NVARCHAR(MAX) = ''
			, @query NVARCHAR(MAX) = ''

	SELECT  @query = N''		
	SELECT	@query = @query + N'EXEC SiteDB_Task_BalanceRecord_SiteDBBalanceTrigger_CleanUp @MaxID'
	
	SELECT	@ExecuteSQL = N'EXECUTE '+ @SiteDBAlias +'.bodb02.dbo.sp_executesql @query, N''@MaxID BIGINT'',@MaxID'
	
	--PRINT @ExecuteSQL
	EXECUTE	sys.sp_executesql @ExecuteSQL, N'@query NVARCHAR(MAX), @MaxID BIGINT', @query, @MaxID

END



