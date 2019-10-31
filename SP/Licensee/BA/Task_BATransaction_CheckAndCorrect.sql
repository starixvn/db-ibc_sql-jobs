/*<info serverAlias="DBEXT-bodb02,DBACC-bodb02,DB042-bodb02" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_BATransaction_CheckAndCorrect]  
AS  
/*  
	Created by:[Henry]  
	Date: 2011-06-20  
	Task: Check missing BA tickets  
	DB: DBEXT.bodb02, DBACC.bodb02
	
	Revisions:   
		- 20110824@Henry: Insert the missing tickets if happen  
		- 20110905@Jamie: Modify remove comma ','  
		- 20111208@Jim: change bettype condition   
		- 20150204@Don: Expand bet type ranges for Sportbook when processing BA  
		- 20150904@Patrick: Exclude bettype 901 for bettrade
		- 20170410@Harper: Implement Cashout Product
		- 20180806@Patrick: Sync BA ticket to DB042 [Redmine #98631]
		- 20181114@Sophia: Revise Job Verify BA - Rename SP from Task_BATransaction_Check To Task_BATransaction_CheckAndCorrect [Redmine: #103653]
		- 20181120@Sophia: Change 'DB052' To 'DB053' for step switch to DB053 [Redmine: #103653]
		- 20180412@Percy: Expand Sportsbook bettype range - ESports [RedmineID: #100721]
		- 20190226@Percy: Apply config setting to raiserror [RedmineID: #109415]
		- 20190311@Parsons: Implement BetBuilder [Redmine: #108995]
		- 20190625@Percy: Change 'DB053' To 'DB052' for step switch to DB052 [Redmine: #103658]
		- 20191010@Percy: Remove table LicenseeBATransaction [RedmineID: #103656]
*/  
SET NOCOUNT ON   
   
 --Query data with DONE status  
DECLARE @BATransaction TABLE (custid INT, transid BIGINT, transdate DATETIME)  
  
DECLARE @BAHistory_Done TABLE (custid INT, ondate DATETIME, offdate DATETIME)  
INSERT INTO @BAHistory_Done  
SELECT custid, ondate, offdate  
FROM bodb_Licensee.dbo.LicenseeBAHistory WITH (nolock)  
WHERE LicenseeID IN (
	SELECT LicenseeID 
	FROM bodb_Licensee.dbo.LicenseeBAConfig (NOLOCK) 
	WHERE EnableBA = 1
)  
AND status = 'Done'

DECLARE @maxTransId BIGINT
SELECT  @maxTransId = cast(isnull(vvalue,0) AS BIGINT)
FROM bodb_licensee.dbo.LICSettings WITH (NOLOCK)   
WHERE vname = 'BA_transid'
  
DECLARE @custid INT, @ondate DATETIME, @offdate DATETIME, @cnt INT

IF @@SERVERNAME IN ('DB042', 'DB054')
BEGIN
	StartLoop_042:
		SELECT TOP 1 @custid = custid, @ondate = ondate, @offdate = offdate FROM @BAHistory_Done  
         
		SELECT @cnt = @@ROWCOUNT
		IF @cnt = 0 GOTO EndLoop_042
  
			INSERT INTO @BATransaction
			SELECT custid, transid, transdate
			FROM bettrans WITH (NOLOCK)
			WHERE custid = @custid
				AND transdate BETWEEN @ondate AND @offdate
				AND tpositiontaking = 0
				AND ( bettype < 31
						OR (bettype BETWEEN 121 AND 999)
						OR (bettype BETWEEN 1301 AND 1399)
						OR (bettype BETWEEN 9001 AND 9399)
						OR bettype = 38 -- BetBuilder
					)
				AND bettype NOT IN (901, 911)
				AND statusID IN (0, 1)
                   
		DELETE FROM @BAHistory_Done WHERE custid = @custid AND ondate = @ondate AND offdate = @offdate
  
		GOTO StartLoop_042
	EndLoop_042:
END
ELSE
BEGIN
	StartLoop:
		SELECT TOP 1 @custid = custid, @ondate = ondate, @offdate = offdate FROM @BAHistory_Done  
         
		SELECT @cnt = @@ROWCOUNT
		IF @cnt = 0 GOTO EndLoop
  
			INSERT INTO @BATransaction
			SELECT custid, transid, transdate
			FROM bettrans WITH (NOLOCK)
			WHERE custid = @custid
				AND transdate BETWEEN @ondate AND @offdate
				AND tpositiontaking = 0
				AND ( bettype < 31
						OR (bettype BETWEEN 121 AND 999)
						OR (bettype BETWEEN 1301 AND 1399)
						OR (bettype BETWEEN 9001 AND 9399)
						OR bettype = 38 -- BetBuilder
					)
				AND bettype NOT IN (901, 911)
                   
		DELETE FROM @BAHistory_Done WHERE custid = @custid AND ondate = @ondate AND offdate = @offdate
  
		GOTO StartLoop
	EndLoop:
END
  
--Query data with Running status  
DECLARE @BAHistory_Running TABLE (custid INT, ondate DATETIME)  
INSERT INTO @BAHistory_Running  
SELECT custid, ondate  
FROM bodb_Licensee.dbo.LicenseeBAHistory WITH (NOLOCK)  
WHERE LicenseeID IN (
	SELECT LicenseeID 
	FROM bodb_Licensee.dbo.LicenseeBAConfig (NOLOCK) 
	WHERE EnableBA = 1
)  
AND STATUS = 'running'  
  
