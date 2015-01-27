USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Acc_Set_ConfirmedAction]    Script Date: 01/26/2015 23:52:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Acc_Set_ConfirmedAction    Script Date: 7/8/2013 1:56:44 PM ******/

CREATE PROCEDURE  [dbo].[Acc_Set_ConfirmedAction]		
@matchid INT,
@action tinyint,
@fth smallint = NULL,
@fta smallint = NULL,
@hth smallint = NULL,
@hta smallint = NULL,
@goalrecord varchar(50)= NULL,
@betstatus nvarchar(50) = NULL
AS	
/**
 * Created by	: Kaden
 * Date			: 20130318
 * Task			: Update Confirmed Action value
 * DB			: SVRTRANS/TransDB
 * Revisions	:
 *	•
 * Parameters:
	@ConfirmedAction: new action
	@action: action key (0: Unsettlement; 1-9: Calculate; 11-19: Refund)
	@fth: finalhomescore,
	@fta: finalawayscore,
	@hth: hthomescore,
	@hta: htawayscore,
	@goalrecord: Goal Record,
	@betstatus: Bet Status
 */

SET NOCOUNT ON
EXEC [Acc_Apl_ExecRep_00]		
	@matchid = @matchid,
	@action = @action,
	@fth = @fth,
	@fta = @fta,
	@hth = @hth,
	@hta = @hta,
	@goalrecord = @goalrecord,
	@betstatus  = @betstatus
GO

GRANT EXECUTE ON [dbo].[Acc_Set_ConfirmedAction] TO [bodbAdminNet] AS [dbo]
GO


