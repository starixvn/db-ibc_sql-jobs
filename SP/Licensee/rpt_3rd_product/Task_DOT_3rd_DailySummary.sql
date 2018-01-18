
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Task_DOT_3rd_DailySummary    Script Date: 12/1/2015 2:38:01 AM ******/


ALTER PROCEDURE [dbo].[Task_DOT_3rd_DailySummary]
	@winlostdate datetime
AS

/*	
	Create: 20150323@Patrick
	Task: Daily summary for 3rd products
	DB: DB052.[bodb_3rdProduct]
	Param's Explanation:
		• @winlostdate: The date need to summary

	Revisions:	
	- 20150327@Winnie Add GoldDeluxe_DailySummary
	- 20180102@Harper: Add separate product Exchange_DailySummary [RedmineID: #86640]
*/
BEGIN
	SET NOCOUNT ON	

	-- Execute SP to insert data for GD
	EXEC DBPTCS.bodb_PlaytechCS.dbo.Task_DOT_GoldDeluxe_DailySummary @winlostdate = @winlostdate

	EXEC bodb_3rdproduct.dbo.Task_DOT_VoidBridge_DailySummary @winlostdate = @winlostdate

	EXEC bodb_3rdproduct.dbo.Task_DOT_Exchange_DailySummary @winlostdate = @winlostdate

	--add more 3rd product at here
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
