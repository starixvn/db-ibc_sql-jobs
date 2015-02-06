USE [master]
GO
/****** Object:  StoredProcedure [dbo].[TASK_CheckFreeSpace]    Script Date: 02/04/2015 23:18:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[TASK_CheckFreeSpace]
AS
BEGIN
	DECLARE @MB_Free INT 
	CREATE TABLE #FreeSpace(Drive CHAR(1), MB_Free INT) 

	INSERT INTO #FreeSpace EXEC xp_fixeddrives 
	SELECT @MB_Free = MB_Free FROM #FreeSpace WHERE Drive = 'C' 

	-- Free Space on C drive Less than Threshold 
	IF (@MB_Free < 500)
	BEGIN
		PRINT @MB_Free
		RAISERROR('C: OS and system database partition free space is now lower than 500MB ',16,1)
	END

	SELECT @MB_Free = MB_Free FROM #FreeSpace WHERE Drive = 'G' 
	-- Free Space on G drive Less than Threshold 
	IF (@MB_Free < 20000)
	BEGIN
		PRINT @MB_Free
		RAISERROR('G: Data partition free space is now lower than 20GB ',16,1)
	END
	
	SELECT @MB_Free = MB_Free FROM #FreeSpace WHERE Drive = 'H' 
	-- (RS) Free Space on H drive Less than Threshold 
	IF (@MB_Free < 2000)
	BEGIN
		PRINT @MB_Free
		RAISERROR('H-RS: Data partition free space is now lower than 2GB ',16,1)
	END

	DROP TABLE #FreeSpace 

END

