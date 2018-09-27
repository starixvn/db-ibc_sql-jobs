/*<info serverAlias="DBPTCS-bodb_PlaytechCS" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_PlaytechCS]
GO

ALTER PROCEDURE [dbo].[Task_Product3rd_ImportQueue_Process]
AS

/*
	Created by Percy
	Date: 2017-12-18
	DB: DBPTCS.bodb_PlaytechCS
	Task: Import raw data

	Revisions:
		- 20171218@Percy: Initalize SP [RedmineID: #88325]
		- 20180926@Sophia: migrate bodb_Licensee from DB052 to DBCUST - remove linked server DBLIC [redmine: #99855]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @ErrCode INT, @ErrMsg NVARCHAR(2000)

	DECLARE @ErrTable TABLE (ProductId INT, ErrCode INT, ErrMsg NVARCHAR(2000))

	-- Gold Deluxe
	SELECT  @ErrCode = 0, @ErrMsg = ''
	EXEC dbo.Task_GoldDeluxe_ImportDataToDB_Queue @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
	BEGIN
		INSERT INTO @ErrTable (ProductId, ErrCode, ErrMsg)
		VALUES (11, @ErrCode, @ErrMsg)
	END

	-- AG Casino
	SELECT  @ErrCode = 0, @ErrMsg = ''
	EXEC dbo.Task_AGCasino_ImportDataToDB_Queue @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
	BEGIN
		INSERT INTO @ErrTable (ProductId, ErrCode, ErrMsg)
		VALUES (10, @ErrCode, @ErrMsg)
	END

	-- Exchange
	SELECT  @ErrCode = 0, @ErrMsg = ''
	EXEC bodb_3rdProduct.dbo.Task_Product3rd_ImportQueue_ProcessData @ProductID = 31, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
	BEGIN
		INSERT INTO @ErrTable (ProductId, ErrCode, ErrMsg)
		VALUES (31, @ErrCode, @ErrMsg)
	END

	DECLARE @Subject VARCHAR(1000) = '', @Msg NVARCHAR(MAX) 

	-- In case having error
	IF EXISTS (SELECT 1 FROM @ErrTable)
	BEGIN
		SELECT @Subject = 'SQL Server Job System: ''Import data from API'' failed on ' + @@SERVERNAME

		SELECT @Msg = '<H3>List products have wrong data</H3>'
						+ '<table border="1"> '
						+ '<tr><th>No.</th><th>Product</th><th>Error Message</th></tr>'
						+ CAST(( SELECT    td = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)), '',
													td = p.ProductName, '',
													td = e.ErrMsg, ''
										FROM @ErrTable e
											INNER JOIN bodb_licensee.dbo.Product3rd p WITH (NOLOCK) ON e.ProductId = p.ProductID
										FOR XML PATH('tr'), TYPE 
									) AS NVARCHAR(MAX) ) + N'</table>'
			
		EXEC msdb.dbo.sp_send_dbmail
			@recipients		= 'jamie.dao@starixsoft.com;percy.nguyen@starixsoft.com;pontus@starixsoft.com',
			@subject		= @subject,
			@body			= @Msg,
			@body_format	= 'HTML'
	END
END
GO