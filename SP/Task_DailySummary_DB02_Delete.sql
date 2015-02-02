USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_DailySummary_DB02_Delete]    Script Date: 02/01/2015 22:50:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Task_DailySummary_DB02_Delete]
	@winlostdate datetime
AS

	-- Run on DB02 (ProductDB)
	-- call by TransDB : Task_DailySummary
	-- 20110802@Sylvia: Delete Dot_Admin_Assignment_Operator
	-- 20121031@Sylvia: Delete SS_GameState
	-- 20130520@Victor: Add Delete VSOutright by eventdate
	-- 20130531@Sophia: Put Delete code into ExecRep_APL_01
	
BEGIN

	EXEC ExecRep_APL_01 @WinlostDate = @Winlostdate

END

GO

GRANT VIEW DEFINITION ON [dbo].[Task_DailySummary_DB02_Delete] TO [vnteam] AS [dbo]
GO


