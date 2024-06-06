/*<info serverAlias="DBSIG-bodb02,DBBAH-bodb02" executers="wsv_nap" viewers="" isFunction="0"></info>*/  
ALTER PROCEDURE DBA_Consistency_BalanceTrigger_Checking
	@CheckingTime		INT		= 180
	,@LastRowInserted	BIGINT  = NULL
	,@TargetServer		VARCHAR(100) = ''
	,@ErrCode			INT				= 0		OUTPUT
	,@ErrMsg			VARCHAR(MAX)	= ''	OUTPUT
	,@SampleData		VARCHAR(MAX)	= ''	OUTPUT

AS
/*
    Created: 20240527@Louisa
    DB: DBSIG/bodb02
   
   Revisions:
		- 20240527@Louisa: Data consistency rule #61 [Redmine:#205573]
		- 20240606@Louisa: Add @TargetServer [Redmine:#205573]

	Param's explaination:
		@CheckingTime: in second
		@LastRowInserted: Last row synchronize from SiteDB to DBBAH

*/
BEGIN
	
	SET NOCOUNT ON

	DECLARE @ActionDate	DATETIME
			,@CurrentTime	DATETIME	 = GETDATE()
			,@ServerName	VARCHAR(100) = @@SERVERNAME
			,@ListCustIDs	VARCHAR(MAX) = ''

	 --checking slowly on sitedb
	IF @ServerName LIKE '%DBGRP%' OR @ServerName IN ('TESTSITEDB2', 'DB67')
	BEGIN
		SELECT TOP(1) @ActionDate = tr.ActionDate
		FROM BalanceTrigger tr WITH(NOLOCK)
		WHERE tr.RowID > @LastRowInserted
		ORDER BY tr.RowID

		IF @ActionDate IS NOT NULL AND DATEDIFF(SECOND, @ActionDate, @CurrentTime) >= @CheckingTime
		BEGIN
			SELECT @ErrMsg = '.bodb02.dbo.BalanceTrigger to '+ ISNULL(@TargetServer,'DBBAH') +' is slowly or pending over ' 
		END
	END

	--checking slowly on DBBAH
	IF @ServerName IN ('DB05','DB05BK1','TESTDB053','SITDB05')
	BEGIN
		SELECT @ActionDate   = MIN(tr.ActionDate)
		FROM BalanceTrigger tr WITH(NOLOCK)

		IF DATEDIFF(SECOND, @ActionDate, @CurrentTime) >= @CheckingTime
		BEGIN
			SELECT @ErrMsg =  '.bodb02.dbo.BalanceTrigger to dbo.BalanceRecord is slowly or pending over ' 
							
		END
	END
	
	IF @ErrMsg <> ''
	BEGIN
		;WITH cte_Cust AS 
		(	SELECT DISTINCT TOP(100) tr.CustID 
			FROM BalanceTrigger tr WITH(NOLOCK)
			WHERE tr.ActionDate BETWEEN @ActionDate AND @CurrentTime
		)

		SELECT @ListCustIDs = @ListCustIDs + ', ' + CAST(CustID AS VARCHAR(50)) FROM cte_Cust
		SELECT @ListCustIDs = STUFF(@listcustids , 1, 2, '')

		SELECT @ErrCode = 100
			 ,@ErrMsg =  @ServerName + @ErrMsg 
						+CAST(@CheckingTime/60 AS VARCHAR(2)) + ' minute(s)
						 CustID IN ('+ @ListCustIDs + ')'
			 ,@SampleData = 'SELECT TOP(100) RowID, CustID FROM dbo.BalanceTrigger WITH(NOLOCK) WHERE ActionDate BETWEEN ''' 
							+ CONVERT(VARCHAR(24),@ActionDate,120)
							+ ''' AND ''' + CONVERT(VARCHAR(24),@currentTime,120)
							+ ''''
	END
END
GO