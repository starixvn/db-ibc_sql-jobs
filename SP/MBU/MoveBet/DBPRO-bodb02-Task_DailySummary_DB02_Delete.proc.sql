SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE [dbo].[Task_DailySummary_DB02_Delete]
	@winlostdate datetime
AS
/*
	-- Run on DB02 (ProductDB)
	-- call by TransDB : Task_DailySummary

	Revisions
		-- 20110802@Sylvia: Delete Dot_Admin_Assignment_Operator
		-- 20121031@Sylvia: Delete SS_GameState
		-- 20130520@Victor: Add Delete VSOutright by eventdate
		-- 20130531@Sophia: Put Delete code into ExecRep_APL_01
		-- 20190323@Patrick: Set deadlock priority to high [RedmineId: #113997]
*/
BEGIN
	SET DEADLOCK_PRIORITY HIGH

	EXEC ExecRep_APL_01 @WinlostDate = @Winlostdate

END
GO
/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/