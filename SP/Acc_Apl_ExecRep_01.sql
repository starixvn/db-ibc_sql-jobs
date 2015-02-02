USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Acc_Apl_ExecRep_01]    Script Date: 01/27/2015 23:08:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Acc_Apl_ExecRep_01    Script Date: 7/8/2013 1:56:44 PM ******/

CREATE PROCEDURE [dbo].[Acc_Apl_ExecRep_01]
(
	@matchids	VARCHAR(2000)
) 
AS
/**
 * Created by	: Kaden
 * Date			: 20130402
 * Task			: Update Confirmed Action value for Mix Parlay
 * DB			: SVRTRANS/TransDB
 * Revisions	:
 	• 2013/07/01@Dan: support auto setllement
 * Parameters:
	@MatchIDs: list matchId
 */
SET NOCOUNT ON

BEGIN
	DECLARE @actionid tinyint
	SET @actionid = 5

	INSERT INTO match_log(Matchid, ActionId)
	SELECT	matchid, @actionid	
	FROM dbo.Match WITH (NOLOCK)
	WHERE matchid IN (SELECT val FROM dbo.strSplit(@matchids,','))

	IF (@@SERVERNAME IN ('DB215\SQL2012', 'SDBTRANS1', 'SDBTRANS2')) -- TransDB server in Apollo system
		EXEC [Admin_AutoSettlement_GenerateCommand]
			@matchids= @matchids, 
			@matchid = NULL,
			@actionID = @actionid,
			@fth = NULL,
			@fta = NULL,
			@hth = NULL,
			@hta = NULL,
			@goalrecord = NULL,
			@betstatus  = NULL
END
GO

GRANT EXECUTE ON [dbo].[Acc_Apl_ExecRep_01] TO [bodbAdminNet] AS [dbo]
GO


