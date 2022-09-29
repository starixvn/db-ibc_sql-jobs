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
	SET @MaxID = (SELECT CONVERT(BIGINT,VValue) FROM bodb02.dbo.SystemSettings WITH (NOLOCK) WHERE VName = @VName/*'BT_SiteDB01_Sync'*/)

	DECLARE @sqlCMD NVARCHAR(MAX), @LinkedAlias VARCHAR(100)='DB05', @MaxID_DB05 BIGINT 

	SET @sqlCMD = N'\
	SELECT @MaxID_DB05 = CONVERT(BIGINT,VValue)
	FROM OPENQUERY('+@LinkedAlias+', ''\
	SELECT VValue
	FROM bodb02.dbo.SystemSettings WITH (NOLOCK) WHERE VName = '''''+@VName+ '''''\
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

	--Keep 10000 very first rows in the table
	IF @MaxID - 10000 <= 0
		RETURN
	
	SET @MaxID = @MaxID - 10000

	DECLARE  @ExecuteSQL NVARCHAR(MAX) = ''
			, @query NVARCHAR(MAX) = ''

	SELECT  @query = N''		
	SELECT	@query = @query + N'EXEC SiteDB_Task_BalanceRecord_SiteDBBalanceTrigger_CleanUp @MaxID'
	
	SELECT	@ExecuteSQL = N'EXECUTE '+ @SiteDBAlias +'.bodb02.dbo.sp_executesql @query, N''@MaxID BIGINT'',@MaxID'
	
	--PRINT @ExecuteSQL
	EXECUTE	sys.sp_executesql @ExecuteSQL, N'@query NVARCHAR(MAX), @MaxID BIGINT', @query, @MaxID

END



