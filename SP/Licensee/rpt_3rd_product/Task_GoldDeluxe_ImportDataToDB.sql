/*<info serverAlias="DBPTCS-bodb_PlaytechCS,DBBAL-bodb_PlaytechCS" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
USE [bodb_PlaytechCS]
GO

ALTER PROCEDURE [dbo].[Task_GoldDeluxe_ImportDataToDB]
    @XmlData		NVARCHAR(MAX),
    @LicenseeName	VARCHAR(50),
	@JobType		TINYINT = 0,
    @ErrCode		INT = 0 OUTPUT,
    @ErrMsg			NVARCHAR(500) = '' OUTPUT
AS

/*
	Created: 20150310@Winnie
	DB: DBPTCS.bodb_PlaytechCS,DBBAL-bodb_PlaytechCS
	Task: Gold Deluxe - Import raw data from API - Import into queue

	Revisions:
		- 20161104@Jim: use bettime instead of balancetime
		- 20161227@Francis: put cmd into a queue to run background to reduce server's loading [RedmineID: #68972]
		- 20181003@Percy: Using colum JobType to apply Tip [RedmineID: #70177]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
		- 20221104@Sol: Deposit - AWS - Modify jobs of separated wallet - Move columns setting to new table - [RedmineID: #176479]

	Param explanation:
		. JobType:
			0: bettrans_GoldDeluxe
			1: GoldDeluxe_Tip
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @XmlText XML
	DECLARE @ListQueueID TABLE(QueueID BIGINT)

	BEGIN TRY
		SET @XmlData = REPLACE(REPLACE(@XmlData, CHAR(10), ''), CHAR(13), '')
		SELECT @XmlText = CONVERT(XML, @XmlData)
		
		INSERT INTO Product3rd_ImportQueue (CheckInTime, LicenseeName, ProductID, XmlData, JobType)
		OUTPUT inserted.QueueID INTO @ListQueueID(QueueID)
		SELECT CURRENT_TIMESTAMP, @LicenseeName, 11, @XmlText, @JobType

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
GO