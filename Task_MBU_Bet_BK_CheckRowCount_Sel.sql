/*<info serverAlias="DBARC-bodb_Archive" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_MBU_Bet_BK_CheckRowCount_Sel]
	@DateCheck SMALLDATETIME,
	@OutputData VARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20180925@Patrick
	Task: Check consistency data for archiving process

	Revisions:
		- 20180926@Patrick:	Initial - [RedmineId: #101207]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @__tempCount TABLE (rowcnt INT, tableName VARCHAR(128))

	--//sum_winloss
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'sum_winloss' 
	FROM DBAGE.bodb_Summary.dbo.sum_winloss_old WITH(NOLOCK) 
	WHERE winlostdate = @DateCheck
	
	--//bettransLC
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettransLC' 
	FROM dbo.bettransLC_bk WITH(NOLOCK)
	WHERE winlostdate = @DateCheck
	
	--//bettransRnG
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettransRnG' 
	FROM dbo.bettransRnG_bk WITH(NOLOCK) 
	WHERE winlostdate = @DateCheck

	--//translog
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'translog' 
	FROM dbo.translog_BK WITH(NOLOCK)
	WHERE winlostdate = @DateCheck

	--//bettransm
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettransm' 
	FROM dbo.bettransm WITH(NOLOCK)
	WHERE winlostdate = @DateCheck
	
	--//SettlementNG2_Message
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'SettlementNG2_Message' 
	FROM dbo.SettlementNG2_Message_bk WITH(NOLOCK) 
	WHERE eventdate = @DateCheck
	
	--//staging_NG2
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettrans_Staging' 
	FROM dbo.bettrans_Staging_bk b WITH(NOLOCK) 
		INNER JOIN dbo.SettlementNG2_Message_bk m WITH(NOLOCK) ON b.SeqId = m.SeqID
	WHERE m.EventDate = @DateCheck
	
	--//LuckyResult3rd
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'BetLucky3Result' 
	FROM dbo.BetLucky3Result_bk WITH(NOLOCK) 
	WHERE WinlostDate = @DateCheck

	--//bettrans
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettrans' 
	FROM dbo.bettrans_bk WITH(NOLOCK) 
	WHERE winlostdate = @DateCheck
	
	--//
	SELECT @OutputData = (
		SELECT rowcnt AS r, tableName AS t
		FROM @__tempCount
		FOR XML RAW ('r')
	)

END
GO
