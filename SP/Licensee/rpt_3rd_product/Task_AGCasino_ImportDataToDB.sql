/*<info serverAlias="DBPTCS-bodb_PlaytechCS,DBBAL-bodb_PlaytechCS" executers="" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_AGCasino_ImportDataToDB]
	@XmlData NVARCHAR(MAX),
	@LicenseeName VARCHAR(50),
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(500) = '' OUTPUT
AS 
/*
Created: 20140909@Victor
Task : [Task_AGCasino_ImportDataToDB]
Description: Pulling AG Casino bet tickets from API
DB: DBPTCS.bodb_PlaytechCS,DBBAL-bodb_PlaytechCS

Original:

Revisions:
	- 20141017@Victor: remove time convertion, input data have GMT -4 timezone already
	- 20141218@Winnie: DBA- Modify sp to Fix the issue of missing AG Casino's data(Task #27842)
	- 20161227@Francis: put cmd into a queue to run background to reduce server's loading [RedmineID: #68972]
	- 20210816@Sophia: add DBBAL [Redmine: #154300]
	- 20221104@Sol: Deposit - AWS - Modify jobs of separated wallet - Move columns setting to new table - [RedmineID: #176479]

Param explanation:

*/
BEGIN
	SET NOCOUNT ON
	--Insert data into queue
	DECLARE @XmlText XML
	DECLARE @ListQueueID TABLE(QueueID BIGINT)

	BEGIN TRY
		SET @XmlData = REPLACE(REPLACE (@XmlData,CHAR(10),''),CHAR(13),'')
		SELECT @XmlText = CONVERT (XML,@XmlData)
		
		INSERT INTO Product3rd_ImportQueue (CheckInTime, LicenseeName, ProductID, XmlData)
		OUTPUT inserted.QueueID INTO @ListQueueID(QueueID)
		SELECT CURRENT_TIMESTAMP, @LicenseeName, 10, @XmlText

		---insert into table tracking
		INSERT INTO bodb_LicenseeReport.dbo.Product3rd_ImportQueue_Tracking(QueueID)
		SELECT QueueID 
		FROM @ListQueueID
		---END

	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
	END CATCH
END