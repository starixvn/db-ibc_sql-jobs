USE [LASDB]
GO

/****** Object:  StoredProcedure [dbo].[Task_BalanceUp_TriggerControl]    Script Date: 01/26/2015 22:47:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_BalanceUp_TriggerControl    Script Date: 3/16/2014 4:56:08 PM ******/
CREATE PROCEDURE [dbo].[Task_BalanceUp_TriggerControl]
	@On	bit
AS

/*
Created: 20140315@Victor
Task : Trigger Control
DB: DBLAS.LASDB
Original: Suncity.Task_BalanceUp_TriggerControl

Revisions: 
	
Param's Explanation: 

*/
SET NOCOUNT ON 
	
	IF @On = 1 ENABLE  TRIGGER balance_insert_Bettrans ON BalanceTable_tmp
	IF @On = 0 DISABLE TRIGGER balance_insert_Bettrans ON BalanceTable_tmp

	IF @On = 1 ENABLE  TRIGGER balance_insert_Bettrans_Agent ON BalanceTable_Agent_tmp
	IF @On = 0 DISABLE TRIGGER balance_insert_Bettrans_Agent ON BalanceTable_Agent_tmp


WAITFOR DELAY '000:00:04.000'
GO


