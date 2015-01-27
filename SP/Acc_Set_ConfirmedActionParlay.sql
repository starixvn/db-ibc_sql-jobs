USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Acc_Set_ConfirmedActionParlay]    Script Date: 01/26/2015 23:51:08 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Acc_Set_ConfirmedActionParlay    Script Date: 6/21/2013 7:19:12 PM ******/

CREATE PROCEDURE [dbo].[Acc_Set_ConfirmedActionParlay]
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
 *	•
 * Parameters:
	@MatchIDs: list matchId
 */
SET NOCOUNT ON

BEGIN
		EXEC Acc_Apl_ExecRep_01 @matchids=@matchids
END
GO

GRANT EXECUTE ON [dbo].[Acc_Set_ConfirmedActionParlay] TO [bodbAdminNet] AS [dbo]
GO