DECLARE @custid_r INT, @ondate_r DATETIME, @cnt_r INT

IF @@SERVERNAME IN ('DB042', 'DB054')
BEGIN
	StartLoop_r_042:
		SELECT TOP 1 @custid_r = custid, @ondate_r = ondate FROM @BAHistory_Running
         
		SELECT @cnt_r = @@ROWCOUNT
		IF @cnt_r = 0 GOTO EndLoop_r_042
  
			INSERT INTO @BATransaction
			SELECT custid, transid, transdate
			FROM bettrans WITH (NOLOCK)
			WHERE custid = @custid_r
				AND transdate >= @ondate_r
				AND tpositiontaking = 0
				AND ( bettype < 31
						OR (bettype BETWEEN 121 AND 999)
						OR (bettype BETWEEN 1301 AND 1399)
						OR (bettype BETWEEN 9001 AND 9399)
						OR bettype = 38 -- BetBuilder
					)  
				AND bettype NOT IN (901, 911)
				AND statusID IN (0, 1)
         
		DELETE FROM @BAHistory_Running WHERE custid = @custid_r AND ondate = @ondate_r  
  
		GOTO StartLoop_r_042
	EndLoop_r_042:
END
ELSE
BEGIN
	StartLoop_r:  
		SELECT TOP 1 @custid_r = custid, @ondate_r = ondate FROM @BAHistory_Running  
         
		SELECT @cnt_r = @@ROWCOUNT  
		IF @cnt_r = 0 GOTO EndLoop_r  
  
			INSERT INTO @BATransaction
			SELECT custid, transid, transdate
			FROM bettrans WITH (NOLOCK)
			WHERE custid = @custid_r
				AND transdate >= @ondate_r
				AND tpositiontaking = 0
				AND ( bettype < 31
						OR (bettype BETWEEN 121 AND 999)
						OR (bettype BETWEEN 1301 AND 1399)
						OR (bettype BETWEEN 9001 AND 9399)
						OR bettype = 38 -- BetBuilder
					)  
				AND bettype NOT IN (901, 911)
         
		DELETE FROM @BAHistory_Running WHERE custid = @custid_r AND ondate = @ondate_r  
  
		GOTO StartLoop_r  
	EndLoop_r:
END

DELETE FROM @BATransaction WHERE transid > @maxTransId
  
IF (SELECT count(a.transid)   
	FROM @BATransaction a  
		LEFT JOIN bodb_licensee.dbo.LicenseeBATransaction_active b (nolock) ON a.transid = b.transid  
	WHERE b.transid IS NULL) > 0  
BEGIN  
	DECLARE @BATicket TABLE (TransID BIGINT, Transdate DATETIME)  
   
	INSERT INTO @BATicket(TransID, Transdate)  
	SELECT a.transid,a.transdate 
	FROM @BATransaction a  
		LEFT JOIN bodb_licensee.dbo.LicenseeBATransaction_active b (nolock) ON a.transid = b.transid  
	WHERE b.transid IS NULL  
   
	DECLARE @tickets VARCHAR(7500)  
	DECLARE @alert VARCHAR(8000)
   
	SELECT @tickets=''  
	SELECT @tickets =@tickets  + CAST(TransID AS varchar(20)) + ','  
	FROM @BATicket

	DECLARE @MaxOfFailedCount INT = 1, @FailedCount INT = 0

	IF LEN(RTRIM(LTRIM(@tickets))) > 1  
	BEGIN  
		INSERT INTO bodb_licensee.dbo.licenseebatransaction_active (TransID,Transdate, custid, recommend, srecommend)  
		SELECT transid, transdate, custid, recommend, srecommend  
		FROM dbo.bettrans with(nolock)  
		where transid in (select transid from @BATicket)

		SELECT @MaxOfFailedCount = CONVERT(INT, VValue)
		FROM bodb_licensee.dbo.LICSettings WITH (NOLOCK)
		WHERE VName = 'BA_MaxOfFailedCount'

		SELECT @FailedCount = CONVERT(INT, VValue)
		FROM bodb_licensee.dbo.LICSettings WITH (NOLOCK)
		WHERE VName = 'BA_MissingTransID'

		SELECT @FailedCount = @FailedCount + 1

		SELECT @tickets = substring(@tickets,0,len(@tickets)) --remove last comma
	END

	UPDATE bodb_licensee.dbo.LICSettings WITH (ROWLOCK, UPDLOCK)
	SET VValue = CONVERT(VARCHAR(200), @FailedCount)
		,VValue2 = CASE @FailedCount WHEN 0 THEN '' WHEN 1 THEN @tickets ELSE VValue2 + ',' + @tickets END
	WHERE VName = 'BA_MissingTransID'

	IF @FailedCount > 0 AND @FailedCount >= @MaxOfFailedCount
	BEGIN
		-- Reset setting
		UPDATE bodb_licensee.dbo.LICSettings WITH (ROWLOCK, UPDLOCK)
		SET VValue = 0
			,VValue2 = ''
		WHERE VName = 'BA_MissingTransID'
  
		SELECT @alert = 'Missing one or more BA tickets: ' + @tickets + '. The job has just inserted the missing tickets. Current VValue: ' + CAST(ISNULL(@maxTransId, 0) AS VARCHAR(20))
		RAISERROR (@alert, 16, 1)    
	END
END
GO