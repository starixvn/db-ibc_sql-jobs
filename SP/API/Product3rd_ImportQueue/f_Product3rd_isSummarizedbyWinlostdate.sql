/*<info serverAlias="DBLIC-bodb_3rdProduct" executers="" viewers="" isFunction="1" isNested="1"></info>*/
USE [bodb_3rdProduct]
GO

ALTER FUNCTION [dbo].[f_Product3rd_isSummarizedbyWinlostdate]
(
	@Winlostdate	DATETIME,
	@RefTable		TINYINT
)
RETURNS TABLE
AS

/*
	Created by Percy
	Date: 2018-01-05
	DB: DBLIC.bodb_3rdProduct
	Task: Check winlostdate is summarized or not

	Revisions:
		- 20180105@Percy: Initialize function [RedmineID: #87526]

	Param's Explanation:
		@RefTable:
			0: all tables
			1: rptDepWinlost_ThirdParty
			2: rpt_BettingByProduct
			3: bettrans
*/

RETURN
	SELECT CASE WHEN COUNT(1) = 0 THEN 0 ELSE 1 END AS IsExists
	FROM dbo.Product3rd_SummarizedDateHistory WITH (NOLOCK)
	WHERE WinlostDate = @Winlostdate
		AND
		(
			(@RefTable = 0 AND SumToThirdPartyDate IS NULL AND SumToBettingProductDate IS NULL AND SumToBettransDate IS NULL)
			OR (@RefTable = 1 AND SumToThirdPartyDate IS NULL)
			OR (@RefTable = 2 AND SumToBettingProductDate IS NULL)
			OR (@RefTable = 3 AND SumToBettransDate IS NULL)
		)
GO