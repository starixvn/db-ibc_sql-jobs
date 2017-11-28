USE [bodb_PlaytechCS]
GO
/****** Object:  StoredProcedure [dbo].[Task_GoldDeluxe_ImportDataToDB]    Script Date: 11/28/2017 3:41:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_GoldDeluxe_ImportDataToDB    Script Date: 1/16/2017 18:13:39 ******/
ALTER PROCEDURE [dbo].[Task_GoldDeluxe_ImportDataToDB]
    @XmlData NVARCHAR(MAX),
    @LicenseeName VARCHAR(50),
    @ErrCode INT = 0 OUTPUT,
    @ErrMsg NVARCHAR(500) = '' OUTPUT
AS 
/*
Created: 20150310@Winnie
Task : [[Task_GoldDeluxe_ImportDataToDB]]
Description: Pulling GD bet tickets from API
DB: DBPTCS.bodb_PlaytechCS

Original:

Revisions:
    - 20161104@Jim: use bettime instead of balancetime
	- 20161227@Francis: put cmd into a queue to run background to reduce server's loading [RedmineID: #68972]

Param explanation:

*/
BEGIN
	SET NOCOUNT ON
	--Insert data into queue
	DECLARE @XmlText XML
	BEGIN TRY
		SET @XmlData = REPLACE(REPLACE (@XmlData,CHAR(10),''),CHAR(13),'')
		SELECT @XmlText = CONVERT (XML,@XmlData)
		
		INSERT INTO Product3rd_ImportQueue (CheckInTime, LicenseeName, ProductID, XmlData)
			SELECT CURRENT_TIMESTAMP, @LicenseeName, 11, @XmlText
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
	END CATCH
END