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
		- 20190806@Patrick: Add transfer_bk - [RedmineId: #118277] 
		- 20191030@Billy:	Remove table [BetLucky3Result] - [Redmine: #122987]
		- 20200728@Brice:	Add 13 tables - [Redmine: #111093]
		- 20210628@Helen:	Move checking for TVS tables to another SP Task_MBU_TVS_BK_CheckRowCount_Sel [RedmineId: #157539]
		- 20230725@Brice: 	remove NG2 [RedmineID: #186722]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @__tempCount TABLE (rowcnt INT, tableName VARCHAR(128))

	DECLARE @__winlostdate SMALLDATETIME
	SET @__winlostdate = @DateCheck

	--//sum_winloss
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'sum_winloss' 
	FROM DBAGE.bodb_Summary.dbo.sum_winloss_old WITH(NOLOCK) 
	WHERE winlostdate = @__winlostdate

	--//bettransLC
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettransLC' 
	FROM dbo.bettransLC_bk WITH(NOLOCK)
	WHERE winlostdate = @__winlostdate

	--//bettransRnG
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettransRnG' 
	FROM dbo.bettransRnG_bk WITH(NOLOCK) 
	WHERE winlostdate = @__winlostdate

	--//translog
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'translog' 
	FROM dbo.translog_BK WITH(NOLOCK)
	WHERE winlostdate = @__winlostdate

	--//bettransm
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettransm' 
	FROM dbo.bettransm WITH(NOLOCK)
	WHERE winlostdate = @__winlostdate

	--//bettrans
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettrans' 
	FROM dbo.bettrans_bk WITH(NOLOCK) 
	WHERE winlostdate = @__winlostdate

	--//transfer
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'transfer'
	FROM dbo.transfer_bk WITH(NOLOCK)
	WHERE winlostdate = @__winlostdate
	
	SELECT @OutputData = (
		SELECT rowcnt AS r, tableName AS t
		FROM @__tempCount
		FOR XML RAW ('r')
	)

END

GO
