/*<info serverAlias="DBSID-bodb02" executers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[SiteDB_Task_BATransaction_CheckAndCorrect]
AS

/*
	Created by: Evan 
	Original: Task_BATransaction_CheckAndCorrect
	Task: Check missing BA tickets for SiteDB
	DB: DBSID-bodb02

	Revisions:
		- 20220724@Evan: Add SP for SiteDB  [Redmine: #175297]
*/

BEGIN
	SET NOCOUNT ON

	-- Query data with DONE status
	DECLARE @BATransaction TABLE (custid INT, transid BIGINT, transdate DATETIME, INDEX IX_transid (transid) )
	DECLARE @BAHistory_Done TABLE (ID INT Identity (1,1) PRIMARY KEY, custid INT, ondate DATETIME, offdate DATETIME)

	INSERT INTO @BAHistory_Done
	SELECT CustID, OnDate, OffDate
	FROM DBCUST.bodb_Licensee.dbo.LicenseeBAHistory l WITH (NOLOCK)
	WHERE LicenseeID IN (
		SELECT s.LicenseeID 
		FROM DBCUST.bodb_Licensee.dbo.LicenseeBAConfig s WITH (NOLOCK)
		WHERE s.EnableBA = 1
	)
	AND l.status = 'Done'

	DECLARE @maxTransId BIGINT
	SELECT @maxTransId = CAST(ISNULL(vvalue,0) AS BIGINT)
	FROM dbo.LICSettings WITH (NOLOCK)
	WHERE vname = 'BA_transid'

	DECLARE @custid INT, @ondate DATETIME, @offdate DATETIME, @cnt INT, @ID INT = 1;

	StartLoop:
		SELECT @custid = custid, @ondate = ondate, @offdate = offdate FROM @BAHistory_Done WHERE ID = @ID

		SELECT @cnt = @@ROWCOUNT
		IF @cnt = 0 GOTO EndLoop

		INSERT INTO @BATransaction
		SELECT custid, transid, transdate
		FROM dbo.bettrans WITH (NOLOCK)
		WHERE custid = @custid
			AND transdate BETWEEN @ondate AND @offdate
			AND tpositiontaking = 0
			AND ( bettype < 31
					OR (bettype BETWEEN 121 AND 999)
					OR (bettype BETWEEN 1301 AND 1399)
					OR (bettype BETWEEN 9001 AND 9399)
					OR (bettype BETWEEN 9400 AND 9998)
					OR (bettype BETWEEN 3900 and 3999)
					OR bettype = 38 -- BetBuilder
				)
			AND bettype NOT IN (901, 911)

		DELETE FROM @BAHistory_Done
		WHERE ID = @ID

		SET @ID = @ID + 1

		GOTO StartLoop
	EndLoop:

	-- Query data with Running status
	DECLARE @BAHistory_Running TABLE (ID INT Identity (1,1) PRIMARY KEY, custid INT, ondate DATETIME)

	INSERT INTO @BAHistory_Running
	SELECT custid, ondate
	FROM DBCUST.bodb_Licensee.dbo.LicenseeBAHistory l WITH (NOLOCK)
	WHERE LicenseeID IN (
		SELECT s.LicenseeID
		FROM DBCUST.bodb_Licensee.dbo.LicenseeBAConfig s WITH (NOLOCK)
		WHERE s.EnableBA = 1
	)
	AND l.Status = 'running'

	DECLARE @custid_r INT, @ondate_r DATETIME, @cnt_r INT, @ID_r INT = 1

	StartLoop_r:
		SELECT @custid_r = custid, @ondate_r = ondate FROM @BAHistory_Running WHERE ID = @ID_r

		SELECT @cnt_r = @@ROWCOUNT
		IF @cnt_r = 0 GOTO EndLoop_r

		INSERT INTO @BATransaction
		SELECT custid, transid, transdate
		FROM dbo.bettrans WITH (NOLOCK)
		WHERE custid = @custid_r
			AND transdate >= @ondate_r
			AND tpositiontaking = 0
			AND ( bettype < 31
					OR (bettype BETWEEN 121 AND 999)
					OR (bettype BETWEEN 1301 AND 1399)
					OR (bettype BETWEEN 9001 AND 9399)
					OR (bettype BETWEEN 9400 AND 9998)
					OR (bettype BETWEEN 3900 and 3999)
					OR bettype = 38 -- BetBuilder
				)
			AND bettype NOT IN (901, 911)

		DELETE FROM @BAHistory_Running
		WHERE ID = @ID_r

		SET @ID_r = @ID_r + 1
		
		GOTO StartLoop_r
	EndLoop_r:
	
	DELETE FROM @BATransaction WHERE transid > @maxTransId

	IF (SELECT COUNT(a.transid)
		FROM @BATransaction a
			LEFT JOIN dbo.LicenseeBATransaction_active b WITH (NOLOCK) ON a.transid = b.transid
		WHERE b.transid IS NULL) > 0
	BEGIN
		DECLARE @BATicket TABLE (TransID BIGINT, Transdate DATETIME)

		INSERT INTO @BATicket(TransID, Transdate)
		SELECT a.transid,a.transdate 
		FROM @BATransaction a
			LEFT JOIN dbo.LicenseeBATransaction_active b WITH (NOLOCK) ON a.transid = b.transid  
		WHERE b.transid IS NULL
   
		DECLARE @tickets VARCHAR(7500)
		DECLARE @alert VARCHAR(8000)

		SELECT @tickets = ''
		SELECT @tickets = @tickets  + CAST(TransID AS VARCHAR(20)) + ','
		FROM @BATicket

		DECLARE @MaxOfFailedCount INT = 1, @FailedCount INT = 0

		IF LEN(RTRIM(LTRIM(@tickets))) > 1
		BEGIN
			INSERT INTO dbo.licenseebatransaction_active (TransID,Transdate, custid, recommend, srecommend)
			SELECT transid, transdate, custid, recommend, srecommend
			FROM dbo.bettrans WITH (NOLOCK)
			WHERE transid in (SELECT transid FROM @BATicket)

			SELECT @MaxOfFailedCount = CONVERT(INT, VValue)
			FROM dbo.LICSettings WITH (NOLOCK)
			WHERE VName = 'BA_MaxOfFailedCount'

			SELECT @FailedCount = CONVERT(INT, VValue)
			FROM dbo.LICSettings WITH (NOLOCK)
			WHERE VName = 'BA_MissingTransID'

			SELECT @FailedCount = @FailedCount + 1

			SELECT @tickets = substring(@tickets,0,len(@tickets)) --remove last comma
		END

		UPDATE dbo.LICSettings WITH (ROWLOCK, UPDLOCK)
		SET VValue = CONVERT(VARCHAR(200), @FailedCount)
			,VValue2 = CASE @FailedCount WHEN 0 THEN '' WHEN 1 THEN @tickets ELSE VValue2 + ',' + @tickets END
		WHERE VName = 'BA_MissingTransID'

		IF @FailedCount > 0 AND @FailedCount >= @MaxOfFailedCount
		BEGIN
			-- Reset setting
			UPDATE dbo.LICSettings WITH (ROWLOCK, UPDLOCK)
			SET VValue = 0
				,VValue2 = ''
			WHERE VName = 'BA_MissingTransID'

			SELECT @alert = 'Missing one or more BA tickets: ' + @tickets + '. The job has just inserted the missing tickets. Current VValue: ' + CAST(ISNULL(@maxTransId, 0) AS VARCHAR(20))
			RAISERROR (@alert, 16, 1)
		END
	END
END
GO
