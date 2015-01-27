USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[sp_GetGlobalVariable]    Script Date: 01/27/2015 04:02:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_GetGlobalVariable]
(
    @varName VARCHAR(100),
    @varValue SQL_VARIANT = NULL OUTPUT,
    @NoResultSet bit = 0
)
AS
    SET NOCOUNT ON    
    -- set the output parameter
    SELECT @varValue = varValue 
    FROM   dbo.GlobalVariables 
    WHERE  varName = @varName

    -- also return it as a resultset
    IF @NoResultSet = 0
		SELECT varName, varValue 
		FROM   dbo.GlobalVariables 
		WHERE  varName = @varName
		
    SET NOCOUNT OFF

GO


