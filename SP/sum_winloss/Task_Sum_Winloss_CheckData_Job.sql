/*<info serverAlias="DBAGE-bodb02" isNested=""></info>*/
CREATE PROCEDURE Task_Sum_Winloss_CheckData_Job	
/*
	Created: 20231018@Lewis
	DB: DBAGE.bodb02
	Task: Input @WinlostDate for Task_CheckData_sum_winloss [RedmineID: #193254]

	Revisions:
		- 20231018@Lewis: Initialize SP [RedmineID: #193254]

*/
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @info TABLE (BU SMALLDATETIME, MB SMALLDATETIME)
	INSERT INTO @info (BU, MB)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

    DECLARE @MoveBetsDay SMALLDATETIME
			,@BalanceUpDay SMALLDATETIME
    SELECT @MoveBetsDay = MB, @BalanceUpDay = BU FROM @info
	
	CREATE TABLE #Result (
		custid INT
		, winlostdate SMALLDATETIME
		, productid INT
		, winlost_sum money
		, winlost_bettrans money
		, playercomm_sum money
		, playercomm_bettrans money
	)
	
	WHILE @BalanceUpDay <= @MoveBetsDay
	BEGIN
		INSERT INTO #Result (
			custid
			, winlostdate
			, productid
			, winlost_sum
			, winlost_bettrans
			, playercomm_sum
			, playercomm_bettrans
		)
		EXEC Task_Sum_winloss_CheckData @WinlostDate = @BalanceUpDay

		SET @BalanceUpDay = DATEADD(DAY,1,@BalanceUpDay)
	END


	-- Send email
	DECLARE @Subject VARCHAR(1000)
			,@body VARCHAR(MAX)
			,@recipients VARCHAR(MAX)

	IF EXISTS (SELECT TOP 1 1 FROM #Result)
	BEGIN
	 	SELECT @Subject = 'Cross check data for job on ' +@@SERVERNAME+ ': Sum_winloss vs Bettrans14 from ' + CONVERT(VARCHAR(20),@BalanceUpDay, 107) + ' to ' + CONVERT(VARCHAR(20),@MoveBetsDay, 107)
		
		SELECT @recipients = CASE WHEN @@SERVERNAME IN ('DB053','DB052','SITDB052','SITDB053') THEN 'dbaadmin@starixsoft.com'
								  ELSE 'dba_local@starixsoft.com'
								  END

		SELECT @body = '<H3>List products have wrong data</H3>'
							+ '<table border="1" style="width: 75%"> '
							+ '<tr><th>No.</th><th>Winlostdate</th><th>ProductId</th><th>CustId</th><th>Winlost_Sum_winloss</th><th>Winlost_Bettrans14</th><th>PlayerComm_Sum_winloss</th><th>PlayerComm_Bettrans14</th></tr>'
							+ CAST(( SELECT    td = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)), '',
														td = r.winlostdate, '',
														td = r.ProductId, '',
														td = r.custid, '',
														td = ISNULL(CAST(r.winlost_sum AS VARCHAR(10)),' '), '',
														td = ISNULL(CAST(r.winlost_bettrans AS VARCHAR(10)),' '), '',
														td = ISNULL(CAST(r.playercomm_sum AS VARCHAR(10)),' '), '',
														td = ISNULL(CAST(r.playercomm_bettrans AS VARCHAR(10)),' '), ''
											FROM #Result r
											FOR XML PATH('tr'), TYPE 
										) AS NVARCHAR(MAX) ) 
							+ N'</table>'
		
		EXEC msdb.dbo.sp_send_dbmail
			@recipients = @recipients
			, @subject = @subject
			, @body = @body
			, @body_format = 'HTML' 
	END


	DROP TABLE #Result

END

