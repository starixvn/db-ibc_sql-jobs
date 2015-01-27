USE [bodb_staging]
GO

/****** Object:  StoredProcedure [dbo].[CheckData_GetWinlostdate]    Script Date: 01/26/2015 22:37:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CheckData_GetWinlostdate]		
	@date varchar(10) OUTPUT
AS
/*   
 Task: get winlostdate to check data
 DB: DB054.bodb_staging
 Revisions:   
  - 20121015@viet: create SP   
*/  
SET NOCOUNT ON	

	SELECT TOP 1 @date = CONVERT(varchar(10), winlostdate, 120)
	FROM dbo.checkdata_setting with(nolock)	
	
	IF @@ROWCOUNT = 0 --if no special date, check the day before yesterday data
	BEGIN
		SELECT @date = CONVERT(varchar(10), DATEADD(dd, -2, current_timestamp), 120)
	END		
	
SET NOCOUNT OFF

GO


