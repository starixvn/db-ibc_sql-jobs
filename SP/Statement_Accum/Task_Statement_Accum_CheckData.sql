/*<info serverAlias="DBRPT-bodb_report" executers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_Statement_Accum_CheckData]
    @FromDate   SMALLDATETIME
    ,@ToDate    SMALLDATETIME
	,@IsManual	BIT = 0 
AS
/*
     Created:    20221108@Danny
    Task:       SSIS Archiving Data - Statement_Accum
    Database:   DBRPT-bodb_report

    Revisions:
        - 20221108@Danny: Initialize SP [RedmineID: #169560]
 */
BEGIN
    SET NOCOUNT ON

    DECLARE @tmp_winlostdate    SMALLDATETIME,
            @BalanceUpDay       SMALLDATETIME,
            @fdate      DATETIME,
            @tdate      DATETIME,
            @accdate    DATETIME,
			@min_winlostdate SMALLDATETIME,
            @max_winlostdate SMALLDATETIME

    DECLARE @MBU TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

	CREATE TABLE #__bettrans 
	(
		custid INT, recommend INT, mrecommend INT, srecommend INT,
		actual_stake MONEY, winlost MONEY, awinlost MONEY, mwinlost MONEY, swinlost MONEY,
		playercomm MONEY, comm MONEY, acomm MONEY, scomm MONEY
	)

	CREATE TABLE #__transfer (custid INT, amount MONEY)

	CREATE TABLE #__Statement_Accum(
		[CustId] [int] NOT NULL,
		[AccDate] [datetime] NOT NULL,
		[TotalAmt] [money] NULL
	 CONSTRAINT [PK_Statement_Accum] PRIMARY KEY CLUSTERED 
		(
			[AccDate] ASC,
			[CustId] ASC
		)
	)

	CREATE TABLE #__custChanged (
		custid INT
		,AccDate DATETIME
		,TotalAmt_Old MONEY
		,TotalAmt_New MONEY
		,Action VARCHAR(10)
	);
    
    INSERT INTO @MBU (BalanceUpDay, MoveBetsDay)
    EXEC dbo.Age_SelBalanceUpDay

    SELECT @BalanceUpDay = BalanceUpDay FROM @MBU

	SELECT	@min_winlostdate = MIN(winlostdate),
			@max_winlostdate = MAX(winlostdate)
    FROM DBTXN.bodb02.dbo.Task_ArchiveDate WITH (NOLOCK)

	IF (@BalanceUpDay = DATEADD(DAY, 1, @max_winlostdate) AND DATEPART(weekday, GETDATE()) = 6 AND @IsManual = 0) OR @IsManual = 1
	BEGIN
		IF @IsManual = 0
		BEGIN
			SELECT @FromDate = @min_winlostdate, @ToDate = @max_winlostdate
		END
		ELSE
		BEGIN
			IF ( DATEDIFF(DAY,@ToDate,@FromDate) <> 6 
					OR DATEPART(WEEKDAY, @FromDate) <> 6 
					OR DATEPART(WEEKDAY, @ToDate) <> 5 
				)
				RETURN
		END

		SELECT @fdate = @FromDate, @tdate = DATEADD(DAY, 1, @ToDate), @accdate = DATEADD(DAY, 1, @ToDate)

		-- Get data from bettrans
		INSERT INTO #__bettrans (custid, recommend, mrecommend, srecommend, actual_stake, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm)
		SELECT custid, recommend, mrecommend, srecommend, SUM(actual_stake), SUM(winlost), SUM(awinlost), SUM(mwinlost), SUM(swinlost), SUM(playercomm), SUM(comm), SUM(acomm), SUM(scomm)
		FROM bodb_Archive.dbo.bettrans_bk WITH (NOLOCK)
		WHERE winlostdate BETWEEN @FromDate AND @ToDate
		GROUP BY custid, recommend, mrecommend, srecommend

		-- Get data from transfer
		SET @tmp_winlostdate = DATEADD(DAY, -14, @FromDate)
    
		WHILE @tmp_winlostdate <= @ToDate
		BEGIN
			IF @tmp_winlostdate >= @BalanceUpDay
				INSERT INTO #__transfer (custid, amount)
				SELECT custid, SUM(Winlost - Actual_Stake) AS amount
				FROM bodb02.dbo.Transfer WITH (NOLOCK)
				WHERE TransDate >= @fdate AND TransDate < @tdate AND bettype > 20000
					AND winlostdate = @tmp_winlostdate
				GROUP BY custid
			ELSE
				INSERT INTO #__transfer (custid, amount)
				SELECT custid, SUM(Credit - Debit) AS amount
				FROM bodb_Archive.dbo.Transfer_bk WITH (NOLOCK)
				WHERE TransDate >= @fdate AND TransDate < @tdate AND bettype > 20000
					AND winlostdate = @tmp_winlostdate
				GROUP BY custid

			SELECT @tmp_winlostdate = DATEADD(DAY, 1, @tmp_winlostdate)
		END

		INSERT INTO #__Statement_Accum(CustId,AccDate,TotalAmt)
		SELECT CustId, @accdate AS AccDate, SUM(totalamt) AS TotalAmt
		FROM (
			-- Opening Accumulated Amount
			SELECT custid, totalamt
			FROM dbo.Statement_Accum WITH (NOLOCK)
			WHERE accdate = @fromdate

			-- Transfer tickets
			UNION ALL
			SELECT custid, SUM(amount) AS totalamt
			FROM #__transfer
			GROUP BY custid

			-- Prize tickets
			UNION ALL
			SELECT custid, SUM(WinAmount) AS totalamt
			FROM bodb02.dbo.PayoutTrans WITH (NOLOCK)
			WHERE winlostdate BETWEEN @FromDate AND @ToDate
				AND PayoutStatusId IN (4, 5) -- 'Completed', 'Expired'      
			GROUP BY custid

			-- Bet tickets
			UNION ALL
			SELECT t.custid, SUM(t.totalamt) AS totalamt
			FROM #__bettrans b
				CROSS APPLY (
					SELECT b.custid, b.winlost - b.actual_stake + b.playercomm AS totalamt
					UNION ALL SELECT b.recommend, b.awinlost + b.comm - b.playercomm
					UNION ALL SELECT b.mrecommend, b.mwinlost + b.acomm - b.comm
					UNION ALL SELECT b.srecommend, b.swinlost + b.scomm - b.acomm
				) t
			GROUP BY t.custid
		) b
		GROUP BY custid
		HAVING SUM(totalamt) <> 0

		DECLARE	@subject	NVARCHAR(MAX)
				,@bodymsg	NVARCHAR(MAX)
				,@recipients NVARCHAR(500)
				,@server_name SYSNAME
			
		SELECT @server_name = @@SERVERNAME
			   ,@recipients	= CASE WHEN @server_name IN ('TESTDB061') THEN 'dba_local@starixvn.com' ELSE 'dbaadmin@starixvn.com' END

		SELECT	@subject	= N'Job - Statement Accum - Check Balance diff(s) found ' + @@SERVERNAME;
		IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.Statement_Accum WITH(NOLOCK) WHERE AccDate = @accdate)
		BEGIN
			SELECT	@bodymsg	= N'\
								Dear All,</br>
								No data found in the RptStatement_Accum.</br>
								Please take a look on bodb_Report: Daily Summary rptStatement Job</br> 
								Data will be inserted by Task_Statement_Accum_CheckData step. </br> 
								'
								+ 'Best regards, </br> 
								This is an auto-mail from the Internal System. Please do not reply.';

			EXECUTE	msdb.dbo.sp_send_dbmail
					@recipients				= @recipients
				,	@copy_recipients		= ''
				,	@blind_copy_recipients	= ''
				,	@subject				= @subject
				,	@body					= @bodymsg
				,	@body_format			= 'HTML'
				;
		END
		ELSE
		BEGIN
			INSERT INTO #__custChanged (custid,AccDate ,TotalAmt_Old ,TotalAmt_New, Action)
			SELECT TOP(50) 
					ISNULL(s.CustId,t.CustId) CustId, 
					ISNULL(s.AccDate, t.AccDate) AccDate, 
					t.TotalAmt, 
					s.TotalAmt,
					CASE WHEN	t.TotalAmt IS NULL THEN 'Insert'
						 WHEN	s.TotalAmt IS NULL THEN 'Delete'
						 WHEN	t.TotalAmt <> s.TotalAmt THEN 'Update'
					END
			FROM #__Statement_Accum s
			FULL JOIN dbo.Statement_Accum t WITH(NOLOCK) ON s.CustId = t.CustId AND s.AccDate = t.AccDate 
			WHERE t.TotalAmt IS NULL OR s.TotalAmt IS NULL OR t.TotalAmt <> s.TotalAmt


			SELECT	@bodymsg	= N'\
								Dear All,</br>
								An different has been found while checking old balance and new balance in the Statement_Accum.</br>
								Please take a look on the table below:</br> '
								+ '<table border="1"> '
								+ '<tr><th>Custid</th><th>AccDate</th><th>TotalAmt_Old</th><th>TotalAmt_New</th><th>Action</th></tr>'
								+ CAST(( SELECT     td = CONVERT(VARCHAR(50), ISNULL(Custid, 0)), '',
													td = CONVERT(VARCHAR(50), AccDate, 120), '',
													td = CONVERT(VARCHAR(50), ISNULL(TotalAmt_Old, 0)), '',
													td = CONVERT(VARCHAR(50), ISNULL(TotalAmt_New, 0)), '',
													td = CONVERT(VARCHAR(50), ISNULL(Action, 0)), ''
										FROM #__custChanged
										FOR XML PATH('tr'), TYPE 
									) AS NVARCHAR(MAX) ) + N'</table>'
								
								+ 'Best regards, </br> 
								This is an auto-mail from the Internal System. Please do not reply.';

		END

		MERGE dbo.Statement_Accum AS t
		USING #__Statement_Accum AS u ON t.AccDate = u.AccDate AND t.CustId = u.CustId
		WHEN MATCHED THEN UPDATE
			SET TotalAmt = u.totalAmt
		WHEN NOT MATCHED THEN
			INSERT(CustID, AccDate, TotalAmt)
			VALUES(u.CustId, u.AccDate, u.TotalAmt)
		WHEN NOT MATCHED BY SOURCE AND t.AccDate = @accdate THEN DELETE;
	END

    DROP TABLE #__bettrans
    DROP TABLE #__transfer
	DROP TABLE #__Statement_Accum
	DROP TABLE #__custChanged
END

