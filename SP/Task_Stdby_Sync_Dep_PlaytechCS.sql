USE [bodb_PlaytechCS]
GO

/****** Object:  StoredProcedure [dbo].[Task_Stdby_Sync_Dep_PlaytechCS]    Script Date: 01/20/2015 05:40:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Task_Stdby_Sync_Dep_PlaytechCS]
AS
/*
Created	: 20140529@Don
Task	: PlaytechCS - Sync data 
DB		: DB054.bodb_PlaytechCS

Revisions:
		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @ServCurrent SYSNAME	= ''
	DECLARE @ServRemote SYSNAME		= ''
 
	SELECT @ServCurrent = @@SERVERNAME
	SELECT @ServRemote  = (SELECT sn FROM OPENQUERY(DBLIC,'SELECT @@SERVERNAME sn'))

	IF @@ERROR != 0
		RETURN

	IF ISNULL(@ServCurrent, '') = ISNULL(@ServRemote, '')
		RETURN

	/* Sync data */
	TRUNCATE TABLE bodb_PlaytechCS.dbo.LicenseeVersionKey

	INSERT INTO bodb_PlaytechCS.dbo.LicenseeVersionKey(LicenseeID,LicenseeName,VersionKey)
	SELECT LicenseeID,LicenseeName,VersionKey FROM DBPTCS.bodb_PlaytechCS.dbo.LicenseeVersionKey WITH(NOLOCK)

	---------------------------
	DECLARE @MAX_TicketID BIGINT = 0
	SELECT @MAX_TicketID = MAX(TicketID) FROM bodb_PlaytechCS.dbo.bettrans_PlaytechCS WITH(NOLOCK)

	INSERT INTO bodb_PlaytechCS.dbo.bettrans_PlaytechCS(
			TicketID,CustID,Transdate,SessionID,GameID,Windowcode,GameName,Stake,Actual_Stake,Winlost,Status,StatusID
			,Username,Winlostdate,PlaytechChagrePercent,PlaytechChargeAmount,PlaytechBalance,BrokenGameBet,LiveNetwork
			,recommend,mrecommend,srecommend,currency,ProgressiveShare,ProgressiveWin)
		SELECT 
			TicketID,CustID,Transdate,SessionID,GameID,Windowcode,GameName,Stake,Actual_Stake,Winlost,Status,StatusID
			,Username,Winlostdate,PlaytechChagrePercent,PlaytechChargeAmount,PlaytechBalance,BrokenGameBet,LiveNetwork
			,recommend,mrecommend,srecommend,currency,ProgressiveShare,ProgressiveWin 
		FROM DBPTCS.bodb_PlaytechCS.dbo.bettrans_PlaytechCS WITH(NOLOCK)
		WHERE TicketID > @MAX_TicketID

END




GO

GRANT VIEW DEFINITION ON [dbo].[Task_Stdby_Sync_Dep_PlaytechCS] TO [vnteam] AS [dbo]
GO


