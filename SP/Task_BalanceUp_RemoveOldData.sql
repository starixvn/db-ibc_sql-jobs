USE [LASDB]
GO

/****** Object:  StoredProcedure [dbo].[Task_BalanceUp_RemoveOldData]    Script Date: 01/20/2015 00:31:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_BalanceUp_RemoveOldData    Script Date: 3/21/2014 1:41:35 PM ******/
CREATE PROCEDURE [dbo].[Task_BalanceUp_RemoveOldData]
AS
/*
	Created by: Victor
	Date: 2014-03-20
	Task: Step 3 - Remove Old data in Bettrans, bettrans_agent
	DB: DBLAS.LASDB
	Revisions:
		
*/
SET NOCOUNT ON

-- Check Step 3 flag
IF NOT EXISTS(SELECT 1 FROM dbo.SystemSettings WHERE VName = 'isWaitingForRemoveData_BU' AND VValue = 1)
BEGIN
	RETURN
END

DECLARE @OldBUDay DATE, @NewBUDay DATE

SELECT @OldBUDay = VValue 
FROM dbo.SystemSettings 
WHERE VName = 'MainDB_OldBUDate'

DECLARE @TmpBUDay TABLE(BUDay DATE, MBDay DATE)
INSERT INTO @TmpBUDay
EXEC bodb02.dbo.Lrf_SelBalanceUpDay
SELECT @NewBUDay = BUDay FROM @TmpBUDay

-- Check completion of IBC's BU process
IF @OldBUDay = @NewBUDay
BEGIN
	RETURN
END

-- Execute step 3 of LAS - BalanceUp process
DECLARE @MaxWLDay DATE
SELECT @MaxWLDay = DATEADD(DAY,-1,@NewBUDay)

EXEC dbo.ExecRep_09_Las @Winlostdate = @MaxWLDay, @parlay = 29

WHILE @OldBUDay < @NewBUDay
BEGIN
	EXEC dbo.ExecRep_02_Las @winlostdate = @OldBUDay

	SELECT @OldBUDay = DATEADD(DAY, 1, @OldBUDay)
	WAITFOR DELAY '00:00:01'
END

-- Update step3 flag
UPDATE LASDB.dbo.SystemSettings
SET VValue = 0
WHERE VName = 'isWaitingForRemoveData_BU'
GO


