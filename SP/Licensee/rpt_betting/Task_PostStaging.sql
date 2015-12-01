
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Task_PostStaging    Script Date: 12/1/2015 2:38:01 AM ******/
CREATE PROCEDURE [dbo].[Task_PostStaging]     
AS  
/*
Created: Viet @ 20121031
Task: clean up staging data to save diskspace
DB: DB052.bodb_licensee

Revisions:
    
Param's Explanation:

*/
SET NOCOUNT ON

TRUNCATE TABLE bodb_licensee.dbo.bettrans
TRUNCATE TABLE bodb_licensee.dbo.match
TRUNCATE TABLE bodb_licensee.dbo.outright

DBCC SHRINKFILE (N'DW_staging_DATA_01', 0, TRUNCATEONLY)	



GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
