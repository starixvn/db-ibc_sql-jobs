/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DailyRptLicWinlossGMT_CopyData]
	@FromDate SMALLDATETIME,
	@ToDate	SMALLDATETIME = NULL,
	@TimeZone SMALLINT = NULL
AS  
/*  
	Created: 20171214@Paul
	Task: Daily summary for RptLicWinlossGMT from bettrans14
	DB: DBLIC.bodb_LicenseeReport
	Revisions:  
	- 20171214@Paul: initial data. Apply for Sportsbook first [redmine: #84932]
*/  
BEGIN
	SET NOCOUNT ON

    IF @ToDate IS NULL
	BEGIN
		SET @ToDate = @FromDate
	END

	DECLARE @RptDates TABLE (RecordID SMALLINT IDENTITY(1, 1), RptDate SMALLDATETIME, TimeZone SMALLINT)
	DECLARE @sql VARCHAR(MAX)

	INSERT INTO @RptDates(RptDate, TimeZone)
	SELECT RptDate, TimeZone
	FROM OPENQUERY(DBRPT, '	SELECT DISTINCT RptDate, TimeZone
							FROM bodb_report.dbo.rptLicWinlossGMTTmp WITH(NOLOCK)')
	WHERE RptDate BETWEEN @FromDate AND @ToDate
		AND (TimeZone = @TimeZone OR @TimeZone IS NULL)

	IF NOT EXISTS (SELECT 1 FROM @RptDates)
	BEGIN
		RETURN
	END

	DECLARE @RptDate SMALLDATETIME,
			@RecordID SMALLINT = 1,
			@ProcessingTimeZone SMALLINT

	WHILE EXISTS(SELECT 1 FROM @RptDates WHERE RecordID = @RecordID)
	BEGIN
		SELECT	@RptDate = RptDate,
				@ProcessingTimeZone = TimeZone
		FROM @RptDates
		WHERE RecordID = @RecordID

		SET @sql = '
			SELECT TimeZone
				,RptDate
				,RptDateGMT
				,Username
				,Username2
				,Custid
				,Roleid
				,Recommend
				,Mrecommend
				,Srecommend
				,Bettype
				,Sporttype
				,ProductId
				,Turnover
				,Winlost
				,AWinlost
				,MWinlost
				,SWinlost
				,BetEffective
				,playercomm
				,Comm
				,AComm
				,SComm		
				,WinlostVirtual
				,CommVirtual
				,BetCount
				,Currency
				,StatusID
				,IsBA
				,IsMobile
				,Betfrom
			FROM OPENQUERY(DBRPT, ''
				SELECT TimeZone
					,RptDate
					,RptDateGMT
					,Username
					,Username2
					,Custid
					,Roleid
					,Recommend
					,Mrecommend
					,Srecommend
					,Bettype
					,Sporttype
					,ProductId
					,Turnover
					,Winlost
					,AWinlost
					,MWinlost
					,SWinlost
					,BetEffective
					,playercomm
					,Comm
					,AComm
					,SComm		
					,WinlostVirtual
					,CommVirtual
					,BetCount
					,Currency
					,StatusID
					,IsBA
					,IsMobile
					,Betfrom
				FROM bodb_report.dbo.rptLicWinlossGMTTmp WITH(NOLOCK)
				WHERE RptDate = ''''' + CAST(@RptDate AS VARCHAR(20)) + '''''
					AND TimeZone = ' + CAST(@ProcessingTimeZone AS VARCHAR(3)) + '
				OPTION (MAXDOP 1)'')
		'

		DELETE dbo.rptLicWinlossGMT WITH(ROWLOCK, UPDLOCK)
		WHERE RptDate = @RptDate
			AND TimeZone = @ProcessingTimeZone

		INSERT INTO dbo.rptLicWinlossGMT (  
			TimeZone
			,RptDate
			,RptDateGMT
			,Username
			,Username2
			,Custid
			,Roleid
			,Recommend
			,Mrecommend
			,Srecommend
			,Bettype
			,Sporttype
			,ProductId
			,Turnover
			,Winlost
			,AWinlost
			,MWinlost
			,SWinlost
			,BetEffective
			,playercomm
			,Comm
			,AComm
			,SComm		
			,WinlostVirtual
			,CommVirtual
			,BetCount
			,Currency
			,StatusID
			,IsBA
			,IsMobile
			,Betfrom
		)
		EXEC(@sql)

		SET @RecordID = @RecordID + 1
		
		WAITFOR DELAY '00:00:00.280'
	END
END
GO