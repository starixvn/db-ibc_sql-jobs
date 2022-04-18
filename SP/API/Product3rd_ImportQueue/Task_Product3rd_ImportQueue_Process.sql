/*<info serverAlias="DBPTCS-bodb_PlaytechCS,DBBAL-bodb_PlaytechCS" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Product3rd_ImportQueue_Process]
AS

/*
	Created: 20171218@Percy
	DB: DBPTCS.bodb_PlaytechCS,DBBAL-bodb_PlaytechCS
	Task: Import raw data from Product3rd_ImportQueue

	Revisions:
		- 20171218@Percy: Initalize SP [RedmineID: #88325]
		- 20180926@Sophia: migrate bodb_Licensee from DB052 to DBCUST - remove linked server DBLIC [redmine: #99855]
		- 20181003@Percy: Using colum JobType to apply Tip [RedmineID: #70177]
		- 20200417@Percy: Integrate Novacash's products [RedmineID: #129873]
		- 20201012@Malcolm :  Change email Starixsoft.com to starixvn.com [RedmineId : #143312]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
		- 20220222@Percy: Remove Novacash's products [RedmineID: #167823]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @ErrCode INT, @ErrMsg NVARCHAR(2000)

	DECLARE @ErrTable TABLE (ProductId INT, ErrCode INT, ErrMsg NVARCHAR(2000))

	-- Gold Deluxe
	BEGIN
		-- 1. bettrans_GoldDeluxe -- Jobtype = 0
		SELECT @ErrCode = 0, @ErrMsg = ''
		EXEC dbo.Task_GoldDeluxe_ImportDataToDB_Queue @JobType = 0, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrTable (ProductId, ErrCode, ErrMsg)
			VALUES (11, @ErrCode, @ErrMsg)
		END

		-- 2. GoldDeluxe_Tip -- Jobtype = 1
		SELECT @ErrCode = 0, @ErrMsg = ''
		EXEC dbo.Task_GoldDeluxe_ImportDataToDB_Queue @JobType = 1, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrTable (ProductId, ErrCode, ErrMsg)
			VALUES (11, @ErrCode, @ErrMsg)
		END
	END

	-- AG Casino
	BEGIN
		SELECT @ErrCode = 0, @ErrMsg = ''
		EXEC dbo.Task_AGCasino_ImportDataToDB_Queue @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrTable (ProductId, ErrCode, ErrMsg)
			VALUES (10, @ErrCode, @ErrMsg)
		END
	END

	-- Exchange
	BEGIN
		SELECT @ErrCode = 0, @ErrMsg = ''
		EXEC bodb_3rdProduct.dbo.Task_Product3rd_ImportQueue_ProcessData @ProductID = 31, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrTable (ProductId, ErrCode, ErrMsg)
			VALUES (31, @ErrCode, @ErrMsg)
		END
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
													td = CASE WHEN e.ProductId = 0 THEN 'Novacash' ELSE p.ProductName END, '',
													td = e.ErrMsg, ''
										FROM @ErrTable e
											LEFT JOIN bodb_licensee.dbo.Product3rd p WITH (NOLOCK) ON e.ProductId = p.ProductID
										FOR XML PATH('tr'), TYPE 
									) AS NVARCHAR(MAX) ) + N'</table>'
			
		EXEC msdb.dbo.sp_send_dbmail
			@recipients		= 'percy.nguyen@starixvn.com;sophia.nguyen@starixvn.com;pontus@starixvn.com',
			@subject		= @subject,
			@body			= @Msg,
			@body_format	= 'HTML'
	END
END
GO