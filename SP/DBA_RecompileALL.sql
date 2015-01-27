USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[DBA_RecompileALL]    Script Date: 01/27/2015 01:53:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DBA_RecompileALL]
AS 

SET NOCOUNT ON 

-- 1a - Declaration statements for all variables
DECLARE @Lists table ([ID] int PRIMARY KEY IDENTITY (1,1), [Name] varchar(128))
DECLARE @CMD1 varchar(8000)
DECLARE @ID int
DECLARE @SP varchar(128)

INSERT INTO @Lists ([Name])
SELECT [Name]
FROM sys.objects
WHERE Type = 'P'
AND Name <> 'Task_DailySummary'
ORDER BY [Name] DESC



-- 2b - Determine the highest UIDDatabaseList to loop through the records
SELECT @ID = MAX([ID]) FROM @Lists

-- 2c - While condition for looping through the database records
WHILE @ID > 0
BEGIN

	-- 2d - Set the @DatabaseName parameter
	SELECT @SP = [Name]
	FROM @Lists
	WHERE [ID] = @ID

	-- 3f - String together the final backup command
	SELECT @CMD1 = 'EXEC sp_recompile ' + '[' + @SP + ']' + char(13)

	-- 3g - Execute the final string to complete the backups
	-- SELECT @CMD1
	EXEC (@CMD1)
	-- PRINT @CMD1

	-- 2h - Descend through the database list
	SELECT @ID = @ID - 1

	IF RIGHT(CAST(@ID as varchar(10)),2) = '00' WAITFOR DELAY '00:00:01.000'

END

SET NOCOUNT OFF


GO

GRANT VIEW DEFINITION ON [dbo].[DBA_RecompileALL] TO [vnteam] AS [dbo]
GO


