/*<info serverAlias="DBLIC-bodb_3rdProduct,DBBAL-bodb_3rdProduct" executers="" viewers="" isFunction="0" isNested="1"></info>*/
USE [bodb_3rdProduct]
GO

ALTER PROCEDURE [dbo].[Product3rd_SummarizedDateHistory_Ins]
	@winlostdatelist NVARCHAR(MAX) = ''
AS

/*
	Created by Percy
	Date: 2018-01-05
	DB: DBLIC.bodb_3rdProduct, DBBAL-bodb_3rdProduct
	Task: Insert winlostdate if it's not summarized

	Revisions:
		- 20180105@Percy: Initialize SP [RedmineID: #87526]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
		- 20221104@Sol: Deposit - AWS - Modify jobs of separated wallet - Move columns setting to new table - [RedmineID: #176479]
*/

BEGIN
	SET NOCOUNT ON

	IF ISNULL(@winlostdatelist, '') = ''
		RETURN

	DECLARE @winlostdate TABLE (winlostdate DATETIME)
	DECLARE @ListIds TABLE (ID BIGINT)
	
	INSERT INTO @winlostdate (winlostdate)
	SELECT val FROM bodb02.dbo.strSplit(@winlostdatelist, ',')

	INSERT INTO dbo.Product3rd_SummarizedDateHistory (ProductID, CreatedDate, WinlostDate)
	OUTPUT inserted.ID INTO @ListIds(ID)
	SELECT 31, GETDATE(), w.winlostdate
	FROM @winlostdate w
		CROSS APPLY dbo.f_Product3rd_isSummarizedbyWinlostdate(winlostdate, 0) f
	WHERE f.IsExists = 0

	---insert data to tracking table
	INSERT INTO bodb_LicenseeReport.dbo.Product3rd_SummarizedDateHistory_Tracking(ID)
	SELECT ID FROM @ListIds
	---END

END
GO