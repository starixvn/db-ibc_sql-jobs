/*<info serverAlias="DBLIC-bodb_3rdProduct" executers="" isFunction="0" isNested="0"></info>*/
USE [bodb_3rdProduct]
GO

ALTER PROCEDURE [dbo].[Task_Sum_winloss_Exchange_CheckData]
	@FromDate	SMALLDATETIME = NULL -- not null for manually
	,@ToDate	SMALLDATETIME = NULL -- not null for manually
AS

/*
	Created: 20190329@Percy
	DB: DBLIC.bodb_3rdProduct
	Task: Check Exchange Data

	Revisions:
		- 20190401@Percy: Initialize SP [RedmineID: #110692]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @isJob BIT = 0

	-- For send mail
	DECLARE @Subject VARCHAR(1000) = '', @Msg NVARCHAR(MAX) = ''
	SELECT  @Subject = 'SQL Server Job System: ''bodb_3rdProduct: Check Exchange data monthly'' on ' + @@SERVERNAME

	IF @FromDate IS NULL OR @ToDate IS NULL -- for job
	BEGIN
		SELECT @isJob = 1

		BEGIN TRY
			SELECT
				@FromDate	= CASE SName WHEN 'FromImportedDate' THEN CONVERT(SMALLDATETIME, SValue) ELSE @FromDate END
				,@ToDate	= CASE SName WHEN 'ToImportedDate' THEN CONVERT(SMALLDATETIME, SValue) ELSE @ToDate END
			FROM dbo.LicSystemSetting WITH (NOLOCK)
			WHERE ProductId = 31
		END TRY
		BEGIN CATCH
			SELECT @Msg = 'Wrong value on <b>LicSystemSetting</b> table'
		END CATCH

		IF @FromDate IS NULL OR @ToDate IS NULL
			SELECT @Msg = 'Wrong value on <b>LicSystemSetting</b> table'
	END

	DECLARE @CheckData TABLE
	(
		TableName			VARCHAR(50)
		,userId				VARCHAR(16)
		,eventID			INT
		,marketID			VARCHAR(50)
		,settledDate		DATETIME
		,resettledDate		DATETIME
		,profitLoss			MONEY
		,marketTotal		MONEY
		,commission			MONEY
		,agentCommission	MONEY
		,stakeTotal			MONEY
	)

	-- Parse XmlData
	IF @Msg = ''
	BEGIN
		DECLARE @ErrCode INT = 0, @ErrMsg NVARCHAR(4000) = ''
		BEGIN TRY
			EXEC dbo.Task_Product3rd_ImportQueue_CheckData_ProcessData
				@ProductId	= 31
				,@ErrCode	= @ErrCode OUTPUT
				,@ErrMsg	= @ErrMsg OUTPUT

			IF @ErrCode <> 0
				SELECT @Msg = @ErrMsg
		END TRY
		BEGIN CATCH
			SELECT @Msg = 'Error occurs when executing Task_Product3rd_ImportQueue_CheckData_ProcessData'
		END CATCH
	END

	-- Check Data
	IF @Msg = ''
	BEGIN
		CREATE TABLE #Source
		(
			userId				VARCHAR(16)
			,eventID			INT
			,marketID			VARCHAR(50)
			,settledDate		DATETIME
			,resettledDate		DATETIME
			,profitLoss			MONEY
			,marketTotal		MONEY
			,commission			MONEY
			,agentCommission	MONEY
			,stakeTotal			MONEY
		)

		CREATE TABLE #Target
		(
			userId				VARCHAR(16)
			,eventID			INT
			,marketID			VARCHAR(50)
			,settledDate		DATETIME
			,resettledDate		DATETIME
			,profitLoss			MONEY
			,marketTotal		MONEY
			,commission			MONEY
			,agentCommission	MONEY
			,stakeTotal			MONEY
		)

		-- Get data
		INSERT INTO #Source
		(
			userId, eventID, marketID, settledDate, resettledDate
			,profitLoss, marketTotal, commission, agentCommission, stakeTotal
		)
		SELECT
			userId, eventID, marketID, settledDate, resettledDate
			,SUM(ISNULL(profitLoss, 0)), SUM(ISNULL(marketTotal, 0)), SUM(ISNULL(commission, 0)), SUM(ISNULL(agentCommission, 0)), SUM(ISNULL(stakeTotal, 0))
		FROM dbo.Sum_winloss_Exchange_CheckData WITH (NOLOCK)
		WHERE settledDate >= @FromDate AND settledDate < DATEADD(DAY, 1, @ToDate)
		GROUP BY
			userId, eventID, marketID, settledDate, resettledDate
		HAVING
			SUM(ISNULL(profitLoss, 0)) <> 0
			OR SUM(ISNULL(marketTotal, 0)) <> 0
			OR SUM(ISNULL(commission, 0)) <> 0
			OR SUM(ISNULL(agentCommission, 0)) <> 0
			OR SUM(ISNULL(stakeTotal, 0)) <> 0

		INSERT INTO #Target
		(
			userId, eventID, marketID, settledDate, resettledDate
			,profitLoss, marketTotal, commission, agentCommission, stakeTotal
		)
		SELECT
			userId, eventID, marketID, settledDate, resettledDate
			,SUM(ISNULL(profitLoss, 0)), SUM(ISNULL(marketTotal, 0)), SUM(ISNULL(commission, 0)), SUM(ISNULL(agentCommission, 0)), SUM(ISNULL(stakeTotal, 0))
		FROM dbo.Sum_winloss_Exchange WITH (NOLOCK)
		WHERE settledDate >= @FromDate AND settledDate < DATEADD(DAY, 1, @ToDate)
		GROUP BY
			userId, eventID, marketID, settledDate, resettledDate
		HAVING
			SUM(ISNULL(profitLoss, 0)) <> 0
			OR SUM(ISNULL(marketTotal, 0)) <> 0
			OR SUM(ISNULL(commission, 0)) <> 0
			OR SUM(ISNULL(agentCommission, 0)) <> 0
			OR SUM(ISNULL(stakeTotal, 0)) <> 0
		-- End Get data
	
		-- Compare data
		INSERT INTO @CheckData
		(
			TableName, userId, eventID, marketID, settledDate, resettledDate
			,profitLoss, marketTotal, commission, agentCommission, stakeTotal
		)
		SELECT 'Sum_winloss_Exchange_CheckData' AS TableName
			,userId, eventID, marketID, settledDate, resettledDate, profitLoss, marketTotal, commission, agentCommission, stakeTotal
		FROM
		(
			SELECT userId, eventID, marketID, settledDate, resettledDate, profitLoss, marketTotal, commission, agentCommission, stakeTotal
			FROM #Source
			EXCEPT
			SELECT userId, eventID, marketID, settledDate, resettledDate, profitLoss, marketTotal, commission, agentCommission, stakeTotal
			FROM #Target
		) AS s

		INSERT INTO @CheckData
		(
			TableName, userId, eventID, marketID, settledDate, resettledDate
			,profitLoss, marketTotal, commission, agentCommission, stakeTotal
		)
		SELECT 'Sum_winloss_Exchange' AS TableName
			,userId, eventID, marketID, settledDate, resettledDate, profitLoss, marketTotal, commission, agentCommission, stakeTotal
		FROM
		(
			SELECT userId, eventID, marketID, settledDate, resettledDate, profitLoss, marketTotal, commission, agentCommission, stakeTotal
			FROM #Target
			EXCEPT
			SELECT userId, eventID, marketID, settledDate, resettledDate, profitLoss, marketTotal, commission, agentCommission, stakeTotal
			FROM #Source
		) AS t
		-- End Compare data

		DROP TABLE #Source
		DROP TABLE #Target

		IF NOT EXISTS (SELECT 1 FROM @CheckData)
		BEGIN
			SELECT @Msg = 'Not found discrepancy data from <b>' + CONVERT(VARCHAR(10), @FromDate, 120) + '</b> to <b>' + CONVERT(VARCHAR(10), @ToDate, 120) + '</b>'
		END
		ELSE
		BEGIN
			SELECT @Msg = 'There is discrepancy data from <b>' + CONVERT(VARCHAR(10), @FromDate, 120) + '</b> to <b>' + CONVERT(VARCHAR(10), @ToDate, 120) + '</b>'
						+ '<table border="1"> '
						+ '<tr>'
							+ '<th>No.</th><th>Table</th><th>userId</th><th>eventID</th><th>marketId</th><th>settledDate</th><th>resettledDate</th>'
							+ '<th>profitLoss</th><th>marketTotal</th><th>commission</th><th>agentCommission</th><th>stakeTotal</th>'
						+ '</tr>'
						+ CAST((SELECT	td = DENSE_RANK() OVER(ORDER BY userId, eventID, marketID), ''
										,td = TableName, ''
										,td = userId, ''
										,td = eventID, ''
										,td = marketId, ''
										,td = CONVERT(VARCHAR(50), settledDate, 121), ''
										,td = ISNULL(CONVERT(VARCHAR(50), resettledDate, 121), 'NULL'), ''
										,td = profitLoss, ''
										,td = marketTotal, ''
										,td = commission, ''
										,td = agentCommission, ''
										,td = stakeTotal, ''
								FROM @CheckData
								ORDER BY userId, eventID, marketID
								FOR XML PATH('tr'), TYPE 
								) AS NVARCHAR(MAX)) + N'</table>'
		END
	END

	EXEC msdb.dbo.sp_send_dbmail
		@recipients		= 'percy.nguyen@starixsoft.com;walter.tran@starixsoft.com;alex.nguyen@starixsoft.com;ann.nguyen@starixsoft.com;pontus@starixsoft.com',
		@subject		= @subject,
		@body			= @Msg,
		@body_format	= 'HTML'
END
GO