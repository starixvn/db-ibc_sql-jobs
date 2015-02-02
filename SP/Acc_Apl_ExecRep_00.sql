USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Acc_Apl_ExecRep_00]    Script Date: 01/27/2015 23:06:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Acc_Apl_ExecRep_00    Script Date: 7/8/2013 1:56:44 PM ******/

CREATE PROCEDURE  [dbo].[Acc_Apl_ExecRep_00]		
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
	• 2013/07/01@Dan: support auto setllement
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
BEGIN
	-- When action is UnSettle, we need update all action status before to true.
	IF(@action=0)
	BEGIN
		UPDATE match_log WITH(ROWLOCK, UPDLOCK) SET [Disabled] = 1	WHERE matchid = @matchid
	END
	-- Insert into match_log
	INSERT INTO match_log(Matchid, Hthomescore, Htawayscore, FinalHomeScore, FinalAwayScore, BetStatus, GoalRecord, ActionId)
	VALUES(@matchid, @hth, @hta, @fth, @fta, @betstatus, @goalrecord, @action)

	IF (@@SERVERNAME IN ('DB215\SQL2012', 'SDBTRANS1', 'SDBTRANS2')) -- TransDB server in Apollo system
		EXEC [Admin_AutoSettlement_GenerateCommand]
			@matchids= '', 
			@matchid = @matchid,
			@actionID = @action,
			@fth = @fth,
			@fta = @fta,
			@hth = @hth,
			@hta = @hta,
			@goalrecord = @goalrecord,
			@betstatus  = @betstatus
END
GO

GRANT EXECUTE ON [dbo].[Acc_Apl_ExecRep_00] TO [bodbAdminNet] AS [dbo]
GO


