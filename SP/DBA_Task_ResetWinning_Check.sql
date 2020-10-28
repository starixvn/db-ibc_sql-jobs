/*<info serverAlias="DBTP-bodb02" executers="" viewers="" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Task_ResetWinning_Check] @ErrorMessage VARCHAR(200) = '' OUTPUT	
AS
/*
	Creator: 20160331@Patrick
	Task: Check whether reset winning action make or not
	DB: DBACC/bodb02
	Revisions:
		- 20171031@Harris: Adding case reset winlost but forgot reset the ExtraPT
		- 20180130@Harris: Change the error message and including the discrepancy of yesterday
		- 20190514@Harris: adjust the discrepancy, ignore if others < 5RM or each products < 1RM
		- 20190819@Patrick: Move to DB061 [RedmineId: #118845]
		- 20190826@Harris: Add more column for new Reset Winning SP [Feature #117809]
		- 20190918@Percy: Remove Racing [RedmineID: #118699]
		- 20201022@Patrick: Change email to starixvn [Redmine: #143607]
*/
BEGIN
    SET NOCOUNT ON

    CREATE TABLE #tmp (winlostdate SMALLDATETIME
	   , product VARCHAR(50)
	   , winlost MONEY
	   , winlostAfterExtraPT MONEY
	   , [reset] MONEY
	   , Seq INT
    )
	
	 CREATE TABLE #tmpExtra (GroupID int
	 , groupname varchar(20)
	 , winlost money
	 , [reset] money
	 , winlostdate smalldatetime
    )

    DECLARE @errCode INT, @errMsg VARCHAR(100), @errCodeExtraPT INT

    SELECT @errCode = 0, @errMsg = '', @errCodeExtraPT = 0

    DECLARE @fromdate SMALLDATETIME, @todate SMALLDATETIME, @winlostdate SMALLDATETIME
    
    SELECT @fromdate = DATEADD(DAY, 1, MAX(winlostdate)) 
    FROM dbo.bettrans14 WITH(NOLOCK)

    SELECT @todate = DATEADD (DAY, -1, CAST(GETDATE() AS DATE))

    INSERT #tmp
    EXEC dbo.Task_ResetWinning_Non3rdParty @fromdate = @fromdate, @todate= @todate, @mode = 0

	-- Not reset yet
    SELECT TOP 1 @winlostdate = winlostdate 
    FROM #tmp
    WHERE product = 'SPL' AND [reset] = 0

    IF @@ROWCOUNT > 0
    BEGIN
	   --SELECT @errMsg = @errMsg + CAST(@winlostdate AS VARCHAR(120)) + ' not reset AND '
		  --, @errCode = 1
		  Select @errCode = 1
		GOTO ignoreExtraPT
    END

    -- Check if forgot to reset the ExtraPT
	INSERT #tmpExtra
    EXEC dbo.Task_ResetWinning_ExtraPT @fromdate = @fromdate, @todate= @todate, @mode = 0 
	
	SELECT TOP 1 @winlostdate = winlostdate
	FROM #tmpExtra
	WHERE GROUPID = 19 and [reset] = 0 -- ACCUT always has winlost =))

	IF @@ROWCOUNT <> 0 
    BEGIN
	   --SELECT @errMsg = @errMsg + CAST(@winlostdate AS VARCHAR(120)) + '  not reset Extra PT AND '
		  --, @errCode = 1
		  SELECT @errCodeExtraPT = 1
    END
	
 ignoreExtraPT:
	-- Discrepancy in Reset Winning Main
 	SELECT TOP 1 @winlostdate = winlostdate 
    FROM #tmp 
    --WHERE winlostAfterExtraPT + [reset] <> 0 AND winlostdate <> @todate
	WHERE ABS(winlostAfterExtraPT + [reset]) > 1

    IF @@ROWCOUNT > 0 
    BEGIN
	   --SELECT @errMsg = @errMsg + CAST(@winlostdate AS VARCHAR(120)) + ' Discrepancy in reset winning AND '
		  --, @errCode = 1
		  SELECT @errCode = 1
    END

	-- Discrepancy in ExtraPT
	SELECT TOP 1 @winlostdate = Winlostdate
	FROM #tmpExtra
	WHERE ABS(winlost + [reset]) > 1 and winlostdate <>@todate

	IF @@ROWCOUNT > 0
	BEGIN
		--SELECT @errMsg = @errMsg + CAST(@winlostdate AS VARCHAR(120)) + ' Discrepancy in reset winning ExtraPT AND '
		--  , @errCode = 1
		SELECT @errCodeExtraPT = 1
	END

	-- Discrepancy in Main Others
    SELECT TOP 1 @winlostdate = total.winlostdate  
    FROM (
	   SELECT winlostdate, winlost AS wl 
	   FROM #tmp 
	   WHERE product = 'total balance'
    ) total INNER JOIN (
		 SELECT winlostdate, SUM(winlost) AS wl 
		 FROM #tmp 
		 WHERE product <> 'total balance' 
		 GROUP BY winlostdate
	) allproduct ON allproduct.winlostdate = total.winlostdate
    WHERE ABS(total.wl - allproduct.wl) >= 5

    IF @@ROWCOUNT <> 0 
    BEGIN
	   --SELECT @errMsg = @errMsg + CAST(@winlostdate AS VARCHAR(120)) + ' Discrepancy in OTHERS'
		  --, @errCode = 1
		  SELECT @errCode = 1
    END

	IF @errCode = 1 SELECT @errMsg = @errMsg + ' + Discrepancy in MAIN Reset winning'
	IF @errCodeExtraPT = 1 SELECT @errMsg = @errMsg + ' + Discrepancy in ExtraPT Reset winning'


    --build string to send email
    DECLARE @email_body NVARCHAR(MAX), @subject NVARCHAR(200)
    SET @email_body = '
	   <html>
		 <body>
		  <h1>Reset Winning Check!</h1>
		  <p><b>Check time:</b> ' + CONVERT(VARCHAR(50), GETDATE(), 121) + ' </p> ' +
		  CASE WHEN @errCode + @errCodeExtraPT <> 0 THEN '<div style="background-color:red;color:white;text-align:center">Failure</div> <p><b> Error message:</b> ' + @errMsg + ''
		  ELSE '<div style="background-color:green;color:white;text-align:center">Success</div>' END + '
		</body>
		</html>'

    SELECT @ErrorMessage = @errMsg
    SELECT @subject	= N'Reset Winning Check - KBT@' + @@SERVERNAME
					
    EXECUTE msdb.dbo.sp_send_dbmail @profile_name	= DEFAULT
	   ,	@recipients			 = 'dbaadmin@starixvn.com'
	   ,	@copy_recipients		 = ''
	   ,	@blind_copy_recipients	 = ''
	   ,	@subject				 = @subject
	   ,	@body				 = @email_body
	   ,	@body_format			 = 'HTML';

    DROP TABLE #tmp
	DROP TABLE #tmpExtra
END
GO