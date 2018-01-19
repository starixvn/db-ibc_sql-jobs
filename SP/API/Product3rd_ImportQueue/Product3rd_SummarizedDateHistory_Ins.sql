/*<info serverAlias="DBLIC-bodb_3rdProduct" executers="" viewers="" isFunction="0" isNested="1"></info>*/
USE [bodb_3rdProduct]
GO

ALTER PROCEDURE [dbo].[Product3rd_SummarizedDateHistory_Ins]
	@winlostdatelist NVARCHAR(MAX) = ''
AS

/*
	Created by Percy
	Date: 2018-01-05
	DB: DBLIC.bodb_3rdProduct
	Task: Insert winlostdate if it's not summarized

	Revisions:
		- 20180105@Percy: Initial sp [RedmineID: #87526]
*/

BEGIN
	SET NOCOUNT ON

	IF ISNULL(@winlostdatelist, '') = ''
		RETURN

	DECLARE @winlostdate TABLE (winlostdate DATETIME)
	
	INSERT INTO @winlostdate (winlostdate)
	SELECT val FROM bodb02.dbo.strSplit(@winlostdatelist, ',')

	INSERT INTO dbo.Product3rd_SummarizedDateHistory (ProductID, CreatedDate, WinlostDate)
	SELECT 31, GETDATE(), w.winlostdate
	FROM @winlostdate w
		CROSS APPLY dbo.f_Product3rd_isSummarizedbyWinlostdate(winlostdate, 0) f
	WHERE f.IsExists = 0
END
GO