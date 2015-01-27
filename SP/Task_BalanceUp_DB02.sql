USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_BalanceUp_DB02]    Script Date: 01/26/2015 23:19:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Task_BalanceUp_DB02]
	@fdate as datetime
AS
/*
Created by:  
Date:  
Task: Call from DBTRANS
DB: DB02.bodb02
Revisions:
	-- 20130603@Sophia: Put Delete code into ExecRep_APL_03

*/
SET NOCOUNT ON

	EXEC ExecRep_APL_02 @fdate


GO


