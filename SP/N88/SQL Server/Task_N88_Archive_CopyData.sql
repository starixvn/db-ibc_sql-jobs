/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_N88_Archive_CopyData]
	@WinlostDate SMALLDATETIME
AS

/*
	Created: 20220222@Percy
	DB: DBN88-bodb_N88
	Task: Job - Archive data for TpBetRecord - Copy data

	Revisions:
		- 20220222@Percy: Initialize SP [RedmineID: #167823]
*/

BEGIN
	SET NOCOUNT ON

	IF EXISTS (SELECT 1 FROM bodb_N88_Archive.dbo.TpBetRecord_bk WITH (NOLOCK) WHERE WinlostDate = @WinlostDate)
		DELETE bodb_N88_Archive.dbo.TpBetRecord_bk WITH (ROWLOCK, UPDLOCK) WHERE WinlostDate = @WinlostDate 

	INSERT INTO bodb_N88_Archive.dbo.TpBetRecord_bk
	(
		TpId,TransId,GameType,CustId,UserName,CurrencyId,SiteId,TpUserName,TransTime,SettledTime
		,Stake,WinlostAmount,SettlementType,TicketStatus,OriginalState,TicketKey,CreateTime,WinlostDate
		,ValidBet,BonusId,Revenue,ProgressiveBet,ProgressiveWin
	)
	SELECT
		TpId,TransId,GameType,CustId,UserName,CurrencyId,SiteId,TpUserName,TransTime,SettledTime
		,Stake,WinlostAmount,SettlementType,TicketStatus,OriginalState,TicketKey,CreateTime,WinlostDate
		,ValidBet,BonusId,Revenue,ProgressiveBet,ProgressiveWin
	FROM dbo.TpBetRecord WITH (NOLOCK)
	WHERE WinlostDate = @WinlostDate
END
GO